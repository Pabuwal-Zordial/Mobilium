# Profile Consolidation Candidate Analysis

## Executive recommendation

Treat these as **candidate families for a shared minimum-access profile plus narrowly scoped Permission Sets**, not as approved merges. Do not union profile grants: Permission Sets only add access, so a shared profile should start from the approved common baseline. Keep role hierarchy and record sharing separate from this design.

The client's direction supports a **minimum-access profile model**: use the fewest profiles compatible with the Salesforce license and profile-only controls, then deliver approved job access through Permission Sets and curated Permission Set Groups. Evaluate whether the existing `Minimum Access - Salesforce` profile is a suitable base before creating another. One baseline profile may work for most of these Salesforce-licensed users, but it is not yet safe to promise a single profile: layouts, default record types, profile-level app action overrides, login hours/IP ranges, and profile-name-dependent logic need explicit preservation or redesign.

Design Permission Sets as small, named modules (for example, job task access, reporting, quote work, or integration capability). Keep system/administrative grants in separately governed sets. Use Permission Set Groups to bundle the approved modules for a user persona; do not create one oversized set per former profile by mechanically copying all grants. A Permission Set Group cannot remove grants that remain on the base profile. A muting permission set only mutes grants contributed by sets inside that group.

### Candidate families

| Priority | Profiles to assess together | Recommendation and key condition |
|---|---|---|
| 1 | `Mobileum - Sales User` + `Mobileum - Sales Head` | Strongest candidate. They share most enabled system grants, all 202 profile layout mappings, all 30 profile app visibilities, and all 8 custom-app profile overrides. They still have distinct object/FLS grants. Use a common baseline and role-specific deltas only after validating Sales User's broad grants. |
| 2 | `Mobileum - Product Management` + `Mobileum - Product Management User` | Candidate only with app-override redesign/preservation. They share 201 of 202 layouts and all 30 app visibilities, but only 3 of 6 custom-app overrides match. The User profile has `RunFlow`, `ManageCustomReportTypes`, and additional object grants, including View All/Modify All on approval-related objects. Validate each difference. |
| 3 | `Mobileum - Marketing User` + `Leads, Accounts and Opportunity Creation Marketing Team` | Candidate only with app-override redesign/preservation. Layouts and app visibilities match, but only 1 of 4 custom-app overrides match. The Leads/Accounts profile includes broad Sales Campaign and Sales Development Support Request grants; confirm both those grants and the required app behavior. |
| 4 | `Mobileum - Sales User` + `Mobileum - Sales User - STDM - APAC` | Lower-priority candidate: APAC has one active user and only 1 of Sales User's 8 custom-app overrides matches. Consider a shared baseline only if app actions/pages can be redesigned and APAC-specific record visibility is handled by roles/sharing. |
| Finance family | `Mobileum - Finance Full Access`, `Mobileum- Finance Full Access`, `Mobileum - Finance User Limited` | Client confirmed the two Full Access profiles are distinct and both should be consolidated. Assess all three for one shared minimum-access Finance baseline, retaining each source cohort's permission differences in separate deltas. Resolve the differing app overrides before retiring the source profiles. |

### Keep separate pending dedicated review

- **`Mobileum Salesops Team Profile`:** 213 enabled system permissions, including `ModifyAllData`, `ViewAllData`, `ManageUsers`, `ManageProfilesPermissionsets`, `ModifyMetadata`, `AuthorApex`, and broad object-level View All/Modify All. It also has active validation, flow, and Apex profile-name dependencies. Treat it as privileged; do not distribute its grants through an ordinary departmental Permission Set.
- **`Quote Creation Team Member`:** 161 enabled system permissions, including `ManageUsers`, `ManageProfilesPermissionsets`, `ModifyMetadata`, `AuthorApex`, `DataExport`, and transfer permissions. Nine active users are assigned. Review its business need and each privileged grant before considering consolidation; a quote-specific set alone would not preserve this profile's broader system access safely.
- **`Mobileum - Super Sales User`:** Two active users; it includes `ModifyMetadata`, `TransferAnyEntity`, and `TransferAnyLead`, plus many object-level View All/Modify All grants. Keep it as a separately governed elevated-sales persona unless those permissions are proven unnecessary and removed from the approved design.
- **`Hubspot`:** One active integration user. `TaskTriggerHandler` checks this profile name directly. Keep the integration persona isolated until the code dependency is replaced with a reviewed permission/custom-permission check and the integration is tested.
- **`Mobileum Read Only` and `Read Only1`:** Do not group based on their names. Their object grants are materially different, and both contain write or View All/Modify All access. `Mobileum Read Only` includes create/edit/delete on some objects; `Read Only1` includes Modify All on approval-related objects and edit access elsewhere. Review whether these grants are intended before calling either profile read-only.

