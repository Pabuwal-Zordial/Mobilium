# Profile Consolidation Implementation Guide

## Purpose and status

This guide turns the 16-profile review into a staged implementation proposal. It is a local planning document; **no org metadata or user assignments have been changed or deployed**. The comparison is based on the `MobiliumStaging` snapshot from 15 October 2026. Refresh the org data before implementation.

The proposed end state is **six access-family baseline profiles plus the existing Hubspot profile (7 total)**, provided the client approves the access and profile-only behavior. The 16 source profiles all use the Salesforce user license. This is a candidate design, not approval to grant every current permission: common grants must also be approved. `System Administrator` and other profiles outside the 16-profile scope are excluded.

The estimate is **27 Permission Sets (PS)**: source-profile-specific access deltas, with system-permission deltas separated from object/field grants, plus one set for the active Project Name restriction. Up to **15 Permission Set Groups (PSG)** can bundle each source cohort's delta sets. This does not include additional Custom Permission sets that may be required after business owners define replacements for other profile-name checks.

## Proposed access families

All grant counts below are enabled system permission flags, object permission flags (CRUD/View All/Modify All/View All Fields), field read/edit flags, and visible record types in the retrieved Profile XML. Counts are flags, not Salesforce objects. The complete row-by-row comparison is in [`Profile_Consolidation_Delta_Matrix.csv`](Profile_Consolidation_Delta_Matrix.csv). The generator is [`build_profile_consolidation_delta_matrix.py`](../scripts/build_profile_consolidation_delta_matrix.py).

| Family and target baseline | Source profiles | Common grants | Profile-specific grants | Readiness |
|---|---|---:|---|---|
| Sales — `Sales_Base_Profile` | Mobileum - Sales User; Mobileum - Sales Head; Mobileum - Sales User - STDM - APAC | 945 | 133; 129; 16, respectively | Conditional. APAC has different app overrides; baseline and deltas must be generated for all three together if APAC joins. The current Sales POC compares only Sales User and Sales Head. |
| Product — `Product_Base_Profile` | Mobileum - Product Management; Mobileum - Product Management User | 974 | 46; 32 | Conditional. One layout and three app overrides differ; review approval-related access. |
| Marketing — `Marketing_Base_Profile` | Mobileum - Marketing User; Leads, Accounts and Opportunity Creation Marketing Team | 999 | 54; 22 | Conditional. App overrides differ; review campaign and support-request access. |
| Finance — `Finance_Base_Profile` | Mobileum - Finance User Limited; Mobileum- Finance Full Access; Mobileum - Finance Full Access | 807 | 211; 250; 60 | Client confirmed the two Full Access profiles are distinct and both should be consolidated. Keep them as separate source cohorts with separate permission deltas on the shared Finance baseline; do not collapse their identities. App overrides differ substantially and must be preserved or redesigned before retirement. |
| Read access — `Read_Access_Base_Profile` | Mobileum Read Only; Read Only1 | 768 | 126; 3 | Strongest additional UI candidate: both have 202 matching layouts, 30 matching app visibilities, and all 3 app overrides match. Review write and View All/Modify All grants; do not rely on either label. |
| Elevated — `Elevated_Access_Base_Profile` | Mobileum - Super Sales User; Mobileum Salesops Team Profile; Quote Creation Team Member | 1,125 | 59; 502; 171 | Hold for security approval. The intersection itself includes 67 system permissions. Keep this family isolated from ordinary business access; reconcile app overrides and profile-name dependencies. |
| Integration — retain `Hubspot` | Hubspot | Not consolidated | Retain current access pending integration review | Keep separate in this phase. Replace the Apex profile-name check and confirm integration login controls before considering a shared baseline. |

If all six families are approved and profile-only settings are reconciled, the 15 source profiles in those families become six baselines; Hubspot remains, for 7 profiles total. This would retire 9 source profile definitions after users and dependencies are migrated. Keep each baseline's access limited to the approved intersection; the intersection is not automatically authorized access.

## Permission Sets and contents

Each `*_Access_Delta` set contains only that cohort's grants beyond its family's common baseline. Each `*_System_Delta` set contains only that cohort's unique enabled system permissions. The exact object, field, system, and record-type entries are in the delta CSV. These are proposed API names and should be checked against org naming rules before metadata is created.

