# Sales Profile POC — isolated Salesforce DX project

This project packages the local Sales User / Sales Head access POC separately from the repository's normal deployment manifest. Use the local CLI alias `shivam-dev` for the development environment called `shivam dev`.

## Current state

- The POC metadata and manifest are local drafts.
- No metadata has been deployed and no user or permission assignment has been changed.
- The Salesforce CLI currently reports no authenticated orgs. Authenticate the intended development org and set the CLI alias to `shivam-dev` before attempting an org validation.
- Review `Sales_Profile_POC.md` and the grant/UI parity CSVs before any deployment decision.

## Safe preparation sequence

From this directory, authenticate the intended development org in the Salesforce CLI or Salesforce VS Code extension and set its local alias to `shivam-dev`. Confirm it is the intended environment with `sf org display --target-org shivam-dev`.

Retrieve current target-org metadata and compare it with this POC before validating. The POC includes the `Project__c.Sales_rep_cannot_edit_project_Name` validation rule, which is an existing business control in the target org; its formula must be reviewed because a real deployment would update that rule.

To perform a **check-only validation** in this development org after authentication and review, run:

```sh
sf project deploy start --manifest manifest/package.xml --target-org shivam-dev --dry-run --test-level RunLocalTests --wait 60
```

The `--dry-run` flag validates the package without saving it to the org. Do not remove that flag or run a non-dry-run deploy unless deployment is separately approved. The package also introduces a draft profile and PS/PSGs; do not assign them to users as part of validation.

The profile POC does not include layout, app override, login/IP, sharing, or role changes. Validate those separately using the parity inventory and representative-user checks.
