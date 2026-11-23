# Three-Profile Consolidation POC

## Result

This local-only POC produces **one shared custom profile**, **three persona-specific Permission Sets**, and **zero Permission Set Groups**. The source profiles are Helpdesk, Manager, and Front Desk Profile. All three use the Salesforce user license. No current active or inactive users are assigned to these profiles, so there is no user assignment list yet.

| Source profile | POC target profile | Add this Permission Set to users moved from the source |
|---|---|---|
| Helpdesk | Shared_Access_Base_POC | Helpdesk_Access_Delta_POC |
| Manager | Shared_Access_Base_POC | Manager_Access_Delta_POC |
| Front Desk Profile | Shared_Access_Base_POC | Front_Desk_Access_Delta_POC |

Assign only the matching persona Permission Set to each user. Do not assign all three to one user unless that user's job requires the combined access and that access is approved. No PSG is needed while each persona maps to one Permission Set.

## What is in the shared profile

The shared profile contains **39 of the 40 positive system permissions present in all three source profiles**. `ViewRoles` is placed in each persona Permission Set because Salesforce validation requires it alongside dependent permissions such as `ManageCustomReportTypes` and `ViewSetup`. `EditTask` remains in the shared profile to satisfy `ListEmailSend` and is also copied into each persona PS to satisfy the `ConvertLeads` dependency. The profile has no object CRUD or FLS grant common to all three. It also keeps Helpdesk's 229 layout assignments as the provisional layout baseline; Helpdesk and Manager have 226 identical assignments and three different ones: `Account__c.Employee`, `Loan_Detail__c.helpdesk`, and `Student__c.(master)`. Front Desk Profile has no layout assignment entries in its retrieved metadata.

The profile also carries Front Desk Profile's recorded login-hours metadata: Thursday start `960` and end `1320` minutes after midnight (16:00–22:00). Helpdesk and Manager have no explicit `loginHours` element. This is a conservative provisional choice, but it could restrict all users of the shared profile and must be confirmed before any deployment.

Review the common system grants carefully before approval. They include `ApiEnabled`, `ApexRestServices`, and `OverrideForecasts`. `ViewRoles` is included in all three persona Permission Sets to satisfy Salesforce permission dependencies. `EditTask` remains in the profile and is duplicated into each persona Permission Set for the `ConvertLeads` dependency. A permission being common does not by itself establish business need.

The 39 system permissions retained in the draft profile are: `ActivitiesAccess`, `AddDirectMessageMembers`, `AllowUniversalSearch`, `AllowViewKnowledge`, `ApexRestServices`, `ApiEnabled`, `AssignTopics`, `ChatterEditOwnPost`, `ChatterFileLink`, `ChatterInternalUser`, `ChatterInviteExternalUsers`, `ChatterOwnGroups`, `ContentWorkspaces`, `CreateCustomizeFilters`, `CreateTopics`, `DistributeFromPersWksp`, `EditEvent`, `EditOppLineItemUnitPrice`, `EditTask`, `EditTopics`, `EmailMass`, `EmailSingle`, `EnableCommunityAppLauncher`, `EnableNotifications`, `FieldServiceAccess`, `LightningConsoleAllowedForUser`, `LightningExperienceUser`, `ListEmailSend`, `MassInlineEdit`, `OverrideForecasts`, `RemoveDirectMessageMembers`, `SelectFilesFromSalesforce`, `SendSitRequests`, `ShareFilesWithNetworks`, `ShowCompanyNameAsUserBadge`, `SubmitMacrosAllowed`, `TransactionalEmailSend`, `UseWebLink`, and `ViewHelpLink`.

## What is in the Permission Sets