| Family | Proposed PS and purpose | Count |
|---|---|---:|
| Sales | `Sales_User_Access_Delta`, `Sales_User_System_Delta`; `Sales_Head_Access_Delta`, `Sales_Head_System_Delta`; `STDM_APAC_Access_Delta`, `STDM_APAC_System_Delta`; `Sales_Project_Name_Restriction` | 7 |
| Product | `Product_Management_Access_Delta`; `Product_Management_User_Access_Delta`, `Product_Management_User_System_Delta` | 3 |
| Marketing | `Marketing_User_Access_Delta`, `Marketing_User_System_Delta`; `Leads_Team_Access_Delta`, `Leads_Team_System_Delta` | 4 |
| Finance | `Finance_Limited_Access_Delta`, `Finance_Limited_System_Delta`; `Finance_Full_Unspaced_Access_Delta`, `Finance_Full_Unspaced_System_Delta`; `Finance_Full_Spaced_Access_Delta` | 5 |
| Read access | `Mobileum_Read_Only_Access_Delta`, `Mobileum_Read_Only_System_Delta`; `Read_Only1_Access_Delta` | 3 |
| Elevated | `Super_Sales_Access_Delta`; `Salesops_Access_Delta`, `Salesops_System_Delta`; `Quote_Access_Delta`, `Quote_System_Delta` | 5 |
| **Total** | Includes one Custom Permission set for the Project Name restriction | **27** |

The Project restriction set grants `Restrict_Project_Name_Edit` to the former Sales User cohort. The existing validation rule must be changed to check the Custom Permission and tested for both allowed and restricted users. Do not assign it to Sales Head or APAC users unless the business owner confirms they need the same restriction.

The 27 count excludes future Custom Permissions/PS for the Finance Flow exclusion, Salesops TSR bypasses, Hubspot integration behavior, and Quote/Salesops approval allowlists. Define each behavior with its owner first; do not copy broad old profile grants into a single catch-all set. The elevated family requires review of all high-impact system and object-level grants before retaining any delta.

## PSG and user assignment proposal

Create a PSG for each source cohort whose approved access requires multiple PS. Proposed PSGs are:

- Sales: `PSG_Sales_User`, `PSG_Sales_Head`, `PSG_STDM_APAC`.
- Product: `PSG_Product_Management_User` (Product Management itself has one delta set and can receive it directly).
- Marketing: `PSG_Marketing_User`, `PSG_Leads_Accounts_Marketing`.
- Finance: `PSG_Finance_Limited`, `PSG_Finance_Full_Unspaced` (the spaced Full Access cohort has one delta set and can receive it directly).
- Read access: `PSG_Mobileum_Read_Only` (Read Only1 has one delta set and can receive it directly).
- Elevated: `PSG_Salesops`, `PSG_Quote_Creation` (Super Sales has one delta set and can receive it directly).

That is **11 PSGs** plus direct assignment of the four single-set deltas. Creating PSGs for all 15 cohorts is also possible but adds groups without bundling multiple sets. Assign only the PSG (not both the PSG and its component sets) to avoid redundant administration.

The current profile assignments are provisional cohort selectors, not final approval. Read the fresh user roster and obtain the client-approved user-to-department/access mapping before assignment. The current snapshot shows:

| Current source profile/cohort | Active users | Inactive users | Proposed target PSG/direct set |
|---|---:|---:|---|
| Mobileum - Sales User | 163 | 140 | `PSG_Sales_User` |
| Mobileum - Sales Head | 20 | 10 | `PSG_Sales_Head` |
| Mobileum - Sales User - STDM - APAC | 1 | 0 | `PSG_STDM_APAC` |
| Mobileum - Product Management | 1 | 1 | `Product_Management_Access_Delta` directly |
| Mobileum - Product Management User | 6 | 14 | `PSG_Product_Management_User` |
| Mobileum - Marketing User | 3 | 4 | `PSG_Marketing_User` |
| Leads, Accounts and Opportunity Creation Marketing Team | 8 | 10 | `PSG_Leads_Accounts_Marketing` |
| Mobileum - Finance User Limited | 2 | 1 | `PSG_Finance_Limited` |
| Mobileum- Finance Full Access | 29 | 20 | `PSG_Finance_Full_Unspaced` |
| Mobileum - Finance Full Access | 1 | 1 | `Finance_Full_Spaced_Access_Delta` directly |
| Mobileum Read Only | 2 | 11 | `PSG_Mobileum_Read_Only` |
| Read Only1 | 9 | 102 | `Read_Only1_Access_Delta` directly |
| Mobileum - Super Sales User | 2 | 0 | `Super_Sales_Access_Delta` directly, after security approval |
| Mobileum Salesops Team Profile | 3 | 0 | `PSG_Salesops`, after security approval |
| Quote Creation Team Member | 9 | 0 | `PSG_Quote_Creation`, after security approval |
| Hubspot | 1 | 0 | Retain current profile pending integration review |
| **Total in scope** | **260** | **314** | Snapshot only; refresh before migration |

