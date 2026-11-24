#!/usr/bin/env python3
"""Create isolated Finance profile/permission-set metadata for review only."""

import csv
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "access-review/finance-poc/force-app/main/default"
PROFILE_DIR = ROOT / "force-app/main/default/profiles"
USER_CSV = Path("/tmp/mobileum_active_users_department.csv")
NS_URI = "http://soap.sforce.com/2006/04/metadata"
NS = {"m": NS_URI}
ET.register_namespace("", NS_URI)
PROFILES = [
    "Mobileum- Finance Full Access",
    "Mobileum - Sales Head",
    "Quote Creation Team Member",
    "Mobileum - Finance User Limited",
    "Mobileum - Sales User",
    "Mobileum - Super Sales User",
]
DATA_PS = {
    "Mobileum- Finance Full Access": "Fin_Full_Access_Delta",
    "Mobileum - Sales Head": "Fin_Sales_Head_Delta",
    "Mobileum - Finance User Limited": "Fin_Limited_Access_Delta",
    "Mobileum - Sales User": "Fin_Sales_User_Delta",
    "Mobileum - Super Sales User": "Fin_Super_Sales_Delta",
}
SYSTEM_PS = {
    "Mobileum- Finance Full Access": "Fin_Full_Access_System",
    "Mobileum - Sales Head": "Fin_Sales_Head_System",
    "Mobileum - Finance User Limited": "Fin_Limited_Access_System",
    "Mobileum - Sales User": "Fin_Sales_User_System",
    "Mobileum - Super Sales User": "Fin_Super_Sales_System",
}
OBJECT_FLAGS = ("allowCreate", "allowDelete", "allowEdit", "allowRead", "modifyAllRecords", "viewAllFields", "viewAllRecords")
FIELD_FLAGS = ("readable", "editable")


def value(node, key, default=""):
    child = node.find(f"m:{key}", NS)
    return child.text.strip() if child is not None and child.text else default


def sub(parent, name, text=None):
    node = ET.SubElement(parent, f"{{{NS_URI}}}{name}")
    if text is not None:
        node.text = str(text)
    return node


def profile_grants(root):
    grants = set()
    for item in root.findall("m:userPermissions", NS):
        if value(item, "enabled") == "true":
            grants.add(("system", value(item, "name"), "enabled"))
    for item in root.findall("m:objectPermissions", NS):
        obj = value(item, "object")
        for key in OBJECT_FLAGS:
            if value(item, key) == "true":
                grants.add(("object", obj, key))
    for item in root.findall("m:fieldPermissions", NS):
        field = value(item, "field")
        for key in FIELD_FLAGS:
            if value(item, key) == "true":
                grants.add(("field", field, key))
    for item in root.findall("m:recordTypeVisibilities", NS):
        if value(item, "visible") == "true":
            grants.add(("recordType", value(item, "recordType"), f"default={value(item, 'default', 'false')}"))
    return grants


def write_sorted_xml(root, path):
    # Salesforce metadata collections are emitted in stable natural-key order.
    key_tags = {
        "objectPermissions": "object",
        "fieldPermissions": "field",
        "recordTypeVisibilities": "recordType",
        "userPermissions": "name",
    }
    def natural_key(node):
        tag = node.tag.rsplit("}", 1)[-1]
        key_tag = key_tags.get(tag)
        key_node = node.find(f"{{{NS_URI}}}{key_tag}") if key_tag else None
        key = key_node.text.strip() if key_node is not None and key_node.text else ""
        return tag.casefold(), key.casefold()
    root[:] = sorted(list(root), key=natural_key)
    ET.indent(root, space="    ")
    tree = ET.ElementTree(root)
    path.parent.mkdir(parents=True, exist_ok=True)
    tree.write(path, encoding="UTF-8", xml_declaration=True)


def add_object_grants(parent, grants):
    grouped = defaultdict(set)
    existing = parent.findall(f"{{{NS_URI}}}objectPermissions")
    for entry in existing:
        obj = value(entry, "object")
        grouped[obj].update(key for key in OBJECT_FLAGS if value(entry, key) == "true")
        parent.remove(entry)
    for _, obj, perm in grants:
        grouped[obj].add(perm)
    for obj, permissions in sorted(grouped.items(), key=lambda item: item[0].casefold()):
        entry = ET.Element(f"{{{NS_URI}}}objectPermissions")
        for key in OBJECT_FLAGS:
            sub(entry, key, "true" if key in permissions else "false")
        sub(entry, "object", obj)
        parent.append(entry)


def add_field_grants(parent, grants):
    grouped = defaultdict(set)
    for _, field, perm in grants:
        grouped[field].add(perm)
    for field, permissions in sorted(grouped.items(), key=lambda item: item[0].casefold()):
        entry = ET.Element(f"{{{NS_URI}}}fieldPermissions")
        sub(entry, "editable", "true" if "editable" in permissions else "false")
        sub(entry, "field", field)
        sub(entry, "readable", "true" if "readable" in permissions else "false")
        parent.append(entry)


