# Main Org Role Dependency Audit and Merge Candidates

## Scope and status

This is a read-only analysis of the local MobiliumStaging snapshot retrieved 2026-10-16. The Salesforce CLI currently has no usable authenticated org; local auth records fail with a macOS Keychain authorization error. This is not a fresh live-org extraction. It covers the role inventory and metadata files present in this workspace. No org data or metadata was changed.

Available local components: 120 role records; 43 public-group metadata files; 10 queue metadata files; 161 sharing-rule metadata files; 42 approval-process metadata files. No Reports/Report Folder metadata or Territory metadata was found in the local dependency package.

## What the local scan found

- Sharing rules contain direct role references. These can change behavior when a referenced role is renamed, deleted, reparented, or users move between roles.
- Sharing rules and approval processes also reference public groups and queues. The local files do not provide reliable live membership for public groups or queue membership through roles. Query GroupMember, Group, QueueSobject, and relevant user assignments in the org to determine role membership.
- Approval processes include hierarchy-based approver steps. Test these if reporting or role relationships change.
- Report folder access could not be assessed because Report/Folder metadata and live folder shares were not retrieved. Retrieve FolderShare and folder membership before retiring roles.
- This scan cannot rule out role references in Apex, Flows, formulas, custom metadata/settings, managed packages, or configuration outside the retrieved scope.

### Direct role references in retrieved sharing rules

- Marketing on Account: source uses System_Administrator (Role + internal subordinates).
- Hubspot on Lead: target uses Hubspot (Role).
- Hubspot on Lead: source uses System_Administrator (Role + internal subordinates).
- Hubspot_Queue on Lead: target uses Hubspot (Role).
- Marketing on Lead: source uses System_Administrator (Role).
- Acronym on Customer_Acronym__c: target uses System_Administrator (Role + internal subordinates).

### Other retrieved dependencies

- 6 sharing-rule references point to public groups. Their role membership is not established by this metadata.
- 30 references point to queues in sharing rules or approvals. Validate queue membership and supported objects live.
- Hierarchy-based approver steps appear in 4 approval processes: pse__Expense_Report__c.FFX_PSA_Manager_Approves_ER.approvalProcess-meta, pse__Expense_Report__c.FFX_PSA_PM_Approves_Expense_Report.approvalProcess-meta, pse__Timecard_Header__c.FFX_PSA_TC_PM_to_LM_of_Project_Global.approvalProcess-meta, pse__Timecard_Header__c.PSA_Timecard_Auto_Approve.approvalProcess-meta. The exact approver field and runtime resolution must be verified.
- No report folder dependency result is available; missing local files do not prove no dependency exists.

## First-pass role consolidation candidates

A mechanical comparison grouped only leaf roles that share the same parent and the same Case, Contact, and Opportunity role-level access. It found 27 candidate sibling groups containing 61 roles. If each group were reduced to one existing role, the theoretical maximum would be 34 fewer role records. This is not an approved reduction estimate: business purpose, region boundary, sharing references, group/queue membership, reporting, approvals, and folder access still need review.

Within these candidates, 20 individual role records have no active or inactive users. Four candidate groups contain only such roles. Investigate these first, then check dependencies before retiring any role.

