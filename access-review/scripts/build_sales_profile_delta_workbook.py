#!/usr/bin/env python3
"""Build a filterable three-profile Salesforce access delta workbook."""

from __future__ import annotations

import re
import zipfile
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
PROFILE_DIR = ROOT / "profile-xml-complete/retrieved/profiles"
OUTPUT = ROOT / "Sales_Profile_Comparison_Deltas.xlsx"
PROFILES = [
    "Mobileum - Sales User",
    "Mobileum - Sales Head",
]
NS_URI = "http://soap.sforce.com/2006/04/metadata"
NS = {"m": NS_URI}

CATEGORY_LABELS = {
    "userPermissions": "System Permissions",
    "objectPermissions": "Object Permissions",
    "fieldPermissions": "Field Permissions (FLS)",
    "classAccesses": "Apex Class Access",
    "pageAccesses": "Visualforce Page Access",
    "flowAccesses": "Flow Access",
    "customMetadataTypeAccesses": "Custom Metadata Access",
    "customSettingAccesses": "Custom Setting Access",
    "customPermissionAccesses": "Custom Permission Access",
    "tabVisibilities": "Tab Visibility",
    "applicationVisibilities": "Application Visibility",
    "recordTypeVisibilities": "Record Type Visibility",
    "layoutAssignments": "Page Layout Assignment",
    "externalDataSourceAccesses": "External Data Source Access",
}

PROFILE_ONLY_TAGS = {"loginHours", "loginIpRanges", "passwordPolicies", "sessionSettings"}

HIGH_RISK_SYSTEM = {
    "ModifyAllData", "ViewAllData", "ManageUsers", "ManageProfilesPermissionsets",
    "ManageRoles", "ManageSharing", "ModifyMetadata", "AuthorApex", "ApiEnabled",
    "CustomizeApplication", "DataExport", "ExportReports", "ManageSandboxes",
    "TransferAnyEntity", "TransferAnyLead", "ManageConnectedApps",
}


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def direct_text(node: ET.Element, name: str) -> str:
    child = node.find(f"m:{name}", NS)
    return (child.text or "").strip() if child is not None else ""


def record(values: dict[tuple[str, str, str], str], category: str, resource: str,
           facet: str, value: str) -> None:
    values[(category, resource, facet)] = value or "Not configured"


def parse_profile(name: str) -> dict[tuple[str, str, str], str]:
    path = PROFILE_DIR / f"{name}.profile-meta.xml"
    if not path.exists():
        path = PROFILE_DIR / f"{name.replace(',', '%2C')}.profile-meta.xml"
    if not path.exists():
        raise FileNotFoundError(path)
    root = ET.parse(path).getroot()
    values: dict[tuple[str, str, str], str] = {}

    for item in root:
        tag = local_name(item.tag)
        if tag == "userLicense":
            record(values, "Profile Metadata", "User License", "license", (item.text or "").strip())
            continue
        if tag == "custom":
            record(values, "Profile Metadata", "Custom Profile", "custom", (item.text or "").strip())
            continue
        if tag in PROFILE_ONLY_TAGS:
            if len(item):
                for child in item:
                    child_name = local_name(child.tag)
                    value = (child.text or "").strip()
                    if child_name == "loginIpRanges":
                        start = direct_text(child, "startIp")
                        end = direct_text(child, "endIp")
                        record(values, "Login/IP Controls", f"IP range {start}-{end}", "configured", "true")
                    else:
                        record(values, "Login/IP Controls", tag, child_name, value)
            else:
                record(values, "Login/IP Controls", tag, "configured", (item.text or "").strip())
            continue

        category = CATEGORY_LABELS.get(tag)
        if not category:
            # Retain access-bearing settings not yet mapped to a dedicated label.
            category = "Other Profile Setting"

        resource_field = {
            "userPermissions": "name", "objectPermissions": "object",
            "fieldPermissions": "field", "classAccesses": "apexClass",
            "pageAccesses": "page", "flowAccesses": "flow",
            "customMetadataTypeAccesses": "name", "customSettingAccesses": "name",
            "customPermissionAccesses": "name", "tabVisibilities": "tab",
            "applicationVisibilities": "application", "recordTypeVisibilities": "recordType",
            "layoutAssignments": "layout", "externalDataSourceAccesses": "externalDataSource",
        }.get(tag)

        if not len(item):
            record(values, category, tag, "value", (item.text or "").strip())
            continue

        resource = direct_text(item, resource_field) if resource_field else ""
        if not resource:
            # For profile settings whose element name itself identifies the setting,
            # flatten scalar children into comparable facets.
            resource = tag

        scalar_children = [child for child in item if not len(child)]
        if not scalar_children:
            record(values, category, resource, "configured", "true")
        for child in scalar_children:
            child_name = local_name(child.tag)
            if child_name == resource_field:
                continue
            record(values, category, resource, child_name, (child.text or "").strip())

    return values


