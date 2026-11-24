# Helpdesk / Manager Profile Comparison

Read-only metadata comparison from the `Shivam dev` org, retrieved 15 October 2026. This is a permission-preservation comparison, not approval to merge or assign access.

## License and profile type

- **Helpdesk:** user license `Salesforce`; custom profile `true`.
- **Manager:** user license `Salesforce`; custom profile `true`.

Both profiles use the Salesforce user license, so license tier does not prevent a shared-profile design.

## Grant and configuration comparison

`COMMON` means the same positive grant/configuration is present in both profiles. `HELPDESK_ONLY` and `MANAGER_ONLY` are profile-specific. `CONFLICT` means the same resource/property has different values. The CSV contains each row.

| Dimension | Common | Helpdesk only | Manager only | Conflicts |
|---|---:|---:|---:|---:|
| System permission | 44 | 0 | 4 | 0 |
| Object permission | 0 | 10 | 26 | 0 |
| Field permission | 132 | 0 | 2 | 0 |
| Apex class access | 0 | 0 | 0 | 0 |
| Visualforce page access | 0 | 0 | 0 | 0 |
| Flow access | 0 | 0 | 0 | 0 |
| Tab visibility | 25 | 0 | 0 | 2 |
| Application visibility | 48 | 0 | 0 | 18 |
| Record type visibility/default | 17 | 0 | 0 | 7 |
| Page layout | 11 | 0 | 0 | 2 |

### System permission differences

- `ConvertLeads`: Helpdesk `not enabled`; Manager `true`.
- `ImportPersonal`: Helpdesk `not enabled`; Manager `true`.
- `ViewSetup`: Helpdesk `not enabled`; Manager `true`.
- `ViewSetupAuditTrail`: Helpdesk `not enabled`; Manager `true`.

## User assignment snapshot

A read-only SOQL query in this org returned **zero users** assigned to either profile. Therefore this POC can compare metadata but cannot validate representative user behavior or establish who should receive any future Permission Set Group. Recheck assignments before implementation.

## Initial interpretation

- Both profiles have 44 enabled system permissions in common. `Manager` has four additional permissions: `ConvertLeads`, `ImportPersonal`, `ViewSetup`, and `ViewSetupAuditTrail`. Common permissions include `ApiEnabled`, `ApexRestServices`, `ExportReport`, and `OverrideForecasts`; the security owner should approve retaining them in any shared baseline.
- There are no shared positive object-permission flags. Helpdesk has object permissions on `Account__c`, `Bank__c`, `Branch__c`, `Loan__c`, and `Loan_Detail__c`; Manager has object permissions on `Batch__c`, `Course__c`, `Faculty__c`, `Institute__c`, `Rating__c`, `Student__c`, and `Student_in_Batch__c`. No View All or Modify All object grants were found in these profile definitions.
- The profiles share 132 enabled field-permission flags, mostly on `Account__c`; Manager adds read/edit access to `Student__c.X12th_Percentage__c`. Manager does not have an `Account__c` object grant in this profile XML, so shared FLS alone does not grant record access.
- UI differences are material: `Bank_Application` is visible/default in Helpdesk but hidden in Manager; `InstituteApp` and several standard apps differ. `Bank__c` and `Branch__c` tab visibility differs. Record-type defaults/visibility conflict on `Account__c.Employee`, `Loan_Detail__c.helpdesk`, and `Student__c` record types. Two layout assignments conflict.

These differences indicate distinct application personas rather than near-duplicate profiles. A common profile would need a deliberately minimal baseline plus separately approved object access for each persona; do not union the custom-object grants. Because there are no assigned users, obtain representative test users or create a safe test cohort in the dev org before evaluating the user experience.

## Initial profile-name reference scan

The retrieved text metadata did not show a direct hardcoded `Helpdesk` or `Manager` profile-name check in code, flows, or validation rules. A generic Apex test utility accepts a profile name as an input and queries `Profile`; this is not a hardcoded dependency on either target profile. Treat this as an initial text scan, not a guarantee against dynamic or indirect references.

## Limits and next review

- This matrix compares enabled system/object/FLS/Apex/VF/Flow grants and profile tab, app, record-type, and layout settings.
- Existing Permission Set/PSG assignments are not included in effective access because there are currently no users on these profiles.
- Role hierarchy and record sharing are separate from profile grants; keep role assignments unchanged in the POC.
- Review exact deltas, sensitive system and View All/Modify All grants, profile-name references, and UI conflicts before producing a merged baseline or PS/PSG metadata.
- No metadata was deployed and no user assignments were changed.
