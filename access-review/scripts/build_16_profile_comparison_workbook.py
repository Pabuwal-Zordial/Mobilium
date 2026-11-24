#!/usr/bin/env python3
"""Build a filterable, project-manager-friendly comparison workbook for 16 profiles."""

from __future__ import annotations

import csv
import itertools
import sys
from collections import Counter
from pathlib import Path

from build_sales_profile_delta_workbook import (
    HIGH_RISK_SYSTEM,
    PROFILE_DIR,
    parse_profile,
    workbook_parts,
)


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "Profile_Comparison_16_Profiles_PM_Workbook.xlsx"
PROFILES = [
    "Hubspot",
    "Leads, Accounts and Opportunity Creation Marketing Team",
    "Mobileum - Finance Full Access",
    "Mobileum - Finance User Limited",
    "Mobileum - Marketing User",
    "Mobileum - Product Management User",
    "Mobileum - Product Management",
    "Mobileum - Sales Head",
    "Mobileum - Sales User - STDM - APAC",
    "Mobileum - Sales User",
    "Mobileum - Super Sales User",
    "Mobileum Read Only",
    "Mobileum Salesops Team Profile",
    "Mobileum- Finance Full Access",
    "Quote Creation Team Member",
    "Read Only1",
]

FAMILY_PROFILES = {
    "Sales": ["Mobileum - Sales User", "Mobileum - Sales Head", "Mobileum - Sales User - STDM - APAC"],
    "Product Management": ["Mobileum - Product Management", "Mobileum - Product Management User"],
    "Marketing": ["Mobileum - Marketing User", "Leads, Accounts and Opportunity Creation Marketing Team"],
    "Finance": ["Mobileum - Finance User Limited", "Mobileum- Finance Full Access", "Mobileum - Finance Full Access"],
    "Read Access": ["Mobileum Read Only", "Read Only1"],
    "Elevated Access": ["Mobileum - Super Sales User", "Mobileum Salesops Team Profile", "Quote Creation Team Member"],
    "Integration": ["Hubspot"],
}

TARGETS = {
    "Sales": ("Sales_Base_Profile", "Conditional candidate", "Review APAC app overrides and regional record visibility; User and Head also differ on a record-type default."),
    "Product Management": ("Product_Base_Profile", "Conditional candidate", "Review app overrides, flow/report-type system grants, and approval-object View All/Modify All."),
    "Marketing": ("Marketing_Base_Profile", "Conditional candidate", "Review broad campaign/support-request grants and app-override differences."),
    "Finance": ("Finance_Base_Profile", "Confirmed consolidation direction; access approval pending", "Client says both Full Access profiles are distinct and both should consolidate. Keep separate source cohorts/deltas; review app overrides."),
    "Read Access": ("Read_Access_Base_Profile", "Review candidate", "Do not rely on profile names: both have write or elevated object access. Confirm each grant with owners."),
    "Elevated Access": ("Elevated_Access_Base_Profile", "Security hold", "Do not combine with ordinary business access. Review high-impact system and object grants individually."),
    "Integration": ("Retain Hubspot pending integration review", "Keep separate", "Replace/test the profile-name Apex check and confirm integration login controls before any future move."),
}

PS_ESTIMATES = {
    "Sales": "7 candidate PS / 3 PSGs",
    "Product Management": "3 candidate PS / 1 PSG",
    "Marketing": "4 candidate PS / 2 PSGs",
    "Finance": "5 candidate PS / 2 PSGs",
    "Read Access": "3 candidate PS / 1 PSG",
    "Elevated Access": "5 candidate PS / 2 PSGs; security approval required",
    "Integration": "No new PS/PSG proposed; retain Hubspot profile for now",
}

