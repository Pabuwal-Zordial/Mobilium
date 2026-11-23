# Finance Profile Consolidation POC

## Scope and method

Analysis and local metadata POC for the six Finance profiles named in the partner matrix, based on their retrieved Salesforce Metadata API XML and the available active-user department snapshot. Access counts below are grants explicitly enabled in profile XML. A permission-set grant can add access; removing a grant from a profile does not itself revoke access granted elsewhere. No org changes were made.

The [grant comparison CSV](./Finance_Profile_Grant_Comparison.csv) lists every unique positive grant across the six profiles (1,363 rows), marks the 941 grants present in all six, and shows which profile XMLs contain each remaining grant. The [Excel review workbook](./Finance_PS_and_Elevated_Permissions_Review.xlsx) adds candidate permission-set contents and user cohorts, each profile's system permissions, and object-level View All Fields / View All Records / Modify All grants. The [builder script](../scripts/build_finance_ps_review_xlsx.py) regenerates the workbook from the profile XML and current read-only exports.

The separate [customization dependency audit](./Customization_Access_Dependencies.md) records profile-name checks in validation rules and the hierarchy custom-setting bypass found in the local source. These dependencies need an approved behavior/assignment map before profile changes; they are not included in the candidate permission sets yet.

## What is and is not being proposed

**No permission has been moved in Salesforce, and nothing has been deployed.** A local, isolated metadata draft now exists under `access-review/finance-poc/`; it contains one candidate baseline profile and eleven candidate permission sets, with no Salesforce assignments or deployment manifest. No org profile, permission set, or role has been created or changed. The CSV is an evidence inventory, not an approved deployment manifest. “Common” means the same positive grant appears in all six source XMLs; it is a baseline candidate for review, not an instruction to grant it to every Finance user. “Observed difference” means it appears in some profiles only; it is not automatically an approved permission-set grant. Some deltas may be obsolete, inappropriate, needed by a different job, or already granted through an assigned permission set/group.

The local POC draft contains five data-access sets, five system-permission sets, and one set for the existing Project Name validation restriction. This is a candidate design; no final permission-set count is approved. After owners approve the intended tasks, keep only validated differences in narrow permission sets (for example, quote workflow access or approved reporting features). Administrative grants found on Quote Creation Team Member require separate security approval and should not be bundled into ordinary Finance access. No role count/change is recommended from profile metadata alone; role design depends on record sharing and reporting hierarchy.

## Proposed profile, permission sets, and user cohorts

For a deployable **next design iteration**, the isolated draft contains **one Finance baseline profile plus eleven candidate permission sets**: five for object/FLS/record-type differences, five separate sets for system-permission differences, and one to preserve an active validation rule. Quote Creation Team Member remains on hold. This is a draft, not approval to create or assign these components. The baseline is the common access intersection; candidate sets contain observed profile differences. Review every grant and remove anything not required before implementation. The workbook's `PS Candidate Grants` sheet is the full permission-by-permission inventory.

| Candidate permission set API name | Source profile differences | Candidate grants | Current Finance users |
|---|---|---:|---:|
| `Fin_Full_Access_Delta` | Mobileum- Finance Full Access; object/FLS/record type | 111 | 25 |
| `Fin_Full_Access_System` | Mobileum- Finance Full Access; system permissions | 5 | 25 |
| `Fin_Sales_Head_Delta` | Mobileum - Sales Head; object/FLS | 127 | 6 |
| `Fin_Sales_Head_System` | Mobileum - Sales Head; system permissions | 6 | 6 |
| `Fin_Limited_Access_Delta` | Mobileum - Finance User Limited; object/FLS/record type | 76 | 2 |
| `Fin_Limited_Access_System` | Mobileum - Finance User Limited; system permissions | 1 | 2 |
| `Fin_Sales_User_Delta` | Mobileum - Sales User; object/FLS | 127 | 2 |
| `Fin_Sales_User_System` | Mobileum - Sales User; system permissions | 10 | 2 |
| `Fin_Super_Sales_Delta` | Mobileum - Super Sales User; object/FLS/record type | 217 | 1 |
| `Fin_Super_Sales_System` | Mobileum - Super Sales User; system permissions | 26 | 1 |
| `Sales_Project_Name_Restriction` | Custom Permission for current Project Name validation behavior; all 163 Sales User-profile users | 1 | 2 Finance users (163 total) |

The Excel workbook's `User Assignments` sheet names the 36 eligible Finance user records, their two access-delta sets, role, and current PS/PSG assignment-row count. The two Finance users on Mobileum - Sales User also have the Project Name restriction set as a candidate. This makes up to 74 Finance user-to-set assignment candidates. A separate `Dependency Assignments` sheet lists all 163 current Sales User-profile users who need the restriction set if that validation rule is refactored; 2 are already in the Finance POC. These are proposals only. Check existing assignments and test the rule before assigning anything. The access-delta sets only make sense with the reviewed baseline profile.

**Hold 8 Finance users currently on Quote Creation Team Member out of this eleven-set proposal.** Their current profile has 120 system-permission grants beyond the intersection, including high-impact administration. Keep their current profile until owners identify the actual quote tasks, security reviews those grants, and an approved design distinguishes quote functionality from unrelated administration. A quote-specific permission set is not counted here because its safe contents cannot be inferred from profile metadata alone. The Super Sales system-permission candidate also contains sensitive grants such as `ModifyMetadata`, `TransferAnyEntity`, and `TransferAnyLead`; these are flagged for security review, not recommended for automatic assignment.

