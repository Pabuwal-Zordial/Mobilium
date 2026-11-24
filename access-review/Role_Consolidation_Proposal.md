# Role Consolidation Proposal

## Purpose and status

This is a read-only proposal based on the local Salesforce DX role metadata and the `MobiliumStaging_Access_Matrix.xlsx` user snapshot (14 October 2026). No role or user assignment was changed. Refresh the org data before making decisions.

## What the repository shows

- There are **120 role metadata files** in `force-app/main/default/roles/`, including three root roles: `System_Administrator`, `Hubspot`, and `Mobileum_Salesops_Team_Role`.
- The definitions describe a substantial sales hierarchy: global and regional management, then region/product-line Vice President, Account Executive, Specialist, and Commercial Specialist roles. Role names and `parentRole` encode reporting and access boundaries.
- Most sales roles have Opportunity access `Edit`, Contact access `Edit`, and Case access `None`. This repeated setting alone does **not** prove roles are equivalent: parent placement controls which records roll up to managers.
- The workbook contains 260 users in the 16-profile scope. **50 have no role value in the export; 210 have a role value.** The workbook is a snapshot and does not establish each user's approved manager or reporting line.
- Several roles share the same parent and role-level object access (for example, Account Executive, Specialist, and Commercial Specialist siblings under a product/region VP). These are candidates for review, not automatic merge recommendations.

## Recommendation

Do not collapse the role tree to one role per department, and do not change `UserRoleId` as part of the profile/Permission Set migration by default. Profiles and Permission Sets control what users can do; roles primarily affect which records they can see through the hierarchy. Treat role consolidation as a separate workstream with its own owner-approved reporting model.

Use a **minimum necessary hierarchy**:

1. Preserve root and executive/manager nodes that represent real reporting lines or ownership boundaries.
2. Retire empty or obsolete roles only after confirming they have no users, children, role-based sharing references, forecast/reporting dependencies, or automation references.
3. Review sibling leaf roles only when they share the same parent, business scope, manager, sharing behavior, and operational purpose. Consolidate only after the business owner accepts the resulting peer visibility and manager roll-up changes.
4. Keep distinct regional/product roles where they represent different record ownership or confidentiality boundaries. If the business wants fewer role nodes but still needs access segmentation, evaluate criteria-based sharing, public groups, territories, or teams separately; these mechanisms must be designed and tested, not assumed equivalent.
5. Keep integration and special-purpose roots (`Hubspot`, SalesOps, inactive-user role) separate until their ownership and automation usage are understood.

## Review and implementation steps

1. Refresh a complete active and inactive user export with `UserRoleId`, role name, parent role, profile, manager, department, and user status. Resolve the 50 missing role values before proposing user moves.
2. Export the full `UserRole` tree and calculate active/inactive user counts, child-role counts, and depth. Identify unused leaves and candidates with the same parent and business purpose.
3. Ask the client to approve the target reporting tree and provide the named user-to-manager/region/product mapping. A department label alone is insufficient.
4. Audit all dependencies before retiring a role: role-based sharing rules, public groups, sharing rules, queues, territory assignments, forecasts, approval routing, report/folder access, Apex/Flow references, and integrations.
5. For each proposed move, compare record visibility before/after using representative users and test owned records, parent/child access, manual shares, and executive roll-ups. Record a rollback mapping from old role to new role.
6. Pilot one low-risk branch in a sandbox, validate with business users, and only then stage production user reassignment and role retirement.

## Read-only SOQL for a fresh roster

```sql
SELECT Id, Name, Username, IsActive, Profile.Name, UserRoleId,
       UserRole.Name, UserRole.ParentRoleId, UserRole.ParentRole.Name,
       ManagerId, Manager.Name, Department
FROM User
WHERE Profile.Name IN (
  'Hubspot', 'Leads, Accounts and Opportunity Creation Marketing Team',
  'Mobileum - Finance Full Access', 'Mobileum - Finance User Limited',
  'Mobileum - Marketing User', 'Mobileum - Product Management',
  'Mobileum - Product Management User', 'Mobileum - Sales Head',
  'Mobileum - Sales User', 'Mobileum - Sales User - STDM - APAC',
  'Mobileum - Super Sales User', 'Mobileum Read Only',
  'Mobileum Salesops Team Profile', 'Mobileum- Finance Full Access',
  'Quote Creation Team Member', 'Read Only1'
)
ORDER BY UserRole.Name, Name
```

To inventory the role tree, query `UserRole` for `Id`, `Name`, and `ParentRoleId`; query active and inactive users separately so an apparently unused role is not retired based only on an active-user count.

## Roster update

The [user assignment proposal](Profile_Consolidation_User_Assignment_Proposal.csv) now has a default role decision per user: preserve the current role pending an approved role design, or hold the row for org verification when the source export has no role. This is not a final role mapping.
