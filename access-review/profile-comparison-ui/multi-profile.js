(() => {
  "use strict";

  const PAGE_SIZE = 100;
  const MAX_PROFILES = 18;
  const MAX_FILE_BYTES = 25 * 1024 * 1024;
  const NS = "http://soap.sforce.com/2006/04/metadata";
  const PORTABLE = new Set([
    "System permission", "Object permission", "Field access", "Apex class access",
    "Visualforce page access", "Custom permission", "Custom metadata access",
    "Custom setting access", "External data source access", "Flow access",
    "Record type access", "Application visibility"
  ]);
  const HIGH_IMPACT = [
    "ModifyAllData", "ViewAllData", "ManageUsers", "CustomizeApplication", "AuthorApex",
    "ModifyMetadata", "ManageProfilesPermissionsets", "ManageIpAddresses",
    "ManagePasswordPolicies", "ViewAllRecords", "ModifyAllRecords", "ViewSetup", "ApiEnabled"
  ];
  const SENSITIVE = /ssn|social.?security|tax.?id|bank|salary|compensation|date.?of.?birth|birth.?date|credit.?card|card.?number|password|secret|token|national.?id|passport/i;
  const state = { files: [], profiles: [], clusters: [], rows: [], filtered: [], page: 0, proposals: null };
  const $ = (id) => document.getElementById(id);
  const ui = {
    files: $("profile-files"), drop: $("drop-zone"), fileList: $("file-list"), message: $("input-message"), analyze: $("analyze-button"),
    threshold: $("similarity-threshold"), thresholdValue: $("threshold-value"), sameSettings: $("require-profile-settings"),
    results: $("results"), warnings: $("warning-box"), summary: $("summary"), clusters: $("clusters"),
    includeRisk: $("include-high-impact"), downloadXml: $("download-xml"), xmlSummary: $("xml-summary"), candidates: $("candidate-table-wrap"),
    view: $("view-filter"), category: $("category-filter"), search: $("search-input"), table: $("comparison-table"),
    resultCount: $("result-count"), prev: $("prev-page"), next: $("next-page"), page: $("page-label"), downloadCsv: $("download-csv")
  };

  function message(text, error = false) { ui.message.textContent = text; ui.message.classList.toggle("error", error); }
  function child(node, name) { return Array.from(node.children).find((x) => x.localName === name); }
  function leaf(node, name) { return child(node, name)?.textContent.trim() || ""; }
  function descendants(node, name) { return Array.from(node.children).filter((x) => x.localName === name); }
  function bool(value) { if (/^true$/i.test(value)) return true; if (/^false$/i.test(value)) return false; return null; }
  function pretty(value) { return value.replace(/(?<=[a-z0-9])(?=[A-Z])/g, " ").replace(/__c$/i, " (custom)"); }
  function uniqueKey(category, member, property) { return `${category}\u0000${member}\u0000${property}`; }
  function isHigh(category, member, property) {
    if (HIGH_IMPACT.some((name) => member.toLowerCase().includes(name.toLowerCase()))) return true;
    return category === "Object permission" && ["View All records", "Modify All records"].includes(property);
  }
  function profileOnlyValue(node) {
    return Array.from(node.children).map((x) => `${x.localName}=${x.textContent.trim()}`).sort().join("; ") || node.textContent.trim() || "Present";
  }

  function parseProfile(xml, fileName) {
    if (/<!DOCTYPE|<!ENTITY/i.test(xml)) throw new Error(`${fileName}: DTD/entity declarations are not accepted.`);
    const doc = new DOMParser().parseFromString(xml, "application/xml");
    if (doc.querySelector("parsererror")) throw new Error(`${fileName}: invalid XML; use a complete Salesforce Profile XML file.`);
    const root = doc.documentElement;
    if (!root || root.localName !== "Profile") throw new Error(`${fileName}: XML root must be <Profile>.`);
    const profile = {
      name: leaf(root, "fullName") || fileName.replace(/\.profile-meta\.xml$/i, "").replace(/\.xml$/i, ""),
      license: leaf(root, "userLicense") || "Not specified in XML",
      custom: leaf(root, "custom").toLowerCase() === "true",
      permissions: new Map(), settings: new Map(), sourceFile: fileName
    };
    const add = (category, member, property, value, grant, movable = true, apiName = member, risk = "") => {
      const key = uniqueKey(category, member, property);
      profile.permissions.set(key, { key, category, member, property, value, grant, movable, apiName, risk: risk || (isHigh(category, apiName, property) ? "High-impact review" : "") });
    };
    const settingTags = new Set(["layoutAssignments", "loginHours", "loginIpRanges", "passwordPolicies", "sessionSettings"]);
    const recognized = new Set(["fullName", "userLicense", "custom", "description", "userPermissions", "objectPermissions", "fieldPermissions", "classAccesses", "pageAccesses", "flowAccesses", "recordTypeVisibilities", "tabVisibilities", "applicationVisibilities", "customPermissions", "customMetadataTypeAccesses", "customSettingAccesses", "externalDataSourceAccesses", ...settingTags]);

    for (const node of Array.from(root.children)) {
      const tag = node.localName;
      if (tag === "fullName" || tag === "userLicense" || tag === "custom" || tag === "description") continue;
      if (settingTags.has(tag) || !recognized.has(tag)) {
        const value = profileOnlyValue(node);
        const name = tag === "layoutAssignments" ? `Layout: ${leaf(node, "layout") || "Not specified"}${leaf(node, "recordType") ? ` (${leaf(node, "recordType")})` : ""}` : pretty(tag);
        profile.settings.set(`${tag}\u0000${name}`, value);
        continue;
      }
      if (tag === "userPermissions") {
        const name = leaf(node, "name"); const enabled = bool(leaf(node, "enabled"));
        if (name) add("System permission", pretty(name), "Enabled", enabled ?? leaf(node, "enabled"), enabled, true, name);
      } else if (tag === "objectPermissions") {
        const objectName = leaf(node, "object");
        for (const [xmlName, label] of [["allowRead", "Read"], ["allowCreate", "Create"], ["allowEdit", "Edit"], ["allowDelete", "Delete"], ["viewAllRecords", "View All records"], ["modifyAllRecords", "Modify All records"]]) {
          const raw = leaf(node, xmlName); if (raw === "") continue;
          const value = bool(raw); add("Object permission", objectName || "Object not named", label, value ?? raw, value);
        }
      } else if (tag === "fieldPermissions") {
        const field = leaf(node, "field");
        for (const [xmlName, label] of [["readable", "Can view"], ["editable", "Can edit"]]) {
          const raw = leaf(node, xmlName); if (raw === "") continue;
          const value = bool(raw); const risk = value && SENSITIVE.test(field) ? "Sensitive field review" : "";
          add("Field access", field || "Field not named", label, value ?? raw, value, true, field, risk);
        }
      } else if (tag === "classAccesses" || tag === "pageAccesses" || tag === "flowAccesses") {
        const kind = tag === "classAccesses" ? ["Apex class access", "apexClass"] : tag === "pageAccesses" ? ["Visualforce page access", "apexPage"] : ["Flow access", "flow"];
        const name = leaf(node, kind[1]); const enabled = bool(leaf(node, "enabled"));
        add(kind[0], name || "Component not named", "Enabled", enabled ?? leaf(node, "enabled"), enabled);
      } else if (["customPermissions", "customMetadataTypeAccesses", "customSettingAccesses", "externalDataSourceAccesses"].includes(tag)) {
        const kind = { customPermissions: ["Custom permission", "name"], customMetadataTypeAccesses: ["Custom metadata access", "name"], customSettingAccesses: ["Custom setting access", "name"], externalDataSourceAccesses: ["External data source access", "externalDataSource"] }[tag];
        const name = leaf(node, kind[1]) || leaf(node, "customPermission"); const enabled = bool(leaf(node, "enabled"));
        if (name) add(kind[0], name, "Enabled", enabled ?? leaf(node, "enabled"), enabled);
      } else if (tag === "tabVisibilities") {
        const tab = leaf(node, "tab"); const visibility = leaf(node, "visibility");
        const grant = ["DefaultOn", "DefaultOff", "Available"].includes(visibility) ? true : visibility === "Hidden" ? false : null;
        add("Tab visibility", tab || "Tab not named", "Visibility", visibility || "Not specified", grant, false);
        profile.settings.set(`tabVisibility\u0000${tab}`, visibility || "Not specified");
      } else if (tag === "applicationVisibilities") {
        const app = leaf(node, "application"); const visible = bool(leaf(node, "visible"));
        add("Application visibility", app || "App not named", "Visible", visible ?? leaf(node, "visible"), visible);
        profile.settings.set(`applicationVisibility\u0000${app}`, String(visible));
        const defaultValue = bool(leaf(node, "default"));
        if (defaultValue !== null) profile.settings.set(`applicationDefault\u0000${app}`, String(defaultValue));
      } else if (tag === "recordTypeVisibilities") {
        const recordType = leaf(node, "recordType"); const visible = bool(leaf(node, "visible"));
        add("Record type access", recordType || "Record type not named", "Available", visible ?? leaf(node, "visible"), visible);
        const defaultValue = bool(leaf(node, "default"));
        if (defaultValue !== null) profile.settings.set(`recordTypeDefault\u0000${recordType}`, String(defaultValue));
      }
    }
    if (!profile.name) throw new Error(`${fileName}: profile name could not be read.`);
    return profile;
  }

  function grantedKeys(profile) { return new Set([...profile.permissions].filter(([, x]) => x.grant === true).map(([key]) => key)); }
  function similarity(a, b) {
    const aa = grantedKeys(a); const bb = grantedKeys(b);
    const union = new Set([...aa, ...bb]); if (!union.size) return 100;
    let intersection = 0; for (const x of aa) if (bb.has(x)) intersection++;
    return Math.round(intersection / union.size * 100);
  }
  function compatible(a, b) { return a.custom && b.custom && a.license !== "Not specified in XML" && a.license === b.license; }
  function sameProfileSettings(a, b) {
    const keys = new Set([...a.settings.keys(), ...b.settings.keys()]);
    for (const key of keys) if (a.settings.get(key) !== b.settings.get(key)) return false;
    return true;
  }
  function pairCanGroup(a, b, threshold, requireSettings) {
    return compatible(a, b) && similarity(a, b) >= threshold && (!requireSettings || sameProfileSettings(a, b));
  }

  // Complete-link grouping avoids chaining a weakly related profile into a cluster.
  function makeClusters(profiles, threshold, requireSettings) {
    const unassigned = new Set(profiles); const clusters = [];
    while (unassigned.size) {
      const candidates = [...unassigned].map((p) => ({ profile: p, degree: [...unassigned].filter((q) => q !== p && pairCanGroup(p, q, threshold, requireSettings)).length }))
        .sort((a, b) => b.degree - a.degree || a.profile.name.localeCompare(b.profile.name));
      const seed = candidates[0].profile; const group = [seed]; unassigned.delete(seed);
      let changed = true;
      while (changed) {
        changed = false;
        const next = [...unassigned].map((p) => ({ profile: p, min: Math.min(...group.map((g) => similarity(p, g))) }))
          .sort((a, b) => b.min - a.min || a.profile.name.localeCompare(b.profile.name));
        for (const item of next) {
          if (group.every((g) => pairCanGroup(item.profile, g, threshold, requireSettings))) {
            group.push(item.profile); unassigned.delete(item.profile); changed = true;
          }
        }
      }
      group.sort((a, b) => a.name.localeCompare(b.name));
      const allKeys = new Set(group.flatMap((p) => [...p.permissions.keys()]));
      const common = new Set([...allKeys].filter((key) => group.every((p) => p.permissions.get(key)?.grant === true)));
      const minSimilarity = group.length > 1 ? Math.min(...group.flatMap((a, i) => group.slice(i + 1).map((b) => similarity(a, b)))) : null;
      const settingsMatch = group.every((p) => sameProfileSettings(group[0], p));
      clusters.push({ profiles: group, common, minSimilarity, settingsMatch });
    }
    return clusters.sort((a, b) => b.profiles.length - a.profiles.length || a.profiles[0].name.localeCompare(b.profiles[0].name));
  }

  function flattenRows(profiles) {
    const keys = new Set(profiles.flatMap((p) => [...p.permissions.keys()]));
    const rows = [];
    for (const key of keys) {
      const sample = profiles.map((p) => p.permissions.get(key)).find(Boolean);
      const items = profiles.map((p) => p.permissions.get(key));
      const grants = items.map((x) => x?.grant);
      const positive = grants.filter((x) => x === true).length;
      const negative = grants.filter((x) => x === false).length;
      const conflict = positive > 0 && negative > 0;
      const allPositive = positive === profiles.length;
      const values = items.map((x) => x ? String(x.value) : "Not specified in XML");
      const valuesDiffer = new Set(values).size > 1;
      const status = conflict ? "conflict" : valuesDiffer && allPositive ? "conflict" : allPositive ? "shared" : positive ? "difference" : valuesDiffer ? "conflict" : "other";
      rows.push({ key, category: sample.category, label: sample.property ? `${sample.member} — ${sample.property}` : sample.member, items, values, status, risk: sample.risk || "" });
    }
    return rows.sort((a, b) => a.category.localeCompare(b.category) || a.label.localeCompare(b.label));
  }

  function hash(text) {
    let h = 2166136261;
    for (let i = 0; i < text.length; i++) { h ^= text.charCodeAt(i); h = Math.imul(h, 16777619); }
    return (h >>> 0).toString(36).toUpperCase();
  }
  function apiPart(text) {
    let x = text.normalize("NFKD").replace(/[^A-Za-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
    if (!x || /^\d/.test(x)) x = `Access_${x}`;
    return x;
  }
  function moduleApi(category, signature) { return `PC_${apiPart(category).slice(0, 16)}_${hash(signature)}`.slice(0, 40); }
  function profilePart(name) { return apiPart(name).slice(0, 22); }
  function xmlEscape(value) { return String(value ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&apos;"); }
  function tag(name, value) { return `<${name}>${xmlEscape(value)}</${name}>`; }

  function candidatesFor(clusters, includeHighImpact) {
    const modules = new Map(); const profileModules = new Map(); const profileDeltaCounts = new Map();
    for (const cluster of clusters.filter((x) => x.profiles.length > 1)) {
      for (const profile of cluster.profiles) {
        const allDelta = [...profile.permissions.values()].filter((x) => x.grant === true && !cluster.common.has(x.key));
        profileDeltaCounts.set(profile, allDelta.length);
        const usable = allDelta.filter((x) => x.movable && PORTABLE.has(x.category));
        const accepted = includeHighImpact ? usable : usable.filter((x) => !x.risk);
        const grouped = new Map();
        for (const item of accepted) {
          if (item.category === "Tab visibility") continue; // DefaultOn/DefaultOff cannot be safely flattened into Permission Set tab visibility.
          if (!grouped.has(item.category)) grouped.set(item.category, []);
          grouped.get(item.category).push(item);
        }
        const profileSet = [];
        for (const [category, entries] of grouped) {
          entries.sort((a, b) => a.key.localeCompare(b.key));
          const signature = entries.map((x) => `${x.key}=${x.value}`).join("\n");
          const key = `${category}\u0000${signature}`;
          if (!modules.has(key)) {
            const api = moduleApi(category, signature);
            modules.set(key, { api, category, entries, signature, profiles: [], label: `Draft ${category} Access`.slice(0, 80) });
          }
          const module = modules.get(key); if (!module.profiles.includes(profile)) module.profiles.push(profile);
          profileSet.push(module);
        }
        profileModules.set(profile, profileSet.sort((a, b) => a.api.localeCompare(b.api)));
      }
    }
    // Bundle only stable-looking cohorts with multiple reusable sets; a one-set PSG adds no value.
    const bundles = new Map();
    for (const [profile, sets] of profileModules) {
      if (sets.length < 2) continue;
      const signature = sets.map((x) => x.api).join("|");
      if (!bundles.has(signature)) bundles.set(signature, { api: `PCG_${profilePart(profile.name)}_${hash(signature)}`.slice(0, 40), label: `Draft ${profile.name} Access`.slice(0, 80), sets, profiles: [] });
      bundles.get(signature).profiles.push(profile);
    }
    return { modules: [...modules.values()], profileModules, profileDeltaCounts, bundles: [...bundles.values()] };
  }

  function metadataForModule(module) {
    const tags = new Map();
    const push = (tagName, content) => { if (!tags.has(tagName)) tags.set(tagName, []); tags.get(tagName).push(content); };
    const objects = new Map(); const fields = new Map();
    for (const item of module.entries) {
      if (item.category === "System permission") push("userPermissions", `<enabled>true</enabled>${tag("name", item.apiName)}`);
      else if (item.category === "Object permission") {
        if (!objects.has(item.member)) objects.set(item.member, {});
        const names = { Read: "allowRead", Create: "allowCreate", Edit: "allowEdit", Delete: "allowDelete", "View All records": "viewAllRecords", "Modify All records": "modifyAllRecords" };
        objects.get(item.member)[names[item.property]] = "true";
      } else if (item.category === "Field access") {
        if (!fields.has(item.member)) fields.set(item.member, {});
        fields.get(item.member)[item.property === "Can view" ? "readable" : "editable"] = "true";
        if (item.property === "Can edit") fields.get(item.member).readable = "true";
      } else if (item.category === "Apex class access") push("classAccesses", `${tag("apexClass", item.apiName)}<enabled>true</enabled>`);
      else if (item.category === "Visualforce page access") push("pageAccesses", `${tag("apexPage", item.apiName)}<enabled>true</enabled>`);
      else if (item.category === "Flow access") push("flowAccesses", `<enabled>true</enabled>${tag("flow", item.apiName)}`);
      else if (item.category === "Custom permission") push("customPermissions", `<enabled>true</enabled>${tag("name", item.apiName)}`);
      else if (item.category === "Custom metadata access") push("customMetadataTypeAccesses", `<enabled>true</enabled>${tag("name", item.apiName)}`);
      else if (item.category === "Custom setting access") push("customSettingAccesses", `<enabled>true</enabled>${tag("name", item.apiName)}`);
      else if (item.category === "External data source access") push("externalDataSourceAccesses", `${tag("externalDataSource", item.apiName)}<enabled>true</enabled>`);
      else if (item.category === "Application visibility") push("applicationVisibilities", `${tag("application", item.apiName)}<default>false</default><visible>true</visible>`);
      else if (item.category === "Record type access") push("recordTypeVisibilities", `<default>false</default>${tag("recordType", item.apiName)}<visible>true</visible>`);
    }
    for (const [name, values] of objects) {
      const order = ["allowCreate", "allowDelete", "allowEdit", "allowRead", "modifyAllRecords", "object", "viewAllRecords"];
      const obj = { ...values, object: name };
      push("objectPermissions", order.filter((k) => obj[k] !== undefined).map((k) => tag(k, obj[k])).join(""));
    }
    for (const [name, values] of fields) {
      const obj = { ...values, field: name };
      push("fieldPermissions", ["editable", "field", "readable"].filter((k) => obj[k] !== undefined).map((k) => tag(k, obj[k])).join(""));
    }
    const order = ["applicationVisibilities", "classAccesses", "customMetadataTypeAccesses", "customPermissions", "customSettingAccesses", "externalDataSourceAccesses", "fieldPermissions", "flowAccesses", "hasActivationRequired", "label", "objectPermissions", "pageAccesses", "recordTypeVisibilities", "userPermissions"];
    tags.set("hasActivationRequired", ["false"]);
    tags.set("label", [xmlEscape(module.label)]);
    const body = order.flatMap((name) => (tags.get(name) || []).sort().map((content) => `<${name}>${content}</${name}>`)).join("\n    ");
    return `<?xml version="1.0" encoding="UTF-8"?>\n<PermissionSet xmlns="${NS}">\n    ${body}\n</PermissionSet>\n`;
  }

  function metadataForGroup(group) {
    return `<?xml version="1.0" encoding="UTF-8"?>\n<PermissionSetGroup xmlns="${NS}">\n    <description>Draft candidate bundle generated from supplied profile XML. Review persona membership and assignments before use.</description>\n    <hasActivationRequired>false</hasActivationRequired>\n    <label>${xmlEscape(group.label)}</label>\n    ${group.sets.map((x) => `<permissionSets>${xmlEscape(x.api)}</permissionSets>`).join("\n    ")}\n    <status>Updated</status>\n</PermissionSetGroup>\n`;
  }

  function makeReadme(proposals, clusters, includeRisk) {
    const profileMap = [...proposals.profileModules.entries()].map(([p, sets]) => `- ${p.name}: ${sets.length ? sets.map((x) => x.api).join(", ") : "no generated delta set"}; ${proposals.bundles.find((b) => b.profiles.includes(p))?.api || "no PSG candidate"}`).join("\n");
    const omitted = [...proposals.profileDeltaCounts.entries()].reduce((sum, [p, n]) => {
      const acceptedCount = (proposals.profileModules.get(p) || []).flatMap((x) => x.entries).length; return sum + Math.max(0, n - acceptedCount);
    }, 0);
    return `# Draft Profile Comparison Metadata\n\nGenerated locally from supplied Profile XML. No org connection or deployment was performed.\n\n## Contents\n- ${proposals.modules.length} candidate Permission Set XML files, grouped by category and exact matching delta signature.\n- ${proposals.bundles.length} optional Permission Set Group XML files. A PSG is generated only for a cohort with at least two candidate Permission Sets.\n- No merged Profile, package.xml, destructive changes, user assignments, or deployment instructions are included.\n\n## Source and model\n- Profiles analyzed: ${state.profiles.length}.\n- Same-license custom profiles only are eligible for automatic clustering.\n- The shared positive grants are a suggested baseline; they are not emitted as a Profile XML.\n- Unique positive portable grants are draft Permission Set candidates. Tabs and profile-only settings are not generated as Permission Set grants.\n- Permission Sets only add access; they cannot enforce denials.\n- High-impact grants ${includeRisk ? "were included by user selection and require explicit review" : "were excluded from XML by default"}. Potentially omitted delta entries: ${omitted}.\n\n## Candidate mapping by source profile\n${profileMap}\n\n## Required review before use\n1. Confirm the source XML files are complete and current, and verify each profile license and user mapping.\n2. Review every object, field, system, component, app, and record-type grant. Review high-impact and sensitive-field access individually.\n3. Resolve layout, tab, app-default, login-hours, IP-range, and other profile-only differences outside these Permission Sets.\n4. Confirm the proposed user personas and PSG bundles with business and security owners. XML alone cannot establish who should receive a set.\n5. Check generated API names against existing org metadata and adjust collisions. Validate metadata with Salesforce CLI and test effective access in a sandbox before any deployment.\n6. Review actual assignments, existing PS/PSG memberships, roles, sharing, territories, and automation dependencies; these inputs were not part of this XML comparison.\n`;
  }

  // Minimal ZIP writer using uncompressed entries, so the tool needs no network or library.
  function makeZip(files) {
    const enc = new TextEncoder(); const entries = []; const crcTable = new Uint32Array(256);
    for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; crcTable[n] = c >>> 0; }
    const crc = (data) => { let c = 0xffffffff; for (const b of data) c = crcTable[(c ^ b) & 0xff] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
    const u16 = (v) => [v & 255, (v >>> 8) & 255]; const u32 = (v) => [...u16(v & 0xffff), ...u16((v >>> 16) & 0xffff)];
    for (const file of files) {
      const name = enc.encode(file.name); const data = enc.encode(file.data); const checksum = crc(data); const offset = entries.reduce((sum, x) => sum + x.local.length, 0);
      const local = new Uint8Array([...u32(0x04034b50), ...u16(20), ...u16(0x0800), ...u16(0), ...u16(0), ...u16(0), ...u32(checksum), ...u32(data.length), ...u32(data.length), ...u16(name.length), ...u16(0), ...name, ...data]);
      const central = new Uint8Array([...u32(0x02014b50), ...u16(20), ...u16(20), ...u16(0x0800), ...u16(0), ...u16(0), ...u16(0), ...u32(checksum), ...u32(data.length), ...u32(data.length), ...u16(name.length), ...u16(0), ...u16(0), ...u16(0), ...u16(0), ...u32(0), ...u32(offset), ...name]);
      entries.push({ local, central });
    }
    const locals = entries.map((x) => x.local); const centrals = entries.map((x) => x.central); const centralBytes = centrals.reduce((n, x) => n + x.length, 0); const localBytes = locals.reduce((n, x) => n + x.length, 0);
    const end = new Uint8Array([...u32(0x06054b50), ...u16(0), ...u16(0), ...u16(entries.length), ...u16(entries.length), ...u32(centralBytes), ...u32(localBytes), ...u16(0)]);
    return new Blob([...locals, ...centrals, end], { type: "application/zip" });
  }
  function downloadBlob(blob, filename) {
    const link = document.createElement("a"); const url = URL.createObjectURL(blob); link.href = url; link.download = filename; document.body.append(link); link.click(); link.remove(); setTimeout(() => URL.revokeObjectURL(url), 1500);
  }

  function renderFiles() {
    ui.fileList.replaceChildren();
    if (!state.files.length) { const p = document.createElement("p"); p.className = "muted"; p.textContent = "No files selected."; ui.fileList.append(p); }
    if (state.files.length) {
      const head = document.createElement("div"); head.className = "file-list-head";
      const count = document.createElement("strong"); count.textContent = `${state.files.length} profile${state.files.length === 1 ? "" : "s"} selected`; head.append(count);
      const clear = document.createElement("button"); clear.type = "button"; clear.className = "text-button"; clear.textContent = "Remove all";
      clear.addEventListener("click", () => { state.files = []; renderFiles(); }); head.append(clear); ui.fileList.append(head);
    }
    state.files.forEach((file, index) => {
      const chip = document.createElement("span"); chip.className = "file-chip";
      const label = document.createElement("span"); label.textContent = file.name; chip.append(label);
      const remove = document.createElement("button"); remove.type = "button"; remove.textContent = "×"; remove.setAttribute("aria-label", `Remove ${file.name}`);
      remove.addEventListener("click", () => { state.files.splice(index, 1); renderFiles(); }); chip.append(remove); ui.fileList.append(chip);
    });
    ui.analyze.disabled = state.files.length < 2 || state.files.length > MAX_PROFILES;
    message(state.files.length < 2 ? "Select at least 2 profile XML files." : state.files.length > MAX_PROFILES ? `Select no more than ${MAX_PROFILES} files.` : "Ready to compare.");
  }
  function addFiles(list) {
    const incoming = [...list];
    if (state.files.length + incoming.length > MAX_PROFILES) { message(`The limit is ${MAX_PROFILES} profiles. Remove files or select fewer.`, true); return; }
    for (const f of incoming) {
      if (f.size > MAX_FILE_BYTES) { message(`${f.name} is over 25 MB and was not added.`, true); continue; }
      if (!/\.xml$/i.test(f.name) && !/xml/i.test(f.type)) { message(`${f.name} is not an XML file.`, true); continue; }
      if (!state.files.some((x) => x.name === f.name && x.size === f.size && x.lastModified === f.lastModified)) state.files.push(f);
    }
    renderFiles();
  }

  function renderSummary() {
    const counts = [
      ["Profiles analyzed", state.profiles.length, "XML files parsed successfully"],
      ["Candidate groups", state.clusters.filter((x) => x.profiles.length > 1).length, "Access-based groups with 2+ profiles"],
      ["Standalone profiles", state.clusters.filter((x) => x.profiles.length === 1).length, "No compatible group met the selected threshold"],
      ["Draft Permission Sets", state.proposals.modules.length, "Category deltas; review before use"]
    ];
    ui.summary.replaceChildren();
    for (const [label, value, detail] of counts) {
      const card = document.createElement("article"); card.className = "summary-card";
      for (const [cls, text] of [["label", label], ["value", value], ["detail", detail]]) { const div = document.createElement("div"); div.className = cls; div.textContent = String(text); card.append(div); }
      ui.summary.append(card);
    }
  }
  function renderClusters() {
    ui.clusters.replaceChildren();
    state.clusters.forEach((cluster, index) => {
      const card = document.createElement("article"); card.className = `cluster-card${cluster.profiles.length > 1 ? " recommended" : ""}`;
      const h = document.createElement("h3"); h.textContent = cluster.profiles.length > 1 ? `Candidate group ${index + 1}` : `Standalone · ${cluster.profiles[0].name}`;
      if (cluster.profiles.length > 1) { const badge = document.createElement("span"); badge.className = "cluster-badge"; badge.textContent = "REVIEW"; h.append(badge); }
      const meta = document.createElement("p"); meta.className = "cluster-meta";
      const licenses = [...new Set(cluster.profiles.map((p) => p.license))].join(", ");
      const commonCount = cluster.common.size;
      meta.textContent = `${cluster.profiles.length} profiles · License: ${licenses} · ${cluster.minSimilarity === null ? "No pair score" : `lowest pair overlap ${cluster.minSimilarity}%`} · ${commonCount} access grants shared by all`;
      const list = document.createElement("ul");
      cluster.profiles.forEach((p) => { const li = document.createElement("li"); li.textContent = `${p.name} (${p.sourceFile})`; list.append(li); });
      if (cluster.profiles.length > 1 && !cluster.settingsMatch) { const li = document.createElement("li"); li.textContent = "Profile-only settings differ; review/retain separately."; list.append(li); }
      card.append(h, meta, list); ui.clusters.append(card);
    });
  }

  function renderCandidates() {
    const p = state.proposals;
    ui.xmlSummary.textContent = `${p.modules.length} draft Permission Set(s), ${p.bundles.length} optional PSG candidate(s). ${p.modules.length ? "Shared grants are not emitted as a merged Profile." : "No portable positive deltas were found under the current grouping."}`;
    const table = document.createElement("table");
    const thead = document.createElement("thead"); const hr = document.createElement("tr");
    ["Suggested Permission Set", "Access type", "Profiles with this difference", "Permissions", "Suggested group"].forEach((x) => { const th = document.createElement("th"); th.textContent = x; hr.append(th); }); thead.append(hr); table.append(thead);
    const tbody = document.createElement("tbody");
    p.modules.forEach((m) => {
      const tr = document.createElement("tr"); const groupNames = m.profiles.map((x) => x.name).join(", ");
      const bundles = p.bundles.filter((x) => x.sets.includes(m)).map((x) => x.label).join(", ");
      const name = document.createElement("td"); name.textContent = m.label;
      const api = document.createElement("code"); api.className = "metadata-name"; api.textContent = m.api; name.append(document.createElement("br"), api); tr.append(name);
      [m.category, groupNames, String(m.entries.length), bundles || "No group suggested"].forEach((x) => { const td = document.createElement("td"); td.textContent = x; tr.append(td); }); tbody.append(tr);
    });
    if (!p.modules.length) { const tr = document.createElement("tr"); const td = document.createElement("td"); td.colSpan = 5; td.textContent = "No Permission Set candidates to show."; tr.append(td); tbody.append(tr); }
    table.append(tbody); ui.candidates.replaceChildren(table);
  }

  function setFilters() {
    const categories = [...new Set(state.rows.map((x) => x.category))].sort();
    ui.category.replaceChildren();
    const all = document.createElement("option"); all.value = "all"; all.textContent = "All categories"; ui.category.append(all);
    categories.forEach((c) => { const o = document.createElement("option"); o.value = c; o.textContent = c; ui.category.append(o); });
    ui.view.value = "all"; ui.search.value = ""; filterRows();
  }
  function filterRows() {
    const view = ui.view.value; const category = ui.category.value; const query = ui.search.value.trim().toLowerCase();
    state.filtered = state.rows.filter((row) => (view === "all" || (view === "shared" && row.status === "shared") || (view === "differences" && row.status === "difference") || (view === "conflicts" && row.status === "conflict")) && (category === "all" || category === row.category) && (!query || `${row.category} ${row.label} ${row.values.join(" ")}`.toLowerCase().includes(query)));
    state.page = 0; renderPage();
  }
  function renderPage() {
    const start = state.page * PAGE_SIZE; const rows = state.filtered.slice(start, start + PAGE_SIZE);
    const thead = document.createElement("thead"); const trh = document.createElement("tr");
    ["Permission or setting", "Category", ...state.profiles.map((p) => p.name), "Result"].forEach((x) => { const th = document.createElement("th"); th.textContent = x; trh.append(th); }); thead.append(trh);
    const tbody = document.createElement("tbody");
    rows.forEach((row) => {
      const tr = document.createElement("tr");
      [row.label, row.category, ...row.values, row.status === "shared" ? "Shared" : row.status === "difference" ? "Differs" : row.status === "conflict" ? "Conflict / review" : "No positive grant"].forEach((val, index) => {
        const td = document.createElement("td"); td.textContent = val;
        if (index === row.values.length + 2) td.className = row.status === "shared" ? "status-shared" : row.status === "difference" ? "status-difference" : row.status === "conflict" ? "status-conflict" : "";
        tr.append(td);
      }); tbody.append(tr);
    });
    ui.table.replaceChildren(thead, tbody);
    const pages = Math.max(1, Math.ceil(state.filtered.length / PAGE_SIZE));
    ui.resultCount.textContent = `Showing ${state.filtered.length ? start + 1 : 0}–${Math.min(start + PAGE_SIZE, state.filtered.length)} of ${state.filtered.length} findings`;
    ui.page.textContent = `Page ${state.page + 1} of ${pages}`; ui.prev.disabled = state.page === 0; ui.next.disabled = state.page + 1 >= pages;
  }
  function renderWarnings() {
    const licenses = new Set(state.profiles.map((p) => p.license)); const nonCustom = state.profiles.filter((p) => !p.custom).map((p) => p.name);
    const warnings = [];
    if (licenses.size > 1 || licenses.has("Not specified in XML")) warnings.push("Profiles with different or missing user licenses are kept in separate candidate groups.");
    if (nonCustom.length) warnings.push(`Standard profiles are not auto-grouped or given Permission Set drafts: ${nonCustom.join(", ")}.`);
        warnings.push("The overlap score compares positive access grants in the supplied XML. A high score does not prove that the profiles are suitable to merge.");
    ui.warnings.textContent = warnings.join(" ");
  }

  async function analyze() {
    try {
      if (state.files.length < 2 || state.files.length > MAX_PROFILES) throw new Error(`Select between 2 and ${MAX_PROFILES} files.`);
      message("Reading and comparing XML locally…"); ui.analyze.disabled = true;
      const profiles = await Promise.all(state.files.map(async (f) => parseProfile(await f.text(), f.name)));
      const names = profiles.map((p) => p.name.toLowerCase());
      if (new Set(names).size !== names.length) throw new Error("Two files contain the same profile name. Remove duplicates before analysis.");
      state.profiles = profiles;
      const threshold = Number(ui.threshold.value); state.clusters = makeClusters(profiles, threshold, ui.sameSettings.checked);
      state.rows = flattenRows(profiles);
      state.proposals = candidatesFor(state.clusters, ui.includeRisk.checked);
      renderWarnings(); renderSummary(); renderClusters(); renderCandidates(); setFilters();
      ui.results.hidden = false; message(`Analyzed ${profiles.length} profiles. Results are local to this browser.`);
      ui.results.scrollIntoView({ behavior: "smooth", block: "start" });
    } catch (e) { ui.results.hidden = true; message(e.message || "Unable to analyze these files.", true); }
    finally { ui.analyze.disabled = state.files.length < 2 || state.files.length > MAX_PROFILES; }
  }

  function refreshProposal() {
    if (!state.profiles.length) return;
    state.clusters = makeClusters(state.profiles, Number(ui.threshold.value), ui.sameSettings.checked);
    state.proposals = candidatesFor(state.clusters, ui.includeRisk.checked);
    renderSummary(); renderClusters(); renderCandidates();
  }

  function downloadXml() {
    if (!state.profiles.length) return;
    const proposals = candidatesFor(state.clusters, ui.includeRisk.checked); const files = [];
    proposals.modules.forEach((m) => files.push({ name: `permissionsets/${m.api}.permissionset-meta.xml`, data: metadataForModule(m) }));
    proposals.bundles.forEach((g) => files.push({ name: `permissionsetgroups/${g.api}.permissionsetgroup-meta.xml`, data: metadataForGroup(g) }));
    files.push({ name: "README_REVIEW_REQUIRED.md", data: makeReadme(proposals, state.clusters, ui.includeRisk.checked) });
    downloadBlob(makeZip(files), "profile_access_candidates_review_required.zip");
  }
  function csvCell(value) { let s = String(value ?? ""); if (/^[\s]*[=+@\-]/.test(s)) s = `'${s}`; return `"${s.replace(/"/g, '""')}"`; }
  function downloadCsv() {
    const header = ["Category", "Permission or setting", ...state.profiles.map((p) => p.name), "Result"];
    const rows = [header, ...state.filtered.map((r) => [r.category, r.label, ...r.values, r.status])];
    const csv = "\uFEFF" + rows.map((r) => r.map(csvCell).join(",")).join("\r\n");
    downloadBlob(new Blob([csv], { type: "text/csv;charset=utf-8" }), "multi_profile_comparison.csv");
  }

  ui.files.addEventListener("change", () => { addFiles(ui.files.files); ui.files.value = ""; });
  ui.drop.addEventListener("dragover", (e) => { e.preventDefault(); ui.drop.classList.add("dragging"); });
  ui.drop.addEventListener("dragleave", () => ui.drop.classList.remove("dragging"));
  ui.drop.addEventListener("drop", (e) => { e.preventDefault(); ui.drop.classList.remove("dragging"); addFiles(e.dataTransfer.files); });
  ui.drop.addEventListener("keydown", (e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); ui.files.click(); } });
  ui.threshold.addEventListener("input", () => { ui.thresholdValue.value = `${ui.threshold.value}%`; if (state.profiles.length) refreshProposal(); });
  ui.sameSettings.addEventListener("change", refreshProposal); ui.includeRisk.addEventListener("change", refreshProposal);
  ui.analyze.addEventListener("click", analyze); ui.view.addEventListener("change", filterRows); ui.category.addEventListener("change", filterRows); ui.search.addEventListener("input", filterRows);
  ui.prev.addEventListener("click", () => { if (state.page > 0) { state.page--; renderPage(); } });
  ui.next.addEventListener("click", () => { if ((state.page + 1) * PAGE_SIZE < state.filtered.length) { state.page++; renderPage(); } });
  ui.downloadXml.addEventListener("click", downloadXml); ui.downloadCsv.addEventListener("click", downloadCsv);
  renderFiles();
})();