CATEGORY_ORDER = [
    "System Permissions", "Object Permissions", "Field Permissions (FLS)",
    "Apex Class Access", "Visualforce Page Access", "Flow Access",
    "Custom Metadata Access", "Custom Setting Access", "Custom Permission Access",
    "Tab Visibility", "Application Visibility", "Record Type Visibility",
    "Page Layout Assignment", "Login/IP Controls", "Profile Metadata",
    "External Data Source Access", "Other Profile Setting",
]


def get_inventory() -> dict[str, dict[str, str]]:
    path = ROOT / "Main_Org_Profile_Inventory.csv"
    with path.open(newline="", encoding="utf-8-sig") as stream:
        return {row["Profile"]: row for row in csv.DictReader(stream)}


def license_for(values: dict[tuple[str, str, str], str]) -> str:
    return values.get(("Profile Metadata", "User License", "license"), "Unknown")


def enabled_set(values: dict[tuple[str, str, str], str], category: str) -> set[tuple[str, str, str]]:
    return {key for key, value in values.items() if key[0] == category and value == "true"}


def similarity(left: set[tuple[str, str, str]], right: set[tuple[str, str, str]]) -> float:
    union = left | right
    return len(left & right) / len(union) if union else 1.0


def family_for_pair(a: str, b: str) -> str:
    pair = {a, b}
    for family, profiles in FAMILY_PROFILES.items():
        if pair <= set(profiles) and len(profiles) > 1:
            return family
    return "Cross-family / no current merge recommendation"


def decision_for_pair(a: str, b: str) -> tuple[str, str, str]:
    family = family_for_pair(a, b)
    if family == "Cross-family / no current merge recommendation":
        return family, "No current recommendation", "Keep separate unless business ownership and access evidence establish a common persona."
    return (family, *TARGETS[family][1:])


def access_kind(category: str, facet: str, a: str, b: str) -> tuple[str, str]:
    if a in {"true", "false"} and b in {"true", "false"}:
        if a == "true" and b == "false":
            return "Grant enabled only in Profile A", "Candidate additive delta for Profile A; review before moving to a PS."
        if b == "true" and a == "false":
            return "Grant enabled only in Profile B", "Candidate additive delta for Profile B; review before moving to a PS."
        return "Boolean setting differs", "Review the explicit values and the Salesforce metadata semantics."
    if "Not configured" in {a, b}:
        return "Configured in one profile only", "Verify missing-node meaning; do not infer a deny from absence alone."
    if category in {"Tab Visibility", "Application Visibility", "Record Type Visibility", "Page Layout Assignment", "Login/IP Controls", "Profile Metadata"}:
        return "Profile control differs", "Profile/UI control; not a straightforward Permission Set delta. Preserve or redesign separately."
    return "Value differs", "Review source metadata and effective access before recommending a change."


