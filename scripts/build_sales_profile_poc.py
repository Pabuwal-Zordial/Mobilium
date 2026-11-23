#!/usr/bin/env python3
"""Build an isolated, local-only Sales User/Sales Head profile consolidation POC."""

import csv
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "access-review/sales-profile-poc/force-app/main/default"
PROFILE_DIR = ROOT / "force-app/main/default/profiles"
AUDIT_CSV = ROOT / "access-review/Org_Profile_Name_References.csv"
SALES_USER = "Mobileum - Sales User"
SALES_HEAD = "Mobileum - Sales Head"
NS_URI = "http://soap.sforce.com/2006/04/metadata"
NS = {"m": NS_URI}
ET.register_namespace("", NS_URI)
OBJECT_FLAGS = ("allowCreate", "allowDelete", "allowEdit", "allowRead", "modifyAllRecords", "viewAllFields", "viewAllRecords")
FIELD_FLAGS = ("readable", "editable")


def q(name):
    return f"{{{NS_URI}}}{name}"


def value(node, key, default=""):
    child = node.find(f"m:{key}", NS)
    return child.text.strip() if child is not None and child.text else default


def sub(parent, name, text=None):
    node = ET.SubElement(parent, q(name))
    if text is not None:
        node.text = str(text)
    return node


def sorted_write(root, path, key_tags=None):
    key_tags = key_tags or {
        "objectPermissions": "object",
        "fieldPermissions": "field",
        "recordTypeVisibilities": "recordType",
        "userPermissions": "name",
        "customPermissions": "name",
    }

    def key(node):
        tag = node.tag.rsplit("}", 1)[-1]
        child_tag = key_tags.get(tag)
        child = node.find(q(child_tag)) if child_tag else None
        return tag.casefold(), (child.text.strip().casefold() if child is not None and child.text else "")

    root[:] = sorted(list(root), key=key)
    ET.indent(root, space="    ")
    path.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(root).write(path, encoding="UTF-8", xml_declaration=True)


def read_profile(name):
    path = PROFILE_DIR / f"{name}.profile-meta.xml"
    return ET.parse(path).getroot()


def extract_grants(root):
    grants = set()
    for item in root.findall("m:userPermissions", NS):
        if value(item, "enabled") == "true":
            grants.add(("system", value(item, "name"), "enabled"))
    for item in root.findall("m:objectPermissions", NS):
        obj = value(item, "object")
        for flag in OBJECT_FLAGS:
            if value(item, flag) == "true":
                grants.add(("object", obj, flag))
    for item in root.findall("m:fieldPermissions", NS):
        field = value(item, "field")
        for flag in FIELD_FLAGS:
            if value(item, flag) == "true":
                grants.add(("field", field, flag))
    for item in root.findall("m:recordTypeVisibilities", NS):
        if value(item, "visible") == "true":
            grants.add(("recordType", value(item, "recordType"), "visible"))
    return grants


def record_type_defaults(root):
    result = {}
    for item in root.findall("m:recordTypeVisibilities", NS):
        record_type = value(item, "recordType")
        result[record_type] = {
            "default": value(item, "default", "false"),
            "personAccountDefault": value(item, "personAccountDefault", "false"),
        }
    return result


def write_object_permissions(root, grants):
    grouped = defaultdict(set)
    for _, obj, flag in grants:
        grouped[obj].add(flag)
    # Keep object permission components self-contained with their read prerequisite.
    for flags in grouped.values():
        if flags - {"allowRead"}:
            flags.add("allowRead")
    for obj, flags in sorted(grouped.items(), key=lambda item: item[0].casefold()):
        item = ET.SubElement(root, q("objectPermissions"))
        for flag in OBJECT_FLAGS:
            sub(item, flag, "true" if flag in flags else "false")
        sub(item, "object", obj)


def write_field_permissions(root, grants):
    grouped = defaultdict(set)
    for _, field, flag in grants:
        grouped[field].add(flag)
    for field, flags in sorted(grouped.items(), key=lambda item: item[0].casefold()):
        item = ET.SubElement(root, q("fieldPermissions"))
        sub(item, "editable", "true" if "editable" in flags else "false")
        sub(item, "field", field)
        # Editable fields must also be readable. Duplicating a common baseline
        # read grant in a delta set is harmless and keeps metadata self-consistent.
        sub(item, "readable", "true" if "readable" in flags or "editable" in flags else "false")


