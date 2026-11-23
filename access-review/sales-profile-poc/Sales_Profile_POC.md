# Sales User / Sales Head Profile POC

## Scope and status

Local-only, isolated POC using the retrieved profile permission grants for `Mobileum - Sales User` and `Mobileum - Sales Head`. No org changes, user assignments, deployment manifest, or deployment were created. This is a mechanical access-preservation draft, not approved access.

## Draft components

- One baseline profile containing positive permission grants common to both source profiles. It carries the Salesforce license and uses Sales User's profile-only record-type defaults as the selected baseline.
- `Sales_User_Access_Delta` and `Sales_User_System_Delta` for Sales User-only grants.
- `Sales_Head_Access_Delta` for Sales Head-only object, field, and record-type grants. No separate Head system-permission set was needed because this comparison found no system grants unique to Sales Head.
- `Sales_User_POC` and `Sales_Head_POC` permission set groups bundling each persona's delta. These are drafts, not assignments.
- A Custom Permission and copied Project validation rule to preserve the current Sales User-only Project Name restriction. The permission set is included in the Sales User group; actual user assignments are not generated.
- `Sales_User_Sales_Head_Grant_Matrix.csv` lists each positive system, object, field, and record-type grant and marks it common or profile-specific.
- `Sales_User_Sales_Head_UI_Parity.csv` records the profile-level layouts, app visibility, and app action overrides to preserve. Both profiles match on these UI mappings in the audit snapshot.

## Record-type default needing approval

Both profiles define six record-type entries, five of which are visible. Their `Territory__c.Region` record type differs: Sales User has `personAccountDefault=true`, while Sales Head does not. The POC baseline carries the Sales User value because it is the chosen source baseline. Confirm this behavior with the owner and test person-account users; if it must differ by persona, this profile-only control may require retaining a second profile or redesigning the record-type experience.

## Source comparison

The source profiles have 1078 and 1074 positive grants across system, object, field, and record-type visibility dimensions; 1020 grants are common, 58 are Sales User-only, and 54 are Sales Head-only. The source audit records 163 active Sales User users and 20 active Sales Head users. Those counts do not establish which user should receive a group.

The baseline contains 47 system grants; 78 object permission flags across 26 objects; 890 field read/edit grants across 572 fields; and five visible record types. Sales User's delta contains four system grants, 11 object flags across two objects, and 43 field grants across 22 fields. Sales Head's delta contains six object flags across two objects and 48 field grants across 34 fields; it has no system grants unique to that profile. The CSV matrix gives the exact resource and permission for every row.

Sales User has broad profile-level grants, including View All/Modify All on `Sales_Campaign__c` and full CRUD on `Technical_Service_Request__c`; Sales Head has different grants on `Item_Request__c` and `Purchase_Request__c`. Review every delta, especially elevated grants, with the access owner before considering assignment.

## Important limits

- Permission Sets are additive. The baseline is built from the intersection; do not use a broad source profile as the base and expect a Permission Set to remove its excess grants.
- Layout/app settings are profile-level, not represented by Permission Sets. This POC does not recreate the 202 layout mappings, 30 app visibilities, or eight shared app action overrides in Salesforce metadata. See the parity CSV and preserve/update those separately.
- The current local profile XML does not include page-layout or app-override definitions. The POC is therefore an access-grant design draft, not a complete deployable package.
- Existing Permission Set and Permission Set Group assignments, role hierarchy, sharing, login/IP controls, and record access have not been computed as effective access.
- The organization has profile-name checks in Apex tests and the Project validation rule. Only the Project rule dependency is represented in this POC; other references need review.

## Files

Generated baseline: `access-review/sales-profile-poc/force-app/main/default/profiles/Sales_Profile_POC_Baseline.profile-meta.xml`. Grant matrix: `access-review/sales-profile-poc/Sales_User_Sales_Head_Grant_Matrix.csv`. UI parity inventory: `access-review/sales-profile-poc/Sales_User_Sales_Head_UI_Parity.csv`. Run `python3 scripts/build_sales_profile_poc.py` to regenerate this isolated draft.