def add_system_grants(parent, grants):
    existing = parent.findall(f"{{{NS_URI}}}userPermissions")
    permissions = {value(entry, "name") for entry in existing if value(entry, "enabled") == "true"}
    for entry in existing:
        parent.remove(entry)
    permissions.update(permission for _, permission, _ in grants)
    for permission in sorted(permissions, key=str.casefold):
        entry = ET.Element(f"{{{NS_URI}}}userPermissions")
        sub(entry, "enabled", "true")
        sub(entry, "name", permission)
        parent.append(entry)


def add_record_types(parent, grants, include_default=True):
    for _, record_type, flag in sorted(grants, key=lambda item: item[1].casefold()):
        is_default = flag.split("=", 1)[1]
        entry = ET.Element(f"{{{NS_URI}}}recordTypeVisibilities")
        if include_default:
            sub(entry, "default", is_default)
        sub(entry, "recordType", record_type)
        sub(entry, "visible", "true")
        parent.append(entry)


def create_profile(common):
    root = ET.Element(f"{{{NS_URI}}}Profile")
    sub(root, "custom", "true")
    add_field_grants(root, {g for g in common if g[0] == "field"})
    add_object_grants(root, {g for g in common if g[0] == "object"})
    add_record_types(root, {g for g in common if g[0] == "recordType"})
    sub(root, "userLicense", "Salesforce")
    add_system_grants(root, {g for g in common if g[0] == "system"})
    path = OUT / "profiles/Finance_POC_Baseline.profile-meta.xml"
    write_sorted_xml(root, path)
    return path


def create_permission_set(api_name, label, category, grants):
    root = ET.Element(f"{{{NS_URI}}}PermissionSet")
    sub(root, "description", f"Finance POC draft only. Source-profile differences for review; not approved or assigned.")
    sub(root, "hasActivationRequired", "false")
    sub(root, "label", label)
    if category == "data":
        add_field_grants(root, {g for g in grants if g[0] == "field"})
        add_object_grants(root, {g for g in grants if g[0] == "object"})
        # PermissionSetRecordTypeVisibility has no <default> field; defaults are profile-only.
        add_record_types(root, {g for g in grants if g[0] == "recordType"}, include_default=False)
    else:
        add_system_grants(root, {g for g in grants if g[0] == "system"})
    path = OUT / f"permissionsets/{api_name}.permissionset-meta.xml"
    write_sorted_xml(root, path)
    return path


def add_validation_prerequisites():
    """Include Salesforce-required dependencies within the metadata component that uses them."""
    for name in ("Fin_Full_Access_System", "Fin_Limited_Access_System", "Fin_Super_Sales_System"):
        path = OUT / f"permissionsets/{name}.permissionset-meta.xml"
        root = ET.parse(path).getroot()
        add_system_grants(root, {("system", perm, "enabled") for perm in ("EditTask", "EmailMass", "EmailSingle")})
        write_sorted_xml(root, path)
    for name in ("Fin_Sales_Head_System", "Fin_Sales_User_System"):
        path = OUT / f"permissionsets/{name}.permissionset-meta.xml"
        root = ET.parse(path).getroot()
        add_system_grants(root, {("system", perm, "enabled") for perm in ("ViewRoles", "ViewSetup")})
        write_sorted_xml(root, path)
    for name in ("Fin_Sales_Head_Delta", "Fin_Sales_User_Delta"):
        path = OUT / f"permissionsets/{name}.permissionset-meta.xml"
        root = ET.parse(path).getroot()
        grants = {("object", "Account", flag) for flag in OBJECT_FLAGS if flag == "allowRead"}
        add_object_grants(root, grants)
        write_sorted_xml(root, path)
    for name in ("Fin_Full_Access_Delta", "Fin_Limited_Access_Delta"):
        path = OUT / f"permissionsets/{name}.permissionset-meta.xml"
        root = ET.parse(path).getroot()
        add_object_grants(root, {("object", "Opportunity", flag) for flag in ("allowRead", "viewAllRecords")})
        write_sorted_xml(root, path)
    for name in ("Fin_Sales_Head_Delta", "Fin_Sales_User_Delta"):
        path = OUT / f"permissionsets/{name}.permissionset-meta.xml"
        root = ET.parse(path).getroot()
        add_object_grants(root, {("object", "Account", flag) for flag in ("allowRead", "viewAllRecords")})
        write_sorted_xml(root, path)
    path = OUT / "permissionsets/Fin_Super_Sales_Delta.permissionset-meta.xml"
    root = ET.parse(path).getroot()
    add_object_grants(root, {("object", "Account", flag) for flag in ("allowRead", "viewAllRecords")})
    write_sorted_xml(root, path)
    for name in ("Fin_Sales_Head_Delta", "Fin_Sales_User_Delta"):
        path = OUT / f"permissionsets/{name}.permissionset-meta.xml"
        root = ET.parse(path).getroot()
        add_object_grants(root, {("object", "Opportunity", "allowRead")})
        write_sorted_xml(root, path)
    for name, grants in {
        "Fin_Full_Access_System": (),
        "Fin_Limited_Access_System": (),
        "Fin_Sales_Head_System": ("CreateCustomizeReports", "RunReports"),
        "Fin_Sales_User_System": ("CreateCustomizeFilters", "CreateCustomizeReports", "RunReports"),
        "Fin_Super_Sales_System": ("CreateCustomizeFilters",),
    }.items():
        path = OUT / f"permissionsets/{name}.permissionset-meta.xml"
        root = ET.parse(path).getroot()
        extra = ()
        if name == "Fin_Full_Access_System":
            extra = ("CreateCustomizeReports", "RunReports")
        elif name == "Fin_Super_Sales_System":
            extra = ("ViewRoles", "ViewSetup")
        add_system_grants(root, {("system", perm, "enabled") for perm in (*grants, *extra)})
        write_sorted_xml(root, path)
    profile_path = OUT / "profiles/Finance_POC_Baseline.profile-meta.xml"
    root = ET.parse(profile_path).getroot()
    # Several shared FLS grants target Opportunity_Legacy_Details__c, whose access
    # requires the parent Opportunity object to be readable.
    add_object_grants(root, {("object", "Opportunity", "allowRead"), ("object", "Opportunity", "viewAllRecords")})
    write_sorted_xml(root, profile_path)


