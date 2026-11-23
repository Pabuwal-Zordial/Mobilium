# MobiliumStaging Full Org Profile and Role Census

Read-only inventory of the main org, alias `MobiliumStaging`, org ID `00DO500000i5xb0MAA`, retrieved 2026-10-16. No org metadata or user assignments were changed.

## Counts

- Profiles retrieved: **105** (87 custom, 18 standard).
- Roles retrieved: **120**.
- Users: **1178 active**, **2284 inactive**.
- Users with roles: **225 active**, **364 inactive**.
- Users without roles: **953 active**, **1920 inactive**.

### Profile counts by user license

| User license | Profiles |
|---|---:|
| Analytics Cloud Integration User | 2 |
| Chatter External | 1 |
| Chatter Free | 2 |
| Customer Community Login | 1 |
| Guest User License | 1 |
| Identity | 2 |
| Sales Insights Integration User | 1 |
| Salesforce | 91 |
| Salesforce Integration | 2 |
| Salesforce Platform | 2 |

### Retrieved role/access dependencies

| Metadata type | Components |
|---|---:|
| Permission Sets | 75 |
| Permission Set Groups | 6 |
| Public groups | 43 |
| Queues | 10 |
| Sharing-rule metadata components | 161 (9 defined rules across 4 objects) |
| Approval processes | 42 |

## Scope implications

The earlier partner list covers 16 of the org's 105 profiles. A full-org consolidation assessment must first partition by user license; Salesforce, Platform, Identity, Integration, Chatter, Community, Guest, and product-specific licenses cannot be treated as one interchangeable profile pool. Standard profiles and privileged or integration profiles also need separate treatment.

Role reduction is a separate access-control analysis. Role hierarchy can change record visibility through hierarchy inheritance, sharing rules, groups, and queues. This census identifies 120 roles and direct user counts; it does not yet recommend role merges. The role inventory CSV includes each parent role and role-level Case, Contact, and Opportunity access.

The generated inventories are snapshots for analysis. Permission Set assignments, Permission Set Group memberships, object sharing, territories, and user business ownership still need to be correlated before proposing user moves or role changes.