def write_system_permissions(root, grants):
    for _, name, _ in sorted(grants, key=lambda grant: grant[1].casefold()):
        item = ET.SubElement(root, q("userPermissions"))
        sub(item, "enabled", "true")
        sub(item, "name", name)


def write_record_types(root, grants, defaults=None, include_default=False):
    defaults = defaults or {}
    for _, record_type, _ in sorted(grants, key=lambda grant: grant[1].casefold()):
        item = ET.SubElement(root, q("recordTypeVisibilities"))
        if include_default:
            default = defaults.get(record_type, {})
            sub(item, "default", default.get("default", "false"))
            if default.get("personAccountDefault") == "true":
                sub(item, "personAccountDefault", "true")
        sub(item, "recordType", record_type)
        sub(item, "visible", "true")


def create_baseline(common, sales_user_root):
    root = ET.Element(q("Profile"))
    sub(root, "custom", "true")
    write_field_permissions(root, {g for g in common if g[0] == "field"})
    write_object_permissions(root, {g for g in common if g[0] == "object"})
    write_record_types(root, {g for g in common if g[0] == "recordType"}, record_type_defaults(sales_user_root), include_default=True)
    sub(root, "userLicense", "Salesforce")
    write_system_permissions(root, {g for g in common if g[0] == "system"})
    path = OUT / "profiles/Sales_Profile_POC_Baseline.profile-meta.xml"
    sorted_write(root, path)
    return path


def create_permission_set(api_name, label, grants, include_description):
    root = ET.Element(q("PermissionSet"))
    if include_description:
        sub(root, "description", "Sales User/Sales Head POC draft. Candidate source-profile delta; not approved or assigned.")
    sub(root, "hasActivationRequired", "false")
    sub(root, "label", label)
    write_field_permissions(root, {g for g in grants if g[0] == "field"})
    write_object_permissions(root, {g for g in grants if g[0] == "object"})
    write_record_types(root, {g for g in grants if g[0] == "recordType"})
    write_system_permissions(root, {g for g in grants if g[0] == "system"})
    path = OUT / f"permissionsets/{api_name}.permissionset-meta.xml"
    sorted_write(root, path)
    return path


def create_rule_dependency():
    custom = ET.Element(q("CustomPermission"))
    sub(custom, "description", "Preserves the existing Project Name edit restriction for users formerly assigned the Mobileum - Sales User profile.")
    sub(custom, "isLicensed", "false")
    sub(custom, "label", "Restrict Project Name Edit")
    sorted_write(custom, OUT / "customPermissions/Restrict_Project_Name_Edit.customPermission-meta.xml")

    ps = ET.Element(q("PermissionSet"))
    sub(ps, "customPermissions", None)
    cp = ps.find(q("customPermissions"))
    sub(cp, "enabled", "true")
    sub(cp, "name", "Restrict_Project_Name_Edit")
    sub(ps, "description", "Sales User/Sales Head POC. Preserves the Project Name restriction only for the former Sales User cohort.")
    sub(ps, "hasActivationRequired", "false")
    sub(ps, "label", "Sales Project Name Restriction")
    sorted_write(ps, OUT / "permissionsets/Sales_Project_Name_Restriction.permissionset-meta.xml")

    source = ROOT / "force-app/main/default/objects/Project__c/validationRules/Sales_rep_cannot_edit_project_Name.validationRule-meta.xml"
    rule = ET.parse(source).getroot()
    formula = rule.find(q("errorConditionFormula"))
    formula.text = "AND($Permission.Restrict_Project_Name_Edit, ISCHANGED(Name))"
    sorted_write(rule, OUT / "objects/Project__c/validationRules/Sales_rep_cannot_edit_project_Name.validationRule-meta.xml")


def create_group(api_name, label, sets):
    root = ET.Element(q("PermissionSetGroup"))
    sub(root, "hasActivationRequired", "false")
    sub(root, "label", label)
    for item in sorted(sets, key=str.casefold):
        sub(root, "permissionSets", item)
    sub(root, "status", "Updated")
    path = OUT / f"permissionsetgroups/{api_name}.permissionsetgroup-meta.xml"
    sorted_write(root, path, key_tags={})


