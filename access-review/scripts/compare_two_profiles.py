#!/usr/bin/env python3
"""Compare two Salesforce profiles using the current local org snapshot.

This script is read-only. It reads files under access-review/ and writes a
Markdown report to stdout, or to a path supplied with --output.
"""

import argparse
import csv
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[2]
REVIEW = ROOT / "access-review"
DATA = REVIEW / "main-env-all-profiles"
PROFILE_DIR = DATA / "profiles"


def local(tag):
    return tag.rsplit("}", 1)[-1]


def read_csv(path):
    with path.open(newline="", encoding="utf-8-sig") as stream:
        return list(csv.DictReader(stream))


def profile_records():
    records = {}
    for path in PROFILE_DIR.glob("*.profile-meta.xml"):
        root = ET.parse(path).getroot()
        name = unquote(path.name.removesuffix(".profile-meta.xml"))
        metadata = {}
        system = set()
        for node in root:
            tag = local(node.tag)
            if tag == "userPermissions":
                permission = {local(child.tag): child.text for child in node}
                if permission.get("enabled", "false").lower() == "true":
                    system.add(permission.get("name", ""))
            else:
                metadata[tag] = node.text or ""
        records[name] = {
            "custom": metadata.get("custom", "false").lower() == "true",
            "license": metadata.get("userLicense", ""),
            "system": system,
            "object": set(),
            "field": set(),
            "metadata_file": path,
        }
    return records


def csv_bool(value):
    return (value or "").lower() == "true"


def load_inventory(records):
    id_to_name = {}
    for row in read_csv(DATA / "profile-id-name-map.csv"):
        profile_name = row.get("ProfileName") or row.get("Profile.Name")
        if row.get("ProfileId") and profile_name:
            id_to_name[row["ProfileId"]] = profile_name

    missing = set(id_to_name.values()) - set(records)
    if missing:
        raise ValueError("Profiles in ID map have no metadata XML: " + ", ".join(sorted(missing)))

    for row in read_csv(DATA / "object-permissions.csv"):
        name = id_to_name.get(row.get("Parent.ProfileId", ""))
        if name not in records:
            continue
        for column, label in (
            ("PermissionsRead", "Read"),
            ("PermissionsCreate", "Create"),
            ("PermissionsEdit", "Edit"),
            ("PermissionsDelete", "Delete"),
            ("PermissionsViewAllRecords", "View All"),
            ("PermissionsModifyAllRecords", "Modify All"),
        ):
            if csv_bool(row.get(column)):
                records[name]["object"].add(f"{row['SobjectType']} | {label}")

    for row in read_csv(DATA / "field-permissions.csv"):
        name = id_to_name.get(row.get("Parent.ProfileId", ""))
        if name not in records:
            continue
        if csv_bool(row.get("PermissionsRead")):
            records[name]["field"].add(f"{row['Field']} | Read")
        if csv_bool(row.get("PermissionsEdit")):
            records[name]["field"].add(f"{row['Field']} | Edit")

    users = {}
    for row in read_csv(REVIEW / "Main_Org_Profile_Inventory.csv"):
        users[row["Profile"]] = (row.get("Active Users", ""), row.get("Inactive Users", ""))
    return users


def find_profile(records, requested):
    exact = [name for name in records if name.casefold() == requested.casefold()]
    if len(exact) == 1:
        return exact[0]
    partial = [name for name in records if requested.casefold() in name.casefold()]
    if len(partial) == 1:
        return partial[0]
    if partial:
        raise ValueError(f"'{requested}' is ambiguous. Matches: " + ", ".join(sorted(partial)))
    raise ValueError(f"Profile '{requested}' was not found in {PROFILE_DIR}")


def section(title, shared, only_a, only_b):
    out = [f"## {title}", "", f"- Shared: **{len(shared)}**", f"- Only Profile A: **{len(only_a)}**", f"- Only Profile B: **{len(only_b)}**", ""]
    for label, values in (("Only Profile A", only_a), ("Only Profile B", only_b)):
        out += [f"### {label}", ""]
        if values:
            out.extend(f"- `{value}`" for value in sorted(values))
        else:
            out.append("- None")
        out.append("")
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("profile_a", help="First profile name (exact or unique partial match)")
    parser.add_argument("profile_b", help="Second profile name (exact or unique partial match)")
    parser.add_argument("--output", type=Path, help="Write the Markdown report to this file instead of stdout")
    args = parser.parse_args()

    records = profile_records()
    users = load_inventory(records)
    a_name, b_name = find_profile(records, args.profile_a), find_profile(records, args.profile_b)
    if a_name == b_name:
        parser.error("Choose two different profiles")
    a, b = records[a_name], records[b_name]
    lines = [
        f"# Profile Comparison: {a_name} vs {b_name}",
        "",
        "Read-only comparison from the local `MobiliumStaging` snapshot. This does not modify the org.",
        "",
        "| Attribute | Profile A | Profile B |",
        "|---|---|---|",
        f"| License | {a['license']} | {b['license']} |",
        f"| Custom profile | {a['custom']} | {b['custom']} |",
        f"| Active users | {users.get(a_name, ('unknown', 'unknown'))[0]} | {users.get(b_name, ('unknown', 'unknown'))[0]} |",
        f"| Inactive users | {users.get(a_name, ('unknown', 'unknown'))[1]} | {users.get(b_name, ('unknown', 'unknown'))[1]} |",
        "",
    ]
    if a["license"] != b["license"]:
        lines += ["**License mismatch:** do not treat these profiles as a merge pair. License differences constrain which users and features the resulting profile can support.", ""]
    elif not (a["custom"] and b["custom"]):
        lines += ["**Standard-profile caution:** standard profiles generally should not be treated as ordinary merge candidates. Review platform constraints and assignment impact first.", ""]

    lines += section("System permissions", a["system"] & b["system"], a["system"] - b["system"], b["system"] - a["system"])
    lines += section("Object permissions (CRUD, View All, Modify All)", a["object"] & b["object"], a["object"] - b["object"], b["object"] - a["object"])
    lines += section("Field permissions (FLS)", a["field"] & b["field"], a["field"] - b["field"], b["field"] - a["field"])
    lines += [
        "## Not covered by this snapshot",
        "",
        "This report does not compare page layout assignments, record type defaults, application/tab visibility, login hours/IP ranges, Apex/VF/Flow access, or effective access from assigned Permission Sets/Permission Set Groups and sharing. Review those separately before proposing a merge. A missing grant in the snapshot is not interpreted as proof that the user lacks effective access.",
        "",
    ]
    report = "\n".join(lines)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(report, encoding="utf-8")
        print(f"Wrote {args.output}")
    else:
        sys.stdout.write(report)


if __name__ == "__main__":
    try:
        main()
    except (FileNotFoundError, ValueError) as exc:
        raise SystemExit(str(exc))
