#!/usr/bin/env python3
"""Build local-only draft metadata for a shared profile plus persona deltas."""

import copy
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROFILE_DIR = ROOT / "force-app/main/default/profiles"
PS_DIR = ROOT / "force-app/main/default/permissionsets"
NS_URI = "http://soap.sforce.com/2006/04/metadata"
ET.register_namespace("", NS_URI)
NS = {"m": NS_URI}
SOURCES = ["Helpdesk", "Manager", "Front Desk Profile"]
PS_DEPENDENCY_PERMISSIONS = {"ViewRoles", "EditTask"}
BASE_NAME = "Shared_Access_Base_POC"
SIMPLE_DIMS = [
    ("userPermissions", "name", ["enabled"]),
    ("objectPermissions", "object", ["allowCreate", "allowRead", "allowEdit", "allowDelete", "viewAllRecords", "modifyAllRecords", "viewAllFields"]),
    ("fieldPermissions", "field", ["readable", "editable"]),
    ("classAccesses", "apexClass", ["enabled"]),
    ("pageAccesses", "apexPage", ["enabled"]),
    ("flowAccesses", "flow", ["enabled"]),
]
CONFIG_DIMS = [
    ("tabVisibilities", "tab", ["visibility"]),
    ("applicationVisibilities", "application", ["visible", "default"]),
    ("recordTypeVisibilities", "recordType", ["visible", "default"]),
]


def child_text(node, key, default=""):
    return node.findtext(f"m:{key}", default=default, namespaces=NS)


def read_profile(name):
    return ET.parse(PROFILE_DIR / f"{name}.profile-meta.xml").getroot()


def key_for(tag, node, keytag, prop):
    return (tag, child_text(node, keytag), prop)


def all_true_keys(root, dims):
    result = set()
    for tag, keytag, props in dims:
        for node in root.findall(f"m:{tag}", NS):
            for prop in props:
                if child_text(node, prop, "false").lower() == "true":
                    result.add(key_for(tag, node, keytag, prop))
    return result


def common_true_keys(roots):
    sets = [all_true_keys(root, SIMPLE_DIMS) for root in roots]
    common = set.intersection(*sets) if sets else set()
    # Salesforce validates dependent system permissions inside a Permission Set.
    # Keep ViewRoles in each persona set even though all source profiles enable it.
    # EditTask remains common in the base profile and is also copied into PSs for
    # ConvertLeads dependency validation.
    common.discard(("userPermissions", "ViewRoles", "enabled"))
    return common


def true_keys(root):
    return all_true_keys(root, SIMPLE_DIMS)


def config_maps(root):
    result = {}
    for tag, keytag, props in CONFIG_DIMS:
        for node in root.findall(f"m:{tag}", NS):
            for prop in props:
                val = child_text(node, prop)
                if val:
                    result[(tag, child_text(node, keytag), prop)] = val
    return result


def common_config(roots):
    maps = [config_maps(root) for root in roots]
    common = {}
    for tag, keytag, props in CONFIG_DIMS:
        resources = set.intersection(*[
            {key[1] for key in mapping if key[0] == tag} for mapping in maps
        ]) if maps else set()
        for resource in resources:
            values = {}
            matches = True
            for prop in props:
                key = (tag, resource, prop)
                candidates = [mapping.get(key, "") for mapping in maps]
                if not candidates[0] or len(set(candidates)) != 1:
                    matches = False
                    break
                values[key] = candidates[0]
            if matches:
                common.update(values)
    return common


def copy_node(root, tag, keytag, key):
    return next((node for node in root.findall(f"m:{tag}", NS) if child_text(node, keytag) == key), None)


