#!/usr/bin/env python3
"""Build a review workbook from retrieved Salesforce metadata and org exports."""

import csv
import glob
import os
import re
import zipfile
from collections import Counter, defaultdict
from pathlib import Path
from urllib.parse import unquote
from xml.etree import ElementTree as ET
from xml.sax.saxutils import escape


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "access-review" / "MobiliumStaging_Access_Matrix.xlsx"
USERS_CSV = Path("/tmp/mobileum_active_users.csv")
ASSIGNMENTS_CSV = Path("/tmp/mobileum_permission_assignments.csv")
ADMIN_SYSTEM_CSV = Path("/tmp/mobileum_system_admin_permissions.csv")
ADMIN_OBJECTS_CSV = Path("/tmp/mobileum_system_admin_objects.csv")
ADMIN_FIELDS_CSV = Path("/tmp/mobileum_system_admin_fields.csv")
PLATFORM_SYSTEM_CSV = Path("/tmp/mobileum_standard_platform_permissions.csv")
PLATFORM_OBJECTS_CSV = Path("/tmp/mobileum_standard_platform_objects.csv")
PLATFORM_FIELDS_CSV = Path("/tmp/mobileum_standard_platform_fields.csv")
DEPARTMENT_USERS_CSV = Path("/tmp/mobileum_active_users_department.csv")
NS_URI = "http://soap.sforce.com/2006/04/metadata"
NS = {"m": NS_URI}
ET.register_namespace("", NS_URI)

DEPARTMENT_PROFILES = {
    "Finance": ["Mobileum- Finance Full Access", "Mobileum - Sales Head", "Quote Creation Team Member", "Mobileum - Finance User Limited", "Mobileum - Sales User", "Mobileum - Super Sales User"],
    "Sales": ["Mobileum - Sales User"],
    "Global Delivery": ["Mobileum - Sales User", "Read Only1", "Mobileum - Sales User - STDM - APAC"],
    "Presales": ["Mobileum - Sales User"],
    "Product Management": ["Mobileum - Sales User", "Mobileum - Product Management User", "Mobileum - Marketing User", "Mobileum - Product Management"],
    "Operations": ["Mobileum - Sales Head", "Mobileum - Sales User", "Mobileum - Marketing User", "Quote Creation Team Member"],
    "IT & Systems": ["System Administrator"],
    "Marketing": ["Leads, Accounts and Opportunity Creation Marketing Team", "Mobileum - Sales User", "Hubspot"],
    "Customer Support": ["Mobileum - Sales User"],
    "Managed Services": ["Mobileum - Sales User", "Read Only1"],
    "Integration user": ["Leads, Accounts and Opportunity Creation Marketing Team", "Read Only1", "Mobileum Read Only"],
    "Sales Operations": ["Mobileum Salesops Team Profile", "Mobileum - Super Sales User"],
    "Bid Management": ["Mobileum - Sales Head"],
    "Cloud Operations": ["Mobileum - Sales User"],
    "QMS": ["Mobileum- Finance Full Access"],
    "Engineering": ["Mobileum - Sales Head", "Mobileum - Marketing User"],
    "Administration": ["Mobileum- Finance Full Access", "Mobileum - Finance Full Access"],
    "TSA Production & Shipping": ["Mobileum - Sales User"],
    "Legal": ["Mobileum - Sales User"],
    "CTO Technology": ["Mobileum - Sales User"],
    "PCC Head": ["Mobileum - Sales User"],
    "CEO - Office": ["Mobileum - Sales User"],
}


def read_csv(path):
    with path.open(newline="", encoding="utf-8-sig") as f:
        return list(csv.DictReader(f))


def xml_value(node, name, default=""):
    child = node.find(f"m:{name}", NS)
    return child.text.strip() if child is not None and child.text else default


def bool_value(value):
    return value.lower() == "true"


