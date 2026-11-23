#!/usr/bin/env python3
"""Build a proposed user-to-permission-set cohort map; never changes Salesforce."""

import csv
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
USERS = Path("/tmp/mobileum_active_users_department.csv")
ASSIGNMENTS = Path("/tmp/mobileum_permission_assignments.csv")
OUT = ROOT / "access-review/Finance_Profile_PS_Assignment_Proposal.csv"
PROFILE_TO_PS = {
    "Mobileum- Finance Full Access": "Fin_Full_Access_Delta",
    "Mobileum - Sales Head": "Fin_Sales_Head_Delta",
    "Mobileum - Finance User Limited": "Fin_Limited_Access_Delta",
    "Mobileum - Sales User": "Fin_Sales_User_Delta",
    "Mobileum - Super Sales User": "Fin_Super_Sales_Delta",
}
PROFILE_TO_SYSTEM_PS = {
    "Mobileum- Finance Full Access": "Fin_Full_Access_System",
    "Mobileum - Sales Head": "Fin_Sales_Head_System",
    "Mobileum - Finance User Limited": "Fin_Limited_Access_System",
    "Mobileum - Sales User": "Fin_Sales_User_System",
    "Mobileum - Super Sales User": "Fin_Super_Sales_System",
}
QUOTE = "Quote Creation Team Member"
SCOPE = set(PROFILE_TO_PS) | {QUOTE}


def read(path):
    with path.open(newline="", encoding="utf-8-sig") as f:
        return list(csv.DictReader(f))


def main():
    users = read(USERS)
    assignments = read(ASSIGNMENTS)
    by_user = defaultdict(list)
    for row in assignments:
        by_user[row["Assignee.Username"]].append(row)
    selected = [
        row for row in users
        if row["Department"].strip().casefold() == "finance" and row["Profile.Name"] in SCOPE
    ]
    selected.sort(key=lambda row: (row["Profile.Name"], row["Name"], row["Username"]))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.writer(f)
        writer.writerow(["User", "Username", "Department", "Current Profile", "Current Role", "Candidate Data Permission Set", "Candidate System Permission Set", "Additional Dependency Permission Set", "Existing PS/PSG assignment rows", "POC disposition"])
        for row in selected:
            profile = row["Profile.Name"]
            if profile == QUOTE:
                data_ps = system_ps = dependency_ps = "—"
                disposition = "Hold out of baseline migration until Quote profile is decomposed and approved"
            else:
                data_ps = PROFILE_TO_PS[profile]
                system_ps = PROFILE_TO_SYSTEM_PS[profile]
                dependency_ps = "Sales_Project_Name_Restriction" if profile == "Mobileum - Sales User" else "—"
                disposition = "Candidate cohort only; assign only with approved baseline-profile migration"
            writer.writerow([row["Name"], row["Username"], row["Department"], profile, row["UserRole.Name"], data_ps, system_ps, dependency_ps, len(by_user[row["Username"]]), disposition])
    counts = Counter(row["Profile.Name"] for row in selected)
    print(f"Finance-scoped users: {len(selected)}; proposed PS-assignment candidates: {len(selected)-counts[QUOTE]}; held Quote users: {counts[QUOTE]}; wrote {OUT}")
    for profile, count in sorted(counts.items()):
        print(profile, count, PROFILE_TO_PS.get(profile, "HOLD"))


if __name__ == "__main__":
    main()