Do not assign delta PSGs to every user solely because of the source Profile.Name. The Sales User profile has 163 active users spread across departments, and the partner matrix does not identify each person's intended access. Obtain the named roster, reconcile it against existing PS/PSG assignments and the approved matrix, and mark exceptions explicitly. Initially migrate active approved users; track inactive users and define what happens if they are reactivated. A blank assignment worksheet is provided at [`Profile_Consolidation_User_Assignment_Template.csv`](Profile_Consolidation_User_Assignment_Template.csv).

The named, provisional active-user roster is in [`Profile_Consolidation_User_Assignment_Proposal.csv`](Profile_Consolidation_User_Assignment_Proposal.csv). It contains 260 active accounts from the workbook's 14 October 2026 read-only export, their current direct PS/PSG assignments, and the proposed target cohort. `Proposed PS included in PSG` lists the component Permission Sets to create and include in that user's proposed group; `Proposed Direct PS` lists sets assigned directly when no PSG is proposed. These mappings are draft cohort mappings and require approval. The role columns preserve each current role by default and flag missing role data for verification; they do not propose a role migration. See the separate [Role Consolidation Proposal](Role_Consolidation_Proposal.md) for role inventory findings and the safe review process. Refresh the source from the org and fill the department/approval columns before using it for a migration.

## Step-by-step implementation

### Recommended order for the first developer

1. Start with **Sales User + Sales Head** as a two-profile pilot: the existing local POC is the most mature, and their layout/app/action mappings match. Review its grant matrix and the Project Name restriction.
2. Assess **Mobileum Read Only + Read Only1** next: their audited UI mappings match, although the 126-grant delta needs careful review.
3. Implement the **Product** and **Marketing** pairs after owners approve their permission deltas and decide how to handle app/layout differences.
4. Handle the **three Finance cohorts** as one baseline-profile family. The client confirmed the two Full Access profiles are distinct but both should be consolidated; preserve their different access through separate cohort-specific deltas. Obtain approval for the differing app overrides and preserve or redesign those profile-only settings before retiring the source profiles.
5. Add **STDM APAC** to the Sales baseline only after regenerating the three-profile intersection and resolving its app-action differences. Do not reuse the two-profile Sales POC baseline for a three-profile merge.
6. Handle the **Elevated** family last, after security owners review its common 67 system permissions, each delta, and all profile-based bypass/approval logic.

This order is for implementation sequencing, not a decision that any source permission is required. The client may reject or reduce grants in any delta.

### 1. Confirm scope and access decisions

1. The client confirmed that `Mobileum - Finance Full Access` and `Mobileum- Finance Full Access` are different profiles and both should be consolidated. Keep their source cohorts and permission deltas distinct under `Finance_Base_Profile`; do not normalize or treat the profile labels as duplicates. Confirm the remaining profile labels and approve the app-override handling before implementation.
2. Confirm the partner workbook is the access baseline and obtain a named user-to-department/cohort roster, including exceptions, integration users, and inactive users likely to return.
3. Have access owners approve each common grant, each delta, and every View All/Modify All/system permission. Common means “present in every source profile in this family,” not “approved for everyone.”
4. Security owners separately approve the Elevated family. Do not add `ModifyAllData`, `ViewAllData`, `ManageUsers`, `ManageProfilesPermissionsets`, `ModifyMetadata`, `AuthorApex`, transfer, or broad object grants to ordinary PSGs.

### 2. Refresh the org snapshot and record assignments

Retrieve the current Profile, PermissionSet, PermissionSetGroup, Flow, Apex, validation-rule, app, and layout metadata from `MobiliumStaging`. Export active and inactive user assignment details and all existing direct PS/PSG assignments. The earlier counts in this guide are from 15 October 2026 and may have changed.

Example read-only SOQL for the cohort roster:

