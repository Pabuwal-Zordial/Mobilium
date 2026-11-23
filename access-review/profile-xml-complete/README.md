# Complete Profile Metadata Export

Retrieved from the `MobiliumStaging` org on 2026-10-19. This is a read-only metadata export; nothing was deployed.

## Profile files

The 17 profile XML files are in [`retrieved/profiles/`](retrieved/profiles/). The set contains the 16 requested business profiles plus System Administrator, whose Salesforce metadata name is `Admin`. The long marketing profile filename is URL-encoded by Salesforce CLI (`%2C` represents a comma).

The profile XMLs include the profile-level user/system permissions, object permissions, field-level security, Apex class and Visualforce page access, tab and application visibility, record-type visibility, and layout assignments returned for the retrieved metadata set.

## Supporting metadata

The other folders under `retrieved/` contain metadata included to let Salesforce return profile grants against their referenced components: Apex classes, Visualforce pages, flows, objects (including fields and object child metadata), tabs, applications, layouts, custom metadata, and custom permissions. Keep these files as audit/reference material; the requested profile files are the contents of `retrieved/profiles/`.

`package.xml` records the retrieve scope. The export contains 6,374 files (about 43 MB), so review or share only the profile folder when the supporting metadata is not needed.
