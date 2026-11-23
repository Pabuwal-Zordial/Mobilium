#!/usr/bin/env python3
"""Build a read-only, permission-based candidate analysis from org exports."""

import csv
import itertools
import re
from urllib.parse import unquote
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REVIEW = ROOT / "access-review"
DATA = REVIEW / "main-env-all-profiles"
PROFILE_DIR = DATA / "profiles"


def local(tag):
    return tag.rsplit("}", 1)[-1]


def read_csv(path):
    with path.open(newline="", encoding="utf-8-sig") as f:
        return list(csv.DictReader(f))


profiles = {}
for path in PROFILE_DIR.glob("*.profile-meta.xml"):
    root = ET.parse(path).getroot()
    name = unquote(path.name.removesuffix(".profile-meta.xml"))
    values = {local(n.tag): n.text for n in root if local(n.tag) != "userPermissions"}
    system = set()
    for node in root:
        if local(node.tag) == "userPermissions":
            fields = {local(c.tag): c.text for c in node}
            if fields.get("enabled", "false").lower() == "true":
                system.add(fields.get("name", ""))
    profiles[name] = {
        "custom": values.get("custom", "false").lower() == "true",
        "license": values.get("userLicense", ""),
        "system": system,
        "object": set(),
        "field": set(),
    }

ids = {}
for row in read_csv(DATA / "profile-permission-set-map.csv"):
    ids[row["ProfileId"]] = row["Name"][1:] if row["Name"].startswith("X") else row["Name"]

# Resolve IDs to exact profile names from the authenticated org's user records
# is not needed: metadata paths provide names, and the mapping file identifies
# profile IDs. Match the generated X<id> PermissionSet names back to profile
# IDs, then use profile XML ordering only if a direct mapping is supplied below.
# Salesforce profile IDs are also captured in profile permission reports by
# joining through profile-owned PermissionSets; the mapping CSV's Name is X+ID.
profile_ids_by_name = defaultdict(list)
# The current org's metadata names are pulled from the adjacent inventory built
# from Profile metadata and the ID map. Reconcile via a local optional mapping.
id_name_file = DATA / "profile-id-name-map.csv"
if id_name_file.exists():
    for row in read_csv(id_name_file):
        profile_name = row.get("ProfileName") or row.get("Profile.Name")
        if row.get("ProfileId") and profile_name:
            profile_ids_by_name[row["ProfileId"]].append(profile_name)

id_to_name = {pid: names[0] for pid, names in profile_ids_by_name.items() if len(names) == 1}
# Fail closed rather than silently attribute permission data to the wrong profile.
if not id_to_name:
    raise SystemExit("Missing profile-id-name-map.csv; export ProfileId/ProfileName mapping before analysis.")

for row in read_csv(DATA / "object-permissions.csv"):
    name = id_to_name.get(row["Parent.ProfileId"])
    if name not in profiles:
        continue
    for key, label in (
        ("PermissionsRead", "Read"),
        ("PermissionsCreate", "Create"),
        ("PermissionsEdit", "Edit"),
        ("PermissionsDelete", "Delete"),
        ("PermissionsViewAllRecords", "ViewAll"),
        ("PermissionsModifyAllRecords", "ModifyAll"),
    ):
        if row[key].lower() == "true":
            profiles[name]["object"].add(f"{row['SobjectType']}|{label}")

for row in read_csv(DATA / "field-permissions.csv"):
    name = id_to_name.get(row["Parent.ProfileId"])
    if name not in profiles:
        continue
    if row["PermissionsRead"].lower() == "true":
        profiles[name]["field"].add(f"{row['Field']}|Read")
    if row["PermissionsEdit"].lower() == "true":
        profiles[name]["field"].add(f"{row['Field']}|Edit")


def jaccard(a, b):
    if not a and not b:
        return 1.0
    return len(a & b) / len(a | b)


rows = []
for a_name, b_name in itertools.combinations(sorted(profiles), 2):
    a, b = profiles[a_name], profiles[b_name]
    same_license = a["license"] == b["license"]
    obj = jaccard(a["object"], b["object"])
    fld = jaccard(a["field"], b["field"])
    sys = jaccard(a["system"], b["system"])
    # No cross-license clustering. Compare positive grants only; omitted grants
    # are not interpreted as denials.
    score = 0.3 * sys + 0.3 * obj + 0.4 * fld
    rows.append({
        "Profile A": a_name,
        "Profile B": b_name,
        "License match": same_license,
        "License": a["license"] if same_license else f"{a['license']} / {b['license']}",
        "Both custom": a["custom"] and b["custom"],
        "System permission similarity": round(sys, 4),
        "Object permission similarity": round(obj, 4),
        "Field permission similarity": round(fld, 4),
        "Weighted similarity": round(score, 4),
        "Object grant deltas": len(a["object"] ^ b["object"]),
        "Field grant deltas": len(a["field"] ^ b["field"]),
        "System permission deltas": len(a["system"] ^ b["system"]),
    })

rows.sort(key=lambda r: (not (r["License match"] and r["Both custom"]), -r["Weighted similarity"]))
candidate_rows = [r for r in rows if r["License match"] and r["Both custom"]]
candidate_rows.sort(key=lambda r: (-r["Weighted similarity"], r["Profile A"], r["Profile B"]))

