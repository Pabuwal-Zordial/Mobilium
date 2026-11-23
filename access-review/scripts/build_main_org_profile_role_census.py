#!/usr/bin/env python3
"""Build read-only inventory CSVs from retrieved org metadata and SOQL counts."""

import csv
import json
import subprocess
from collections import Counter
from pathlib import Path
from urllib.parse import unquote
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
ACCESS = ROOT / "access-review"
PROFILE_DIR = ACCESS / "main-env-all-profiles/profiles"
ROLE_DIR = ACCESS / "main-env-all-roles/roles"
DEPS_DIR = ACCESS / "main-env-access-dependencies"
NS = {"m": "http://soap.sforce.com/2006/04/metadata"}
ORG = "MobiliumStaging"


def query(soql):
    result = subprocess.run(
        ["sf", "data", "query", "--query", soql, "--target-org", ORG, "--json"],
        check=True,
        capture_output=True,
        text=True,
    )
    payload = json.loads(result.stdout)
    if payload.get("status") != 0:
        raise RuntimeError(payload.get("message", payload))
    return payload["result"]["records"]


def counts_by_name(records, key):
    counts = {}
    for row in records:
        name = row.get(key) or ""
        if not name:
            continue
        counts.setdefault(name, {"active": 0, "inactive": 0})
        counts[name]["active" if row["IsActive"] else "inactive"] = row["UserCount"]
    return counts


def metadata_files(directory, suffix):
    return sorted(directory.glob(f"*{suffix}"), key=lambda p: p.name.casefold())


def value(node, field):
    return node.findtext(f"m:{field}", "", NS)


