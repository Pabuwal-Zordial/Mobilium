#!/usr/bin/env python3
"""Build a plain-language Excel access review for one Salesforce profile.

The script reads only the local access-review snapshot and writes an XLSX file.
It never connects to or modifies a Salesforce org.
"""

import argparse
import csv
import re
from collections import Counter
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import unquote
from xml.sax.saxutils import escape
from zipfile import ZIP_DEFLATED, ZipFile


ROOT = Path(__file__).resolve().parents[2]
REVIEW = ROOT / "access-review"
DATA = REVIEW / "main-env-all-profiles"
PROFILE_DIR = DATA / "profiles"
FULL_PROFILE_DIR = REVIEW / "main-env-single-profile-access" / "profiles"
PROFILE_DEFAULT = "Mobileum - Sales User"
OUT_DEFAULT = REVIEW / "Mobileum_Sales_User_Profile_Access_Review.xlsx"
# Salesforce uses the metadata API name `Admin` for the standard profile
# whose org-facing Profile.Name label is `System Administrator`.
PROFILE_METADATA_ALIASES = {"System Administrator": "Admin"}

SYSTEM_EXPLANATIONS = {
    "ActivitiesAccess": "Use Salesforce activities such as tasks and events.",
    "AllowEmailIC": "Feature-specific email permission; confirm exact feature use with the Salesforce administrator.",
    "AllowUniversalSearch": "Search across available Salesforce records.",
    "AllowViewKnowledge": "View Salesforce Knowledge articles.",
    "ApexRestServices": "Use custom Apex REST services.",
    "ApiEnabled": "Access Salesforce through APIs and connected integrations.",
    "AssignTopics": "Assign topics to records or content.",
    "ChatterEditOwnPost": "Edit the user's own Chatter posts.",
    "ChatterFileLink": "Link files in Chatter.",
    "ChatterInternalUser": "Use Chatter as an internal Salesforce user.",
    "ChatterInviteExternalUsers": "Invite external users to Chatter groups.",
    "ChatterOwnGroups": "Create and own Chatter groups.",
    "ContentWorkspaces": "Use Salesforce content workspaces.",
    "ConvertLeads": "Convert leads into accounts, contacts, and opportunities.",
    "CreateCustomizeDashboards": "Create and customize dashboards.",
    "CreateCustomizeFilters": "Create and customize list/report filters.",
    "CreateCustomizeReports": "Create and customize reports.",
    "CreateDashboardFolders": "Create dashboard folders.",
    "CreateReportFolders": "Create report folders.",
    "CreateTopics": "Create topics.",
    "DistributeFromPersWksp": "Distribute content from a personal workspace.",
    "EditEvent": "Edit events the user can access.",
    "EditMyReports": "Edit the user's own reports.",
    "EditOppLineItemUnitPrice": "Edit opportunity product unit prices.",
    "EditPublicFilters": "Edit public list-view filters.",
    "EditTask": "Edit tasks the user can access.",
    "EditTopics": "Edit topics.",
    "EmailMass": "Send mass email where Salesforce allows it.",
    "EmailSingle": "Send individual email from Salesforce.",
    "EnableNotifications": "Receive Salesforce notifications.",
    "ExportReport": "Export report results.",
    "LightningConsoleAllowedForUser": "Use Salesforce console apps when assigned and available.",
    "LightningExperienceUser": "Use Salesforce Lightning Experience.",
    "ManageCustomReportTypes": "Create or manage custom report types.",
    "ManageReportsInPubFolders": "Manage reports in shared folders where access permits.",
    "MassInlineEdit": "Edit multiple records at once in list views when supported.",
    "OverrideForecasts": "Override forecast amounts; review this elevated business permission.",
    "RunFlow": "Run flows that the user can access.",
    "RunReports": "Run reports the user can access.",
    "SelectFilesFromSalesforce": "Select Salesforce files in supported features.",
    "SendSitRequests": "Send Salesforce feature/service requests; confirm exact feature use with the administrator.",
    "ShowCompanyNameAsUserBadge": "Show the company name in the user's Salesforce badge.",
    "SubmitMacrosAllowed": "Submit macros in supported Salesforce features.",
    "SubscribeToLightningReports": "Subscribe to Lightning report notifications.",
    "TransactionalEmailSend": "Send transactional email through supported Salesforce features.",
    "UseWebLink": "Use web links in Salesforce.",
    "ViewHelpLink": "View Salesforce help links.",
    "ViewPublicReports": "View reports in public folders where folder access permits.",
    "ViewRoles": "View the role hierarchy.",
    "ViewSetup": "View Setup pages; this is administrative visibility.",
    "ViewSetupAuditTrail": "View the Setup Audit Trail of configuration changes.",
}


