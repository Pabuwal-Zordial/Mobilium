# Main Org Profile Permission Clustering (Read Only)

## Scope and method

Compared 105 profiles using current org profile metadata for license, custom/standard status, and enabled system permissions, plus live profile-owned object and field grants exported from `MobiliumStaging`.

Candidates are restricted to custom profiles with the same user license. Similarity weights are 30% system permissions, 30% object permissions, and 40% field permissions. Suggested groups use a 0.90 weighted threshold and complete-link membership: every pair in a group must meet the threshold. Similarity is a triage signal, not approval to merge or proof of equivalent effective access.

The profile-based field-permission export returned 470,297 rows; object-permission export returned 20,101 rows. These are positive grants. The initial Metadata API profile retrieval does not include every profile-only setting, so validate login hours/IP ranges, tab/app visibility, record types, layouts, Apex/VF/flow access, and other profile settings before implementation. Permission Set assignments and role hierarchy also affect effective access.

## Candidate groups

### Group 1 — Salesforce license

53 profiles; keep as a review candidate only. Names are shown for traceability; grouping is based on measured access signatures, not profile labels.

| Profile | Active users | Inactive users | Notes |
|---|---:|---:|---|
| InActive Users | 0 | 69 | Compare deltas before approval |
| Mobileum - PM - EI | 0 | 0 | Compare deltas before approval |
| Mobileum - SCM User | 0 | 0 | Compare deltas before approval |
| Mobileum - SM - Security | 0 | 0 | Compare deltas before approval |
| Mobileum - SM User | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - Africa | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - Africa - AM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - Africa - AM1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - Canada - AM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - Canada - TAM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - EECIS - AM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - EECIS - AM1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - EECIS - TAM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - EECIS - TAM1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - Europe - AM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - Europe - AM1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - Europe - AM2 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - Europe - AM3 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - Europe - TAM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - Europe - TAM1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - LATAM - AM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - LATAM - AM1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - LATAM - TAM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - LATAM - TAM1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - MENA - AM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - MENA - AM1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - MENA - TAM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - MENA - TAM1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - NAMR - AM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - NAMR - LATAM - AM1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - NAMR - TAM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - NAMR - TAM1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - NASA - AM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - NASA - AM1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - NASA - TAM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - SAARC - AM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - SAARC - TAM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - SEAO - AM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - SEAO - AM1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - SEAO - TAM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User v1 | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User-AE-SGM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User-Africa-GM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User-EECIS-GM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User-LATAM-SGM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User-MENA-SGM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User-NAEC-SGM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User-NASA-SGM | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User-SSA-SGM | 0 | 0 | Compare deltas before approval |
| Mobileum - Security - AM | 0 | 0 | Compare deltas before approval |
| Mobileum-Sales User-Africa-TAM | 0 | 0 | Compare deltas before approval |
| Mobileum-Sales User-Africa-TAM1 | 0 | 0 | Compare deltas before approval |
| Read Only | 0 | 1 | Compare deltas before approval |

Within-group weighted similarity range: 0.909–1.000.

### Group 2 — Salesforce license

16 profiles; keep as a review candidate only. Names are shown for traceability; grouping is based on measured access signatures, not profile labels.

| Profile | Active users | Inactive users | Notes |
|---|---:|---:|---|
| Leads, Accounts and Opportunity Creation Marketing Team | 8 | 10 | Compare deltas before approval |
| Mobileum - BDM User | 0 | 0 | Compare deltas before approval |
| Mobileum - Finance User Limited | 2 | 1 | Compare deltas before approval |
| Mobileum - Marketing User | 3 | 4 | Compare deltas before approval |
| Mobileum - Product Management | 1 | 1 | Compare deltas before approval |
| Mobileum - Product Management User | 6 | 14 | Compare deltas before approval |
| Mobileum - Sales & Marketing Head | 0 | 1 | Compare deltas before approval |
| Mobileum - Sales Head | 20 | 10 | Compare deltas before approval |
| Mobileum - Sales User - STDM - APAC | 1 | 0 | Compare deltas before approval |
| Mobileum - Sales User - STDM - EUR | 0 | 1 | Compare deltas before approval |
| Mobileum - Sales User - STDM - GRWTH | 0 | 1 | Compare deltas before approval |
| Mobileum - Sales User - STDM - MENA | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User - STDM - NAMR | 0 | 0 | Compare deltas before approval |
| Mobileum - Sales User Limited | 0 | 0 | Compare deltas before approval |
| Mobileum - Support Head | 0 | 1 | Compare deltas before approval |
| Mobileum Support Head 09292021 | 0 | 0 | Compare deltas before approval |