| Permission Set | Profile deltas captured |
|---|---|
| Helpdesk_Access_Delta_POC | `CreateCustomizeReports`, `EditTask`, `ExportReport`, `RunReports`, `SubscribeToLightningReports`, `ViewRoles`; Account__c read/edit; Bank__c and Branch__c read; Loan__c and Loan_Detail__c create/read/edit; 76 field access entries; 12 app visibility grants; 7 record-type visibility grants; 17 tab settings. |
| Manager_Access_Delta_POC | `ConvertLeads`, `CreateCustomizeReports`, `EditTask`, `ExportReport`, `ImportPersonal`, `RunReports`, `SubscribeToLightningReports`, `ViewRoles`, `ViewSetup`, `ViewSetupAuditTrail`; source custom-object CRUD and 77 field access entries; 26 app visibility grants; 4 record-type visibility grants; 19 tab settings. Also includes the Convert Leads dependency grants: Account Create/Read/Edit, Contact Create/Read/Edit, and Lead Read/Edit. |
| Front_Desk_Access_Delta_POC | 7 system permissions: ConvertLeads, EditTask, ImportPersonal, ManageCustomReportTypes, ViewRoles, ViewSetup, and ViewSetupAuditTrail. Also includes the Convert Leads dependency grants: Account Create/Read/Edit, Contact Create/Read/Edit, and Lead Read/Edit. The source metadata had no object or field grants; these standard-object grants are an explicitly approved addition. |

No source profile has enabled Apex class or Visualforce page access in the retrieved metadata. No View All Records or Modify All Records object grants were found in the three source profiles.

## Important limitations and review items

- Permission Sets can grant app, tab, object, field, Apex/VF, and record-type access, but they do not assign page layouts. The 3 Helpdesk/Manager layout differences must be resolved by the business owner; this POC selects Helpdesk's mapping provisionally. Default app and default record-type choices also need review because a Permission Set does not reproduce those profile defaults.
- Front Desk Profile's login-hours restriction cannot be expressed in a Permission Set. Confirm the intended schedule for users from all three source profiles before approving a shared profile.
- Profiles do not control role hierarchy or record sharing. No roles, sharing rules, or user assignments are changed by this POC.
- The comparison covers retrieved profile metadata. Effective access may also come from existing Permission Sets, PSGs, licenses, sharing, and automation. Review those before a production change.
- The 40 common system grants are preserved across the model (39 in the profile plus `ViewRoles` in each PS; `EditTask` is duplicated in each PS for dependency validation), not certified as least privilege. Security/business owners must approve or remove unnecessary grants.
- The complete dependency scan is in `Profile_Name_Reference_Audit.md`; the end-to-end no-deploy procedure is in `Helpdesk_Manager_Front_Desk_POC_Runbook.md`.

## Deployment and assignment status

The initial check-only dry run (job `0AfdL00000hOzw2SAC`) reported that `ConvertLeads` in the Manager and Front Desk sets requires Account and Contact Create/Read/Edit plus Lead Read/Edit in those same Permission Sets. These grants were absent from their source profile metadata. The user approved adding this required CRUD on 2026-10-16. The draft adds those eight CRUD grants in each of the Manager and Front Desk Permission Sets; Delete, View All, and Modify All remain false. Check-only validation job `0AfdL00000hP8ODSA0` accepted all four metadata components, then failed in `RunLocalTests`: 33 tests/classes failed to compile because `CTPersonController.getCohabitants(Set<Id>, Set<Id>)` is missing or has an incompatible signature. There were no metadata validation errors. With the user's deployment authorization, deployment job `0AfdL00000hP8T3SAK` succeeded to Shivam dev and created the shared profile and all three Permission Sets. Tests were skipped because of the existing Apex compile issue.

The four POC metadata components are deployed in Shivam dev. On 2026-10-16, the active Helpdesk user Jack Sparrow (`jackshivam@gmail.com`) was moved to `Shared_Access_Base_POC` and assigned `Helpdesk_Access_Delta_POC`. The user had no existing assignment to that POC Permission Set; unrelated existing assignments were retained. A follow-up query found no users remaining on Helpdesk, Manager, or Front Desk Profile. No Permission Set Groups exist in this POC. Before promoting or extending this POC: approve the common system permissions, login hours, layout/default choices, and record-level access; fix the org Apex compile blocker and rerun tests; and validate with representative users.
