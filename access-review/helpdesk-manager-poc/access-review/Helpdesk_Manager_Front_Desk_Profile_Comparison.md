# Helpdesk, Manager, and Front Desk Profile Comparison

Read-only metadata comparison retrieved from the `Shivam dev` org on 16 October 2026. This is an access-delta analysis, not approval to merge profiles or assign access.

## License and profile type

- **Helpdesk:** user license `Salesforce`; custom profile `true`.
- **Manager:** user license `Salesforce`; custom profile `true`.
- **Front Desk Profile:** user license `Salesforce`; custom profile `true`.

All three profiles use the `Salesforce` license.

## Delta matrix summary

`COMMON_ALL` is the same positive grant/configuration on all three profiles. `*_ONLY` is present on only one profile. `MIXED_OR_CONFLICT` is present on multiple profiles with different values, or present on two but absent on the third. Full resource-level rows are in the CSV.

| Dimension | Common across all | Helpdesk only | Manager only | Front Desk only | Mixed/conflicting |
|---|---:|---:|---:|---:|---:|
| System permission | 40 | 0 | 0 | 1 | 8 |
| Object permission | 0 | 10 | 26 | 0 | 0 |
| Field permission | 0 | 0 | 2 | 0 | 132 |
| Apex class access | 0 | 0 | 0 | 0 | 0 |
| Visualforce page access | 0 | 0 | 0 | 0 | 0 |
| Flow access | 0 | 0 | 0 | 0 | 0 |
| Tab visibility | 0 | 0 | 0 | 0 | 27 |
| Application visibility | 0 | 0 | 0 | 0 | 66 |
| Record type visibility/default | 0 | 0 | 0 | 0 | 24 |
| Page layout | 0 | 0 | 0 | 0 | 229 |

## Review guidance

- Do not merge by taking a simple permission union. That can give every resulting user the combined object, field, and system access of all three personas. Review each `*_ONLY` and mixed row with the business/security owner.
- Check especially system permissions, object `View All`/`Modify All`, sensitive field access, app visibility, record-type defaults, and layout assignments before proposing a shared baseline.
- Profile metadata alone does not show effective access from Permission Sets, Permission Set Groups, licenses, sharing, or role hierarchy.
- A read-only user query returned zero active or inactive users assigned to these three profiles. This means the metadata comparison cannot validate the experience of an existing representative user; check again before implementation.
- No user assignments or org metadata were changed by this retrieval; nothing was deployed.