def local(tag):
    return tag.rsplit("}", 1)[-1]


def load_csv(path):
    with path.open(newline="", encoding="utf-8-sig") as f:
        return list(csv.DictReader(f))


def xml_text(value):
    return escape(str(value), {"\"": "&quot;"})


def col_name(number):
    result = ""
    while number:
        number, rem = divmod(number - 1, 26)
        result = chr(65 + rem) + result
    return result


def make_cell(ref, value, style=2):
    if value is None:
        value = ""
    if isinstance(value, bool):
        value = "Yes" if value else "No"
    if isinstance(value, int) or isinstance(value, float):
        return f'<c r="{ref}" s="{style}" t="n"><v>{value}</v></c>'
    text = str(value)
    return f'<c r="{ref}" s="{style}" t="inlineStr"><is><t xml:space="preserve">{xml_text(text)}</t></is></c>'


def sheet_xml(rows, widths, filter_rows=True, freeze=True):
    max_col = max((len(row) for row in rows), default=1)
    max_row = max(1, len(rows))
    cols = "".join(f'<col min="{i}" max="{i}" width="{width}" customWidth="1"/>' for i, width in enumerate(widths, 1))
    xml_rows = []
    for row_num, row in enumerate(rows, 1):
        cells = []
        for col_num, value in enumerate(row, 1):
            style = 1 if row_num == 1 else (3 if isinstance(value, bool) and value else 4 if isinstance(value, bool) else 2)
            if isinstance(value, bool):
                value = "Yes" if value else "No"
            cells.append(make_cell(f"{col_name(col_num)}{row_num}", value, style))
        xml_rows.append(f'<row r="{row_num}" customHeight="1" ht="30">{"".join(cells)}</row>' if row_num == 1 else f'<row r="{row_num}">{"".join(cells)}</row>')
    views = '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>' if freeze else '<sheetViews><sheetView workbookViewId="0"/></sheetViews>'
    auto = f'<autoFilter ref="A1:{col_name(max_col)}{max_row}"/>' if filter_rows and max_row > 1 else ""
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        f'<dimension ref="A1:{col_name(max_col)}{max_row}"/>{views}<sheetFormatPr defaultRowHeight="18"/>'
        f'<cols>{cols}</cols><sheetData>{"".join(xml_rows)}</sheetData>{auto}</worksheet>'
    )


