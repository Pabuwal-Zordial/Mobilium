#!/usr/bin/env python3
"""Compare Helpdesk, Manager, and Front Desk Profile metadata from Shivam dev."""

import csv
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
META = ROOT / "force-app/main/default"
OUT = ROOT / "access-review"
PROFILES = ["Helpdesk", "Manager", "Front Desk Profile"]
NS = {"m": "http://soap.sforce.com/2006/04/metadata"}

BOOL_DIMS = [
    ("System permission", "userPermissions", "name", ["enabled"]),
    ("Object permission", "objectPermissions", "object", [
        "allowCreate", "allowRead", "allowEdit", "allowDelete",
        "viewAllRecords", "modifyAllRecords", "viewAllFields",
    ]),
    ("Field permission", "fieldPermissions", "field", ["readable", "editable"]),
    ("Apex class access", "classAccesses", "apexClass", ["enabled"]),
    ("Visualforce page access", "pageAccesses", "apexPage", ["enabled"]),
    ("Flow access", "flowAccesses", "flow", ["enabled"]),
]
CATEGORICAL_DIMS = [
    ("Tab visibility", "tabVisibilities", "tab", ["visibility"]),
    ("Application visibility", "applicationVisibilities", "application", ["visible", "default"]),
    ("Record type visibility/default", "recordTypeVisibilities", "recordType", ["visible", "default"]),
]


def value(node, tag, default=""):
    return node.findtext(f"m:{tag}", default=default, namespaces=NS)


def load_profile(name):
    path = META / "profiles" / f"{name}.profile-meta.xml"
    root = ET.parse(path).getroot()
    entries = []
    for label, tag, keytag, props in BOOL_DIMS:
        for node in root.findall(f"m:{tag}", NS):
            resource = value(node, keytag)
            for prop in props:
                if value(node, prop, "false").lower() == "true":
                    entries.append((label, resource, prop, "true"))
    for label, tag, keytag, props in CATEGORICAL_DIMS:
        for node in root.findall(f"m:{tag}", NS):
            resource = value(node, keytag)
            for prop in props:
                prop_value = value(node, prop)
                if prop_value:
                    entries.append((label, resource, prop, prop_value))
    for node in root.findall("m:layoutAssignments", NS):
        layout = value(node, "layout")
        record_type = value(node, "recordType", "")
        if record_type:
            object_name, record_type_name = record_type.split(".", 1)
            resource = f"{object_name}.{record_type_name}"
        else:
            # For master assignments, infer the object from Salesforce's
            # standard `<Object>-<Layout label>` layout full name.
            object_name = layout.split("-", 1)[0]
            resource = f"{object_name}.(master)"
        entries.append(("Page layout", resource, "layout", layout))
    config = {key: value(root, key) for key in ["userLicense", "custom"]}
    return entries, config


def main():
    data = {name: load_profile(name) for name in PROFILES}
    keyed = {
        name: {(dim, resource, prop): val for dim, resource, prop, val in entries}
        for name, (entries, _) in data.items()
    }
    all_keys = set().union(*(set(mapping) for mapping in keyed.values()))
    rows = []
    stats = defaultdict(lambda: {"common": 0, "conflicts": 0, **{f"{p} only": 0 for p in PROFILES}})
    for key in sorted(all_keys, key=lambda item: tuple(part.casefold() for part in item)):
        dim, resource, prop = key
        vals = {name: keyed[name].get(key, "") for name in PROFILES}
        present = {name: val for name, val in vals.items() if val}
        if len(present) == len(PROFILES) and len(set(present.values())) == 1:
            classification = "COMMON_ALL"
            stats[dim]["common"] += 1
        elif len(present) == 1:
            classification = f"{next(iter(present))}_ONLY"
            stats[dim][f"{next(iter(present))} only"] += 1
        elif len(present) > 1:
            classification = "MIXED_OR_CONFLICT"
            stats[dim]["conflicts"] += 1
        else:
            continue
        rows.append({
            "Dimension": dim, "Resource": resource, "Property": prop,
            **{f"{name} value": vals[name] for name in PROFILES},
            "Classification": classification,
        })

    OUT.mkdir(parents=True, exist_ok=True)
    matrix_path = OUT / "Helpdesk_Manager_Front_Desk_Profile_Delta_Matrix.csv"
    with matrix_path.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    report_path = OUT / "Helpdesk_Manager_Front_Desk_Profile_Comparison.md"
    dimensions = [item[0] for item in BOOL_DIMS] + [item[0] for item in CATEGORICAL_DIMS] + ["Page layout"]
    with report_path.open("w", encoding="utf-8") as stream:
        stream.write("# Helpdesk, Manager, and Front Desk Profile Comparison\n\n")
        stream.write("Read-only metadata comparison retrieved from the `Shivam dev` org on 16 October 2026. This is an access-delta analysis, not approval to merge profiles or assign access.\n\n")
        stream.write("## License and profile type\n\n")
        for name, (_, config) in data.items():
            stream.write(f"- **{name}:** user license `{config['userLicense']}`; custom profile `{config['custom']}`.\n")
        licenses = {config["userLicense"] for _, config in data.values()}
        if len(licenses) == 1:
            stream.write(f"\nAll three profiles use the `{next(iter(licenses))}` license.\n\n")
        else:
            stream.write("\n**License mismatch:** these profiles use different user license tiers; license ceilings prevent treating them as interchangeable.\n\n")
        stream.write("## Delta matrix summary\n\n")
        stream.write("`COMMON_ALL` is the same positive grant/configuration on all three profiles. `*_ONLY` is present on only one profile. `MIXED_OR_CONFLICT` is present on multiple profiles with different values, or present on two but absent on the third. Full resource-level rows are in the CSV.\n\n")
        stream.write("| Dimension | Common across all | Helpdesk only | Manager only | Front Desk only | Mixed/conflicting |\n|---|---:|---:|---:|---:|---:|\n")
        for dim in dimensions:
            s = stats[dim]
            stream.write(f"| {dim} | {s['common']} | {s['Helpdesk only']} | {s['Manager only']} | {s['Front Desk Profile only']} | {s['conflicts']} |\n")
        stream.write("\n## Review guidance\n\n")
        stream.write("- Do not merge by taking a simple permission union. That can give every resulting user the combined object, field, and system access of all three personas. Review each `*_ONLY` and mixed row with the business/security owner.\n")
        stream.write("- Check especially system permissions, object `View All`/`Modify All`, sensitive field access, app visibility, record-type defaults, and layout assignments before proposing a shared baseline.\n")
        stream.write("- Profile metadata alone does not show effective access from Permission Sets, Permission Set Groups, licenses, sharing, or role hierarchy.\n")
        stream.write("- A read-only user query returned zero active or inactive users assigned to these three profiles. This means the metadata comparison cannot validate the experience of an existing representative user; check again before implementation.\n")
        stream.write("- No user assignments or org metadata were changed by this retrieval; nothing was deployed.\n")
    print(f"Wrote {len(rows)} comparison rows to {matrix_path.relative_to(ROOT)}")
    print(f"Wrote summary to {report_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