## Comparison evidence

All 16 profile XML definitions were found locally. Each declares the Salesforce user license and is a custom profile, so license type alone does not block these comparisons. Identical license does **not** establish that profiles are safe to merge.

The counts below compare exact positive permission entries from the profile XML. Field permission counts include both read and edit flags; a matching count does not mean matching field access.

| Pair | Enabled system grants | Object permission entries | Field permission entries | Assessment |
|---|---:|---:|---:|---|
| Sales User / Sales Head | 47 common; 4 only on Sales User | 26 exact matches; 2 unique to each | 753 exact matches; 56 entries differ on each side | Closest practical candidate, but Sales User has extra elevated custom-object access. |
| Sales User / STDM APAC | 41 common; 10 only on Sales User; 1 only on APAC | 19 exact matches; 9 unique to Sales User; 4 unique to APAC | 753 exact matches; 56 entries differ on each side | Possible one-user profile retirement only after APAC-specific behavior is checked. |
| Product Management / Product Management User | 45 common; 2 only on User | 14 exact matches; 3 unique to Product Management; 11 unique to User | 787 exact matches; 22 entries differ on each side | Candidate with meaningful job-specific object deltas. |
| Marketing User / Leads, Accounts and Opportunity Creation | 43 common; 6 only on Marketing User; 1 only on Leads profile | 18 exact matches; 1 unique to Marketing User; 3 unique to Leads profile | 781 exact matches; 28 entries differ on each side | Candidate after explicit review of broad campaign/support-request grants. |
| Finance Full Access (spaced) / Finance Full Access (unspaced) | 41 common; 5 only on unspaced profile | 8 exact matches; 1 unique to spaced; 17 unique to unspaced | 661 exact matches; 148 entries differ on each side | Distinct profiles per client; retain separate source cohorts and preserve their access differences in any shared-baseline design. |
| Mobileum Read Only / Read Only1 | 34 common; 9 only on Mobileum Read Only | 3 exact matches; 32 unique to Mobileum Read Only; 5 unique to Read Only1 | 760 exact matches; 49 entries differ on each side | Do not consolidate as read-only profiles without permission-owner review. |

Examples of material object differences: Sales User has View All/Modify All on `Sales_Campaign__c` and full access to `Technical_Service_Request__c`; Sales Head instead has create/edit/read on `Item_Request__c` and `Purchase_Request__c`. The Product Management User profile has View All/Modify All on `Opportunity_Dynamic_Approvals__c` and `Related_Approver__c`. The Leads/Accounts marketing profile has broad access to `Sales_Campaign__c` and `Sales_Development_Support_Request__c`.

The org audit CSV adds profile UI configuration that is absent from the local Profile XML files: every in-scope profile has 202 layout mappings and 30 app visibilities. The candidate pairs have these exact mapping overlaps: Sales User/Sales Head share all 202 layouts; Product Management profiles share 201; Sales User/STDM APAC share 201; both Finance Full Access variants share 197; Marketing profiles and the two Read Only profiles share all 202. All these pairs share all 30 app visibilities. App-specific profile action/page overrides are less consistent: Sales User/Sales Head match 8/8; Product Management match 3/6; Marketing match 1/4; Sales User/STDM APAC match 1/8; Finance Full Access variants match 7 of the unspaced profile's 9 (the spaced profile has 38); Read Only profiles match 3/3. These overrides are profile-level UI behavior; a Permission Set does not preserve a different profile-specific override. Preserve or intentionally redesign them before retiring a profile.

## Current user assignments