with (REVIEW / "Main_Org_Profile_Pairwise_Permission_Similarity.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)

# Greedy complete-link clusters: each member must meet the threshold against
# every other member. This avoids chaining unlike profiles into one group.
threshold = 0.90
groups = []
remaining = set(profiles)
sim = {(r["Profile A"], r["Profile B"]): r for r in rows}

def pair(a, b):
    return sim[tuple(sorted((a, b)))]

for seed_row in candidate_rows:
    a, b = seed_row["Profile A"], seed_row["Profile B"]
    if a not in remaining or b not in remaining or seed_row["Weighted similarity"] < threshold:
        continue
    if not (profiles[a]["custom"] and profiles[b]["custom"] and profiles[a]["license"] == profiles[b]["license"]):
        continue
    group = [a, b]
    for candidate in sorted(remaining - set(group)):
        if profiles[candidate]["custom"] and profiles[candidate]["license"] == profiles[a]["license"] and all(pair(candidate, member)["Weighted similarity"] >= threshold for member in group):
            group.append(candidate)
    groups.append(group)
    remaining.difference_update(group)

inventory = {row["Profile"]: row for row in read_csv(REVIEW / "Main_Org_Profile_Inventory.csv")}
lines = [
    "# Main Org Profile Permission Clustering (Read Only)",
    "",
    "## Scope and method",
    "",
    f"Compared {len(profiles)} profiles using current org profile metadata for license, custom/standard status, and enabled system permissions, plus live profile-owned object and field grants exported from `MobiliumStaging`.",
    "",
    "Candidates are restricted to custom profiles with the same user license. Similarity weights are 30% system permissions, 30% object permissions, and 40% field permissions. Suggested groups use a 0.90 weighted threshold and complete-link membership: every pair in a group must meet the threshold. Similarity is a triage signal, not approval to merge or proof of equivalent effective access.",
    "",
    "The profile-based field-permission export returned 470,297 rows; object-permission export returned 20,101 rows. These are positive grants. The initial Metadata API profile retrieval does not include every profile-only setting, so validate login hours/IP ranges, tab/app visibility, record types, layouts, Apex/VF/flow access, and other profile settings before implementation. Permission Set assignments and role hierarchy also affect effective access.",
    "",
    "## Candidate groups",
    "",
]
clustered = set()
if not groups:
    lines.append("No multi-profile group met the conservative 0.90 threshold. Review the highest-scoring candidate pairs in the CSV; do not lower the threshold without business and access-owner review.")
else:
    for i, group in enumerate(groups, 1):
        clustered.update(group)
        lines.append(f"### Group {i} — {profiles[group[0]]['license']} license")
        lines.append("")
        lines.append(f"{len(group)} profiles; keep as a review candidate only. Names are shown for traceability; grouping is based on measured access signatures, not profile labels.")
        lines.append("")
        lines.append("| Profile | Active users | Inactive users | Notes |")
        lines.append("|---|---:|---:|---|")
        for name in sorted(group):
            item = inventory.get(name, {})
            lines.append(f"| {name} | {item.get('Active Users', 'n/a')} | {item.get('Inactive Users', 'n/a')} | Compare deltas before approval |")
        lines.append("")
        deltas = [pair(x, y) for x, y in itertools.combinations(group, 2)]
        if deltas:
            lines.append(f"Within-group weighted similarity range: {min(r['Weighted similarity'] for r in deltas):.3f}–{max(r['Weighted similarity'] for r in deltas):.3f}.")
            lines.append("")
ungrouped = sorted(set(profiles) - clustered)
lines += ["## Profiles not placed in a candidate group", ""]
if ungrouped:
    lines.append("These profiles either are standard profiles, lack a same-license custom-profile match at the threshold, or were left out by the complete-link grouping rule. Keep separate pending review.")
    lines.append("")
    lines.append("| Profile | License | Custom | Active users | Inactive users |")
    lines.append("|---|---|---:|---:|---:|")
    for name in ungrouped:
        item = inventory.get(name, {})
        lines.append(f"| {name} | {profiles[name]['license']} | {profiles[name]['custom']} | {item.get('Active Users', 'n/a')} | {item.get('Inactive Users', 'n/a')} |")
else:
    lines.append("None.")
lines.append("")
lines += [
    "## Review guidance",
    "",
    "1. Treat each group as a candidate for a common baseline profile only after confirming job function and license compatibility with the client.",
    "2. Move documented, approved additive deltas into permission sets or permission set groups; do not use union-by-default because that can grant excess access.",
    "3. Review system permissions, View All/Modify All, sensitive object/FLS grants, and user assignment counts explicitly. Keep elevated/admin access isolated unless there is a documented requirement.",
    "4. Analyze role hierarchy separately. Roles control record visibility through hierarchy and sharing; they are not interchangeable with profiles or permission sets.",
    "5. Keep all changes in a review branch and validate in a sandbox. This analysis made no org changes and deployed nothing.",
    "",
    "See `Main_Org_Profile_Pairwise_Permission_Similarity.csv` for all pairwise deltas and similarity scores.",
]
(REVIEW / "Main_Org_Profile_Permission_Cluster_Analysis.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Profiles={len(profiles)}; object-permission rows={sum(1 for _ in csv.DictReader((DATA / 'object-permissions.csv').open()))}; field-permission rows={sum(1 for _ in csv.DictReader((DATA / 'field-permissions.csv').open()))}; candidate groups={len(groups)}")