def create_project_name_rule_dependency():
    custom_permission = ET.Element(f"{{{NS_URI}}}CustomPermission")
    sub(custom_permission, "description", "Marks users whose current Sales User profile restricts Project Name edits.")
    sub(custom_permission, "isLicensed", "false")
    sub(custom_permission, "label", "Restrict Project Name Edit")
    custom_path = OUT / "customPermissions/Restrict_Project_Name_Edit.customPermission-meta.xml"
    write_sorted_xml(custom_permission, custom_path)

    permission_set = ET.Element(f"{{{NS_URI}}}PermissionSet")
    entry = ET.Element(f"{{{NS_URI}}}customPermissions")
    sub(entry, "enabled", "true")
    sub(entry, "name", "Restrict_Project_Name_Edit")
    permission_set.append(entry)
    sub(permission_set, "description", "Preserves the existing Project Name edit restriction for users moved off the Mobileum - Sales User profile.")
    sub(permission_set, "hasActivationRequired", "false")
    sub(permission_set, "label", "Sales Project Name Restriction")
    permission_path = OUT / "permissionsets/Sales_Project_Name_Restriction.permissionset-meta.xml"
    write_sorted_xml(permission_set, permission_path)

    rule = ET.parse(ROOT / "force-app/main/default/objects/Project__c/validationRules/Sales_rep_cannot_edit_project_Name.validationRule-meta.xml").getroot()
    formula = rule.find(f"{{{NS_URI}}}errorConditionFormula")
    formula.text = "AND($Permission.Restrict_Project_Name_Edit, ISCHANGED(Name))"
    rule_path = OUT / "objects/Project__c/validationRules/Sales_rep_cannot_edit_project_Name.validationRule-meta.xml"
    ET.indent(rule, space="    ")
    rule_path.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(rule).write(rule_path, encoding="UTF-8", xml_declaration=True)

    if not USER_CSV.exists():
        raise FileNotFoundError(f"Need the active-user export to prepare the dependency assignment list: {USER_CSV}")
    with USER_CSV.open(newline="", encoding="utf-8-sig") as stream:
        users = [row for row in csv.DictReader(stream) if row["Profile.Name"] == "Mobileum - Sales User"]
    output = ROOT / "access-review/finance-poc/Sales_Project_Name_Restriction_Assignment_Proposal.csv"
    with output.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.writer(stream)
        writer.writerow(["User", "Username", "Department", "Current Profile", "Current Role", "Proposed Permission Set", "Status"])
        for user in sorted(users, key=lambda row: (row["Name"], row["Username"])):
            writer.writerow([user["Name"], user["Username"], user["Department"], user["Profile.Name"], user["UserRole.Name"], "Sales_Project_Name_Restriction", "Candidate only; preserves current rule behavior; review before assignment"])
    print(f"Project-name rule dependency: {len(users)} users in assignment proposal")


def main():
    by_profile = {}
    for profile in PROFILES:
        path = PROFILE_DIR / f"{profile}.profile-meta.xml"
        by_profile[profile] = profile_grants(ET.parse(path).getroot())
    common = set.intersection(*by_profile.values())
    profile_path = create_profile(common)
    ps_count = 0
    for profile in PROFILES:
        if profile not in DATA_PS:
            continue  # Quote Creation Team Member remains held out of this POC.
        delta = by_profile[profile] - common
        create_permission_set(DATA_PS[profile], DATA_PS[profile].replace("_", " "), "data", delta)
        create_permission_set(SYSTEM_PS[profile], SYSTEM_PS[profile].replace("_", " "), "system", delta)
        ps_count += 2
    add_validation_prerequisites()
    create_project_name_rule_dependency()
    print(f"Wrote {profile_path}")
    print(f"Wrote {ps_count + 1} candidate permission sets and one Custom Permission/rule refactor. No assignments or deployment manifest were created.")
    print(f"Common baseline grants: {len(common)}; quote profile held out: yes")


if __name__ == "__main__":
    main()