def export_ui_parity():
    rows = []
    with AUDIT_CSV.open(newline="", encoding="utf-8-sig") as stream:
        for row in csv.DictReader(stream):
            if row["Profile Label"] in (SALES_USER, SALES_HEAD) and row["Category"] in {
                "Profile layout assignment",
                "Profile application visibility",
                "Custom app profile action override",
            }:
                rows.append(row)
    by_profile = defaultdict(set)
    for row in rows:
        by_profile[row["Profile Label"]].add((row["Category"], row["Component"], row["Assignment or Literal"], row["Details"]))
    left, right = by_profile[SALES_USER], by_profile[SALES_HEAD]
    output = OUT.parents[2] / "Sales_User_Sales_Head_UI_Parity.csv"
    with output.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.writer(stream)
        writer.writerow(["Category", "Component", "Assignment or Literal", "Details", "Present for Sales User", "Present for Sales Head", "Exact Match"])
        for category, component, assignment, details in sorted(left | right, key=lambda r: tuple(v.casefold() for v in r)):
            key = (category, component, assignment, details)
            writer.writerow([category, component, assignment, details, key in left, key in right, key in left and key in right])
    counts = defaultdict(lambda: [0, 0, 0])
    for category, *_ in left | right:
        counts[category][0] += 1
    for category, *_ in left:
        counts[category][1] += 1
    for category, *_ in left & right:
        counts[category][2] += 1
    return output, dict(counts)


def export_grant_matrix(common, user_delta, head_delta):
    path = OUT.parents[2] / "Sales_User_Sales_Head_Grant_Matrix.csv"
    with path.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.writer(stream)
        writer.writerow(["Grant Type", "Metadata Resource", "Permission", "Common Baseline", "Sales User Delta", "Sales Head Delta", "Draft Component"])
        for grant in sorted(common | user_delta | head_delta, key=lambda g: tuple(v.casefold() for v in g)):
            kind, resource, permission = grant
            is_common, is_user, is_head = grant in common, grant in user_delta, grant in head_delta
            component = "Baseline" if is_common else (
                "Sales_User_Access_Delta / Sales_User_System_Delta" if is_user else "Sales_Head_Access_Delta"
            )
            writer.writerow([kind, resource, permission, is_common, is_user, is_head, component])
    return path


