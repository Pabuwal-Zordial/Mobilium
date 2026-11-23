#!/usr/bin/env python3
"""Build a read-only Finance permission-set and elevated-access review workbook."""

import csv
import sys
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import build_access_matrix as xlsx_writer  # noqa: E402

PROFILE_DIR = ROOT / "force-app/main/default/profiles"
USER_CSV = Path("/tmp/mobileum_active_users_department.csv")
ASSIGNMENT_CSV = Path("/tmp/mobileum_permission_assignments.csv")
OUT = ROOT / "access-review/Finance_PS_and_Elevated_Permissions_Review.xlsx"
NS = {"m": "http://soap.sforce.com/2006/04/metadata"}
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


def val(node, key, default=""):
    child = node.find(f"m:{key}", NS)
    return child.text.strip() if child is not None and child.text else default


def read_csv(path):
    with path.open(newline="", encoding="utf-8-sig") as f:
        return list(csv.DictReader(f))


def parse_profile(root):
    grants = set()
    system_rows, object_rows = [], []
    for row in root.findall("m:userPermissions", NS):
        enabled = val(row, "enabled") == "true"
        perm = val(row, "name")
        system_rows.append((perm, enabled))
        if enabled:
            grants.add(("System Permission", perm, "enabled"))
    for row in root.findall("m:objectPermissions", NS):
        obj = val(row, "object")
        flags = {key: val(row, key) == "true" for key in ("allowCreate", "allowRead", "allowEdit", "allowDelete", "viewAllFields", "viewAllRecords", "modifyAllRecords")}
        object_rows.append((obj, flags))
        for key, enabled in flags.items():
            if enabled:
                grants.add(("Object Permission", obj, key))
    for row in root.findall("m:fieldPermissions", NS):
        field = val(row, "field")
        for key in ("readable", "editable"):
            if val(row, key) == "true":
                grants.add(("Field-Level Security", field, key))
    for row in root.findall("m:recordTypeVisibilities", NS):
        if val(row, "visible") == "true":
            grants.add(("Record Type Visibility", val(row, "recordType"), f"visible; default={val(row, 'default', 'false')}"))
    return grants, system_rows, object_rows


def system_risk(name):
    # A conservative name-based review flag, not a Salesforce risk classification.
    risk_tokens = ("Manage", "Modify", "Author", "TransferAny", "CustomizeApplication", "Import", "Delete", "Freeze", "Reset", "Assign")
    explicit = {"ViewAllUsers", "ViewSetup", "ViewSetupAuditTrail", "ConnectOrgToEnvironmentHub", "OutboundMigrationToolsUser", "InboundMigrationToolsUser", "Packaging2", "SolutionImport"}
    return "Elevated — security review" if name in explicit or any(token in name for token in risk_tokens) else "Standard — owner review"


