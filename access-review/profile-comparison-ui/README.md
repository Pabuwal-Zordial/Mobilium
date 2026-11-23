# Salesforce Profile Compare

An offline browser tool for reviewing Salesforce Profile XML. It has a pair-comparison page and a multi-profile analysis page for 2–18 files. It does not connect to Salesforce or deploy changes.

## Open it

Open `index.html` in a current Chrome, Edge, Firefox, or Safari browser. No installation, server, or internet connection is required. Each reviewer can select files, drop them onto the profile cards, or paste XML. Enter a comparison label if the XML came from a paste and does not include a name.

For four-profile or larger reviews, use `multi-profile.html`. Select or drop 2–18 complete Profile XML files, then choose **Compare profiles**. The page shows suggested groups, draft Permission Set candidates, and a permission-by-permission table. Optional grouping settings let you change the similarity threshold or relax the profile-settings match requirement. By default, different licenses, standard profiles, and profiles with different profile-only settings are kept apart.

## What it compares

- Object permissions: Read, Create, Edit, Delete, View All, and Modify All.
- Field-level security: view and edit access by field.
- System permissions, Apex class access, Visualforce page access, custom permissions, custom metadata/settings, and external data source access when those elements are present.
- Record type availability/default, tab visibility, and application visibility/default settings.
- Profile-only settings such as layout assignments, login hours, and IP ranges.

The report separates shared positive grants, grants specified on only one side, conflicts, and profile-only settings. `Not specified in XML` is different from an explicit false value; absence is never silently treated as a denial.

## Multi-profile grouping and XML drafts

Multi-profile grouping compares positive permission grants. The threshold is a percentage overlap score: at 85%, every pair of profiles in a suggested group must score at least 85%. The tool groups only custom profiles with the same declared license. By default, profile-only settings must also match. Profile names do not drive grouping. This is a review aid, not proof that users share the same business persona or effective access.

The page identifies common positive grants as a baseline candidate and one-sided positive portable grants as Permission Set candidates. It can download a ZIP containing draft Permission Set XML, optional Permission Set Group XML, and a review README. It does not generate a merged Profile, package manifest, user assignments, or deployment actions. Generated API names must be checked for collisions. Tabs, layouts, login restrictions, app defaults, and other profile-only behavior require separate handling. High-impact permissions are excluded from generated XML unless the reviewer explicitly selects the inclusion checkbox.

Permission Set Groups are proposed only when a profile cohort has at least two candidate Permission Sets. Even then, the user persona and group membership require business approval.

## Pair-comparison Permission Set suggestions

For two custom profiles with the same license, the tool identifies positive one-sided grants that may be candidates for profile-specific Permission Sets. It suggests two delta sets only as a draft. A Permission Set adds access; it cannot take access away or enforce a denial. If a grant conflicts with an explicit false setting, the tool flags that for review.

Use the common grants only as a possible baseline, not an automatically safe merged profile. Review high-impact access, licensing, XML completeness, user assignment mapping, and business need. Create a Permission Set Group only when you know which reusable Permission Sets should be bundled for a stable persona; two XML files cannot establish that. The tool does not generate deployable Permission Set or Group XML.

## Limits

The comparison is limited to the supplied files. It cannot determine effective user access from assigned Permission Sets/Groups, role hierarchy, record sharing, territories, validation rules, Flows, Apex references elsewhere in the org, managed packages, or user assignment data. Retrieve complete profile XML and have an administrator validate proposed changes in a sandbox. Multi-profile analysis limits each file to 25 MB and the batch to 18 files.

The CSV export contains the current filtered comparison. XML is processed locally in browser memory; use **Clear** after review on a shared device.
