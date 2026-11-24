#!/usr/bin/env python3
"""Build a provisional user-to-PS/PSG roster from the existing staging workbook."""

import csv
import re
import zipfile
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKBOOK = ROOT / "access-review/MobiliumStaging_Access_Matrix.xlsx"
OUT = ROOT / "access-review/Profile_Consolidation_User_Assignment_Proposal.csv"

NS = {
    "a": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
}

TARGETS = {
    "Mobileum - Sales User": ("Sales_Base_Profile", "", "PSG_Sales_User", "PROVISIONAL; confirm named department/access roster"),
    "Mobileum - Sales Head": ("Sales_Base_Profile", "", "PSG_Sales_Head", "PROVISIONAL; confirm named department/access roster"),
    "Mobileum - Sales User - STDM - APAC": ("Sales_Base_Profile", "", "PSG_STDM_APAC", "HOLD; APAC UI differences need approval"),
    "Mobileum - Product Management": ("Product_Base_Profile", "Product_Management_Access_Delta", "", "PROVISIONAL; access/UI approval required"),
    "Mobileum - Product Management User": ("Product_Base_Profile", "", "PSG_Product_Management_User", "PROVISIONAL; access/UI approval required"),
    "Mobileum - Marketing User": ("Marketing_Base_Profile", "", "PSG_Marketing_User", "PROVISIONAL; access/UI approval required"),
    "Leads, Accounts and Opportunity Creation Marketing Team": ("Marketing_Base_Profile", "", "PSG_Leads_Accounts_Marketing", "PROVISIONAL; access/UI approval required"),
    "Mobileum - Finance User Limited": ("Finance_Base_Profile", "", "PSG_Finance_Limited", "PROVISIONAL; user cohort and UI approval required"),
    "Mobileum- Finance Full Access": ("Finance_Base_Profile", "", "PSG_Finance_Full_Unspaced", "HOLD; confirm separate Full Access cohort and UI"),
    "Mobileum - Finance Full Access": ("Finance_Base_Profile", "Finance_Full_Spaced_Access_Delta", "", "HOLD; confirm distinct cohort and resolve UI differences"),
    "Mobileum Read Only": ("Read_Access_Base_Profile", "", "PSG_Mobileum_Read_Only", "PROVISIONAL; review write/View All grants"),
    "Read Only1": ("Read_Access_Base_Profile", "Read_Only1_Access_Delta", "", "PROVISIONAL; review write/View All grants"),
    "Mobileum - Super Sales User": ("Elevated_Access_Base_Profile", "Super_Sales_Access_Delta", "", "HOLD; security approval required"),
    "Mobileum Salesops Team Profile": ("Elevated_Access_Base_Profile", "", "PSG_Salesops", "HOLD; security and dependency approval required"),
    "Quote Creation Team Member": ("Elevated_Access_Base_Profile", "", "PSG_Quote_Creation", "HOLD; security and approval-flow review required"),
    "Hubspot": ("Hubspot (retain)", "", "", "RETAIN; integration review before any migration"),
}

# Proposed PSG membership for each source-profile cohort. These are planning
# names only; create/validate the PSG metadata after access and roster approval.
PSG_PERMISSION_SETS = {
    "Mobileum - Sales User": "Sales_User_Access_Delta; Sales_User_System_Delta; Sales_Project_Name_Restriction",
    "Mobileum - Sales Head": "Sales_Head_Access_Delta; Sales_Head_System_Delta",
    "Mobileum - Sales User - STDM - APAC": "STDM_APAC_Access_Delta; STDM_APAC_System_Delta",
    "Mobileum - Product Management User": "Product_Management_User_Access_Delta; Product_Management_User_System_Delta",
    "Mobileum - Marketing User": "Marketing_User_Access_Delta; Marketing_User_System_Delta",
    "Leads, Accounts and Opportunity Creation Marketing Team": "Leads_Team_Access_Delta; Leads_Team_System_Delta",
    "Mobileum - Finance User Limited": "Finance_Limited_Access_Delta; Finance_Limited_System_Delta",
    "Mobileum- Finance Full Access": "Finance_Full_Unspaced_Access_Delta; Finance_Full_Unspaced_System_Delta",
    "Mobileum Read Only": "Mobileum_Read_Only_Access_Delta; Mobileum_Read_Only_System_Delta",
    "Mobileum Salesops Team Profile": "Salesops_Access_Delta; Salesops_System_Delta",
    "Quote Creation Team Member": "Quote_Access_Delta; Quote_System_Delta",
}


def column_index(cell_ref):
    letters = re.sub(r"[0-9]", "", cell_ref)
    number = 0
    for letter in letters:
        number = number * 26 + ord(letter.upper()) - ord("A") + 1
    return number - 1


