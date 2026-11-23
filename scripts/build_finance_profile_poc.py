#!/usr/bin/env python3
"""Export a read-only, six-profile Finance permission comparison to CSV."""

import csv
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
PROFILE_DIR = ROOT / "force-app/main/default/profiles"
OUT = ROOT / "access-review/Finance_Profile_Grant_Comparison.csv"
NS = {"m": "http://soap.sforce.com/2006/04/metadata"}
PROFILES = [
    "Mobileum- Finance Full Access",
    "Mobileum - Sales Head",
    "Quote Creation Team Member",
    "Mobileum - Finance User Limited",
    "Mobileum - Sales User",
    "Mobileum - Super Sales User",
]


def val(node, key, default=""):
    child = node.find(f"m:{key}", NS)
    return child.text.strip() if child is not None and child.text else default


def parse_grants(root):
    grants = set()
    for item in root.findall("m:userPermissions", NS):
        if val(item, "enabled") == "true":
            grants.add(("System Permission", val(item, "name"), "enabled"))
    for item in root.findall("m:objectPermissions", NS):
        obj = val(item, "object")
        for field in ("allowCreate", "allowRead", "allowEdit", "allowDelete", "viewAllFields", "viewAllRecords", "modifyAllRecords"):
            if val(item, field) == "true":
                grants.add(("Object Permission", obj, field))
    for item in root.findall("m:fieldPermissions", NS):
        target = val(item, "field")
        for field in ("readable", "editable"):
            if val(item, field) == "true":
                grants.add(("Field-Level Security", target, field))
    entries = [
        ("classAccesses", "Apex Class Access", "apexClass", "enabled", "true"),
        ("pageAccesses", "Visualforce Page Access", "apexPage", "enabled", "true"),
        ("flowAccesses", "Flow Access", "flow", "enabled", "true"),
        ("customMetadataTypeAccesses", "Custom Metadata Type Access", "name", "enabled", "true"),
        ("customPermissions", "Custom Permission", "name", "enabled", "true"),
        ("recordTypeVisibilities", "Record Type Visibility", "recordType", "visible", "true"),
        ("applicationVisibilities", "Application Visibility", "application", "visible", "true"),
    ]
    for tag, category, target_key, value_key, expected in entries:
        for item in root.findall(f"m:{tag}", NS):
            if val(item, value_key) == expected:
                detail = f"default={val(item, 'default', 'false')}" if category in ("Record Type Visibility", "Application Visibility") else expected
                grants.add((category, val(item, target_key), detail))
    for tag in ("tabVisibilities", "tabSettings"):
        for item in root.findall(f"m:{tag}", NS):
            visibility = val(item, "visibility")
            if visibility and visibility != "Hidden":
                grants.add(("Tab Visibility", val(item, "tab"), visibility))
    for item in root.findall("m:layoutAssignments", NS):
        grants.add(("Page Layout Assignment", val(item, "recordType", "(master)"), val(item, "layout")))
    return grants


def main():
    per_profile = {}
    for name in PROFILES:
        path = PROFILE_DIR / f"{name}.profile-meta.xml"
        if not path.exists():
            raise FileNotFoundError(path)
        root = ET.parse(path).getroot()
        per_profile[name] = parse_grants(root)

    all_grants = set.union(*per_profile.values())
    common = set.intersection(*per_profile.values())
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.writer(stream)
        writer.writerow(["Category", "Resource", "Grant / Value", "Common to all six", "Profiles with grant", "POC handling"])
        for category, resource, grant in sorted(all_grants, key=lambda row: tuple(x.casefold() for x in row)):
            holders = [name for name in PROFILES if (category, resource, grant) in per_profile[name]]
            is_common = (category, resource, grant) in common
            handling = "Common grant only; validate owner/security need before baseline design" if is_common else "Observed difference only; not an approved permission-set transfer"
            if category == "Page Layout Assignment":
                handling = "No serialized assignments found in scope" if not holders else "Review layout/record-type collision before migration"
            writer.writerow([category, resource, grant, "Yes" if is_common else "No", "; ".join(holders), handling])
    print(f"Profiles: {len(per_profile)}; unique grants: {len(all_grants)}; common grants: {len(common)}; wrote {OUT}")
    for category in sorted({row[0] for row in all_grants}):
        rows = [row for row in all_grants if row[0] == category]
        print(f"{category}: {len(rows)} total, {sum(row in common for row in rows)} common")


if __name__ == "__main__":
    main()