def profile_grants(root):
    grants = set()
    for item in root.findall("m:objectPermissions", NS):
        for key in ("allowCreate", "allowRead", "allowEdit", "allowDelete", "viewAllFields", "viewAllRecords", "modifyAllRecords"):
            if bool_value(xml_value(item, key, "false")):
                grants.add(("Object Permission", xml_value(item, "object"), key))
    for item in root.findall("m:fieldPermissions", NS):
        for key in ("readable", "editable"):
            if bool_value(xml_value(item, key, "false")):
                grants.add(("Field-Level Security", xml_value(item, "field"), key))
    for item in root.findall("m:userPermissions", NS):
        if bool_value(xml_value(item, "enabled", "false")):
            grants.add(("System Permission", xml_value(item, "name"), "enabled"))
    details = {
        "classAccesses": ("Apex Class Access", "apexClass", "enabled"),
        "pageAccesses": ("Visualforce Page Access", "apexPage", "enabled"),
        "recordTypeVisibilities": ("Record Type Visibility", "recordType", "visible"),
        "applicationVisibilities": ("App Visibility", "application", "visible"),
        "tabVisibilities": ("Tab Visibility", "tab", "visibility"),
        "customPermissions": ("Custom Permission", "name", "enabled"),
    }
    for tag, (kind, target_key, value_key) in details.items():
        for item in root.findall(f"m:{tag}", NS):
            value = xml_value(item, value_key, "false")
            if value == "true" or (kind == "Tab Visibility" and value != "Hidden"):
                grants.add((kind, xml_value(item, target_key), value))
    return grants


def csv_profile_grants(system_path, objects_path, fields_path):
    grants = set()
    for row in read_csv(objects_path):
        for key in ("PermissionsCreate", "PermissionsRead", "PermissionsEdit", "PermissionsDelete", "PermissionsViewAllFields", "PermissionsViewAllRecords", "PermissionsModifyAllRecords"):
            if bool_value(row.get(key, "false")):
                grants.add(("Object Permission", row.get("SobjectType", ""), key))
    for row in read_csv(fields_path):
        for key in ("PermissionsRead", "PermissionsEdit"):
            if bool_value(row.get(key, "false")):
                grants.add(("Field-Level Security", row.get("Field", ""), key))
    system = read_csv(system_path)
    if system:
        for key, value in system[0].items():
            if key.startswith("Permissions") and bool_value(value):
                grants.add(("System Permission", key.removeprefix("Permissions"), "enabled"))
    return grants


def profile_name(path):
    stem = path.name.removesuffix(".profile-meta.xml")
    return unquote(stem)


def metadata_files(folder, suffix):
    result = {}
    for p in sorted((ROOT / "force-app/main/default" / folder).glob(f"*{suffix}")):
        result[unquote(p.name.removesuffix(suffix))] = ET.parse(p).getroot()
    return result


def containers(files, name_key):
    return [(name, root) for name, root in files.items()]


def add_rows_for_access(container_type, name, root, summary, object_rows, field_rows, system_rows, other_rows):
    summary.append([
        container_type, name,
        sum(1 for _ in root.findall("m:objectPermissions", NS)),
        sum(1 for _ in root.findall("m:fieldPermissions", NS)),
        sum(1 for _ in root.findall("m:userPermissions", NS)),
        sum(1 for _ in root.findall("m:classAccesses", NS)),
        sum(1 for _ in root.findall("m:pageAccesses", NS)),
    ])
    for item in root.findall("m:objectPermissions", NS):
        object_rows.append([name, xml_value(item, "object"), *[xml_value(item, k, "false") for k in ("allowCreate", "allowRead", "allowEdit", "allowDelete", "viewAllFields", "viewAllRecords", "modifyAllRecords")]])
    for item in root.findall("m:fieldPermissions", NS):
        field_rows.append([name, xml_value(item, "field"), xml_value(item, "readable", "false"), xml_value(item, "editable", "false")])
    for item in root.findall("m:userPermissions", NS):
        system_rows.append([name, xml_value(item, "name"), xml_value(item, "enabled", "false")])
    tags = {
        "classAccesses": ("Apex Class", "apexClass", "enabled"),
        "pageAccesses": ("Visualforce Page", "apexPage", "enabled"),
        "recordTypeVisibilities": ("Record Type", "recordType", "visible"),
        "applicationVisibilities": ("App", "application", "visible"),
        "tabVisibilities": ("Tab", "tab", "visibility"),
        "tabSettings": ("Tab", "tab", "visibility"),
        "customPermissions": ("Custom Permission", "name", "enabled"),
    }
    for tag, (kind, key, value) in tags.items():
        for item in root.findall(f"m:{tag}", NS):
            other_rows.append([container_type, name, kind, xml_value(item, key), xml_value(item, value)])