def build_base(roots, common, common_ui):
    # Helpdesk is the explicit provisional source for page layout assignments.
    # Front Desk Profile contains the strictest observed login-hours restriction.
    base = ET.Element(f"{{{NS_URI}}}Profile")
    helpdesk = roots[0]
    frontdesk = roots[2]
    keep = {"custom", "userLicense", "layoutAssignments"}
    for child in helpdesk:
        tag = child.tag.split("}")[-1]
        if tag in keep:
            base.append(copy.deepcopy(child))
        elif tag in {d[0] for d in SIMPLE_DIMS}:
            _, keytag, props = next(d for d in SIMPLE_DIMS if d[0] == tag)
            ident = child_text(child, keytag)
            cloned = copy.deepcopy(child)
            has_grant = False
            for prop in props:
                common_grant = (tag, ident, prop) in common
                value = cloned.find(f"m:{prop}", NS)
                if value is not None:
                    value.text = "true" if common_grant else "false"
                has_grant = has_grant or common_grant
            if has_grant:
                base.append(cloned)
        elif tag in {d[0] for d in CONFIG_DIMS}:
            _, keytag, props = next(d for d in CONFIG_DIMS if d[0] == tag)
            ident = child_text(child, keytag)
            cloned = copy.deepcopy(child)
            valid = True
            for prop in props:
                original = child_text(child, prop)
                agreed = common_ui.get((tag, ident, prop))
                if original and original != agreed:
                    valid = False
                    break
            if valid and any((tag, ident, prop) in common_ui for prop in props):
                base.append(cloned)
    login_hours = frontdesk.find("m:loginHours", NS)
    if login_hours is not None:
        base.append(copy.deepcopy(login_hours))
    order = {tag: i for i, tag in enumerate([
        "applicationVisibilities", "classAccesses", "custom", "fieldPermissions",
        "layoutAssignments", "loginHours", "objectPermissions", "pageAccesses",
        "recordTypeVisibilities", "tabVisibilities", "userLicense", "userPermissions",
    ])}
    children = sorted(list(base), key=lambda e: (order.get(e.tag.split("}")[-1], 99), ET.tostring(e, encoding="unicode").casefold()))
    base[:] = children
    return base