Priority groups for business review:
- Parent Vice_President_East_Europe_Risk: Account Executive East Europe Risk (1 active/0 inactive); Commercial Specialist East Europe Risk (0 active/0 inactive); Specialist East Europe Risk (1 active/2 inactive). Same parent/access signature; 2 active and 2 inactive users total.
- Parent Vice_President_East_Europe_Roaming_and_Security: Account Executive East Europe Roaming and Security (0 active/0 inactive); Commercial Specialist East Europe Roaming and Security (0 active/0 inactive); Specialist East Europe Roaming and Security (1 active/0 inactive). Same parent/access signature; 1 active and 0 inactive users total.
- Parent Vice_President_East_Europe_Testing: Account Executive East Europe Testing (0 active/1 inactive); Commercial Specialist East Europe Testing (0 active/0 inactive); Specialist East Europe Testing (0 active/2 inactive). Same parent/access signature; 0 active and 3 inactive users total.
- Parent Vice_President_Middle_East_Testing: Account Executive Middle East Testing (0 active/0 inactive); Commercial Specialist Middle East Testing (0 active/0 inactive); Specialist Middle East Testing (1 active/0 inactive). Same parent/access signature; 1 active and 0 inactive users total.
- Parent Vice_President_West_Europe_for_Risk: Account Executive West Europe Risk (2 active/0 inactive); Commercial Specialist West Europe Risk (3 active/1 inactive); Specialist West Europe Risk (2 active/0 inactive). Same parent/access signature; 7 active and 1 inactive users total.
- Parent Vice_President_West_Europe_for_Roaming_and_Security: Account Executive West Europe Roaming and Security (0 active/1 inactive); Commercial Specialist West Europe Roaming and Security (0 active/0 inactive); Specialist West Europe Roaming and Security (2 active/2 inactive). Same parent/access signature; 2 active and 3 inactive users total.
- Parent Vice_President_West_Europe_for_Testing: Account Executive West Europe Testing (1 active/0 inactive); Commercial Specialist West Europe Testing (0 active/4 inactive); Specialist West Europe Testing (2 active/2 inactive). Same parent/access signature; 3 active and 6 inactive users total.
- Parent Vice_President_East_Europe_Engagement_and_Experience: Account Executive East Europe Engagement and Experience (0 active/0 inactive); Commercial Specialist East Europe Engagement and Experience (0 active/0 inactive). Same parent/access signature; 0 active and 0 inactive users total.
- Parent Vice_President_NASA_Engagement_and_Experience: Account Executive NASA Engagement and Experience (0 active/0 inactive); Commercial Specialist NASA Engagement and Experience (0 active/0 inactive). Same parent/access signature; 0 active and 0 inactive users total.
- Parent Vice_President_North_America_Engagement_and_Experience: Account Executive North America Engagement and Experience (0 active/0 inactive); Commercial Specialist North America Engagement and Experience (0 active/0 inactive). Same parent/access signature; 0 active and 0 inactive users total.
- Parent Vice_President_West_Europe_Engagement_and_Experience: Account Executive West Europe Engagement and Experience (0 active/0 inactive); Commercial Specialist West Europe Engagement and Experience (0 active/0 inactive). Same parent/access signature; 0 active and 0 inactive users total.

Other two-role sibling groups are listed in Main_Org_Role_Merge_Candidate_Groups.csv. Account Executive, Specialist, and Commercial Specialist labels may represent different business functions even where role-level access matches.

### Safe merge test

Consider consolidating only leaf sibling roles where all are true: same approved business purpose; same parent and regional visibility boundary; same role-level access; no distinct forecast, approval, or reporting need; no role-specific sharing or folder grant; and all user owners approve reassignment. Keep separate regional branches where managers must not see other regions. Do not combine Hubspot and Mobileum Salesops Team Role: they are separate roots with distinct purposes.

## Required live-org extraction before final recommendations

1. Restore Salesforce CLI authentication for the approved org and confirm its name and ID. Refresh roles and active/inactive user assignments.
2. Export GroupMember rows, including nested role/subordinate-role group membership; export queue membership and QueueSobject configuration.
3. Retrieve all SharingRules, Report/Folder metadata and folder shares, territory models/memberships, approval processes, Apex, Flows, and configuration that could refer to role IDs or names.
4. Build a role-to-dependency map and review each candidate with its business owner. Re-run the scan after changes in a sandbox.
5. Validate effective record access with representative users before approved production retirement.

## Files

- Candidate groups: [Main_Org_Role_Merge_Candidate_Groups.csv](Main_Org_Role_Merge_Candidate_Groups.csv)
- Parsed references: [Main_Org_Role_Dependency_References.csv](Main_Org_Role_Dependency_References.csv)
- Role inventory: [Main_Org_Role_Inventory.csv](Main_Org_Role_Inventory.csv)
- Census: [Main_Org_Profile_Role_Census.md](Main_Org_Profile_Role_Census.md)