def main() -> None:
    missing = [name for name in PROFILES if not (PROFILE_DIR / f"{name}.profile-meta.xml").exists() and not (PROFILE_DIR / f"{name.replace(',', '%2C')}.profile-meta.xml").exists()]
    if missing:
        raise FileNotFoundError("Missing profile XML: " + ", ".join(missing))
    data = {name: parse_profile(name) for name in PROFILES}
    inventory = get_inventory()
    all_keys = set().union(*(set(values) for values in data.values()))
    pairs = list(itertools.combinations(PROFILES, 2))
    pair_detail = [["Profile A", "Profile B", "License match", "Category", "Resource", "Permission / Setting", "Profile A value", "Profile B value", "Difference type", "Suggested handling"]]
    pair_summary = [["Profile A", "Profile B", "Family", "License match", "Weighted similarity", "System differences", "Object differences", "FLS differences", "Other setting differences", "A-only grants", "B-only grants", "Total delta rows", "Recommendation", "Decision / key review"]]
    profile_grants = [["Profile", "License", "Category", "Resource", "Permission / Setting", "Value", "Enabled grant?", "Review signal"]]
    candidate_groups = [["Candidate family", "Proposed target / disposition", "Source profile(s)", "Active users snapshot", "Inactive users snapshot", "PS / PSG estimate", "Current recommendation", "Key review before any retirement"]]

    for name in PROFILES:
        values = data[name]
        inv = inventory.get(name, {})
        for (category, resource, facet), value in sorted(values.items(), key=lambda entry: (entry[0][0].casefold(), entry[0][1].casefold(), entry[0][2].casefold())):
            enabled = value == "true"
            signal = "High-impact review" if (
                (category == "System Permissions" and resource in HIGH_RISK_SYSTEM and enabled)
                or (category == "Object Permissions" and facet in {"viewAllRecords", "modifyAllRecords", "viewAllFields"} and enabled)
            ) else ""
            profile_grants.append([name, license_for(values), category, resource, facet, value, "Yes" if enabled else "No", signal])

    for family, members in FAMILY_PROFILES.items():
        target, status, notes = TARGETS[family]
        active = sum(int(inventory.get(profile, {}).get("Active Users", "0") or 0) for profile in members)
        inactive = sum(int(inventory.get(profile, {}).get("Inactive Users", "0") or 0) for profile in members)
        candidate_groups.append([family, target, "\n".join(members), active, inactive, PS_ESTIMATES[family], status, notes])

    for a, b in pairs:
        left, right = data[a], data[b]
        same_license = license_for(left) == license_for(right)
        delta_keys = [key for key in all_keys if left.get(key) != right.get(key)]
        system_delta = sum(1 for key in delta_keys if key[0] == "System Permissions")
        object_delta = sum(1 for key in delta_keys if key[0] == "Object Permissions")
        fls_delta = sum(1 for key in delta_keys if key[0] == "Field Permissions (FLS)")
        other_delta = len(delta_keys) - system_delta - object_delta - fls_delta
        a_only = sum(1 for key in delta_keys if left.get(key) == "true" and right.get(key) != "true")
        b_only = sum(1 for key in delta_keys if right.get(key) == "true" and left.get(key) != "true")
        score = (
            0.30 * similarity(enabled_set(left, "System Permissions"), enabled_set(right, "System Permissions"))
            + 0.30 * similarity(enabled_set(left, "Object Permissions"), enabled_set(right, "Object Permissions"))
            + 0.40 * similarity(enabled_set(left, "Field Permissions (FLS)"), enabled_set(right, "Field Permissions (FLS)"))
        )
        family, recommendation, notes = decision_for_pair(a, b)
        pair_summary.append([a, b, family, "Yes" if same_license else "No", f"{score:.3f}", system_delta, object_delta, fls_delta, other_delta, a_only, b_only, len(delta_keys), recommendation, notes])
        for category, resource, facet in sorted(delta_keys, key=lambda k: (k[0].casefold(), k[1].casefold(), k[2].casefold())):
            va = left.get((category, resource, facet), "Not configured")
            vb = right.get((category, resource, facet), "Not configured")
            diff_type, handling = access_kind(category, facet, va, vb)
            pair_detail.append([a, b, "Yes" if same_license else "No", category, resource, facet, va, vb, diff_type, handling])

    candidate_groups.extend([
        ["Scope", "16 profile definitions; System Administrator excluded", "", "", "", "Review scope", "This workbook is for the 16 in-scope custom profiles; it is not an effective-user-access calculation."],
        ["Target count", "Six family baselines plus retained Hubspot (7 total)", "", "", "", "Planning proposal", "From the implementation guide; depends on license/profile-control compatibility, owner approval, and preserving UI behavior."],
    ])

    # Put suggested families in a useful order and mark all-candidate merge intentions distinctly.
    start_here = [
        ["16-Profile Comparison Workbook"],
        ["Audience", "Project managers, access owners, and Salesforce reviewers"],
        ["Purpose", "Compare every in-scope profile pair, inspect exact deltas, and review candidate consolidation families."],
        ["Step 1", "Open Candidate Groups to see the suggested baseline families and why each is conditional, held, or retained."],
        ["Step 2", "Open Pair Summary and filter by Profile A, Profile B, Family, or Recommendation to select a pair."],
        ["Step 3", "Use those same Profile A / Profile B filter values in Pairwise Deltas to see each differing permission or setting."],
        ["Step 4", "Filter Profile Grants by Profile and Category for a complete access inventory of that profile."],
        ["Reading the differences", "Enabled only in one profile is a candidate additive delta. 'Not configured' requires metadata-semantics review. App, tab, layout, record-type, login, and license settings need separate handling."],
        ["Merge rule", "Similarity and common grants are review evidence, not approval. Build a least-access common baseline; move only business-approved additive differences to modular Permission Sets."],
        ["Assignment rule", "Current profiles identify provisional cohorts, not final users. Confirm active and inactive users, department/persona, existing PS/PSG assignments, and exceptions before assignment."],
        ["Important", "Permission Sets add access; they do not remove profile grants. Review elevated permissions, field sensitivity, record sharing, role hierarchy, and profile-name dependencies separately."],
        ["Source", "Profile XML from MobiliumStaging, retrieved 2026-10-19; 16 profiles. System Administrator is excluded."],
        ["Limit", "Flow, Apex, approval, validation, sharing, and other profile-name dependencies are not inferred from a permission comparison. See the org dependency audit and implementation guide."],
        ["Safety", "Local analysis only; no org metadata or assignments were changed or deployed."],
    ]

    reference = [["Category", "What is compared", "How to interpret a difference"]]
    for row in [
        ("System Permissions", "Enabled/disabled user permission flags", "Treat admin/API/data export permissions as high-impact review signals."),
        ("Object Permissions", "Create, Read, Edit, Delete, View All Fields, View All Records, Modify All Records", "Permission values are per object; View All/Modify All can materially broaden access."),
        ("Field Permissions (FLS)", "Readable and editable flags per field", "Review sensitive fields with the data owner."),
        ("Apex / Visualforce", "Class and page enabled flags", "Check dependencies and runtime behavior."),
        ("Apps / Tabs", "Visibility and defaults", "UI behavior may need redesign; it is not a normal object/FLS delta."),
        ("Record Types / Layouts", "Visibility, default selections, and layout assignments", "Defaults and layout behavior may require separate profile treatment."),
        ("Other profile settings", "License, custom-profile flag, and captured login controls", "Different license tiers block a shared profile; do not infer access from missing XML nodes."),
    ]:
        reference.append(list(row))

    candidate_groups.extend([
        ["Overall planning model", "Six family baselines + retained Hubspot", "All 16 in-scope profiles", "", "", "27 candidate PS / 11 PSGs", "Planning proposal", "All counts are provisional. Confirm profile-only behavior, existing set reuse, user/persona mapping, and owner-approved entitlements before build."],
    ])

    sheets = [
        ("Start Here", start_here, [32, 110]),
        ("Candidate Groups", candidate_groups, [28, 40, 70, 18, 18, 42, 38, 85]),
        ("Pair Summary", pair_summary, [45, 45, 32, 16, 20, 20, 20, 18, 24, 16, 16, 16, 38, 90]),
        ("Pairwise Deltas", pair_detail, [45, 45, 15, 32, 55, 25, 24, 24, 32, 90]),
        ("Profile Grants", profile_grants, [48, 32, 32, 55, 25, 22, 16, 28]),
        ("Reference", reference, [30, 80, 90]),
    ]
    parts = workbook_parts(sheets)
    import zipfile

    with zipfile.ZipFile(OUTPUT, "w", zipfile.ZIP_DEFLATED) as archive:
        for path, content in parts.items():
            archive.writestr(path, content)
    print(f"Created {OUTPUT}")
    print(f"Profiles: {len(PROFILES)}; pair comparisons: {len(pairs)}; delta detail rows: {len(pair_detail)-1}; grant inventory rows: {len(profile_grants)-1}")


if __name__ == "__main__":
    main()
