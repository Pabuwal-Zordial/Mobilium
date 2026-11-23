#!/usr/bin/env python3
"""Export permission intersections and deltas for the 16-profile consolidation proposal."""

import csv
import urllib.parse
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROFILE_DIR = ROOT / "force-app/main/default/profiles"
OUT = ROOT / "access-review/Profile_Consolidation_Delta_Matrix.csv"
NS = {"m": "http://soap.sforce.com/2006/04/metadata"}

GROUPS = {
    "Sales": {
        "baseline": "Sales_Base_Profile",
        "members": {
            "Mobileum - Sales User": ("Sales_User_Access_Delta", "Sales_User_System_Delta"),
            "Mobileum - Sales Head": ("Sales_Head_Access_Delta", "Sales_Head_System_Delta"),
            "Mobileum - Sales User - STDM - APAC": ("STDM_APAC_Access_Delta", "STDM_APAC_System_Delta"),
        },
    },
    "Product": {
        "baseline": "Product_Base_Profile",
        "members": {
            "Mobileum - Product Management": ("Product_Management_Access_Delta", ""),
            "Mobileum - Product Management User": ("Product_Management_User_Access_Delta", "Product_Management_User_System_Delta"),
        },
    },
    "Marketing": {
        "baseline": "Marketing_Base_Profile",
        "members": {
            "Mobileum - Marketing User": ("Marketing_User_Access_Delta", "Marketing_User_System_Delta"),
            "Leads, Accounts and Opportunity Creation Marketing Team": ("Leads_Team_Access_Delta", "Leads_Team_System_Delta"),
        },
    },
    "Finance": {
        "baseline": "Finance_Base_Profile",
        "members": {
            "Mobileum - Finance User Limited": ("Finance_Limited_Access_Delta", "Finance_Limited_System_Delta"),
            "Mobileum- Finance Full Access": ("Finance_Full_Unspaced_Access_Delta", "Finance_Full_Unspaced_System_Delta"),
            "Mobileum - Finance Full Access": ("Finance_Full_Spaced_Access_Delta", ""),
        },
    },
    "ReadAccess": {
        "baseline": "Read_Access_Base_Profile",
        "members": {
            "Mobileum Read Only": ("Mobileum_Read_Only_Access_Delta", "Mobileum_Read_Only_System_Delta"),
            "Read Only1": ("Read_Only1_Access_Delta", ""),
        },
    },
    "Elevated": {
        "baseline": "Elevated_Access_Base_Profile",
        "members": {
            "Mobileum - Super Sales User": ("Super_Sales_Access_Delta", ""),
            "Mobileum Salesops Team Profile": ("Salesops_Access_Delta", "Salesops_System_Delta"),
            "Quote Creation Team Member": ("Quote_Access_Delta", "Quote_System_Delta"),
        },
    },
}

SPECS = (
    ("userPermissions", "name", ("enabled",)),
    ("objectPermissions", "object", (
        "allowCreate", "allowRead", "allowEdit", "allowDelete",
        "viewAllRecords", "modifyAllRecords", "viewAllFields",
    )),
    ("fieldPermissions", "field", ("readable", "editable")),
    ("recordTypeVisibilities", "recordType", ("visible",)),
)


def load_profile_files():
    return {
        urllib.parse.unquote(path.name.removesuffix(".profile-meta.xml")): path
        for path in PROFILE_DIR.glob("*.profile-meta.xml")
    }


def extract_grants(path):
    root = ET.parse(path).getroot()
    grants = set()
    for metadata_type, resource_tag, permission_tags in SPECS:
        for item in root.findall(f"m:{metadata_type}", NS):
            resource = item.findtext(f"m:{resource_tag}", default="", namespaces=NS)
            for permission in permission_tags:
                value = item.findtext(f"m:{permission}", default="false", namespaces=NS)
                if value == "true":
                    grants.add((metadata_type, resource, permission))
    return grants


def main():
    profiles = load_profile_files()
    output_rows = []
    for group_name, group in GROUPS.items():
        members = {
            name: extract_grants(profiles[name])
            for name in group["members"]
        }
        common = set.intersection(*members.values())
        for profile_name, grants in members.items():
            access_ps, system_ps = group["members"][profile_name]
            for metadata_type, resource, permission in sorted(grants, key=lambda row: tuple(x.casefold() for x in row)):
                if (metadata_type, resource, permission) in common:
                    status = "COMMON_BASELINE"
                    permission_set = ""
                else:
                    status = "PROFILE_DELTA"
                    permission_set = system_ps if metadata_type == "userPermissions" else access_ps
                output_rows.append({
                    "Group": group_name,
                    "Source Profile": profile_name,
                    "Grant Classification": status,
                    "Metadata Type": metadata_type,
                    "Resource": resource,
                    "Permission Flag": permission,
                    "Proposed Target": group["baseline"] if status == "COMMON_BASELINE" else permission_set,
                })

    # Hubspot remains unchanged in this proposal; include its current grants as a separate reference.
    hubspot_grants = extract_grants(profiles["Hubspot"])
    for metadata_type, resource, permission in sorted(hubspot_grants, key=lambda row: tuple(x.casefold() for x in row)):
        output_rows.append({
            "Group": "Integration - retained",
            "Source Profile": "Hubspot",
            "Grant Classification": "REVIEW_EXISTING",
            "Metadata Type": metadata_type,
            "Resource": resource,
            "Permission Flag": permission,
            "Proposed Target": "Retain Hubspot profile pending integration review",
        })

    OUT.parent.mkdir(parents=True, exist_ok=True)
    columns = ["Group", "Source Profile", "Grant Classification", "Metadata Type", "Resource", "Permission Flag", "Proposed Target"]
    with OUT.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.DictWriter(stream, fieldnames=columns)
        writer.writeheader()
        writer.writerows(output_rows)
    print(f"Wrote {len(output_rows)} rows to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