def make_ps(name, source_root, common, common_ui):
    root = ET.Element(f"{{{NS_URI}}}PermissionSet")
    grants = true_keys(source_root) - common
    for permission in PS_DEPENDENCY_PERMISSIONS:
        if ("userPermissions", permission, "enabled") in true_keys(source_root):
            grants.add(("userPermissions", permission, "enabled"))
    for tag, keytag, props in SIMPLE_DIMS:
        nodes = {}
        for node in source_root.findall(f"m:{tag}", NS):
            ident = child_text(node, keytag)
            enabled_props = [p for p in props if (tag, ident, p) in grants]
            if not enabled_props:
                continue
            clone = copy.deepcopy(node)
            for prop in props:
                element = clone.find(f"m:{prop}", NS)
                if element is not None:
                    element.text = "true" if prop in enabled_props else "false"
            nodes[ident] = clone
        # Salesforce requires these object grants in the same Permission Set
        # as ConvertLeads. They were not present in the retrieved source profiles;
        # the business owner explicitly approved adding the minimum CRUD required.
        if tag == "objectPermissions" and ("userPermissions", "ConvertLeads", "enabled") in true_keys(source_root):
            required = {
                "Account": {"allowCreate", "allowRead", "allowEdit"},
                "Contact": {"allowCreate", "allowRead", "allowEdit"},
                "Lead": {"allowRead", "allowEdit"},
            }
            for object_name, allowed in required.items():
                node = nodes.get(object_name)
                if node is None:
                    node = ET.Element(f"{{{NS_URI}}}objectPermissions")
                    ET.SubElement(node, f"{{{NS_URI}}}object").text = object_name
                for prop in props:
                    element = node.find(f"m:{prop}", NS)
                    if element is None:
                        element = ET.SubElement(node, f"{{{NS_URI}}}{prop}")
                    element.text = "true" if prop in allowed else "false"
                nodes[object_name] = node
        for ident in sorted(nodes, key=str.casefold):
            root.append(nodes[ident])

    for node in source_root.findall("m:applicationVisibilities", NS):
        app = child_text(node, "application")
        # Permission Sets can grant app visibility but cannot carry profile defaults.
        if child_text(node, "visible").lower() == "true" and common_ui.get(("applicationVisibilities", app, "visible")) != "true":
            grant = ET.Element(f"{{{NS_URI}}}applicationVisibilities")
            ET.SubElement(grant, f"{{{NS_URI}}}application").text = app
            ET.SubElement(grant, f"{{{NS_URI}}}visible").text = "true"
            root.append(grant)

    for node in source_root.findall("m:recordTypeVisibilities", NS):
        record_type = child_text(node, "recordType")
        if child_text(node, "visible").lower() == "true" and common_ui.get(("recordTypeVisibilities", record_type, "visible")) != "true":
            grant = ET.Element(f"{{{NS_URI}}}recordTypeVisibilities")
            ET.SubElement(grant, f"{{{NS_URI}}}recordType").text = record_type
            ET.SubElement(grant, f"{{{NS_URI}}}visible").text = "true"
            root.append(grant)

    for node in source_root.findall("m:tabVisibilities", NS):
        tab = child_text(node, "tab")
        visibility = child_text(node, "visibility")
        if visibility == "DefaultOn" and common_ui.get(("tabVisibilities", tab, "visibility")) != "DefaultOn":
            output_visibility = "Visible"
        elif visibility == "DefaultOff" and common_ui.get(("tabVisibilities", tab, "visibility")) != "DefaultOff":
            output_visibility = "Available"
        else:
            continue
        grant = ET.Element(f"{{{NS_URI}}}tabSettings")
        ET.SubElement(grant, f"{{{NS_URI}}}tab").text = tab
        ET.SubElement(grant, f"{{{NS_URI}}}visibility").text = output_visibility
        root.append(grant)

    ET.SubElement(root, f"{{{NS_URI}}}hasActivationRequired").text = "false"
    label = name.replace("_", " ")
    ET.SubElement(root, f"{{{NS_URI}}}label").text = label
    order = {tag: i for i, tag in enumerate([
        "applicationVisibilities", "classAccesses", "fieldPermissions",
        "flowAccesses", "hasActivationRequired", "label", "objectPermissions",
        "pageAccesses", "recordTypeVisibilities", "tabSettings", "userPermissions",
    ])}
    root[:] = sorted(list(root), key=lambda e: (order.get(e.tag.split("}")[-1], 99), ET.tostring(e, encoding="unicode").casefold()))
    return root


def write_xml(path, root):
    ET.indent(root, space="    ")
    path.write_bytes(ET.tostring(root, encoding="utf-8", xml_declaration=True) + b"\n")


def main():
    roots = [read_profile(name) for name in SOURCES]
    common = common_true_keys(roots)
    common_ui = common_config(roots)
    base = build_base(roots, common, common_ui)
    base_path = PROFILE_DIR / f"{BASE_NAME}.profile-meta.xml"
    write_xml(base_path, base)

    mapping = {
        "Helpdesk": "Helpdesk_Access_Delta_POC",
        "Manager": "Manager_Access_Delta_POC",
        "Front Desk Profile": "Front_Desk_Access_Delta_POC",
    }
    ps_counts = {}
    for source in SOURCES:
        ps_name = mapping[source]
        ps = make_ps(ps_name, read_profile(source), common, common_ui)
        ps_path = PS_DIR / f"{ps_name}.permissionset-meta.xml"
        write_xml(ps_path, ps)
        ps_counts[source] = len(list(ps)) - 2

    print(f"Wrote shared base profile with {len(common)} common positive grants and {len(base.findall('m:layoutAssignments', NS))} provisional Helpdesk layouts: {base_path}")
    for source, count in ps_counts.items():
        print(f"Wrote {mapping[source]} for {source} deltas ({count} metadata rows)")


if __name__ == "__main__":
    main()
