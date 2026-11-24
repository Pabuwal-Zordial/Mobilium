# Helpdesk, Manager, and Front Desk Profile POC Runbook

## POC objective and boundary

Evaluate this access model in the isolated `Shivam dev` project: replace three Salesforce-license profiles (`Helpdesk`, `Manager`, `Front Desk Profile`) with one shared profile plus persona-specific Permission Sets. Current POC artifacts are local drafts. **Do not deploy, assign Permission Sets, reassign users, or delete profiles as part of this runbook.** Role reduction is a separate activity; this POC leaves roles and record-sharing configuration unchanged.

## Current proposed model

- 1 profile: `Shared_Access_Base_POC`, holding 39 of the 40 positive system permissions common to all three source profiles. `ViewRoles` is in each persona Permission Set because Salesforce requires it alongside dependent permissions: `ManageCustomReportTypes` and `ViewSetup`. `EditTask` remains in the profile for `ListEmailSend` and is copied into each PS for `ConvertLeads`.
- 3 Permission Sets: `Helpdesk_Access_Delta_POC`, `Manager_Access_Delta_POC`, `Front_Desk_Access_Delta_POC`.
- 0 Permission Set Groups: each user maps to one persona Permission Set, so a group adds no value for this POC.
- User mapping rule: source Helpdesk → base profile + Helpdesk PS; source Manager → base + Manager PS; source Front Desk → base + Front Desk PS. Assign only the applicable PS. The org query found zero users on the three source profiles, so no individual assignment list can currently be produced.

## Step-by-step execution

### 1. Confirm the environment and inputs

Use the Salesforce CLI alias `shivamorg` (org ID ends `z6zjEAA`) and verify it is `Shivam dev` before any org-facing command. The source profiles all have the Salesforce user license. Keep this POC separate from the Mobileum/Mobilium project. Do not use a deploy command.

### 2. Review the source access and dependency evidence

Read `Helpdesk_Manager_Front_Desk_Profile_Comparison.md` and its CSV delta matrix, then `Profile_Name_Reference_Audit.md`. Review all system permissions, object CRUD, FLS, Apex/VF/Flow access, apps, tabs, record types, layouts, and profile-name references. The source profiles have no enabled Apex or VF grants and no Flow access entries. No View All Records or Modify All Records object grants were found. Profile XML has no additional custom metadata/custom permission access entries; review object CRUD for any custom-setting objects.

### 3. Review the generated access model

Review the shared profile and three Permission Set XML files against the source profile XMLs. Confirm each PS contains only the positive grants for its persona that are not in the shared profile, plus `ViewRoles` and the dependency copy of `EditTask`. Do not union the three object/FLS permissions into the profile. The detailed PS inventory and names are in `Consolidated_Profile_POC_Implementation_Notes.md`.

### 4. Resolve required security and UI decisions

Obtain owner decisions before treating the model as deployable:

- Approve or remove the 40 common system permissions. They include `ApiEnabled`, `ApexRestServices`, and `OverrideForecasts`.
- Confirm Front Desk's profile `loginHours` values (Thursday 960–1320 minutes) and whether the shared profile may apply that restriction to all three personas. Login-hour restrictions cannot be moved into a Permission Set.
- Approve the Helpdesk layout assignments as the provisional base. Helpdesk and Manager agree on 226 of 229 assignments and differ on `Account__c.Employee`, `Loan_Detail__c.helpdesk`, and `Student__c.(master)`. Front Desk returned no layout assignments. Page layouts remain profile-controlled.
- Resolve default app and default record-type choices. Persona Permission Sets can grant visibility, but do not preserve all profile default choices.
- Confirm whether the Helpdesk record type named `Loan_Detail__c.helpdesk` remains; it is not a profile-name dependency.

### 5. Keep role and sharing work separate

The org has 25 role metadata entries and the read-only user query returned one active user assigned to role `Director`. None of the three target profiles has assigned users. Do not merge or delete roles as part of this access POC. Roles control hierarchy-based record access; Permission Sets do not replace that function. A separate role-reduction assessment must map active/inactive users, parent-child role relationships, role-based sharing rules, public groups, queues, ownership, territories, and approval routing before proposing role changes.

### 6. Run POC checks without production changes

Because no existing users represent the three profiles, use a disposable test org or obtain explicit approval to create isolated test users in `Shivam dev`. Give each persona test user the shared profile plus exactly one matching PS. Compare access against the source behavior for:

- Object CRUD and FLS, including positive and negative cases for each persona's custom objects and sensitive fields.
- System permissions, especially setup, API, report/export, and administrative grants.
- Apex/VF/Flow execution, validation rules, approval processes, and UI components.
- App/tab availability, record types/defaults, layouts, login hours, and expected user workflows.
- Record-level visibility with the user's existing role and sharing model; do not use a Permission Set union as a substitute for sharing review.

Dry-run 1 (job `0AfdL00000hP113SAC`) found that `ManageCustomReportTypes` and `ViewSetup` required `ViewRoles` in each Permission Set. Dry-run 2 (job `0AfdL00000hP7f3SAC`) confirmed that fix and found `ConvertLeads` also requires `EditTask` in the same Permission Set. Dry-run 3 (job `0AfdL00000hOxW2SAK`) reported both that dependency and that the profile's `ListEmailSend` requires `EditTask` in the profile. The draft keeps `EditTask` in the profile and duplicates it in each PS. Dry-run 4 (job `0AfdL00000hOzw2SAC`) cleared the profile/EditTask error but found `ConvertLeads` requires Account and Contact Create/Read/Edit plus Lead Read/Edit in both Manager and Front Desk Permission Sets. The user approved adding these grants on 2026-10-16. The drafts contain that minimum CRUD; Delete, View All, and Modify All remain false. Dry-run 5 (job `0AfdL00000hP8ODSA0`) accepted all four metadata components, then failed during `RunLocalTests` with 33 failures caused by the org Apex compile error `CTPersonController.getCohabitants(Set<Id>, Set<Id>)` missing or having an incompatible signature. There were no profile/Permission Set metadata errors. At the user's request, deployment job `0AfdL00000hP8T3SAK` then succeeded to Shivam dev with tests skipped. The shared profile and three Permission Sets now exist in that org. No users were reassigned and no Permission Sets were assigned. Fix the Apex issue and run tests before using this POC with users or promoting it.

### 7. Record results and stop for review

Document each test user's persona, expected access, actual result, defects, and the owner who approved each exception. Update the PS/profile artifacts and delta matrix. Stop before deployment or assignments; present the validated draft and unresolved decisions for review.

## Rollback and eventual implementation notes

For a later approved pilot, retain old profiles and a user-to-original-profile/PS assignment export. A rollback would restore each pilot user to the original profile and remove the assigned delta PS, then retest. Do not retire an old profile until its users are migrated, dependencies and external identity/connected-app use are checked, and a rollback window has passed. Production deployment, user reassignment, and profile deletion are explicitly outside this POC run.