def main():
    per_profile, system_entries, object_entries = {}, {}, {}
    metadata = {}
    for profile in PROFILES:
        path = PROFILE_DIR / f"{profile}.profile-meta.xml"
        root = ET.parse(path).getroot()
        grants, sysrows, objrows = parse_profile(root)
        per_profile[profile] = grants
        system_entries[profile] = sysrows
        object_entries[profile] = objrows
        metadata[profile] = (val(root, "custom"), val(root, "userLicense", "(omitted)"))

    common = set.intersection(*per_profile.values())
    all_users = read_csv(USER_CSV)
    users = [u for u in all_users if u["Department"].strip().casefold() == "finance" and u["Profile.Name"] in PROFILES]
    sales_project_users = [u for u in all_users if u["Profile.Name"] == "Mobileum - Sales User"]
    assignment_rows = read_csv(ASSIGNMENT_CSV)
    assigned = defaultdict(list)
    for a in assignment_rows:
        assigned[a["Assignee.Username"]].append(a)
    users_by_profile = defaultdict(list)
    for user in users:
        users_by_profile[user["Profile.Name"]].append(user)

    notes = [
        ["Purpose", "Review proposal generated from six retrieved Finance-listed Profile XML files and current read-only user/assignment exports."],
        ["Not deployed", "No profile, permission set, permission set group, role, or user assignment was created or changed in Salesforce. Isolated draft metadata is under access-review/finance-poc."],
        ["Proposal count", "Eleven candidate permission sets: five object/FLS/record-type delta sets, five system-permission delta sets, and one cross-department set to preserve the active Project Name validation restriction. Zero PSGs."],
        ["Baseline method", "A grant is labelled common only when the same positive grant appears in all six profiles. This is a review baseline candidate, not an approved design."],
        ["Assignment method", "Finance department users are grouped by their current profile. The candidate set names show intended cohort only; assign only after grant review and a baseline profile migration."],
        ["Quote profile hold", "Eight Finance users on Quote Creation Team Member are excluded from the candidate assignment sets because its 120 extra system grants include high-impact admin capabilities. Keep the current profile until reviewed."],
        ["Elevated flag", "The system-permission risk label uses permission-name patterns as a conservative review aid. Security must confirm actual risk and business need."],
        ["Object View All / Modify All", "These are object-level flags, shown on Object Access and Elevated Object Grants tabs; they are not the same as system permission flags."],
        ["Validation dependency", "Project__c.Sales_rep_cannot_edit_project_Name uses a Sales User profile-name check. The isolated POC proposes a Custom Permission replacement and a set for all current users on that profile; this must be reviewed before deployment."],
        ["Custom setting", "Proposal_Code__c.Prevent_Edit uses the Validation_Rule_Bypass__c hierarchy custom setting. It is unchanged; inspect org setting records before any change."],
        ["Assignment counts", "Current PS/PSG assignment rows are shown as reconciliation hints. Inspect actual assigned sets and group muting before adding any proposed set."],
        ["Limitations", "Profile XML comparison does not calculate effective access from licenses, PS/PSG, sharing, record ownership, role hierarchy, apps, login restrictions, or user-specific exceptions."],
    ]
    inventory = [["Candidate API Name", "Category", "Source Profile", "Candidate Grants", "Eligible Finance Users", "Assignment Scope", "Assignment Status"]]
    candidate_permissions = [["Candidate API Name", "Category", "Source Profile", "Grant Type", "Resource", "Permission / Value", "Common to all six", "Review Flag"]]
    assignments = [["User", "Username", "Department", "Current Profile", "Current Role", "Candidate Data PS", "Candidate System PS", "Additional Dependency PS", "Current PS/PSG Assignment Rows", "Recommendation"]]
    dependency_assignments = [["User", "Username", "Department", "Current Profile", "Current Role", "Candidate Permission Set", "Recommendation"]]
    dependency_notes = [
        ["Component", "Current behavior", "POC proposal", "Affected user cohort", "Status"],
        ["Project__c.Sales_rep_cannot_edit_project_Name", "Blocks Name edits for users whose Profile.Name is Mobileum - Sales User.", "Use $Permission.Restrict_Project_Name_Edit and grant it through Sales_Project_Name_Restriction.", f"{len(sales_project_users)} current Sales User profile users; includes the 2 Finance users in User Assignments.", "Local draft only; review before moving profile users"],
        ["Proposal_Code__c.Prevent_Edit", "Uses $Setup.Validation_Rule_Bypass__c.Bypass__c.", "No change proposed; inspect hierarchy custom-setting records and overrides first.", "User/profile/org setting owners to be confirmed from org data", "Unchanged"],
        ["Apex / triggers / flows", "No corresponding source files were found in this local retrieve.", "Retrieve full relevant source and scan before profile retirement.", "Unknown until source retrieval", "Not assessed in org"],
    ]
    system_matrix = [["Profile", "Custom", "User License", "System Permission", "Enabled", "Common to all six", "Review Flag"]]
    object_access = [["Profile", "Object", "Create", "Read", "Edit", "Delete", "View All Fields", "View All Records", "Modify All Records", "Elevated Access Flag"]]
    elevated = [["Profile", "Object", "View All Fields", "View All Records", "Modify All Records", "Other CRUD", "Review Flag"]]
    profile_summary = [["Profile", "Custom", "User License", "Enabled System Permissions", "Objects with explicit grants", "Enabled FLS grants", "Visible Record Types", "Active Finance Users", "Other-department users on this profile"]]

    for profile in PROFILES:
        custom, license = metadata[profile]
        grants = per_profile[profile]
        sys_enabled = {name for name, enabled in system_entries[profile] if enabled}
        for name, enabled in sorted(system_entries[profile]):
            system_matrix.append([profile, custom, license, name, "Yes" if enabled else "No", "Yes" if ("System Permission", name, "enabled") in common else "No", system_risk(name) if enabled else "Not enabled"])
        for obj, flags in sorted(object_entries[profile]):
            if not any(flags.values()):
                continue
            elevated_yes = flags["viewAllFields"] or flags["viewAllRecords"] or flags["modifyAllRecords"]
            object_access.append([profile, obj, *["Yes" if flags[k] else "No" for k in ("allowCreate", "allowRead", "allowEdit", "allowDelete", "viewAllFields", "viewAllRecords", "modifyAllRecords")], "Review elevated grant" if elevated_yes else "Standard CRUD"])
            if elevated_yes:
                other = ", ".join(k for k in ("allowCreate", "allowRead", "allowEdit", "allowDelete") if flags[k]) or "None"
                elevated.append([profile, obj, "Yes" if flags["viewAllFields"] else "No", "Yes" if flags["viewAllRecords"] else "No", "Yes" if flags["modifyAllRecords"] else "No", other, "Review with object owner/security"])
        object_count = sum(1 for t, _, _ in grants if t == "Object Permission")
        field_count = sum(1 for t, _, _ in grants if t == "Field-Level Security")
        rt_count = sum(1 for t, _, _ in grants if t == "Record Type Visibility")
        finance_count = len(users_by_profile[profile])
        total_count = sum(1 for u in all_users if u["Profile.Name"] == profile)
        profile_summary.append([profile, custom, license, len(sys_enabled), object_count, field_count, rt_count, finance_count, total_count-finance_count])

        for category, ps_name in (("Data Access", DATA_PS.get(profile)), ("System Permission", SYSTEM_PS.get(profile))):
            if not ps_name:
                continue
            if category == "Data Access":
                selected = [g for g in grants-common if g[0] in ("Object Permission", "Field-Level Security", "Record Type Visibility")]
            else:
                selected = [g for g in grants-common if g[0] == "System Permission"]
            inventory.append([ps_name, category, profile, len(selected), len(users_by_profile[profile]), "Finance users currently on source profile", "Candidate only; approval required"])
            for grant_type, resource, permission in sorted(selected):
                review = system_risk(resource) if grant_type == "System Permission" else ("Review elevated object grant" if permission in ("viewAllFields", "viewAllRecords", "modifyAllRecords") else "Owner validation")
                candidate_permissions.append([ps_name, category, profile, grant_type, resource, permission, "No", review])

    inventory.append(["Sales_Project_Name_Restriction", "Validation dependency", "Project__c.Sales_rep_cannot_edit_project_Name", 1, sum(u["Department"].strip().casefold() == "finance" for u in sales_project_users), f"All {len(sales_project_users)} current Mobileum - Sales User profile users", "Candidate only; preserve existing restriction"])
    candidate_permissions.append(["Sales_Project_Name_Restriction", "Validation dependency", "Project__c.Sales_rep_cannot_edit_project_Name", "Custom Permission", "Restrict_Project_Name_Edit", "enabled", "No", "Review formula and assignments"])
    for user in sorted(sales_project_users, key=lambda u: (u["Name"], u["Username"])):
        dependency_assignments.append([user["Name"], user["Username"], user["Department"], user["Profile.Name"], user["UserRole.Name"], "Sales_Project_Name_Restriction", "Candidate only; preserve current validation behavior after rule refactor"])

    quote_name = "Quote Creation Team Member"
    for user in sorted(users, key=lambda u: (u["Profile.Name"], u["Name"])):
        profile = user["Profile.Name"]
        if profile == quote_name:
            assignments.append([user["Name"], user["Username"], user["Department"], profile, user["UserRole.Name"], "—", "—", "—", len(assigned[user["Username"]]), "Hold; separate high-privilege review before migration"])
        else:
            additional = "Sales_Project_Name_Restriction" if profile == "Mobileum - Sales User" else "—"
            assignments.append([user["Name"], user["Username"], user["Department"], profile, user["UserRole.Name"], DATA_PS[profile], SYSTEM_PS[profile], additional, len(assigned[user["Username"]]), "Candidate cohort only; assign after approval and baseline migration"])

    sheets = {
        "Read Me": notes,
        "PS Inventory": inventory,
        "PS Candidate Grants": candidate_permissions,
        "User Assignments": assignments,
        "Dependency Assignments": dependency_assignments,
        "Customization Dependencies": dependency_notes,
        "System Permissions": system_matrix,
        "Object Access": object_access,
        "Elevated Object Grants": elevated,
        "Profile Summary": profile_summary,
    }
    xlsx_writer.OUT = OUT
    xlsx_writer.write_xlsx(sheets)
    print(f"Created {OUT}")
    print(f"Candidate PS={len(inventory)-1}; grant rows={len(candidate_permissions)-1}; Finance users={len(users)}; Quote hold={sum(u['Profile.Name']==quote_name for u in users)}; validation dependency users={len(sales_project_users)}")
    print(f"System rows={len(system_matrix)-1}; object access rows={len(object_access)-1}; elevated object rows={len(elevated)-1}")


if __name__ == "__main__":
    main()
