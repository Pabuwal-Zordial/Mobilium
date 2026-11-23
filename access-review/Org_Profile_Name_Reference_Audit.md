# Mobileum Org Profile Name Reference Audit

**Environment:** `MobiliumStaging`  
**Snapshot:** 15 October 2026  
**Method:** Read-only Metadata API retrieve (project API v67.0 via org API v68.0) and SOQL inventory of `Profile.Name` and user license. No deployment or org changes were made.

## Scope

The org returned **105 Profile records**. The retrieve included **6,083 files across 30 requested metadata types**. It covered the requested Apex, Visualforce, Aura, LWC, Flow, validation, layout, approval, community, connected-app, group/queue, sharing, and restriction-rule areas, plus custom objects/formulas, custom metadata, workflows, labels, Profile definitions, and Permission Sets. Matching used actual Profile labels and checked profile-specific metadata fields and logic contexts, avoiding generic word matches such as “Admin” in unrelated descriptions.

## Confirmed profile-name dependencies

### Validation rules

Found **11 rules across 6 objects**, with 18 rule/profile references. One rule is inactive. These formulas use `$Profile.Name`; renaming or retiring a referenced profile can change behavior.

| Validation rule | Profile name | Status |
|---|---|---|
| `Billing_Details__c.Prevent_Changes_if_Oppty_Closed_Won` | System Administrator | Active |
| `Project__c.Prevent_Changes_if_Oppty_Closed_Won` | System Administrator | Active |
| `Project__c.Sales_rep_cannot_edit_project_Name` | Mobileum - Sales User | Active |
| `Proposal_Code__c.Restricted_Non_Master_Code` | Mobileum- Finance Full Access | Inactive |
| `Proposal_Code__c.Restricted_Non_Master_Code` | Mobileum - Finance User Limited | Inactive |
| `Proposal_Code__c.Restricted_Non_Master_Code` | System Administrator | Inactive |
| `Purchase_Order__c.Prevent_Changes_if_Oppty_Closed_Won` | System Administrator | Active |
| `Schedule__c.Prevent_Changes_if_Oppty_Closed_Won` | System Administrator | Active |
| `Technical_Service_Request__c.Can_not_change_status_to_Cancelled` | System Administrator | Active |
| `Technical_Service_Request__c.Can_not_change_status_to_Cancelled` | Mobileum Salesops Team Profile | Active |
| `Technical_Service_Request__c.Can_not_change_status_to_Implemented` | System Administrator | Active |
| `Technical_Service_Request__c.Can_not_change_status_to_Implemented` | Mobileum Salesops Team Profile | Active |
| `Technical_Service_Request__c.Cannot_set_to_New_from_Other` | System Administrator | Active |
| `Technical_Service_Request__c.Cannot_set_to_New_from_Other` | Mobileum Salesops Team Profile | Active |
| `Technical_Service_Request__c.TSR_is_not_editable_Cancelled` | System Administrator | Active |
| `Technical_Service_Request__c.TSR_is_not_editable_Cancelled` | Mobileum Salesops Team Profile | Active |
| `Technical_Service_Request__c.TSR_is_not_editable_implemented` | System Administrator | Active |
| `Technical_Service_Request__c.TSR_is_not_editable_implemented` | Mobileum Salesops Team Profile | Active |

### Flows

Found **6 Flow/profile pairs** using a literal profile name:

| Flow | Profile name | Occurrences |
|---|---|---:|
| `DIAB_MB_Project_Dependency_tracking` | Mobileum- Finance Full Access | 1 |
| `PPO_New_Process_Record_Flow` | System Administrator | 2 |
| `PPO_New_Process_Record_Flow` | System Admin Certinia | 2 |
| `PPO_New_Process_Record_Flow` | Quote Creation Team Member | 2 |
| `PPO_New_Process_Record_Flow` | Mobileum System Admin | 2 |
| `PPO_New_Process_Record_Flow` | Mobileum Salesops Team Profile | 2 |

`PPO_New_Process_Record_Flow` checks five profile names in two branches. `DIAB_MB_Project_Dependency_tracking` excludes `Mobileum- Finance Full Access`. `DIAB_MB_Minimum_Hrs_Last_Week_Validation` reads a related user’s `ProfileId`, but does not hardcode a profile name.

### Apex runtime logic

Found **7 production Apex components** with profile-name checks (12 component/profile pairs):

| Component | Profile names checked | Source lines |
|---|---|---|
| `ContentDocumentTrigger` | System Administrator | 3 |
| `OpportunityTeamMemberTriggerHandler` | Mobileum Salesops Team Profile, System Administrator | 99, 117, 135 |
| `RestrictChange` | System Administrator | 7 |
| `RestrictChangeAttachement` | System Administrator | 9 |
| `TaskTriggerHandler` | Hubspot | 215 |
| `cls_PPOApprovalHandler` | Mobileum Salesops Team Profile, Mobileum System Admin, Quote Creation Team Member, System Admin Certinia, System Administrator | 236, 421 |
| `trg_RestrictChange` | System Administrator | 7 |