```sql
SELECT Id, Name, Username, IsActive, Profile.Name, UserRole.Name, UserType
FROM User
WHERE Profile.Name IN (
  'Hubspot',
  'Leads, Accounts and Opportunity Creation Marketing Team',
  'Mobileum - Finance Full Access',
  'Mobileum- Finance Full Access',
  'Mobileum - Finance User Limited',
  'Mobileum - Marketing User',
  'Mobileum - Product Management',
  'Mobileum - Product Management User',
  'Mobileum - Sales Head',
  'Mobileum - Sales User',
  'Mobileum - Sales User - STDM - APAC',
  'Mobileum - Super Sales User',
  'Mobileum Read Only',
  'Mobileum Salesops Team Profile',
  'Quote Creation Team Member',
  'Read Only1'
)
ORDER BY Profile.Name, IsActive DESC, Username
```

Export PS/PSG assignments for those user IDs as a separate query and retain them in the assignment worksheet. Existing permission assignments may add access beyond Profile XML; compare effective access before and after.

### 3. Resolve settings and code dependencies

Before retiring a profile, reconcile page layouts, app visibility/action overrides, record-type defaults, login hours/IP ranges, and any other profile-only behavior. Permission Sets do not replace all these settings. Where settings differ, either standardize the experience with the business owner or retain an additional profile.

Refactor profile-name checks with explicit business permissions where appropriate. The org audit found a Sales User Project validation rule, Salesops validation/Flow/Apex behavior, Finance Flow behavior, Hubspot Apex logic, and Quote/Salesops approval checks; it also found profile-name references in tests. Update and test each behavior. Keep unrelated System Administrator checks outside this migration.

### 4. Build metadata in an isolated branch

1. Create six proposed baseline profiles with the approved common grants and Salesforce user license. Build profile-only settings from the approved UI mapping.
2. Create only approved delta PS from the matrix. Keep system permissions in the separate system sets listed above. Remove grants the owner does not approve; do not preserve an obsolete grant just because it exists today.
3. Create the 11 PSGs and include only the PS shown for that cohort. Assign one direct PS for the four single-set cohorts if PSGs are not needed.
4. Add approved Custom Permissions for converted behavior checks. Keep POC files isolated until reviewed; do not add them to the deployment manifest by default.
5. Rebuild/inspect the exact matrix after any approval changes. A pairwise POC baseline must not be reused for a larger family without recalculating the multi-profile intersection. In particular, the current Sales POC baseline covers Sales User and Sales Head only; adding APAC changes the baseline and deltas.

### 5. Validate access and business behavior in staging

For each cohort, compare a representative user's current and proposed effective permissions, including existing PS/PSG assignments, role hierarchy, sharing, and license. Test create/read/edit/delete, sensitive fields, View All/Modify All, record types, application behavior, layouts, and the profile-dependent rules/flows/approvals. Test one user who should receive each Custom Permission and one who should not.

Run Apex tests relevant to changed dependencies and a Salesforce CLI check-only deployment validation after the metadata is reviewed. Example, once a migration manifest has been approved:

```sh
sf project deploy validate --manifest path/to/reviewed-manifest.xml \
  --target-org MobiliumStaging --test-level RunLocalTests
```

A successful check-only validates deployability; it does not establish that the business access is correct. Record test users, expected results, actual results, and client sign-off.

### 6. Pilot, migrate, and retire safely

1. Pilot one approved cohort in staging. Use the Sales User/Sales Head POC as the first code/design reference; do not extend it to APAC without regenerating the three-profile baseline.
2. After staging approval and change approval, deploy baseline profiles, PS, PSGs, and behavior refactors first. Do not include destructive profile deletion in the same initial release.
3. In a scheduled migration, assign each user's approved PSG/direct PS and change their profile to the target baseline. Verify login and critical workflows immediately. Preserve unrelated existing PS/PSG assignments unless an explicit access review approves changes.
4. Keep a rollback roster with old profile, new profile, and added PS/PSG. If access or workflow checks fail, restore the prior profile and remove only the new migration assignments.
5. After active users are migrated, verify inactive users, integrations, queues/groups, approvals, and all code references. Retire an old profile only after it has no assigned users and no live dependency; delete it in a later reviewed release.

## Important boundaries

- This is an access consolidation proposal, not a role or sharing redesign. Do not change roles, sharing rules, territories, or record access as a side effect.
- The CSV describes profile grant intersections/differences and retained Hubspot grants. It does not compute a user's full effective access and does not contain user names or assignments.
- Layouts, app overrides, login/IP controls, profile-name dependencies, permission license constraints, existing PS/PSG assignments, and client approval remain separate work items.
- No deployment, permission assignment, or profile retirement has been performed.