def col_name(n):
    out = ""
    while n:
        n, rem = divmod(n - 1, 26)
        out = chr(65 + rem) + out
    return out


def cell_xml(ref, value, header=False):
    style = ' s="1"' if header else ""
    if value is None:
        value = ""
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return f'<c r="{ref}"{style}><v>{value}</v></c>'
    value = str(value)
    return f'<c r="{ref}" t="inlineStr"{style}><is><t xml:space="preserve">{escape(value)}</t></is></c>'


def worksheet_xml(rows):
    out = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>', '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">']
    out.append('<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>')
    out.append('<sheetFormatPr defaultRowHeight="15"/><sheetData>')
    last_col, last_row = 1, 1
    for row_num, row in enumerate(rows, 1):
        last_row, last_col = row_num, max(last_col, len(row))
        out.append(f'<row r="{row_num}">')
        for col_num, value in enumerate(row, 1):
            out.append(cell_xml(f"{col_name(col_num)}{row_num}", value, row_num == 1))
        out.append("</row>")
    out.append(f'</sheetData><autoFilter ref="A1:{col_name(last_col)}{last_row}"/></worksheet>')
    return "".join(out)


def write_xlsx(sheets):
    OUT.parent.mkdir(parents=True, exist_ok=True)
    names = list(sheets)
    content_types = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>', '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>']
    for i in range(1, len(names) + 1):
        content_types.append(f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>')
    content_types.append("</Types>")
    workbook_sheets, rels = [], []
    for i, name in enumerate(names, 1):
        workbook_sheets.append(f'<sheet name="{escape(name)}" sheetId="{i}" r:id="rId{i}"/>')
        rels.append(f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>')
    workbook = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>' + "".join(workbook_sheets) + "</sheets></workbook>"
    styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts><fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills><borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="2"><xf xfId="0"/><xf xfId="0" fontId="1" applyFont="1"/></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>'
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", "".join(content_types))
        z.writestr("_rels/.rels", '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>')
        z.writestr("xl/workbook.xml", workbook)
        z.writestr("xl/_rels/workbook.xml.rels", '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + "".join(rels) + f'<Relationship Id="rId{len(names)+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>')
        z.writestr("xl/styles.xml", styles)
        for i, name in enumerate(names, 1):
            z.writestr(f"xl/worksheets/sheet{i}.xml", worksheet_xml(sheets[name]))


def main():
    users = read_csv(USERS_CSV)
    assignments = read_csv(ASSIGNMENTS_CSV)
    department_users = read_csv(DEPARTMENT_USERS_CSV)
    active_by_profile = Counter(r["Profile.Name"] for r in users if r.get("IsActive", "").lower() == "true" and r.get("Profile.Name"))
    active_by_role = Counter(r["UserRole.Name"] for r in users if r.get("IsActive", "").lower() == "true" and r.get("UserRole.Name"))
    pset_assignments = Counter(r["PermissionSet.Name"] for r in assignments if r.get("PermissionSet.Name") and not r.get("PermissionSetGroup.DeveloperName"))
    pset_labels = {r["PermissionSet.Name"]: r.get("PermissionSet.Label", "") for r in assignments if r.get("PermissionSet.Name") and not r.get("PermissionSetGroup.DeveloperName")}
    group_assignments = Counter(r["PermissionSetGroup.DeveloperName"] for r in assignments if r.get("PermissionSetGroup.DeveloperName"))
    profile_files = {}
    for p in sorted((ROOT / "force-app/main/default/profiles").glob("*.profile-meta.xml")):
        profile_files[profile_name(p)] = ET.parse(p).getroot()
    permission_sets = metadata_files("permissionsets", ".permissionset-meta.xml")
    muting_sets = metadata_files("mutingpermissionsets", ".mutingpermissionset-meta.xml")
    groups = metadata_files("permissionsetgroups", ".permissionsetgroup-meta.xml")
    roles = metadata_files("roles", ".role-meta.xml")

    prof_summary = [["Profile", "Partner Department Mapping", "Metadata Retrieved", "Active User Records", "Object Permission Entries", "Field Permission Entries", "System Permission Entries", "Enabled System Permissions", "Apex Class Entries", "Visualforce Page Entries"]]
    p_obj = [["Profile", "Object", "Create", "Read", "Edit", "Delete", "View All Fields", "View All Records", "Modify All Records"]]
    p_field = [["Profile", "Field", "Readable", "Editable"]]
    p_system = [["Profile", "System Permission", "Enabled"]]
    p_other = [["Permission Container Type", "Container", "Access Type", "Component", "Enabled / Visibility"]]
    for name, root in profile_files.items():
        temp = []
        add_rows_for_access("Profile", name, root, temp, p_obj, p_field, p_system, p_other)
        row = temp[0]
        enabled_system = sum(1 for x in root.findall("m:userPermissions", NS) if bool_value(xml_value(x, "enabled", "false")))
        departments = "; ".join(dept for dept, profiles in DEPARTMENT_PROFILES.items() if name in profiles)
        prof_summary.append([name, departments or "Unmapped in partner table", "Yes", active_by_profile[name], row[2], row[3], row[4], enabled_system, row[5], row[6]])
    fallback_sources = {
        "System Administrator": (ADMIN_SYSTEM_CSV, ADMIN_OBJECTS_CSV, ADMIN_FIELDS_CSV),
        "Standard Platform User": (PLATFORM_SYSTEM_CSV, PLATFORM_OBJECTS_CSV, PLATFORM_FIELDS_CSV),
    }
    profile_grant_sets = {name: profile_grants(root) for name, root in profile_files.items()}
    for name, (system_path, objects_path, fields_path) in fallback_sources.items():
        fallback_object_rows = read_csv(objects_path)
        fallback_field_rows = read_csv(fields_path)
        fallback_system_rows = read_csv(system_path)
        for item in fallback_object_rows:
            p_obj.append([name, item.get("SobjectType", ""), item.get("PermissionsCreate", "false"), item.get("PermissionsRead", "false"), item.get("PermissionsEdit", "false"), item.get("PermissionsDelete", "false"), item.get("PermissionsViewAllFields", "false"), item.get("PermissionsViewAllRecords", "false"), item.get("PermissionsModifyAllRecords", "false")])
        for item in fallback_field_rows:
            p_field.append([name, item.get("Field", ""), item.get("PermissionsRead", "false"), item.get("PermissionsEdit", "false")])
        permission_values = fallback_system_rows[0] if fallback_system_rows else {}
        permission_fields = [key for key in permission_values if key.startswith("Permissions")]
        for field in permission_fields:
            p_system.append([name, field.removeprefix("Permissions"), permission_values[field]])
        departments = "; ".join(dept for dept, profiles in DEPARTMENT_PROFILES.items() if name in profiles)
        enabled_count = sum(1 for field in permission_fields if bool_value(permission_values[field]))
        prof_summary.append([name, departments or "Not mapped in partner table", "SOQL fallback; Profile XML unavailable", active_by_profile[name], len(fallback_object_rows), len(fallback_field_rows), len(permission_fields), enabled_count, "Not retrieved", "Not retrieved"])
        profile_grant_sets[name] = csv_profile_grants(system_path, objects_path, fields_path)
    for name, active_count in sorted(active_by_profile.items()):
        if name not in profile_files:
            if name in fallback_sources:
                continue
            departments = "; ".join(dept for dept, profiles in DEPARTMENT_PROFILES.items() if name in profiles)
            prof_summary.append([name, departments or "Unmapped in partner table", "No", active_count, "Not retrieved", "Not retrieved", "Not retrieved", "Not retrieved", "Not retrieved", "Not retrieved"])

    ps_summary = [["Permission Set", "Label", "Metadata Retrieved", "Active Direct Assignments", "Permission Set Groups containing it", "Object Permission Entries", "Field Permission Entries", "System Permission Entries", "Enabled System Permissions", "Apex Class Entries", "Visualforce Page Entries"]]
    ps_obj = [["Permission Set", "Object", "Create", "Read", "Edit", "Delete", "View All Records", "Modify All Records"]]
    ps_field = [["Permission Set", "Field", "Readable", "Editable"]]
    ps_system = [["Permission Set", "System Permission", "Enabled"]]
    ps_other = [["Permission Container Type", "Container", "Access Type", "Component", "Enabled / Visibility"]]
    for name, root in permission_sets.items():
        temp = []
        add_rows_for_access("Permission Set", name, root, temp, ps_obj, ps_field, ps_system, ps_other)
        row = temp[0]
        enabled_system = sum(1 for x in root.findall("m:userPermissions", NS) if bool_value(xml_value(x, "enabled", "false")))
        member_of = sum(1 for group_root in groups.values() if any((x.text or "").strip() == name for x in group_root.findall("m:permissionSets", NS)))
        ps_summary.append([name, xml_value(root, "label"), "Yes", pset_assignments[name], member_of, row[2], row[3], row[4], enabled_system, row[5], row[6]])
    for name, count in sorted(pset_assignments.items()):
        if name not in permission_sets:
            ps_summary.append([name, pset_labels.get(name, ""), "No", count, sum(1 for group_root in groups.values() if any((x.text or "").strip() == name for x in group_root.findall("m:permissionSets", NS))), "Not retrieved", "Not retrieved", "Not retrieved", "Not retrieved", "Not retrieved", "Not retrieved"])

    muting_summary = [["Muting Permission Set", "Label", "Object Permission Entries", "Field Permission Entries", "System Permission Entries"]]
    mute_obj = [["Muting Permission Set", "Object", "Create", "Read", "Edit", "Delete", "View All Records", "Modify All Records"]]
    mute_field = [["Muting Permission Set", "Field", "Readable", "Editable"]]
    mute_system = [["Muting Permission Set", "System Permission", "Enabled"]]
    for name, root in muting_sets.items():
        muting_summary.append([name, xml_value(root, "label"), len(root.findall("m:objectPermissions", NS)), len(root.findall("m:fieldPermissions", NS)), len(root.findall("m:userPermissions", NS))])
        add_rows_for_access("Muting Permission Set", name, root, [], mute_obj, mute_field, mute_system, p_other)

    psg_members = [["Permission Set Group", "Label", "Active Group Assignments", "Member Permission Set", "Member Retrieved", "Muting Permission Set", "Status", "Activation Required"]]
    for group_name, root in groups.items():
        muting_name = xml_value(root, "mutingPermissionSet")
        members = [x.text.strip() for x in root.findall("m:permissionSets", NS) if x.text]
        for member in members or [""]:
            psg_members.append([group_name, xml_value(root, "label"), group_assignments[group_name], member, "Yes" if member in permission_sets else "No", muting_name, xml_value(root, "status"), xml_value(root, "hasActivationRequired")])

    assignments_rows = [["Username", "Assignment Kind", "Direct Permission Set", "Permission Set Group", "Group Aggregate Permission Set", "Permission Set Label"]]
    for row in assignments:
        group = row.get("PermissionSetGroup.DeveloperName", "")
        assignments_rows.append([row.get("Assignee.Username", ""), "Permission Set Group" if group else "Direct Permission Set", "" if group else row.get("PermissionSet.Name", ""), group, row.get("PermissionSet.Name", "") if group else "", row.get("PermissionSet.Label", "")])
    user_rows = [["Name", "Username", "User Type", "License", "Profile", "Role", "Active"]]
    for row in users:
        user_rows.append([row.get("Name", ""), row.get("Username", ""), row.get("UserType", ""), row.get("Profile.UserLicense.Name", ""), row.get("Profile.Name", ""), row.get("UserRole.Name", ""), row.get("IsActive", "")])

    role_rows = [["Role API Name", "Role Label", "Parent Role API Name", "Active User Records", "Case Access", "Contact Access", "Opportunity Access"]]
    for name, root in roles.items():
        role_rows.append([name, xml_value(root, "name"), xml_value(root, "parentRole"), active_by_role[name], xml_value(root, "caseAccessLevel"), xml_value(root, "contactAccessLevel"), xml_value(root, "opportunityAccessLevel")])

    department_rows = [["Department", "Partner-listed Profile", "Retrieved Profile Metadata", "Active User Records", "Review Note"]]
    for department, names in DEPARTMENT_PROFILES.items():
        for name in names:
            found = name in profile_files
            status = "Yes" if found else ("SOQL fallback; Profile XML unavailable" if name == "System Administrator" else "No")
            note = "Profile metadata unavailable; object, field, and system permissions included from profile-owned PermissionSet record" if name == "System Administrator" else ("Verify name / assignment" if not found else "Partner mapping; validate with department owner")
            department_rows.append([department, name, status, active_by_profile[name], note])

    partner_pairs = {(department, name) for department, names in DEPARTMENT_PROFILES.items() for name in names}
    actual_counts = Counter()
    profile_licenses = defaultdict(set)
    department_licenses = defaultdict(set)
    for row in department_users:
        department = row.get("Department", "").strip()
        profile = row.get("Profile.Name", "").strip()
        license_name = row.get("Profile.UserLicense.Name", "").strip()
        if not department or not profile:
            continue
        actual_counts[(department, license_name, profile)] += 1
        profile_licenses[profile].add(license_name)
        department_licenses[department].add(license_name)

    actual_profile_rows = [["Org Department", "User License", "Current Profile", "Active Users", "Profile Listed by Partner?", "Permission Source"]]
    for (department, license_name, profile), count in sorted(actual_counts.items()):
        source = "Retrieved Profile XML" if profile in profile_files else ("SOQL profile-owned PermissionSet fallback" if profile in fallback_sources else "Missing")
        actual_profile_rows.append([department, license_name, profile, count, "Yes" if (department, profile) in partner_pairs else "No", source])

    partner_vs_org_rows = [["Partner Department", "Partner-listed Profile", "Active Users in Matching Org Department", "Observed User Licenses", "In Retrieved Metadata", "Review"]]
    for department, profile in sorted(partner_pairs):
        count = sum(n for (dept, _, prof), n in actual_counts.items() if dept == department and prof == profile)
        licenses = "; ".join(sorted({lic for (dept, lic, prof), n in actual_counts.items() if dept == department and prof == profile}))
        source_status = "Yes" if profile in profile_files else ("SOQL fallback" if profile in fallback_sources else "No")
        review = "Confirm no current users or mapping is stale" if count == 0 else "Compare with org profile assignments"
        partner_vs_org_rows.append([department, profile, count, licenses, source_status, review])
    for department, license_name, profile in sorted(actual_counts):
        if (department, profile) not in partner_pairs:
            source_status = "Yes" if profile in profile_files else ("SOQL fallback" if profile in fallback_sources else "No")
            partner_vs_org_rows.append([department, profile, actual_counts[(department, license_name, profile)], license_name, source_status, "Used in org but absent from partner department mapping"])

    cohort_profiles = defaultdict(Counter)
    for (department, license_name, profile), count in actual_counts.items():
        cohort_profiles[(department, license_name)][profile] += count
    consolidation_rows = [["Department", "User License", "Active Users", "Current Profiles", "Profile Count", "Common Profile Grants", "Candidate Permission Set Grants", "Proposed Base Profile", "Profiles Excluded for Special Access", "Profiles Missing Permission Source", "Recommendation"]]
    baseline_rows = [["Department", "User License", "Proposed Base Profile", "Grant Type", "Object / Field / Permission", "Access"]]
    delta_rows = [["Department", "User License", "Source Profile", "Users in Cohort", "Candidate Permission Set Label", "Grant Type", "Object / Field / Permission", "Access", "Review"]]
    for cohort, profile_counts in sorted(cohort_profiles.items()):
        department, license_name = cohort
        names = sorted(profile_counts)
        total_users = sum(profile_counts.values())
        excluded_profiles = [name for name in names if name == "System Administrator" or "system admin" in name.lower()]
        migration_names = [name for name in names if name not in excluded_profiles]
        missing_sources = [name for name in migration_names if name not in profile_grant_sets]
        proposed_base = f"Base - {department} - {license_name}" if migration_names else "Retain dedicated privileged profile"
        if missing_sources:
            common = set()
            extras = 0
            recommendation = "Complete source profile permissions before choosing the common baseline."
        elif not migration_names:
            common = set()
            extras = 0
            recommendation = "Keep the privileged admin profile separate; do not convert administrative access into a department permission set."
        else:
            grant_sets = [profile_grant_sets[name] for name in migration_names]
            common = set.intersection(*grant_sets) if grant_sets else set()
            extras = sum(len(profile_grant_sets[name] - common) for name in migration_names)
            recommendation = "Use one base profile for this license cohort; assess each source-profile delta for a permission set and validate with the department owner."
        if department == "Integration user":
            recommendation += " Confirm integration identity, connected app, and API requirements before consolidating."
        common_value = len(common) if not missing_sources and migration_names else ("Not applicable" if not migration_names else "Not available")
        extras_value = extras if not missing_sources and migration_names else ("Not applicable" if not migration_names else "Not available")
        consolidation_rows.append([department, license_name, total_users, "; ".join(names), len(names), common_value, extras_value, proposed_base, "; ".join(excluded_profiles), "; ".join(missing_sources), recommendation])
        if missing_sources:
            continue
        for kind, target, access in sorted(common):
            baseline_rows.append([department, license_name, proposed_base, kind, target, access])
        for name in migration_names:
            delta_label = f"Migrate {name} access - {department} ({license_name})"
            for kind, target, access in sorted(profile_grant_sets[name] - common):
                delta_rows.append([department, license_name, name, profile_counts[name], delta_label, kind, target, access, "Validate business need, permission-set support, and license compatibility before creating or assigning."])

    controls_rows = [["Profile", "Observed User Licenses", "Login Hours Configured", "Login IP Range Count", "Default Record Type Count", "Profile Metadata Source", "Review"]]
    for name in sorted(set(profile_licenses) | {profile for _, profile in partner_pairs}):
        if name in profile_files:
            root = profile_files[name]
            login_hours = "Yes" if root.find("m:loginHours", NS) is not None else "No"
            ip_count = len(root.findall("m:loginIpRanges", NS))
            default_records = sum(1 for item in root.findall("m:recordTypeVisibilities", NS) if bool_value(xml_value(item, "default", "false")))
            source = "Retrieved Profile XML"
            review = "Check profile-only settings before consolidation; permission sets do not replace login IP/hour controls."
        else:
            login_hours, ip_count, default_records = "Unknown", "Unknown", "Unknown"
            source = "SOQL permission fallback" if name in fallback_sources else "Not retrieved"
            review = "Obtain full profile settings or confirm standard-profile behavior before consolidation."
        controls_rows.append([name, "; ".join(sorted(profile_licenses.get(name, set()))), login_hours, ip_count, default_records, source, review])

    mapped = {name for profiles in DEPARTMENT_PROFILES.values() for name in profiles}
    current_dept_profiles = {row.get("Profile.Name", "").strip() for row in department_users if row.get("Profile.Name", "").strip()}
    current_departments = {row.get("Department", "").strip() for row in department_users if row.get("Department", "").strip()}
    current_cohorts = {(row.get("Department", "").strip(), row.get("Profile.UserLicense.Name", "").strip()) for row in department_users if row.get("Department", "").strip()}
    notes = [
        ["MobiliumStaging Access Review Matrix", "Snapshot date: 2026-10-14"],
        ["Source", "Retrieved Salesforce metadata plus live read-only User and PermissionSetAssignment queries from MobiliumStaging."],
        ["Partner input", "Department-to-profile mapping transcribed from the partner table supplied in chat. Blank table rows were not inferred."],
        ["Scope", f"{len(profile_files)} profiles; {len(permission_sets)} permission sets; {len(groups)} permission set groups; {len(roles)} roles; {len(users)} active user records; {len(assignments)} active permission assignment records."],
        ["Important", "Permission sheets show entries defined directly on each profile, permission set, or muting permission set. They do not compute each user's effective access after profile, assignments, groups, muting, licenses, sharing, and object relationships are combined."],
        ["Metadata gaps", "System Administrator and Standard Platform User were unavailable as Profile metadata; their object, field, and system permissions were included from profile-owned PermissionSet records via SOQL. Apex class and Visualforce page entries and profile-only controls were not available through those fallbacks."],
        ["Permission set groups", "The group membership sheet lists component permission sets. Some members may not have retrievable local XML (for example, package-managed or license-generated sets); check Member Retrieved."],
        ["Record visibility", "Role hierarchy and role-level access are listed, but org-wide defaults, sharing rules, public groups, territories, queues, and manual shares are not included in this matrix."],
        ["Department mapping", f"{len(mapped)} partner-listed profiles across {len(DEPARTMENT_PROFILES)} departments. Actual user department/license assignments are compared in the new consolidation sheets; unmapped profiles and departments are flagged."],
        ["Partner vs org count", f"The partner table names {len(mapped)} distinct profiles. The active-user export shows {len(current_dept_profiles)} distinct profiles across {len(current_departments)} departments and {len(current_cohorts)} department/license cohorts. Resolve mismatches before finalizing the target count."],
        ["Consolidation proposal", "Proposed base grants are the intersection of positive permissions across the profiles currently used within each department and user-license cohort. Candidate permission-set deltas are the remaining grants per source profile. These are analysis candidates, not approved changes."],
        ["Privileged profile exception", "System Administrator access is excluded from department base-profile intersections and permission-set delta candidates. Keep it as a separately governed privileged profile and review its assignment independently."],
        ["License and persona constraint", "A Salesforce Profile is tied to a user license. The proposed consolidation starts with one base profile per Department x User License and may need more profiles or permission-set variants after persona, license, and business-owner review."],
        ["Profile controls", "Login hours and IP ranges remain profile controls and must be reviewed separately. Role hierarchy and record-sharing design remain separate from profile/permission-set consolidation."],
        ["User data", "The Users and Assignments sheets contain usernames and access assignments. Treat this workbook as internal access-review data."],
        ["Interpretation", "This is an audit baseline, not a recommendation to grant or revoke access. Confirm access needs with department owners before changing the sandbox."],
    ]
    sheets = {
        "Read Me": notes,
        "Department Mapping": department_rows,
        "Profile Summary": prof_summary,
        "Profile Object Access": p_obj,
        "Profile Field Access": p_field,
        "Profile System Access": p_system,
        "Perm Set Summary": ps_summary,
        "Perm Set Object Access": ps_obj,
        "Perm Set Field Access": ps_field,
        "Perm Set System Access": ps_system,
        "Other Component Access": p_other + ps_other[1:],
        "PSG Members": psg_members,
        "Muting Summary": muting_summary,
        "Muting Object Access": mute_obj,
        "Muting Field Access": mute_field,
        "Muting System Access": mute_system,
        "Actual Dept Profile Usage": actual_profile_rows,
        "Partner vs Org": partner_vs_org_rows,
        "Consolidation Summary": consolidation_rows,
        "Base Profile Grants": baseline_rows,
        "Permission Set Delta": delta_rows,
        "Profile Controls": controls_rows,
        "Users": user_rows,
        "Assignments": assignments_rows,
        "Roles": role_rows,
    }
    write_xlsx(sheets)
    print(f"Created {OUT}")
    print(f"Sheets: {len(sheets)}; mapped partner profiles: {len(mapped)}; retrieved profiles: {len(profile_files)}")
    print(f"Rows: profile fields={len(p_field)-1}; permission-set fields={len(ps_field)-1}; department/license cohorts={len(consolidation_rows)-1}; candidate permission deltas={len(delta_rows)-1}; user assignments={len(assignments_rows)-1}")


if __name__ == "__main__":
    main()
