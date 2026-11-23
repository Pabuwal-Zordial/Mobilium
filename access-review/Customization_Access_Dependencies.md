# Profile Consolidation: Customization Dependency Audit

## Scope

Read-only scan of the local Salesforce DX metadata for profile/role-based logic and bypass configuration. This is a source-checkout audit, not proof that the org has no additional Apex, Flow, managed-package, or declarative logic. No org metadata was changed or deployed. The isolated Finance POC contains a candidate copy of the Project validation rule refactored to a Custom Permission.

## Findings

| Finding | Count / location | Migration impact |
|---|---|---|
| Active validation rules that check `$Profile.Name` | 10 rules across Billing Details, Project, Purchase Order, Schedule, and Technical Service Request | Replacing or consolidating profiles can change rule behavior unless the current exceptions are represented another way. |
| Inactive profile-based validation rule | `Proposal_Code__c.Restricted_Non_Master_Code` | It is inactive today. Do not activate it as part of this cleanup. Its Finance profile-name exceptions include a duplicated Finance Full Access condition. |
| Profile-specific Project restriction | `Project__c.Sales_rep_cannot_edit_project_Name` | It restricts name changes for users on Mobileum - Sales User. Preserve this behavior for the intended sales persona after profile consolidation. |
| System Administrator / Sales Ops bypasses | Four closed-won rules exempt System Administrator; five TSR status rules exempt System Administrator and/or Mobileum Salesops Team Profile | Replace profile-name tests only after identifying the intended bypass users and preserving each rule's current behavior. |
| Hardcoded email exceptions | Three email addresses appear in two TSR status rules | Confirm each exception is still required. A permission-based exception is easier to administer than embedding individual email addresses, but requires explicit approved assignments. |
| Hierarchy custom setting bypass | `Proposal_Code__c.Prevent_Edit` uses `$Setup.Validation_Rule_Bypass__c.Bypass__c`; setting type is Hierarchy and the field metadata default is `true` | This is separate from the profile-name checks. Audit org setting records and owners before changing or retiring the bypass. Preserve any intended user/profile/org overrides; the default value makes live-record verification especially important. |
| Apex classes, triggers, and Flows in this checkout | None found | The current source retrieve cannot support Apex/Flow refactoring. Retrieve them from the org/package source before asserting there are no references. |
| `$UserRole` / role-name checks in formulas | None found in the scanned validation-rule metadata | Role dependencies may still exist in Apex, Flows, approvals, formulas outside the retrieved scope, or managed packages. |

## Validation rules with profile checks

- `Billing_Details__c.Prevent_Changes_if_Oppty_Closed_Won`
- `Project__c.Prevent_Changes_if_Oppty_Closed_Won`
- `Purchase_Order__c.Prevent_Changes_if_Oppty_Closed_Won`
- `Schedule__c.Prevent_Changes_if_Oppty_Closed_Won`
- `Project__c.Sales_rep_cannot_edit_project_Name`
- `Technical_Service_Request__c.Can_not_change_status_to_Cancelled`
- `Technical_Service_Request__c.Can_not_change_status_to_Implemented`
- `Technical_Service_Request__c.Cannot_set_to_New_from_Other`
- `Technical_Service_Request__c.TSR_is_not_editable_Cancelled`
- `Technical_Service_Request__c.TSR_is_not_editable_implemented`
- Inactive: `Proposal_Code__c.Restricted_Non_Master_Code`

## Recommended implementation sequence

1. Retrieve the complete current Apex, Flow, approval, formula, and custom-setting data from the target org, including managed-package constraints where available.
2. For each exception, document the business action allowed, the intended user/persona, and an owner who approves it. Do not assume every current profile exception remains valid.
3. Replace hardcoded profile-name checks with narrowly named Custom Permissions or another supported, centrally managed authorization marker. Keep the hierarchy custom setting if its existing user/profile/org override behavior is still required; otherwise migrate it only after enumerating its actual records and testing equivalent behavior.
4. Grant each approved Custom Permission through the target profile/permission sets and explicit assignments. Add an active verification case for both the authorized and unauthorized behavior of every changed rule.
5. Deploy to sandbox, test each persona and rule, reconcile effective access, then include the refactor in the same release plan as the profile migration. Do not retire source profiles until no formula or automation depends on them.

The Finance POC workbook includes one candidate Custom Permission and a candidate set for the Project Name restriction, along with a proposed assignment list for the 163 current Sales User profile users. The isolated copied rule uses that permission. This preserves the present profile-based restriction only if the Custom Permission is granted to the full cohort and future provisioning maintains the assignment. Other profile-name checks and the custom-setting bypass are not changed in the POC; refactor them only after the business/security owner approves their exception mapping.