Read-only SOQL against `MobiliumStaging` on 2026-10-15 returned these profile-assignment counts. These are user counts, not department counts.

| Profile | Active | Inactive |
|---|---:|---:|
| Hubspot | 1 | 0 |
| Leads, Accounts and Opportunity Creation Marketing Team | 8 | 10 |
| Mobileum - Finance Full Access | 1 | 1 |
| Mobileum- Finance Full Access | 29 | 20 |
| Mobileum - Finance User Limited | 2 | 1 |
| Mobileum - Marketing User | 3 | 4 |
| Mobileum - Product Management | 1 | 1 |
| Mobileum - Product Management User | 6 | 14 |
| Mobileum - Sales Head | 20 | 10 |
| Mobileum - Sales User | 163 | 140 |
| Mobileum - Sales User - STDM - APAC | 1 | 0 |
| Mobileum - Super Sales User | 2 | 0 |
| Mobileum Read Only | 2 | 11 |
| Mobileum Salesops Team Profile | 3 | 0 |
| Quote Creation Team Member | 9 | 0 |
| Read Only1 | 9 | 102 |
| **Total** | **260** | **314** |

The partner matrix assigns `Mobileum - Sales User` to many departments, but the supplied mapping does not identify which individual users belong to each department. The access-matrix workbook repeats the profile's total active-user count on each department row; it is not a user-to-department mapping. Get that mapping before creating departmental Permission Set assignments. The partner matrix also names `System Administrator`, which is outside this 16-profile scope; retain it as a separately governed privileged profile.

The staging workbook also shows existing direct Permission Set and Permission Set Group assignments for these users. For example, 60 of the 163 active Sales User users have a group assignment, while 15 of 20 active Sales Head users do. These assignments must be preserved and reviewed as part of effective-access testing; the workbook explicitly does not calculate users' total effective access.

## Dependencies and limits

The org profile-name audit found profile-dependent behavior for in-scope profiles: an active Project validation rule for Sales User; active Technical Service Request validation rules and flow/Apex logic for Salesops; a Finance flow exclusion for `Mobileum- Finance Full Access`; a Hubspot Apex check; and Quote Creation Team Member checks in approval flow/Apex. Tests also query several of these profile names. Update and test these dependencies as part of any future consolidation.

This comparison reads profile grants, not each user's effective access. Permission Sets/Groups can add access; role hierarchy, sharing, territories, licenses, and business requirements also affect outcomes. Inactive assignments were included because some users may be reactivated. The Finance POC validation remains pending and has not established deployability. No org metadata or user assignments were changed.

## Recommended implementation order

1. Approve the low-access baseline and confirm whether `Minimum Access - Salesforce` can serve as the base.
2. Normalize profile-only layouts, record-type defaults, app overrides, and login controls, or retain the smallest number of profiles needed to preserve those controls.
3. Convert approved object, field, system, Apex/VF, tab, app, and record-type grants into narrowly scoped Permission Sets where Salesforce supports them; assemble persona bundles with Permission Set Groups.
4. Keep `ManageUsers`, `ManageProfilesPermissionsets`, `ModifyAllData`, `ViewAllData`, `AuthorApex`, `ModifyMetadata`, and broad object View All/Modify All grants in separately approved privileged sets, assigned only to confirmed users.
5. Replace profile-name checks in rules, flows, and Apex with permission/custom-permission-based business controls where appropriate; update tests and verify effective access for representative active users.
6. Reconcile all 260 active and 314 inactive users in the current 16-profile scope, plus existing Permission Set/Group assignments, before proposing retirement. No deployment or reassignment until the client approves the matrix and validation results.

## Sales User / Sales Head POC

A local-only draft for the strongest candidate pair is in [`sales-profile-poc/Sales_Profile_POC.md`](sales-profile-poc/Sales_Profile_POC.md). It contains one common baseline profile, three source-profile delta Permission Sets, one Project Name restriction Permission Set, two Permission Set Groups, and a UI parity inventory. It is not a complete deployable package: the source Profile XML omitted layout/app configuration, and a `Territory__c.Region` person-account default differs between the source profiles. The POC does not assign users or deploy metadata.