def cell_text(cell, shared_strings):
    cell_type = cell.attrib.get("t")
    if cell_type == "inlineStr":
        return "".join(node.text or "" for node in cell.findall(".//a:t", NS))
    value = cell.findtext("a:v", default="", namespaces=NS)
    if cell_type == "s" and value:
        return shared_strings[int(value)]
    return value


def read_sheet(zf, workbook_root, rel_map, shared_strings, sheet_name):
    sheet = next(s for s in workbook_root.findall("a:sheets/a:sheet", NS) if s.attrib["name"] == sheet_name)
    target = rel_map[sheet.attrib["{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id"]]
    path = target if target.startswith("xl/") else f"xl/{target}"
    root = ET.fromstring(zf.read(path))
    result = []
    for row in root.findall(".//a:sheetData/a:row", NS):
        cells = {}
        for cell in row.findall("a:c", NS):
            cells[column_index(cell.attrib["r"])] = cell_text(cell, shared_strings)
        result.append(cells)
    return result


def rows_as_dicts(rows):
    headers = rows[0]
    header_map = {index: value for index, value in headers.items()}
    for row in rows[1:]:
        yield {header_map[index]: value for index, value in row.items() if index in header_map}


def main():
    with zipfile.ZipFile(WORKBOOK) as zf:
        workbook = ET.fromstring(zf.read("xl/workbook.xml"))
        relationships = ET.fromstring(zf.read("xl/_rels/workbook.xml.rels"))
        rel_map = {rel.attrib["Id"]: rel.attrib["Target"] for rel in relationships}
        shared_strings = []
        if "xl/sharedStrings.xml" in zf.namelist():
            shared_root = ET.fromstring(zf.read("xl/sharedStrings.xml"))
            shared_strings = [
                "".join(node.text or "" for node in item.findall(".//a:t", NS))
                for item in shared_root.findall("a:si", NS)
            ]
        users = list(rows_as_dicts(read_sheet(zf, workbook, rel_map, shared_strings, "Users")))
        assignment_rows = list(rows_as_dicts(read_sheet(zf, workbook, rel_map, shared_strings, "Assignments")))

    assignments = defaultdict(lambda: {"direct": set(), "groups": set()})
    for row in assignment_rows:
        username = row.get("Username", "").strip()
        kind = row.get("Assignment Kind", "").strip()
        if not username:
            continue
        if kind == "Direct Permission Set":
            label = row.get("Permission Set Label", "").strip() or row.get("Direct Permission Set", "").strip()
            if label:
                assignments[username]["direct"].add(label)
        elif kind == "Permission Set Group":
            group = row.get("Permission Set Group", "").strip()
            if group:
                assignments[username]["groups"].add(group)

    output = []
    for user in users:
        profile = user.get("Profile", "").strip()
        if profile not in TARGETS:
            continue
        target_profile, direct_ps, psg, disposition = TARGETS[profile]
        active = user.get("Active", "").strip().lower() == "true"
        if not active and disposition.startswith("PROVISIONAL"):
            disposition = "HOLD INACTIVE; confirm on reactivation; " + disposition
        current = assignments[user.get("Username", "").strip()]
        output.append({
            "Snapshot Date": "2026-10-14",
            "Name": user.get("Name", ""),
            "Username": user.get("Username", ""),
            "Active": str(active).lower(),
            "User Type": user.get("User Type", ""),
            "License": user.get("License", ""),
            "Current Profile": profile,
            "Current Role": user.get("Role", ""),
            "Proposed Role (default)": user.get("Role", "").strip() or "UNRESOLVED - role missing in source export",
            "Role Review Status": (
                "PRESERVE CURRENT ROLE pending approved role redesign"
                if user.get("Role", "").strip()
                else "HOLD - confirm role from refreshed org/user roster"
            ),
            "Partner Department (confirm)": "",
            "Current Direct PS Count": len(current["direct"]),
            "Current Direct PS Labels": "; ".join(sorted(current["direct"], key=str.casefold)),
            "Current PSG Count": len(current["groups"]),
            "Current PSG API Names": "; ".join(sorted(current["groups"], key=str.casefold)),
            "Proposed Target Profile": target_profile,
            "Proposed Direct PS": direct_ps,
            "Proposed PSG": psg,
            "Proposed PS included in PSG": PSG_PERMISSION_SETS.get(profile, ""),
            "Assignment Disposition": disposition,
        })

    columns = list(output[0]) if output else []
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.DictWriter(stream, fieldnames=columns)
        writer.writeheader()
        writer.writerows(sorted(output, key=lambda row: (
            row["Current Profile"].casefold(), row["Active"] != "true", row["Name"].casefold()
        )))
    active_count = sum(row["Active"] == "true" for row in output)
    inactive_count = len(output) - active_count
    print(f"Wrote {len(output)} users ({active_count} active, {inactive_count} inactive) to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
