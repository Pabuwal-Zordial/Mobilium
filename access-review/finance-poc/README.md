# Finance Profile POC Metadata (Local Only)

This folder contains isolated Salesforce metadata drafts for review. **Do not deploy these files.** They are outside the normal `force-app/main/default`, are not referenced by `manifest/package.xml`, and have no deployment manifest or Salesforce assignments.

## Draft components

- `Finance_POC_Baseline.profile-meta.xml`: one Salesforce-license profile containing only the positive grants common to the six Finance-matrix profiles.
- Five `*_Delta.permissionset-meta.xml` files: profile-specific object, field, and record-type grants beyond that common baseline.
- Five `*_System.permissionset-meta.xml` files: profile-specific system permissions beyond that common baseline.
- `Sales_Project_Name_Restriction.permissionset-meta.xml`, a Custom Permission, and a copied validation rule: a candidate refactor preserving the active Sales User project-name restriction.
- Quote Creation Team Member is excluded from permission-set generation. Its users remain on the existing profile pending review of its elevated system permissions.

The 10 access-delta permission sets contain **706 profile-grant entries**; the separate rule-preservation set adds one Custom Permission. These are mechanical profile deltas, not owner-approved access. In particular, `Fin_Super_Sales_System` contains sensitive system permissions such as `ModifyMetadata`, `TransferAnyEntity`, and `TransferAnyLead`; review and remove any grant without a documented need.

## Known behavior dependencies

The isolated `Project__c.Sales_rep_cannot_edit_project_Name` copy replaces the profile-name check with `$Permission.Restrict_Project_Name_Edit`. The associated permission set must be assigned to all 163 current Mobileum - Sales User profile users to preserve behavior when the rule changes; two of these users are in the Finance POC. Assignments are listed in `Sales_Project_Name_Restriction_Assignment_Proposal.csv`. Deploy the Custom Permission, set, rule, and assignments as one reviewed change, and include future provisioning. The other profile-name validation checks and hierarchy custom-setting bypass are documented in [Customization_Access_Dependencies.md](../Customization_Access_Dependencies.md). No Apex classes, triggers, or flows were present in the local retrieve to refactor.

The `Validation_Rule_Bypass__c.Bypass__c` custom setting is unchanged. Its field metadata has default value `true`; inspect hierarchy custom-setting records and effective user/profile/org overrides before changing this behavior.

## Regenerate

Run `python3 scripts/build_finance_metadata_poc.py`. The script reads the six profile XMLs under the normal source tree and rewrites only this isolated POC folder.