def write_csv(path, fields, rows):
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def main():
    profile_user_counts = counts_by_name(
        query("SELECT Profile.Name ProfileName, IsActive, COUNT(Id) UserCount "
              "FROM User GROUP BY Profile.Name, IsActive"),
        "ProfileName",
    )
    role_user_counts = counts_by_name(
        query("SELECT UserRole.Name RoleName, IsActive, COUNT(Id) UserCount "
              "FROM User WHERE UserRoleId != null "
              "GROUP BY UserRole.Name, IsActive"),
        "RoleName",
    )
    no_role_counts = {
        row["IsActive"]: row["UserCount"]
        for row in query("SELECT IsActive, COUNT(Id) UserCount FROM User "
                         "WHERE UserRoleId = null GROUP BY IsActive")
    }

    profile_rows = []
    license_counts = Counter()
    custom_counts = Counter()
    for path in metadata_files(PROFILE_DIR, ".profile-meta.xml"):
        node = ET.parse(path).getroot()
        name = unquote(path.name.removesuffix(".profile-meta.xml"))
        license_name = value(node, "userLicense")
        is_custom = value(node, "custom").lower() == "true"
        counts = profile_user_counts.get(name, {"active": 0, "inactive": 0})
        license_counts[license_name] += 1
        custom_counts["Custom" if is_custom else "Standard"] += 1
        profile_rows.append({
            "Profile": name,
            "Custom": str(is_custom).lower(),
            "User License": license_name,
            "Active Users": counts["active"],
            "Inactive Users": counts["inactive"],
            "Metadata File": str(path.relative_to(ROOT)),
        })
    write_csv(
        ACCESS / "Main_Org_Profile_Inventory.csv",
        ["Profile", "Custom", "User License", "Active Users", "Inactive Users", "Metadata File"],
        profile_rows,
    )

    role_rows = []
    for path in metadata_files(ROLE_DIR, ".role-meta.xml"):
        node = ET.parse(path).getroot()
        developer_name = path.name.removesuffix(".role-meta.xml")
        name = value(node, "name") or developer_name
        counts = role_user_counts.get(name, {"active": 0, "inactive": 0})
        role_rows.append({
            "Role": name,
            "Developer Name": developer_name,
            "Parent Role": value(node, "parentRole"),
            "Case Access": value(node, "caseAccessLevel"),
            "Contact Access": value(node, "contactAccessLevel"),
            "Opportunity Access": value(node, "opportunityAccessLevel"),
            "Active Users": counts["active"],
            "Inactive Users": counts["inactive"],
            "Metadata File": str(path.relative_to(ROOT)),
        })
    write_csv(
        ACCESS / "Main_Org_Role_Inventory.csv",
        ["Role", "Developer Name", "Parent Role", "Case Access", "Contact Access",
         "Opportunity Access", "Active Users", "Inactive Users", "Metadata File"],
        role_rows,
    )

    dependency_counts = {
        folder: len(list((DEPS_DIR / folder).glob("*")))
        for folder in ["permissionsets", "permissionsetgroups", "groups", "queues",
                       "sharingRules", "approvalProcesses"]
    }
    total_users = query("SELECT IsActive, COUNT(Id) UserCount FROM User GROUP BY IsActive")
    user_totals = {row["IsActive"]: row["UserCount"] for row in total_users}
    role_totals = query("SELECT IsActive, COUNT(Id) UserCount FROM User "
                        "WHERE UserRoleId != null GROUP BY IsActive")
    role_assigned = {row["IsActive"]: row["UserCount"] for row in role_totals}

    lines = [
        "# MobiliumStaging Full Org Profile and Role Census",
        "",
        "Read-only inventory of the main org, alias `MobiliumStaging`, org ID `00DO500000i5xb0MAA`, retrieved 2026-10-16. No org metadata or user assignments were changed.",
        "",
        "## Counts",
        "",
        f"- Profiles retrieved: **{len(profile_rows)}** ({custom_counts['Custom']} custom, {custom_counts['Standard']} standard).",
        f"- Roles retrieved: **{len(role_rows)}**.",
        f"- Users: **{user_totals.get(True, 0)} active**, **{user_totals.get(False, 0)} inactive**.",
        f"- Users with roles: **{role_assigned.get(True, 0)} active**, **{role_assigned.get(False, 0)} inactive**.",
        f"- Users without roles: **{no_role_counts.get(True, 0)} active**, **{no_role_counts.get(False, 0)} inactive**.",
        "",
        "### Profile counts by user license",
        "",
        "| User license | Profiles |",
        "|---|---:|",
    ]
    lines.extend(f"| {license_name} | {count} |" for license_name, count in sorted(license_counts.items()))
    lines.extend([
        "",
        "### Retrieved role/access dependencies",
        "",
        "| Metadata type | Components |",
        "|---|---:|",
    ])
    label = {
        "permissionsets": "Permission Sets",
        "permissionsetgroups": "Permission Set Groups",
        "groups": "Public groups",
        "queues": "Queues",
        "sharingRules": "Sharing rules",
        "approvalProcesses": "Approval processes",
    }
    lines.extend(f"| {label[folder]} | {count} |" for folder, count in dependency_counts.items())
    lines.extend([
        "",
        "## Scope implications",
        "",
        "The earlier partner list covers 16 of the org's 105 profiles. A full-org consolidation assessment must first partition by user license; Salesforce, Platform, Identity, Integration, Chatter, Community, Guest, and product-specific licenses cannot be treated as one interchangeable profile pool. Standard profiles and privileged or integration profiles also need separate treatment.",
        "",
        "Role reduction is a separate access-control analysis. Role hierarchy can change record visibility through hierarchy inheritance, sharing rules, groups, and queues. This census identifies 120 roles and direct user counts; it does not yet recommend role merges. The role inventory CSV includes each parent role and role-level Case, Contact, and Opportunity access.",
        "",
        "The generated inventories are snapshots for analysis. Permission Set assignments, Permission Set Group memberships, object sharing, territories, and user business ownership still need to be correlated before proposing user moves or role changes.",
        "",
    ])
    (ACCESS / "Main_Org_Profile_Role_Census.md").write_text("\n".join(lines), encoding="utf-8")
    print(f"Profiles: {len(profile_rows)}; roles: {len(role_rows)}; wrote census and inventory CSVs.")


if __name__ == "__main__":
    main()
