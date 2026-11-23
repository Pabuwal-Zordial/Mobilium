# Role Cleanup by Region: Project Manager Guide

For a hands-on implementation checklist written for junior admins and non-technical reviewers, see the [Word runbook](Role_Territory_Management_Implementation_Runbook.docx).

## Executive summary

The org has **120 roles** in the current MobiliumStaging snapshot. The sales branch is deep (up to **10 levels**) and many role names combine a region with a specialty, such as `Account Executive North America Risk` and `Specialist West Europe Roaming and Security`.

**Recommendation:** assess Salesforce Enterprise Territory Management (ETM) for the sales coverage model. Use a smaller role hierarchy for manager reporting and use territories to organize regional account, lead, and opportunity coverage. Do not activate ETM or retire roles until the business has approved the target access model and sandbox testing confirms the results. Keep Hubspot, Salesops, inactive-user handling, and non-sales roles out of the initial sales redesign unless their owners approve including them.

This is a proposal for review, not a deployment plan or a final target count. The inventory does not establish the business's official region definitions, ETM licensing/current status, or the access users must retain.

## Roles explained simply

- **Profile and permission set:** what a user can do (for example, read or edit an object or field).
- **Role:** which records a user may see based on their place in the role hierarchy and other sharing rules.
- **Territory:** which geographic or coverage-based sales records and users are grouped together. A user may be assigned to more than one territory.