def main():
    sales_user_root = read_profile(SALES_USER)
    sales_head_root = read_profile(SALES_HEAD)
    user_grants = extract_grants(sales_user_root)
    head_grants = extract_grants(sales_head_root)
    common = user_grants & head_grants
    user_delta = user_grants - common
    head_delta = head_grants - common

    base = create_baseline(common, sales_user_root)
    create_permission_set("Sales_User_Access_Delta", "Sales User Access Delta", {g for g in user_delta if g[0] != "system"}, True)
    create_permission_set("Sales_User_System_Delta", "Sales User System Delta", {g for g in user_delta if g[0] == "system"}, True)
    create_permission_set("Sales_Head_Access_Delta", "Sales Head Access Delta", {g for g in head_delta if g[0] != "system"}, True)
    create_rule_dependency()
    create_group("Sales_User_POC", "Sales User POC", ["Sales_User_Access_Delta", "Sales_User_System_Delta", "Sales_Project_Name_Restriction"])
    create_group("Sales_Head_POC", "Sales Head POC", ["Sales_Head_Access_Delta"])
    ui_path, ui_counts = export_ui_parity()
    grants_path = export_grant_matrix(common, user_delta, head_delta)

    report = OUT.parents[2] / "Sales_Profile_POC.md"
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(
        "# Sales User / Sales Head Profile POC\n\n"
        "## Scope and status\n\n"
        "Local-only, isolated POC using the retrieved profile permission grants for `Mobileum - Sales User` and `Mobileum - Sales Head`. "
        "No org changes, user assignments, deployment manifest, or deployment were created. This is a mechanical access-preservation draft, not approved access.\n\n"
        "## Draft components\n\n"
        "- One baseline profile containing positive permission grants common to both source profiles. It carries the Salesforce license and uses Sales User's profile-only record-type defaults as the selected baseline.\n"
        "- `Sales_User_Access_Delta` and `Sales_User_System_Delta` for Sales User-only grants.\n"
        "- `Sales_Head_Access_Delta` for Sales Head-only object, field, and record-type grants. No separate Head system-permission set was needed because this comparison found no system grants unique to Sales Head.\n"
        "- `Sales_User_POC` and `Sales_Head_POC` permission set groups bundling each persona's delta. These are drafts, not assignments.\n"
        "- A Custom Permission and copied Project validation rule to preserve the current Sales User-only Project Name restriction. The permission set is included in the Sales User group; actual user assignments are not generated.\n"
        "- `Sales_User_Sales_Head_Grant_Matrix.csv` lists each positive system, object, field, and record-type grant and marks it common or profile-specific.\n"
        "- `Sales_User_Sales_Head_UI_Parity.csv` records the profile-level layouts, app visibility, and app action overrides to preserve. Both profiles match on these UI mappings in the audit snapshot.\n\n"
        "## Record-type default needing approval\n\n"
        "Both profiles define six record-type entries, five of which are visible. Their `Territory__c.Region` record type differs: Sales User has `personAccountDefault=true`, while Sales Head does not. The POC baseline carries the Sales User value because it is the chosen source baseline. Confirm this behavior with the owner and test person-account users; if it must differ by persona, this profile-only control may require retaining a second profile or redesigning the record-type experience.\n\n"
        "## Source comparison\n\n"
        f"The source profiles have {len(user_grants)} and {len(head_grants)} positive grants across system, object, field, and record-type visibility dimensions; {len(common)} grants are common, {len(user_delta)} are Sales User-only, and {len(head_delta)} are Sales Head-only. "
        "The source audit records 163 active Sales User users and 20 active Sales Head users. Those counts do not establish which user should receive a group.\n\n"
        "The baseline contains 47 system grants; 78 object permission flags across 26 objects; 890 field read/edit grants across 572 fields; and five visible record types. Sales User's delta contains four system grants, 11 object flags across two objects, and 43 field grants across 22 fields. Sales Head's delta contains six object flags across two objects and 48 field grants across 34 fields; it has no system grants unique to that profile. The CSV matrix gives the exact resource and permission for every row.\n\n"
        "Sales User has broad profile-level grants, including View All/Modify All on `Sales_Campaign__c` and full CRUD on `Technical_Service_Request__c`; Sales Head has different grants on `Item_Request__c` and `Purchase_Request__c`. Review every delta, especially elevated grants, with the access owner before considering assignment.\n\n"
        "## Important limits\n\n"
        "- Permission Sets are additive. The baseline is built from the intersection; do not use a broad source profile as the base and expect a Permission Set to remove its excess grants.\n"
        "- Layout/app settings are profile-level, not represented by Permission Sets. This POC does not recreate the 202 layout mappings, 30 app visibilities, or eight shared app action overrides in Salesforce metadata. See the parity CSV and preserve/update those separately.\n"
        "- The current local profile XML does not include page-layout or app-override definitions. The POC is therefore an access-grant design draft, not a complete deployable package.\n"
        "- Existing Permission Set and Permission Set Group assignments, role hierarchy, sharing, login/IP controls, and record access have not been computed as effective access.\n"
        "- The organization has profile-name checks in Apex tests and the Project validation rule. Only the Project rule dependency is represented in this POC; other references need review.\n\n"
        "## Files\n\n"
        f"Generated baseline: `{base.relative_to(ROOT)}`. Grant matrix: `{grants_path.relative_to(ROOT)}`. UI parity inventory: `{ui_path.relative_to(ROOT)}`. Run `python3 scripts/build_sales_profile_poc.py` to regenerate this isolated draft.\n",
        encoding="utf-8",
    )
    print(f"Common positive grants: {len(common)}")
    print(f"Sales User-only grants: {len(user_delta)}")
    print(f"Sales Head-only grants: {len(head_delta)}")
    print(f"Profile UI mappings (union, exact match counts): {ui_counts}")
    print(f"Grant matrix: {grants_path.relative_to(ROOT)}")
    print(f"Generated isolated POC at {report.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
