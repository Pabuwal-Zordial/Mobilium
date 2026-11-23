# Profile Name Reference Audit

## Scope

Read-only text and metadata scan of the retrieved `Shivam dev` project for the three target profile names: `Helpdesk`, `Manager`, and `Front Desk Profile`. It covers the retrieved Apex classes/tests, triggers, LWC, Aura, Visualforce, flows, validation rules, object metadata, page layouts, FlexiPages, applications, connected apps, networks/Experience metadata, approval processes, groups, queues, sharing sets, restriction rules, sharing rules, roles, and permission metadata.

Retrieved source counts include 56 Apex classes, 16 triggers, 36 LWC bundles, 2 Aura bundles, 1 Visualforce page, 8 flows, 20 validation rules, 247 layouts, 24 FlexiPages, 1 approval process, 2 public groups, 3 queues, 259 sharing-rule metadata files, and 25 role metadata files. The org returned no connected apps, Experience bundles, Networks, Sharing Sets, or Restriction Rules in the requested retrieve.

## Findings

- **No direct hard-coded check for any of the three target profile names was found** in retrieved Apex, tests, triggers, LWC/Aura, Visualforce, flows, validation rules, approval processes, groups/queues, connected-app/community metadata, sharing metadata, layouts, or FlexiPages.
- `classes/TestFactory.cls` has a generic `generateUser(String profileName)` helper that queries `Profile.Name` from the argument. The retrieved code contains no call site passing one of the three target profile names. It is a dynamic test helper, not a hard-coded dependency.
- `lwc/getUserDetails/getUserDetails.js` reads the current user's `User.Profile.Name` dynamically and stores it for display. It does not branch on the target profile names. After a user receives the shared profile, any UI that displays this value will show the new profile name.
- `objects/Student__c/Student__c.object-meta.xml` has a profile search-layout entry for `System Administrator`, which is not one of the target profiles.
- The string `helpdesk` appears as the `Loan_Detail__c.helpdesk` record type and its layout/record-type assignments, including in a permission set. This is a record type developer name, not a Profile name. Preserve it unless the business separately changes that record type.
- Other `Manager` matches are names such as the User.Manager relationship, `ContactManager`, and manager-related fields. They are not Profile-name checks.

## Limits and follow-up

This is a source-text and retrieved-metadata scan. It cannot prove that no dynamic reference is assembled at runtime, stored in data, or maintained in metadata not returned by the org. The requested metadata types with no returned components were absent from the local retrieve; this is not evidence that the org can never use them later. Repeat the scan against the final deployment package and inspect any new components before retiring profiles.

No code or org metadata was changed during this audit.