These are different controls. A territory or role does not give object or field permissions. Record visibility can also come from organization-wide defaults, sharing rules, teams, ownership, and other access grants. Salesforce describes roles as record-level access and ETM as territory-based record access. [Salesforce access model](https://help.salesforce.com/s/articleView?id=platform.security_features_access.htm&language=en_US&type=5)

## Current hierarchy, read from the inventory

There are **three top-level roles**. `System Administrator` is the name of a role in this inventory; it does not mean that every user assigned to that role necessarily has the System Administrator profile.

```text
Hubspot                                      (separate root)
Mobileum Salesops Team Role                  (separate root)
System Administrator                        (main root)
└── Global ISS and IRS team
    └── World Wide Sales Executive
        └── World Wide Sales
            └── Global TDM
                └── Global TAM
                    ├── Americas General Manager
                    ├── Asia General Manager
                    ├── Europe General Manager
                    ├── Middle East and Africa General Manager
                    └── Account Executive WW
```

The regional branches continue beneath the general managers. For example, the inventory places Renewal Sales Manager North America and Senior Vice President South America under Americas General Manager; Renewal Sales Manager ASIA, Senior Vice President SEAO, and other roles under Asia General Manager; and East/West Europe leadership under Europe General Manager. These are **metadata parent links**, not proof of the approved company reporting structure. Some parent chains mix region and specialty, so business owners must confirm whether they are intentional.

`InActive User` is a separate child under the `System Administrator` role in the inventory. It has **193 inactive users and no active users**. Keep this and the two separate roots out of the sales redesign until their purpose and dependencies are confirmed.

## What ETM could change

ETM can move geographic sales coverage from many specialty-by-region role branches into a territory hierarchy. It is a good fit only if the business actually assigns accounts/leads/opportunities by territory. It will not automatically remove every role: keep role branches needed for manager visibility, approvals, reporting, or other processes. Also, users' role-based access is additive; ETM must not be used to assume a user will lose access granted by the role hierarchy.

### Illustrative future model (not yet approved)

**Role hierarchy — management visibility**

```text
Global Sales Leadership
├── North America Manager
│   └── North America Sales Users
├── Europe Manager
│   └── Europe Sales Users
├── Asia / Pacific Manager
│   └── Asia / Pacific Sales Users
└── Middle East & Africa Manager
    └── Middle East & Africa Sales Users
```

Each region is shown as a separate role branch to avoid placing regional managers above one shared sales-user role, which could give every manager visibility to every region's users' records. The final regions and manager layers must be decided by Mobileum. Current labels such as NASA, SEAO, Africa, East Europe, West Europe, and North America/South America do not form one unambiguous region list.

**Territory hierarchy — sales coverage**

```text
Global Sales Territory
├── Approved Region A
│   ├── Subregion or coverage area (only if needed)
│   └── Specialty coverage (only if needed)
└── Approved Region B
```

Territories can organize users and accounts by coverage. A specialist may be assigned to more than one territory if approved. Territory user roles (such as Sales Manager or Specialist) describe a user's function inside that territory; they are not Salesforce profiles or permission sets. Define assignment rules and verify parent/child assignment behavior: Salesforce does not automatically assign an account to a parent territory just because it matches a child territory.

## How the role count could come down

1. **Stop creating a role for each region × specialty × job title** unless it represents a distinct manager visibility boundary or a required process.
2. **Keep only role levels that are needed for management record visibility.** Candidate structure: one global sales leadership node plus separate manager and sales-user role branches for each approved region. Additional levels remain only where the business proves they are needed.
3. **Use ETM for geographic/matrix sales coverage** (including cross-region specialist coverage) where its access model satisfies the requirement. Use sharing rules, account/opportunity teams, or other approved sharing mechanisms for exceptions ETM does not cover cleanly.
4. **Review unused and inactive-only roles** after checking user records, sharing rules, groups, queues, approvals, forecasts, integrations, and automation. Do not delete solely based on zero active users.

The *illustrative* sales-role count formula is `1 global sales role + 2 roles per approved region + approved exceptions`. This is a planning aid, **not a committed target**. The final number depends on the approved region list, required manager layers, non-sales roles, existing sharing dependencies, and whether regional managers must be isolated from other regions. Compare the target against the current 120 total roles only after classifying each role as sales, non-sales, service/integration, or inactive-user support.

## Step-by-step project plan

| Phase | Work | Deliverable / exit check |
|---|---|---|
| 1. Confirm business design | Client confirms regions, managers, specialties, cross-region work, and who should see/edit which records. Check ETM edition/license and whether a territory model already exists. | Signed-off region and access requirements. |
| 2. Baseline and dependency audit | Refresh role/user inventory. Review sharing rules, groups, queues, territories, forecasts, approvals, and metadata references. | Role-to-user/dependency map; exceptions and data gaps listed. |
| 3. Design alternatives | Compare a role-only reduction with role-plus-ETM. Identify which role nodes remain, which access moves to territories, and which roles stay out of scope. | Before/after hierarchy diagrams and proposed count range. |
| 4. Sandbox prototype | Build a Planning territory model if ETM is available. Preview account assignments; test region managers, sales reps, specialists, and multi-region users. | Access test results show required records visible and restricted records hidden. |
| 5. Approve migration | Sales, Salesforce owner, and security/data owners approve mappings, user moves, dependencies, schedule, communications, and rollback. | Written sign-off and cutover/rollback plan. |
| 6. Implement in stages | Deploy only after approval. Reassign users and dependencies before retiring old roles; monitor sharing recalculations. | Reconciled users, working sharing, reports, forecasts, approvals, and integrations. |

Keep the territory model in **Planning** while designing and validating. Salesforce allows one active territory model at a time; activation makes its assignments operational and cannot be reverted to Planning. Confirm forecast impact before activation. [Territory models](https://help.salesforce.com/s/articleView?id=sf.tm2_territory_model.htm&language=en_US&type=5) · [Activate a territory model](https://help.salesforce.com/s/articleView?id=sales.tm2_activate_territory_model.htm&language=en_US&type=5)

## Decision needed from the client

Before setting the final role target, ask the client to approve:

1. The official region list and whether NASA, SEAO, Africa, Middle East, East/West Europe, and North/South America are regions, subregions, or business units.
2. Whether specialty teams (Risk, Testing, Roaming and Security, Engagement and Experience) serve one region or multiple regions.
3. Whether regional managers may see records across their region only, or also other regions.
4. Which records ETM must cover (accounts, leads, opportunities) and any requirements for contacts, cases, custom objects, forecasts, or approvals.
5. Whether ETM is licensed/enabled and whether territory forecasting is in use.

## Snapshot and references

Counts come from the read-only MobiliumStaging census retrieved **October 16, 2026**: 120 roles; 225 active users assigned a role; 953 active users with no role; 31 roles with no active or inactive users; 25 roles with only inactive users. Refresh before implementation. See [Main_Org_Role_Inventory.csv](Main_Org_Role_Inventory.csv) and [Main_Org_Profile_Role_Census.md](Main_Org_Profile_Role_Census.md).

Salesforce references: [Territory Management Best Practices](https://help.salesforce.com/s/articleView?id=000386766&language=en_US&type=1) · [Territory model concepts](https://help.salesforce.com/s/articleView?id=sf.tm2_territory_mgmt_concepts.htm&language=en_US&type=5) · [Territory model lifecycle](https://help.salesforce.com/s/articleView?id=sales.tm2_territory_model_state.htm&language=en_US&type=5)