The Finance-only cohort is 44 users from the partner-listed profile names: 36 eligible for two candidate sets each and 8 held. Other users on these same profiles are outside this Finance POC (including QMS, Operations, Bid Management, Engineering, CEO - Office, Sales Operations, and other departments); do not assign them Finance sets based only on profile name. Since source profiles are shared with other departments, this POC does **not** support deleting or deprecating those profiles org-wide. No roles are proposed for creation or reassignment.

The isolated candidate Salesforce XML is under [finance-poc](./finance-poc/README.md). It is intentionally outside the deployable source directory and has no manifest. Review the grants and rule dependencies before moving any components into `force-app/main/default`.

## Profile inventory

All six XML files have `<custom>true</custom>` and `<userLicense>Salesforce</userLicense>`. They are therefore license-compatible for consideration as a shared Salesforce-license baseline; this does not establish that their business access is equivalent.

| Profile | Active users in snapshot | Department distribution | System grants | Object CRUD / “all” grants | Enabled FLS grants |
|---|---:|---|---:|---:|---:|
| Mobileum- Finance Full Access | 29 | Finance 25; QMS 2; CEO - Office 1; blank 1 | 46 | 81 | 925 |
| Mobileum - Sales Head | 20 | Operations 9; Finance 6; Bid Management 4; Engineering 1 | 47 | 84 | 938 |
| Quote Creation Team Member | 9 | Finance 8; Operations 1 | 161 | 158 | 973 |
| Mobileum - Finance User Limited | 2 | Finance 2 | 42 | 67 | 903 |
| Mobileum - Sales User | 163 | Finance 2; other departments 160; blank 1 | 51 | 89 | 933 |
| Mobileum - Super Sales User | 2 | Finance 1; Sales Operations 1 | 67 | 165 | 946 |

The similar names **“Mobileum- Finance Full Access”** and **“Mobileum - Finance Full Access”** are distinct. Only the former appears in the supplied Finance matrix; the latter has no matching file in this six-profile scope and must not be silently treated as the same profile. The 163-user Sales User profile is shared broadly across departments, so it is not a Finance-specific profile candidate.

## N-way comparison

The intersection across all six profiles is 41 enabled system permissions, 46 object permission grants, and 849 enabled field-level grants. Their union contains 162, 198, and 997 grants respectively. The remaining grants differ among profiles: 121 system, 152 object, and 148 FLS grants beyond the common intersection. These are counts of permission flags, not counts of users or Salesforce objects. Object permission counts now include `viewAllFields`, which appears on Sales User and Super Sales User profiles.

| Profile | System grants beyond common | Object grants beyond common | FLS grants beyond common |
|---|---:|---:|---:|
| Mobileum- Finance Full Access | 5 | 34 | 76 |
| Mobileum - Sales Head | 6 | 38 | 89 |
| Quote Creation Team Member | 120 | 110 | 124 |
| Mobileum - Finance User Limited | 1 | 21 | 54 |
| Mobileum - Sales User | 10 | 43 | 84 |
| Mobileum - Super Sales User | 26 | 119 | 97 |

Notable divergence: **Quote Creation Team Member** carries 161 enabled system permissions, including administrative capabilities such as `ManageUsers`, `ManageProfilesPermissionsets`, `ManageRoles`, `ManageSharing`, `ModifyMetadata`, `ManageSandboxes`, and `AuthorApex`. That is a strong reason to treat it as a separate high-privilege persona and validate business need before retaining or assigning any of those permissions. “Finance Full Access” is not a safe label-based assumption: its XML has fewer enabled system grants than Sales User and Super Sales User.

The five shared visible record types are `Sales_Campaign__c.RAID_9`, `Sales_Campaign__c.ROAMING_DNA`, and `Territory__c.Country`, `Region`, and `Sub_Region`; `RAID_9` and `Territory__c.Region` are default in all six. `Territory__c.VSOE_Region` is visible in Mobileum- Finance Full Access, Quote Creation Team Member, Finance User Limited, and Super Sales User, but absent from Sales Head and Sales User. No layout assignment entries were serialized in these six profile XMLs. The retrieved XML also contains no explicit Apex class, Visualforce page, flow, custom metadata type, tab, or application access entries for this group. Confirm effective assignments in the org before treating an absent XML entry as proof of no effective access.

## POC recommendation

Do **not** merge all six profiles using Boolean union. That would distribute Quote Creation Team Member’s extensive administrative rights to all users on the new profile. For a controlled consolidation proposal:

1. Keep the common intersection as a *candidate* baseline, then validate each common grant with Finance and security owners; common does not automatically mean appropriate.
2. Separate Quote Creation Team Member as a high-privilege persona. Review its 120 system-permission differences individually; do not package them as one broad “Finance” permission set.
3. Treat Sales Head, Super Sales User, and Sales User as role/persona variants, not Finance-only entitlements. Identify the specific users and required tasks before extracting each delta into narrowly scoped permission sets.
4. Keep Finance User Limited as a separate low-volume cohort until owners confirm its two users’ needs. Compare its effective access including permission-set assignments before proposing retirement.
5. Resolve department mismatches (Sales User users across many departments; Sales Head mostly Operations/Bid Management) with the partner. The supplied department/profile table is an intended mapping, not evidence that current assignments match it.

## Next validation before any change

Review user-level assignments and all directly assigned permission sets, permission-set groups, muting sets, role/sharing needs, and profile-specific app/login controls. Obtain owners’ approval of the baseline and persona deltas. In a sandbox, pilot a small representative user group, compare effective access and business workflows, then document rollback and reassignment steps. Profile retirement and deployment are out of scope for this POC.