These checks control bypass or eligibility behavior. `cls_PPOApprovalHandler` also has a profile allowlist. Convert these dependencies to permission/custom-permission checks as profiles are consolidated.

### Apex test dependencies

**17 Apex test/support classes** query or compare named profiles when building test users or validating behavior:

- `ContentDocumentTest`: Mobileum - Super Sales User
- `DIAB_MB_BatchShareTimecardsToNewPM_Test`: Standard User
- `DIAB_MB_BatchTimecardReAssignment_TC`: System Administrator
- `DynamicApprovalEngineTest`: System Administrator
- `OpportunitySplitTriggerHandlerTest`: System Administrator
- `PendingApproverTrackerTest`: System Administrator
- `SecureAgreementApprovalEngineTest`: System Administrator
- `TestBDMChangeOpptyTeam`: Mobileum - Sales User, Mobileum - Super Sales User
- `UpdateOppsPendingApprovalsBatchTest`: Mobileum - Sales User, System Administrator
- `clsHandler_billingSchedule_project_test`: Mobileum - Finance User Limited, Mobileum - Sales User, System Administrator
- `clsHandler_milestone_schedule_test`: Mobileum - Finance User Limited, Mobileum - Sales User, System Administrator
- `cls_PPOApprovalHandler_Test`: Mobileum Salesops Team Profile, Mobileum System Admin, Quote Creation Team Member, System Admin Certinia, System Administrator
- `quoteAttainmentMgmt_clsHandler_test`: Mobileum - Sales User, System Administrator
- `test_clsLCmpt_LoECalculator`: Mobileum - Finance User Limited, Mobileum - Sales User, System Administrator
- `test_clsMultiCurrency`: Mobileum - Finance User Limited, Mobileum - Sales User, System Administrator
- `test_clsPRTemplates`: Mobileum - Finance User Limited, Mobileum - Sales User, System Administrator
- `test_clsQuoteTemplateHandler`: Mobileum - Finance User Limited, Mobileum - Sales User, System Administrator

`clsOpportunityHandlerTest` contains one commented-out System Administrator lookup; it is not executable. The CSV contains source paths and line numbers for all matches.

### Profile-to-layout and application assignments

The Profile metadata contains **20849 profile-to-layout assignments** and **3150 profile-to-application visibility entries** across the 105 profiles. These are configuration assignments on each Profile and need to be preserved/reconciled when a profile is retired. The CSV includes the profile, assigned layout/application, record type, and visibility/default values.

### Custom application profile action overrides

Found **275 profile action/page overrides** in **13 custom applications**, representing **86 unique application/profile pairs**. These overrides map profiles to actions and Lightning/FlexiPage content:

| Application | Unique profile assignments |
|---|---:|
| `FFX_Accounts_Payable` | 3 |
| `FFX_Accounts_Receivable` | 3 |
| `FFX_FFA_Organization_Setup` | 3 |
| `FFX_Month_End_Close` | 3 |
| `Sales` | 19 |
| `SubContractor_Services_Delivery` | 1 |
| `standard__DataManager` | 3 |
| `standard__FlowsApp` | 3 |
| `standard__LightningSales` | 26 |
| `standard__LightningSalesConsole` | 11 |
| `standard__LightningService` | 1 |
| `standard__OnlineSales` | 5 |
| `standard__Optimizer` | 5 |

Metadata API names `Admin`, `ContractManager`, `MarketingProfile`, `SolutionManager`, and `Standard` map to Salesforce labels `System Administrator`, `Contract Manager`, `Marketing User`, `Solution Manager`, and `Standard User`. The app metadata also contains `StandardAul`, which did not match a `Profile.Name` returned by SOQL; verify this API name before changing it. The CSV lists the specific action, target object, page type, Lightning page, and form factor for each override.

## No direct profile-name reference found

No hardcoded profile-name reference was found in the retrieved **261 page-layout files, 144 Lightning-page files, 5 Connected App definitions, 42 approval processes, 23 workflow files, 14 Visualforce page files, 6 Visualforce component files, 72 Aura files, 52 LWC files, 43 public-group metadata files, 10 queue files, or 161 sharing-rule files**. No Network/Experience site, Sharing Set, or Restriction Rule metadata components were returned. No profile-specific connected-app assignment tag was present in the retrieved Profile metadata. The `Hubspot` sharing rules refer to a role/group; a separate Apex check does use the actual `Hubspot` profile.

The User layouts expose the `ProfileId` field, but do not name a specific profile. No direct profile-name reference was found in LWC, Aura, or Visualforce source.

## Files and limits

- Full reference and profile-assignment data: [`Org_Profile_Name_References.csv`](Org_Profile_Name_References.csv)
- Retrieved org metadata stayed in `/private/tmp/mobileum-profile-audit`; it was not added to source folders.
- This is a metadata snapshot of the requested and profile-relevant types. It cannot inspect managed-package source that Salesforce does not expose or profile names stored in live Custom Setting records/data.