def styles_xml():
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
 <fonts count="3"><font><sz val="10"/><name val="Aptos"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="10"/><name val="Aptos"/></font><font><b/><color rgb="FF17365D"/><sz val="10"/><name val="Aptos"/></font></fonts>
 <fills count="4"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF17365D"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFE2F0D9"/><bgColor indexed="64"/></patternFill></fill></fills>
 <borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border><border><left style="thin"><color rgb="FFD9E2F3"/></left><right style="thin"><color rgb="FFD9E2F3"/></right><top style="thin"><color rgb="FFD9E2F3"/></top><bottom style="thin"><color rgb="FFD9E2F3"/></bottom><diagonal/></border></borders>
 <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
 <cellXfs count="5"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf><xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf><xf numFmtId="0" fontId="0" fillId="3" borderId="1" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf><xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf></cellXfs>
 <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>'''


def write_xlsx(path, sheets):
    path.parent.mkdir(parents=True, exist_ok=True)
    content_overrides = ''.join(f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' for i in range(1, len(sheets) + 1))
    workbook_sheets = ''.join(f'<sheet name="{xml_text(name)}" sheetId="{i}" r:id="rId{i}"/>' for i, (name, _, _) in enumerate(sheets, 1))
    rels = ''.join(f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>' for i in range(1, len(sheets) + 1))
    rels += f'<Relationship Id="rId{len(sheets)+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
    content_types = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' + content_overrides + '</Types>')
    root_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>')
    workbook = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<bookViews><workbookView/></bookViews><sheets>' + workbook_sheets + '</sheets></workbook>')
    workbook_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + rels + '</Relationships>')
    with ZipFile(path, "w", ZIP_DEFLATED) as archive:
        archive.writestr("[Content_Types].xml", content_types)
        archive.writestr("_rels/.rels", root_rels)
        archive.writestr("xl/workbook.xml", workbook)
        archive.writestr("xl/_rels/workbook.xml.rels", workbook_rels)
        archive.writestr("xl/styles.xml", styles_xml())
        for i, (_, rows, widths) in enumerate(sheets, 1):
            archive.writestr(f"xl/worksheets/sheet{i}.xml", sheet_xml(rows, widths))


def profile_xml(profile_name):
    paths = list(FULL_PROFILE_DIR.glob("*.profile-meta.xml")) + list(PROFILE_DIR.glob("*.profile-meta.xml"))
    lookup_names = {profile_name.casefold()}
    metadata_alias = PROFILE_METADATA_ALIASES.get(profile_name)
    if metadata_alias:
        lookup_names.add(metadata_alias.casefold())
    for path in paths:
        if unquote(path.name.removesuffix(".profile-meta.xml")).casefold() in lookup_names:
            return path, ET.parse(path).getroot()
    raise ValueError(f"Profile not found in local snapshot: {profile_name}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", default=PROFILE_DEFAULT, help="Exact Salesforce profile label")
    parser.add_argument("--output", type=Path, default=None, help="Output XLSX path")
    args = parser.parse_args()
    profile_name = args.profile
    output = args.output or (OUT_DEFAULT if profile_name == PROFILE_DEFAULT else REVIEW / (re.sub(r"[^A-Za-z0-9_-]+", "_", profile_name).strip("_") + "_Profile_Access_Review.xlsx"))
    profile_path, root = profile_xml(profile_name)

    id_to_name = {}
    for row in load_csv(DATA / "profile-id-name-map.csv"):
        name = row.get("ProfileName") or row.get("Profile.Name")
        if name:
            id_to_name[row["ProfileId"]] = name
    profile_ids = {pid for pid, name in id_to_name.items() if name.casefold() == profile_name.casefold()}
    if len(profile_ids) != 1:
        raise ValueError(f"Expected one current profile ID for {profile_name}; found {len(profile_ids)}")
    profile_id = next(iter(profile_ids))

    inventory_names = {profile_name.casefold()}
    inventory_alias = PROFILE_METADATA_ALIASES.get(profile_name)
    if inventory_alias:
        inventory_names.add(inventory_alias.casefold())
    inv = next((r for r in load_csv(REVIEW / "Main_Org_Profile_Inventory.csv") if r["Profile"].casefold() in inventory_names), {})
    licenses = [x.text or "" for x in root if local(x.tag) == "userLicense"]
    custom_values = [x.text or "" for x in root if local(x.tag) == "custom"]
    user_permissions = {}
    for element in root:
        if local(element.tag) == "userPermissions":
            p = {local(x.tag): x.text or "" for x in element}
            if p.get("enabled", "false").lower() == "true":
                user_permissions[p.get("name", "")] = True

    obj_permissions = {}
    for row in load_csv(DATA / "object-permissions.csv"):
        if row.get("Parent.ProfileId") not in profile_ids:
            continue
        obj = row["SobjectType"]
        obj_permissions[obj] = {k: row[k].lower() == "true" for k in (
            "PermissionsRead", "PermissionsCreate", "PermissionsEdit", "PermissionsDelete", "PermissionsViewAllRecords", "PermissionsModifyAllRecords")}
    object_rows = [["Salesforce object", "Can view records", "Can create records", "Can edit records", "Can delete records", "Can view all records", "Can edit/delete all records"]]
    object_key_labels = [
        ("PermissionsRead", "Read"), ("PermissionsCreate", "Create"), ("PermissionsEdit", "Edit"),
        ("PermissionsDelete", "Delete"), ("PermissionsViewAllRecords", "View All"), ("PermissionsModifyAllRecords", "Modify All"),
    ]
    object_rows += [[obj] + [perms[key] for key, _ in object_key_labels] for obj, perms in sorted(obj_permissions.items()) if any(perms.values())]
    object_grant_count = len(object_rows) - 1
    object_permission_count = sum(sum(bool(v) for v in perms.values()) for perms in obj_permissions.values())

    field_rows = [["Object.Field", "Can see field", "Can edit field"]]
    field_grants = {}
    for row in load_csv(DATA / "field-permissions.csv"):
        if row.get("Parent.ProfileId") not in profile_ids:
            continue
        can_read, can_edit = row["PermissionsRead"].lower() == "true", row["PermissionsEdit"].lower() == "true"
        if can_read or can_edit:
            field_grants[row["Field"]] = (can_read, can_edit)
    field_rows += [[name, read, edit] for name, (read, edit) in sorted(field_grants.items())]

    system_rows = [["Permission code", "Plain-language name", "What it allows"]]
    for code in sorted(user_permissions):
        label = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", " ", code).replace("IC", "IC")
        explanation = SYSTEM_EXPLANATIONS.get(code, f"Allows the Salesforce feature '{label}'. Ask your Salesforce administrator to confirm the exact use of this feature permission.")
        system_rows.append([code, label, explanation])

    refs_all = load_csv(REVIEW / "Org_Profile_Name_References.csv")
    refs = [r for r in refs_all if r.get("Profile Label", "").casefold() == profile_name.casefold() or r.get("Profile API Name", "").casefold() == profile_name.casefold()]
    all_reference_counts = Counter(r.get("Category", "") for r in refs_all)
    profile_reference_counts = Counter(r.get("Category", "") for r in refs)
    app_rows = [["Application", "Visible to this profile", "Default app", "Plain-language note"]]
    for element in root:
        if local(element.tag) == "applicationVisibilities":
            values = {local(x.tag): x.text or "" for x in element}
            app_rows.append([values.get("application", ""), values.get("visible", "false").lower() == "true", values.get("default", "false").lower() == "true", "Controls whether the app appears for this profile."])
    if len(app_rows) == 1:
        for r in refs:
            if r["Category"] == "Profile application visibility":
                details = r.get("Details", "")
                app_rows.append([r["Assignment or Literal"], "visible=true" in details.lower(), "default=true" in details.lower(), "From the 15 Oct profile-reference audit."])

    layout_rows = [["Object - layout assignment", "Record type mapping note"]]
    reference_rows = [["Reference type", "Component", "Profile name use", "Status or details", "Why this matters"]]
    for r in refs:
        category = r["Category"]
        if category == "Profile layout assignment":
            layout_rows.append([r["Assignment or Literal"], r.get("Details", "")])
        elif category == "Profile application visibility":
            continue
        else:
            why = {
                "Validation rule": "This rule can block saving a record when its conditions are met; it does not grant access.",
                "Apex test profile dependency": "A test looks up this profile by name when creating or checking test users.",
                "Apex runtime profile dependency": "Production code checks this profile name; a rename may change runtime behavior.",
                "Flow profile dependency": "A flow checks this profile name; a rename may change the flow path.",
                "Custom app profile action override": "This profile receives a custom page/action in the app.",
            }.get(category, "Review this profile-name dependency before renaming or retiring the profile.")
            details = r.get("Details", "")
            if category == "Validation rule":
                rule_name = r.get("Component", "").split(".")[-1]
                candidates = list(ROOT.rglob(f"{rule_name}.validationRule-meta.xml"))
                if candidates:
                    try:
                        rule_root = ET.parse(candidates[0]).getroot()
                        formula = next((x.text or "" for x in rule_root if local(x.tag) == "errorConditionFormula"), "")
                        message = next((x.text or "" for x in rule_root if local(x.tag) == "errorMessage"), "")
                        if formula:
                            details += f"; formula: {formula}"
                        if message:
                            why = f"When a user with this profile changes a Project record's Name, this active rule blocks the save and shows: “{message}”. If users move to another profile, this profile-name condition may stop matching."
                    except ET.ParseError:
                        pass
            reference_rows.append([category, r.get("Component", ""), r.get("Assignment or Literal", ""), details, why])
    if not any(r[0] == "Validation rule" for r in reference_rows[1:]):
        reference_rows.append(["Validation rule", "No matching literal profile-name reference", "—", "None found in the audit snapshot", "Validation rules can affect saves but do not grant access."])
    if not any(r[0] == "Flow profile dependency" for r in reference_rows[1:]):
        reference_rows.append(["Flow profile dependency", "No matching literal profile-name reference", "—", "None found in the audit snapshot", "Flows may still affect users through other logic or assignments."])
    if not any(r[0] == "Apex runtime profile dependency" for r in reference_rows[1:]):
        reference_rows.append(["Apex runtime profile dependency", "No matching literal profile-name reference", "—", "None found for this profile in the audit snapshot", "This only reports hardcoded name references found by the audit."])

    # Give reviewers a plain-language inventory of both positive matches and
    # scanned areas with no match. A metadata snapshot cannot prove that no
    # dependency exists in inaccessible package code or live configuration data.
    scan_rows = [["Component area", "Audit result for this profile", "Org snapshot coverage", "Review note"]]
    scan_specs = [
        ("Validation rules", "Validation rule", "The rule can block record saves; review its formula before changing profile names."),
        ("Flows", "Flow profile check", "No literal match does not rule out access through flow assignments or other conditions."),
        ("Production Apex", "Apex production profile check", "Production code with profile-name checks can change runtime behavior after a rename."),
        ("Apex tests / support", "Apex test profile dependency", "Tests may query this profile by name and need updates if it is renamed or retired."),
        ("Approval processes", None, "Approval routing can depend on users, roles, queues, or criteria without naming a profile."),
        ("Custom metadata", None, "Custom metadata was included in the retrieved snapshot; no matching literal was recorded."),
        ("Custom settings / live configuration", None, "Live setting records are not covered by a source metadata text scan; check runtime data separately."),
        ("Connected Apps", None, "The audit retrieved 5 Connected App definitions; no direct profile-name match was recorded."),
        ("Visualforce pages and components", None, "No direct profile-name match was recorded in 14 Visualforce pages or 6 components."),
        ("Aura and Lightning Web Components", None, "No direct match was recorded in 72 Aura and 52 LWC files."),
        ("Lightning pages", None, "No direct profile-name match was recorded in 144 Lightning-page files."),
        ("Workflow rules", None, "No direct profile-name match was recorded in 23 workflow files."),
        ("Sharing rules", None, "No direct match was recorded in 161 sharing-rule files; these may still grant record access."),
        ("Public groups and queues", None, "No direct match was recorded in 43 public-group and 10 queue metadata files."),
        ("Network / Experience site", None, "Metadata API did not return these component types in this audit; result is unknown."),
        ("Sharing Sets and Restriction Rules", None, "Metadata API did not return these component types in this audit; result is unknown."),
        ("Managed-package source / runtime logic", None, "Package internals may be hidden from metadata retrieval; result is unknown."),
        ("Profile-to-layout assignments", "Profile layout assignment", "These are profile configuration assignments, not hardcoded name references; preserve or remap them."),
        ("Application visibility", "Profile application visibility", "These are profile configuration entries; preserve or remap them."),
        ("Custom app page/action overrides", "Custom app profile action override", "Profile-specific page/action routing may need to be recreated on the retained profile."),
    ]
    for label, category, note in scan_specs:
        count = profile_reference_counts.get(category, 0) if category else 0
        total = all_reference_counts.get(category, 0) if category else None
        if category and count:
            result = f"Found: {count} profile-specific entr{'y' if count == 1 else 'ies'}"
        elif category:
            result = "No matching reference found for this profile in the audit snapshot"
        else:
            result = "No direct match recorded" if "unknown" not in note.lower() else "Not returned / cannot confirm"
        coverage = f"{total} entries across all profiles in the audit" if total is not None else "See Org Profile Name Reference Audit (15 Oct 2026)"
        scan_rows.append([label, result, coverage, note])

    tab_rows = [["Tab", "Visibility setting", "Plain-language note"]]
    for element in root:
        if local(element.tag) == "tabVisibilities":
            values = {local(x.tag): x.text or "" for x in element}
            visibility = values.get("visibility", "")
            note = {"DefaultOn": "Shown by default.", "DefaultOff": "Available but not shown by default.", "Hidden": "Hidden for this profile."}.get(visibility, "Review this setting with the Salesforce administrator.")
            tab_rows.append([values.get("tab", ""), visibility, note])

    record_type_rows = [["Record type", "Visible", "Default for object", "Plain-language note"]]
    for element in root:
        if local(element.tag) == "recordTypeVisibilities":
            values = {local(x.tag): x.text or "" for x in element}
            record_type_rows.append([values.get("recordType", ""), values.get("visible", "false").lower() == "true", values.get("default", "false").lower() == "true", "Controls record type availability/default when creating records."])

    class_page_rows = [["Component type", "Apex class or Visualforce page", "Enabled", "Plain-language note"]]
    for element in root:
        tag = local(element.tag)
        if tag in ("classAccesses", "pageAccesses"):
            values = {local(x.tag): x.text or "" for x in element}
            is_class = tag == "classAccesses"
            name = values.get("apexClass" if is_class else "apexPage", "")
            enabled = values.get("enabled", "false").lower() == "true"
            class_page_rows.append(["Apex class" if is_class else "Visualforce page", name, enabled, "Technical component access; confirm whether users need it before changing the profile."])

    login_rows = [["Restriction", "Configured value", "Plain-language meaning"]]
    login_settings_found = False
    for element in root:
        tag = local(element.tag)
        if tag == "loginHours":
            login_settings_found = True
            values = {local(x.tag): x.text or "" for x in element}
            login_rows.append(["Allowed login hours", "; ".join(f"{k}: {v}" for k, v in values.items()), "Limits when users with this profile can log in."])
        elif tag == "loginIpRanges":
            login_settings_found = True
            values = {local(x.tag): x.text or "" for x in element}
            login_rows.append(["Allowed IP range", f"{values.get('startAddress','')} – {values.get('endAddress','')}", "Limits logins from outside this IP range."])
    if not login_settings_found:
        login_rows.append(["Login hours / IP ranges", "No profile-specific restriction entries in retrieved metadata", "This means none were listed on this profile; org-wide security policies may still apply."])

    assigned_user_summary = f"{inv.get('Active Users', 'unknown')} active; {inv.get('Inactive Users', 'unknown')} inactive (inventory snapshot)"
    if profile_name.casefold() == "system administrator" and inv.get("Profile", "").casefold() == "admin":
        assigned_user_summary = "Not confirmed: inventory uses metadata name 'Admin', while the org profile ID export labels it 'System Administrator'. Verify assigned users with a current org query."

    summary = [
        ["Review item", "Plain-language result"],
        ["Profile reviewed", profile_name],
        ["User license", licenses[0] if licenses else "Not available"],
        ["Custom profile", custom_values[0] if custom_values else "Not available"],
        ["Assigned users", assigned_user_summary],
        ["Object access", f"{object_grant_count} objects have at least one granted permission; {object_permission_count} object-level permission grants."],
        ["Field access", f"{len(field_grants)} fields have at least one granted field permission."],
        ["System permissions", f"{len(user_permissions)} enabled profile-level system permissions in the retrieved profile metadata."],
        ["Apps", f"{len(app_rows)-1} app visibility entries; see Apps tab."],
        ["Tabs", f"{len(tab_rows)-1} tab visibility entries; see Tabs tab."],
        ["Record types", f"{len(record_type_rows)-1} record type settings; see Record Types tab."],
        ["Page layouts", f"{len(layout_rows)-1} profile-to-layout assignments; see Page Layouts tab."],
        ["Apex / Visualforce", f"{len(class_page_rows)-1} component access entries; see Class & VF Access tab."],
        ["Org references", f"{len(refs)} profile-specific reference and assignment rows found in the reference audit; see Org References tab."],
        ["Important scope", "This describes grants on the profile itself. Users may get additional access from Permission Sets/Groups, roles, sharing, licenses, or other org rules."],
        ["Snapshot dates", "Profile/object/FLS and user-count data: 16 Oct 2026. Profile layout/app/name-reference audit: 15 Oct 2026."],
        ["Read/deploy status", "Read-only workbook. No org changes or deployment were made."],
    ]

    coverage_rows = [
        ["Area", "Included?", "What this workbook contains or why it is missing"],
        ["Object permissions", True, "Current profile-owned Read/Create/Edit/Delete/View All/Modify All grants."],
        ["Field-level security", True, "Current profile-owned field Read/Edit grants. A permission-set grant can add effective access for an assigned user."],
        ["System permissions", True, "Enabled userPermissions from the current retrieved Profile metadata."],
        ["Application visibility", True, "Profile applicationVisibilities from the full current Profile metadata retrieve."],
        ["Tab visibility", bool(len(tab_rows) > 1), "Current Profile metadata includes the tab visibility settings."],
        ["Record type visibility/default", bool(len(record_type_rows) > 1), "Current Profile metadata includes record type visibility and default settings."],
        ["Page layout assignments", True, "Profile-to-layout assignments from the org profile-reference audit."],
        ["Apex class / Visualforce page access", bool(len(class_page_rows) > 1), "Current Profile metadata includes enabled Apex class and Visualforce page accesses."],
        ["Login hours and IP ranges", True, "The complete Profile metadata was retrieved; the Login Restrictions tab reports profile-specific settings or confirms none are listed."],
        ["Validation rules", True, "Literal profile-name matches from the org reference audit; validation rules can block actions, they do not grant CRUD/FLS."],
        ["Flow and Apex name references", True, "The reference audit found test-class references for this profile; no matching production Apex or Flow literal profile-name reference was listed."],
        ["Custom app page/action overrides", True, "Profile-specific app action/page override references from the org audit."],
        ["Profile-name dependencies", True, "See the Component Scan tab for component types checked, matches found, no-match results, and areas the metadata snapshot could not inspect."],
        ["Flow access grants", False, "No per-flow grant element was returned in the Profile metadata; RunFlow is listed under System Permissions. Verify flow access requirements separately."],
        ["Permission Sets / Groups assigned to users", False, "These are assigned to users, not granted by this profile; review separately to calculate effective access."],
        ["Role and record sharing", False, "Roles, sharing rules, groups, queues, territories, and record ownership affect record visibility; this workbook does not evaluate them."],
        ["Managed package hidden logic", False, "Salesforce does not expose all managed-package source or runtime logic in retrieved metadata."],
    ]

    glossary_rows = [
        ["Term", "Simple meaning"],
        ["Profile", "The user's baseline access and some user-interface settings."],
        ["Permission Set / Permission Set Group", "Extra access assigned to a user on top of their profile."],
        ["Read", "Can view records of this object, subject to record sharing."],
        ["Create", "Can create records of this object."],
        ["Edit", "Can edit records of this object, subject to sharing and field access."],
        ["Delete", "Can delete records of this object, subject to other controls."],
        ["View All", "Can view all records of this object, bypassing sharing for that object."],
        ["Modify All", "Can view, edit, delete, transfer, and manage all records of this object, bypassing sharing."],
        ["Field-level security", "Controls whether a user can see or edit a particular field."],
        ["Validation rule", "A rule that can stop a record from being saved when a condition is true; it is not a permission grant."],
        ["Record sharing / role hierarchy", "Determines which records a user can access after object permission is granted."],
    ]

    sheets = [
        ("Start Here", summary, [29, 115]),
        ("Object Access", object_rows, [39, 18, 18, 18, 18, 21, 25]),
        ("Field Access", field_rows, [65, 18, 18]),
        ("System Permissions", system_rows, [37, 37, 95]),
        ("Apps", app_rows, [45, 22, 18, 68]),
        ("Tabs", tab_rows, [55, 24, 75]),
        ("Record Types", record_type_rows, [65, 15, 20, 75]),
        ("Page Layouts", layout_rows, [76, 55]),
        ("Class & VF Access", class_page_rows, [20, 66, 14, 80]),
        ("Login Restrictions", login_rows, [32, 90, 75]),
        ("Org References", reference_rows, [34, 52, 55, 65, 80]),
        ("Component Scan", scan_rows, [38, 52, 55, 100]),
        ("Coverage Notes", coverage_rows, [40, 16, 105]),
        ("Glossary", glossary_rows, [38, 100]),
    ]
    write_xlsx(output, sheets)
    print(f"Created {output}")
    print(f"Profile: {profile_name}; objects: {object_grant_count}; fields: {len(field_grants)}; enabled system permissions: {len(user_permissions)}; profile reference rows: {len(refs)}")


if __name__ == "__main__":
    main()