def column_name(number: int) -> str:
    result = ""
    while number:
        number, remainder = divmod(number - 1, 26)
        result = chr(65 + remainder) + result
    return result


def cell_xml(ref: str, value: object, style: int = 0) -> ET.Element:
    cell = ET.Element("{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c", {"r": ref, "s": str(style), "t": "inlineStr"})
    inline = ET.SubElement(cell, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}is")
    text = ET.SubElement(inline, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t")
    text.text = str(value if value is not None else "")
    if text.text[:1].isspace() or text.text[-1:].isspace():
        text.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")
    return cell


def make_sheet(rows: list[list[object]], widths: list[float] | None = None,
               filter_enabled: bool = True, title_rows: int = 0) -> bytes:
    x = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
    root = ET.Element(x + "worksheet")
    views = ET.SubElement(root, x + "sheetViews")
    view = ET.SubElement(views, x + "sheetView", {"workbookViewId": "0"})
    if rows:
        ET.SubElement(view, x + "pane", {"ySplit": "1", "topLeftCell": "A2", "activePane": "bottomLeft", "state": "frozen"})
        ET.SubElement(view, x + "selection", {"pane": "bottomLeft", "activeCell": "A2", "sqref": "A2"})
    if widths:
        cols = ET.SubElement(root, x + "cols")
        for index, width in enumerate(widths, 1):
            ET.SubElement(cols, x + "col", {"min": str(index), "max": str(index), "width": str(width), "customWidth": "1"})
    sheet_data = ET.SubElement(root, x + "sheetData")
    for row_index, row in enumerate(rows, 1):
        row_el = ET.SubElement(sheet_data, x + "row", {"r": str(row_index)})
        for col_index, value in enumerate(row, 1):
            style = 2 if row_index == 1 else 0
            if row_index > 1 and len(row) and str(row[-1]).lower().startswith("common"):
                style = 3
            elif row_index > 1 and len(row) and ("delta" in str(row[-1]).lower() or "unique" in str(row[-1]).lower()):
                style = 4
            elif row_index > 1 and len(row) and ("review" in str(row[-1]).lower() or "conflict" in str(row[-1]).lower()):
                style = 5
            row_el.append(cell_xml(f"{column_name(col_index)}{row_index}", value, style))
    if rows and filter_enabled:
        end_col = column_name(max(len(row) for row in rows))
        ET.SubElement(root, x + "autoFilter", {"ref": f"A1:{end_col}{len(rows)}"})
    ET.SubElement(root, x + "pageMargins", {"left": "0.25", "right": "0.25", "top": "0.5", "bottom": "0.5", "header": "0.2", "footer": "0.2"})
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def make_styles() -> bytes:
    x = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
    root = ET.Element(x + "styleSheet")
    fonts = ET.SubElement(root, x + "fonts", {"count": "2"})
    ET.SubElement(fonts, x + "font").append(ET.Element(x + "sz", {"val": "10"}))
    f = ET.SubElement(fonts, x + "font")
    ET.SubElement(f, x + "b")
    ET.SubElement(f, x + "color", {"rgb": "FFFFFFFF"})
    ET.SubElement(f, x + "sz", {"val": "10"})
    ET.SubElement(f, x + "name", {"val": "Aptos"})
    fills = ET.SubElement(root, x + "fills", {"count": "5"})
    for pattern, color in [("none", None), ("gray125", None), ("solid", "FF315A7D"), ("solid", "FFDDEBF7"), ("solid", "FFFFE699")]:
        fill = ET.SubElement(fills, x + "fill")
        pf = ET.SubElement(fill, x + "patternFill", {"patternType": pattern})
        if color:
            ET.SubElement(pf, x + "fgColor", {"rgb": color})
            ET.SubElement(pf, x + "bgColor", {"indexed": "64"})
    borders = ET.SubElement(root, x + "borders", {"count": "1"})
    ET.SubElement(borders, x + "border")
    base = ET.SubElement(root, x + "cellStyleXfs", {"count": "1"})
    ET.SubElement(base, x + "xf", {"numFmtId": "0", "fontId": "0", "fillId": "0", "borderId": "0"})
    xfs = ET.SubElement(root, x + "cellXfs", {"count": "6"})
    ET.SubElement(xfs, x + "xf", {"numFmtId": "0", "fontId": "0", "fillId": "0", "borderId": "0", "xfId": "0", "applyAlignment": "1"}).append(ET.Element(x + "alignment", {"vertical": "top", "wrapText": "1"}))
    ET.SubElement(xfs, x + "xf", {"numFmtId": "0", "fontId": "1", "fillId": "2", "borderId": "0", "xfId": "0", "applyAlignment": "1"}).append(ET.Element(x + "alignment", {"vertical": "center", "wrapText": "1"}))
    ET.SubElement(xfs, x + "xf", {"numFmtId": "0", "fontId": "0", "fillId": "3", "borderId": "0", "xfId": "0", "applyAlignment": "1"}).append(ET.Element(x + "alignment", {"vertical": "top", "wrapText": "1"}))
    ET.SubElement(xfs, x + "xf", {"numFmtId": "0", "fontId": "0", "fillId": "3", "borderId": "0", "xfId": "0", "applyAlignment": "1"}).append(ET.Element(x + "alignment", {"vertical": "top", "wrapText": "1"}))
    ET.SubElement(xfs, x + "xf", {"numFmtId": "0", "fontId": "0", "fillId": "4", "borderId": "0", "xfId": "0", "applyAlignment": "1"}).append(ET.Element(x + "alignment", {"vertical": "top", "wrapText": "1"}))
    ET.SubElement(xfs, x + "xf", {"numFmtId": "0", "fontId": "0", "fillId": "4", "borderId": "0", "xfId": "0", "applyAlignment": "1"}).append(ET.Element(x + "alignment", {"vertical": "top", "wrapText": "1"}))
    styles = ET.SubElement(root, x + "cellStyles", {"count": "1"})
    ET.SubElement(styles, x + "cellStyle", {"name": "Normal", "xfId": "0", "builtinId": "0"})
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def col_letter(index: int) -> str:
    return column_name(index)


def workbook_parts(sheets: list[tuple[str, list[list[object]], list[float]]]) -> dict[str, bytes]:
    main = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
    rel = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    pkgrel = "http://schemas.openxmlformats.org/package/2006/relationships"
    ct = "http://schemas.openxmlformats.org/package/2006/content-types"
    ET.register_namespace("", main)
    ET.register_namespace("r", rel)
    workbook = ET.Element(f"{{{main}}}workbook")
    bookviews = ET.SubElement(workbook, f"{{{main}}}bookViews")
    ET.SubElement(bookviews, f"{{{main}}}workbookView", {"xWindow": "0", "yWindow": "0", "windowWidth": "24000", "windowHeight": "12000"})
    sheets_el = ET.SubElement(workbook, f"{{{main}}}sheets")
    for i, (name, _, _) in enumerate(sheets, 1):
        ET.SubElement(sheets_el, f"{{{main}}}sheet", {"name": name, "sheetId": str(i), f"{{{rel}}}id": f"rId{i}"})
    ET.SubElement(workbook, f"{{{main}}}calcPr", {"calcId": "191029"})
    rels = ET.Element(f"{{{pkgrel}}}Relationships")
    for i, (_, _, _) in enumerate(sheets, 1):
        ET.SubElement(rels, f"{{{pkgrel}}}Relationship", {"Id": f"rId{i}", "Type": f"{rel}/worksheet", "Target": f"worksheets/sheet{i}.xml"})
    ET.SubElement(rels, f"{{{pkgrel}}}Relationship", {"Id": f"rId{len(sheets)+1}", "Type": f"{rel}/styles", "Target": "styles.xml"})
    types = ET.Element(f"{{{ct}}}Types")
    ET.SubElement(types, f"{{{ct}}}Default", {"Extension": "rels", "ContentType": "application/vnd.openxmlformats-package.relationships+xml"})
    ET.SubElement(types, f"{{{ct}}}Default", {"Extension": "xml", "ContentType": "application/xml"})
    ET.SubElement(types, f"{{{ct}}}Override", {"PartName": "/xl/workbook.xml", "ContentType": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"})
    ET.SubElement(types, f"{{{ct}}}Override", {"PartName": "/xl/styles.xml", "ContentType": "application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"})
    for i in range(1, len(sheets) + 1):
        ET.SubElement(types, f"{{{ct}}}Override", {"PartName": f"/xl/worksheets/sheet{i}.xml", "ContentType": "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"})
    root_rels = ET.Element(f"{{{pkgrel}}}Relationships")
    ET.SubElement(root_rels, f"{{{pkgrel}}}Relationship", {"Id": "rId1", "Type": f"{rel}/officeDocument", "Target": "xl/workbook.xml"})
    parts = {
        "[Content_Types].xml": ET.tostring(types, encoding="utf-8", xml_declaration=True),
        "_rels/.rels": ET.tostring(root_rels, encoding="utf-8", xml_declaration=True),
        "xl/workbook.xml": ET.tostring(workbook, encoding="utf-8", xml_declaration=True),
        "xl/_rels/workbook.xml.rels": ET.tostring(rels, encoding="utf-8", xml_declaration=True),
        "xl/styles.xml": make_styles(),
    }
    for i, (sheet_name, rows, widths) in enumerate(sheets, 1):
        parts[f"xl/worksheets/sheet{i}.xml"] = make_sheet(
            rows, widths, filter_enabled=sheet_name not in {"Overview", "Summary", "Start Here"}
        )
    return parts


def main() -> None:
    profiles = {name: parse_profile(name) for name in PROFILES}
    names = list(profiles)
    keys = sorted(set().union(*(set(v) for v in profiles.values())), key=lambda k: (k[0].casefold(), k[1].casefold(), k[2].casefold()))
    rows: list[list[object]] = []
    rows_by_profile: dict[str, list[list[object]]] = {n: [] for n in names}
    risk_rows: list[list[object]] = []
    counts: dict[str, Counter[str]] = {n: Counter() for n in names}
    category_counts: dict[str, Counter[str]] = {}
    conflict_rows: list[list[object]] = []

    headers = ["Category", "Permission / Setting", "Access facet", *names, "Assessment"]
    rows.append(headers)
    for key in keys:
        category, resource, facet = key
        raw = [profiles[n].get(key) for n in names]
        vals = [v if v is not None else "Not configured" for v in raw]
        present = [v is not None for v in raw]
        boolean = all(v in {"true", "false"} for v in raw if v is not None) and any(v is not None for v in raw)
        if boolean:
            true_names = [n for n, v in zip(names, vals) if v == "true"]
            if len(true_names) == len(names):
                assessment = "Common grant"
                counts[names[0]]["Common grants"] += 1
                for n in names[1:]: counts[n]["Common grants"] += 1
            elif true_names:
                assessment = "Delta: " + "; ".join(true_names)
                for n in true_names:
                    counts[n]["Unique grants"] += 1
                    category_counts.setdefault(category, Counter())[n] += 1
            else:
                assessment = "Disabled in all profiles" if all(present) else "Not configured in some profiles"
        elif len(set(vals)) == 1 and all(present):
            assessment = "Common setting"
        else:
            assessment = "Setting differs; review"
            conflict_rows.append([category, resource, facet, *vals, assessment])

        row = [category, resource, facet, *vals, assessment]
        rows.append(row)
        if assessment.startswith("Delta:") or assessment.startswith("Setting differs") or "Not configured" in assessment:
            for n, value in zip(names, vals):
                if (value == "true" and assessment.startswith("Delta:")) or assessment.startswith("Setting differs"):
                    rows_by_profile[n].append([category, resource, facet, value, assessment])

        low = resource.casefold() + " " + facet.casefold()
        high_risk = (
            category == "System Permissions" and resource in HIGH_RISK_SYSTEM and "true" in vals
        ) or (
            category == "Object Permissions" and facet in {"viewAllRecords", "modifyAllRecords", "viewAllFields"} and "true" in vals
        )
        if high_risk:
            signal = "Review: elevated system permission" if category == "System Permissions" else "Review: object View All / Modify All"
            risk_rows.append(row + [signal])

        if boolean:
            for n, value in zip(names, vals):
                if value == "true": counts[n][f"Enabled {category}"] += 1

    summary = [["Profile", "License", "Custom", "Active user snapshot", "Enabled system grants", "Object permission flags", "FLS grants", "Apex/VF grants", "Common enabled grants", "Profile-specific enabled grants"]]
    active_users = {
        "Mobileum - Sales User": "163",
        "Mobileum - Sales Head": "20",
    }
    for n in names:
        values = profiles[n]
        license_value = values.get(("Profile Metadata", "User License", "license"), "Unknown")
        custom_value = values.get(("Profile Metadata", "Custom Profile", "custom"), "Unknown")
        sum_cat = lambda cat: sum(1 for (c, _, _), v in values.items() if c == cat and v == "true")
        common = sum(1 for row in rows[1:] if row[-1] == "Common grant" and row[names.index(n) + 3] == "true")
        unique = sum(1 for row in rows[1:] if row[-1].startswith("Delta:") and row[names.index(n) + 3] == "true")
        summary.append([n, license_value, custom_value, active_users[n] + " active (snapshot)", sum_cat("System Permissions"), sum_cat("Object Permissions"), sum_cat("Field Permissions (FLS)"), sum_cat("Apex Class Access") + sum_cat("Visualforce Page Access"), common, unique])

    summary.extend([
        ["Decision guide", "Common enabled grants are only a possible baseline; confirm business need before retaining them."],
        ["Delta interpretation", "True access enabled in one or more source profiles but not all. Permission Sets can add approved grants; they cannot remove access from a broad baseline."],
        ["Settings requiring separate treatment", "Layout assignments, app/tab visibility, record-type defaults, login hours/IP ranges, roles, sharing, existing Permission Sets/Groups, and profile-name dependencies require explicit review."],
        ["Known Sales UI concern", "Sales User and Sales Head match on all eight custom app overrides in the saved audit. Their Territory__c.Region personAccountDefault differs; review and test that profile-level setting."],
        ["Record type review", "Sales User and Sales Head differ on Territory__c.Region personAccountDefault. The full row values are on the UI & Settings sheet."],
        ["Scope / source", "Complete Profile XMLs retrieved from MobiliumStaging on 2026-10-19; three Salesforce-licensed profiles. This is a local comparison only; no org change or deployment."],
        ["Profile flow grants", "No direct flowAccesses entries were found in these Profile XMLs. Check flow/Apex dependencies and existing assignments separately."],
    ])

    ui_categories = {"Tab Visibility", "Application Visibility", "Record Type Visibility", "Page Layout Assignment", "Login/IP Controls", "Profile Metadata"}
    ui_rows = [headers]
    for row in rows[1:]:
        if row[0] in ui_categories:
            ui_rows.append(row)

    risk_sheet = [headers + ["Review Signal"]]
    risk_sheet.extend(risk_rows)

    sheets: list[tuple[str, list[list[object]], list[float]]] = [
        ("Overview", [["Sales User and Sales Head Profile Comparison"], ["Profiles compared", "; ".join(PROFILES)], ["Org snapshot", "MobiliumStaging metadata retrieved 2026-10-19"], ["Purpose", "Show grants shared by Sales User and Sales Head and each profile's positive access differences."], ["Important", "This workbook is a review aid, not an approved target design or deployment package."], ["How to use", "Start with Summary; filter All Grants or a profile Delta sheet by category, resource, or assessment."], ["Baseline", "Use only approved shared grants in a minimum-access Sales baseline. Do not use boolean UNION as an automatic merge rule."], ["Permission Sets", "A Permission Set is additive. Put approved source-only access in narrowly scoped sets and keep elevated grants under explicit security review."], ["Persona groups", "Create a PSG only where a stable user persona needs multiple approved Permission Sets. Do not assign users based only on their current profile."], ["Delta tabs", "Each persona delta tab includes unique enabled grants and differing settings. Layout, app, tab, record-type, and login controls may not be movable to Permission Sets."], ["Candidate design", "The two-profile POC proposes one Sales_Profile_POC_Baseline, four candidate Permission Sets, and two persona PSGs. See PS & PSG Plan; validate module contents and user assignments before implementation."], ["Important limits", "Profile XML does not calculate effective user access from existing PS/PSGs, roles, sharing, territories, or managed packages. App action overrides require separate validation."], ["Files", "The three-profile Sales / APAC comparison is preserved in Sales_Profile_Comparison_Deltas_All_3_Profiles.xlsx. The isolated two-profile POC is in access-review/sales-profile-poc/."], ["No deployment", "No org metadata or user assignments were changed."]], [30, 100]),
        ("Summary", summary, [42, 45, 14, 30, 22, 24, 18, 18, 22, 26]),
        ("All Grants", rows, [28, 55, 22, 22, 22, 28, 55]),
        ("SU Delta", [headers[:3] + [PROFILES[0], "Assessment"]] + rows_by_profile[PROFILES[0]], [28, 55, 22, 24, 55]),
        ("Head Delta", [headers[:3] + [PROFILES[1], "Assessment"]] + rows_by_profile[PROFILES[1]], [28, 55, 22, 24, 55]),
        ("UI & Settings", ui_rows, [28, 55, 24, 23, 23, 34, 45]),
        ("High Risk Review", risk_sheet, [28, 55, 22, 22, 22, 28, 55, 38]),
        ("PS & PSG Plan", [["Component", "Candidate API Name", "Candidate contents / purpose", "Source cohort", "Review note"],
            ["Permission Set", "Sales_User_Access_Delta", "Approved object, field, and record-type grants above Sales_Base_Profile", "Mobileum - Sales User", "Populate from SU Delta after owner review."],
            ["Permission Set", "Sales_User_System_Delta", "Approved enabled system permissions above Sales_Base_Profile", "Mobileum - Sales User", "Review high-impact system permissions individually."],
            ["Permission Set", "Sales_Head_Access_Delta", "Approved object, field, and record-type grants above the shared baseline", "Mobileum - Sales Head", "No Sales Head-only system grants were found in the two-profile POC."],
            ["Permission Set", "Sales_Project_Name_Restriction", "Custom Permission for the existing Sales User Project Name validation behavior", "Mobileum - Sales User", "Update and test the rule before assignments."],
            ["Permission Set Group", "Sales_User_POC", "Sales User access/system deltas plus approved Project Name restriction set", "Mobileum - Sales User", "Assign group only; do not separately assign included component sets."],
            ["Permission Set Group", "Sales_Head_POC", "Sales Head access delta", "Mobileum - Sales Head", "Confirm user roster and any other existing PS/PSG assignments."],
            ["Profile", "Sales_Profile_POC_Baseline", "Approved least-access grants common to both source profiles", "Sales User and Sales Head", "A common grant is not automatically authorized; check each row in All Grants."]], [22, 36, 70, 48, 62]),
    ]
    parts = workbook_parts(sheets)
    with zipfile.ZipFile(OUTPUT, "w", zipfile.ZIP_DEFLATED) as archive:
        for path, data in parts.items():
            archive.writestr(path, data)
    print(f"Created {OUTPUT}")
    delta_counts = ", ".join(str(len(rows_by_profile[name])) for name in PROFILES)
    print(f"Rows: {len(rows)-1} permission/settings entries; common grants: {sum(1 for r in rows[1:] if r[-1] == 'Common grant')}; profile delta rows: {delta_counts}; high-risk rows: {len(risk_rows)}")


if __name__ == "__main__":
    main()
