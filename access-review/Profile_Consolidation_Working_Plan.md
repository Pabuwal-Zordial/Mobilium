# Profile Consolidation Working Plan

## Goal and scope

Prepare a reviewed proposal to reduce Salesforce profile count, move job-specific access into Permission Sets or Permission Set Groups, and update metadata that depends on profile names. This is a planning and source-preparation effort only: **do not deploy or reassign users** without explicit approval.

The in-scope profiles are:

- Hubspot
- Leads, Accounts and Opportunity Creation Marketing Team
- Mobileum - Finance Full Access
- Mobileum- Finance Full Access
- Mobileum - Finance User Limited
- Mobileum - Marketing User
- Mobileum - Product Management
- Mobileum - Product Management User
- Mobileum - Sales Head
- Mobileum - Sales User
- Mobileum - Sales User - STDM - APAC
- Mobileum - Super Sales User
- Mobileum Read Only
- Mobileum Salesops Team Profile
- Quote Creation Team Member
- Read Only1

The client confirmed that the two Finance Full Access labels identify distinct profiles and that both should be consolidated. Keep them as separate source cohorts in comparisons and preserve their different access in separate deltas on the shared Finance baseline. This is 16 literal labels, with the remaining list comprising 14 others. Their differing app overrides still need an approved preservation or redesign plan.

## Work sequence

1. **Resolve scope and users:** Compare active and inactive users assigned to these profiles with the partner’s department matrix. Record the intended target access for each in-scope user, including service and integration accounts. Flag unmatched users for client direction.
2. **Check compatibility:** Confirm user-license compatibility before proposing any profile consolidation. Identify any profiles that cannot share a target profile because of license or other platform constraints.
3. **Build the access comparison:** Compare system permissions, object CRUD and View All/Modify All, field access, Apex and Visualforce access, flows, tabs, apps, record types, and layout assignments. Separate common baseline access from profile-specific access and sensitive grants.
4. **Design the target model:** Recommend retained profiles and identify job-specific differences for Permission Sets or Permission Set Groups. Document proposed assignments by approved role or user group; do not assign them in the org.
5. **Review dependencies:** Trace profile-name references in validation rules, flows, Apex, app overrides, and other retrieved metadata. Propose behavior-preserving replacements and call out items needing business approval.
6. **Sandbox verification:** After the design is reviewed, verify representative user access and key workflows, then run check-only metadata validation. Report results and resolve issues before requesting deployment approval.

## Client confirmations needed

- The two Finance Full Access profiles are distinct and both are to be consolidated. Confirm the owner-approved grants for each separate delta and the handling of their differing app overrides.
- The approved, complete user-to-department/target-access mapping, including exceptions and service/integration users.
- Whether the partner matrix is the access baseline, and confirmation of sensitive permissions such as View All, Modify All, API, export, and user administration.
- Whether role hierarchy, sharing, and record visibility are in scope in addition to profiles and Permission Sets.
- Named reviewers for the access matrix and sandbox test results.

## Current status and constraints

- The org-wide profile-name reference audit is available in `Org_Profile_Name_Reference_Audit.md` and `Org_Profile_Name_References.csv`. Re-filter its findings to this scope before implementation decisions.
- The existing Finance POC is a local-only draft in `finance-poc/`; its staging validation job `0AfO500000fQjhpKAC` was still Pending at last check, with zero components processed. It is not validated until Salesforce reports a completed result.
- No org deployment or user reassignment has been performed. Keep the POC isolated from the normal deployment manifest until it is approved.
