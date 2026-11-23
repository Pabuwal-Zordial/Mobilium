# Three-Profile Consolidation POC

## Target and status

Source org: **Shivam dev** (Salesforce CLI alias `shivamorg`, Developer Edition, org ID ending `z6zjEAA`). Retrieved on 16 October 2026 into this isolated project. The POC now covers `Helpdesk`, `Manager`, and `Front Desk Profile`; all three use the Salesforce license. A read-only query found no users assigned to these profiles.

No metadata was deployed and no user or permission assignments were changed. The generated files are review drafts, not validated deployment artifacts.

## Outputs

- `access-review/Helpdesk_Manager_Front_Desk_Profile_Comparison.md` and `access-review/Helpdesk_Manager_Front_Desk_Profile_Delta_Matrix.csv` — comparison across three profiles.
- `access-review/Consolidated_Profile_POC_Implementation_Notes.md` — proposed mapping, permission-set contents, assignment approach, and unresolved decisions.
- `access-review/Profile_Name_Reference_Audit.md` — scan of hard-coded/profile-name dependencies across retrieved metadata, with findings and limits.
- `access-review/Helpdesk_Manager_Front_Desk_POC_Runbook.md` — step-by-step no-deploy scope, access review, role boundary, test plan, and rollback notes.
- `force-app/main/default/profiles/Shared_Access_Base_POC.profile-meta.xml` — one shared candidate profile; uses Helpdesk's layout mapping provisionally and Front Desk's recorded login-hours metadata.
- `force-app/main/default/permissionsets/*_Access_Delta_POC.permissionset-meta.xml` — one additive permission set per source persona.
- `manifest/poc-merge-output.xml` — manifest that selects only the four generated draft components if a later, separately approved validation is desired.
- `scripts/build_profile_comparison.py` and `scripts/build_consolidated_poc.py` — regenerate the comparison and draft metadata from the retrieved profiles.

## Review before any deployment

The shared profile keeps 39 of the 40 system grants common to all three profiles; `ViewRoles` is in each persona Permission Set for dependency compliance, and `EditTask` is duplicated in each PS while remaining in the profile. The profile contains no object CRUD or FLS common to all three. The Front Desk profile's login-hours metadata and the Helpdesk/Manager layout/default conflicts also need a decision. The role hierarchy stays unchanged; a separate read-only snapshot shows 25 role metadata entries and one active role-assigned user (`Director`). A dry run surfaced an unresolved `ConvertLeads` dependency on Account, Contact, and Lead CRUD in Manager and Front Desk PSs. See the implementation notes and runbook before changing the output manifest or deploying anything.