Within-group weighted similarity range: 0.901–1.000.

### Group 3 — Salesforce license

2 profiles; keep as a review candidate only. Names are shown for traceability; grouping is based on measured access signatures, not profile labels.

| Profile | Active users | Inactive users | Notes |
|---|---:|---:|---|
| Mobileum System Admin | 0 | 0 | Compare deltas before approval |
| Quote Creation Team Member | 9 | 0 | Compare deltas before approval |

Within-group weighted similarity range: 0.991–0.991.

### Group 4 — Salesforce license

2 profiles; keep as a review candidate only. Names are shown for traceability; grouping is based on measured access signatures, not profile labels.

| Profile | Active users | Inactive users | Notes |
|---|---:|---:|---|
| Mobileum - Finance Full Access | 1 | 1 | Compare deltas before approval |
| Mobileum - O&M | 0 | 0 | Compare deltas before approval |

Within-group weighted similarity range: 0.985–0.985.

### Group 5 — Salesforce license

2 profiles; keep as a review candidate only. Names are shown for traceability; grouping is based on measured access signatures, not profile labels.

| Profile | Active users | Inactive users | Notes |
|---|---:|---:|---|
| Mobileum - Revenue Team User | 0 | 0 | Compare deltas before approval |
| Mobileum - Super Sales User | 2 | 0 | Compare deltas before approval |

Within-group weighted similarity range: 0.979–0.979.

## Profiles not placed in a candidate group

These profiles either are standard profiles, lack a same-license custom-profile match at the threshold, or were left out by the complete-link grouping rule. Keep separate pending review.

| Profile | License | Custom | Active users | Inactive users |
|---|---|---:|---:|---:|
| Accounts Creation Only | Salesforce | True | 0 | 0 |
| Admin | Salesforce | False | 0 | 0 |
| Analytics Cloud Integration User | Analytics Cloud Integration User | False | 1 | 0 |
| Analytics Cloud Security User | Analytics Cloud Integration User | False | 1 | 0 |
| Anypoint Integration | Identity | False | 0 | 0 |
| Chatter External User | Chatter External | False | 0 | 0 |
| Chatter Free User | Chatter Free | False | 0 | 0 |
| Chatter Moderator User | Chatter Free | False | 0 | 0 |
| ContractManager | Salesforce | False | 0 | 0 |
| Customer Community Login User | Customer Community Login | False | 0 | 0 |
| Guest License User | Guest User License | False | 0 | 0 |
| Hubspot | Salesforce | True | 1 | 0 |
| Identity User | Identity | False | 0 | 0 |
| MarketingProfile | Salesforce | False | 0 | 0 |
| Minimum Access - API Only Integrations | Salesforce Integration | False | 1 | 0 |
| Minimum Access - Salesforce | Salesforce | False | 0 | 1 |
| Mobileum - Read Only | Salesforce | True | 0 | 0 |
| Mobileum - Sales User | Salesforce | True | 163 | 140 |
| Mobileum Read Only | Salesforce | True | 2 | 11 |
| Mobileum Salesops Team Profile | Salesforce | True | 3 | 0 |
| Mobileum- Finance Full Access | Salesforce | True | 29 | 20 |
| Read Only Custom profile | Salesforce | True | 0 | 0 |
| Read Only1 | Salesforce | True | 9 | 102 |
| Sales Insights Integration User | Sales Insights Integration User | False | 1 | 0 |
| Salesforce API Only System Integrations | Salesforce Integration | True | 0 | 0 |
| SolutionManager | Salesforce | False | 0 | 0 |
| Standard | Salesforce | False | 0 | 0 |
| Standard Platform User - Subcontractor | Salesforce Platform | True | 65 | 16 |
| StandardAul | Salesforce Platform | False | 0 | 0 |
| System Admin Certinia | Salesforce | True | 0 | 0 |

## Review guidance

1. Treat each group as a candidate for a common baseline profile only after confirming job function and license compatibility with the client.
2. Move documented, approved additive deltas into permission sets or permission set groups; do not use union-by-default because that can grant excess access.
3. Review system permissions, View All/Modify All, sensitive object/FLS grants, and user assignment counts explicitly. Keep elevated/admin access isolated unless there is a documented requirement.
4. Analyze role hierarchy separately. Roles control record visibility through hierarchy and sharing; they are not interchangeable with profiles or permission sets.
5. Keep all changes in a review branch and validate in a sandbox. This analysis made no org changes and deployed nothing.

See `Main_Org_Profile_Pairwise_Permission_Similarity.csv` for all pairwise deltas and similarity scores.
