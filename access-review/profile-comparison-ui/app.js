(() => {
  "use strict";

  const PAGE_SIZE = 100;
  const PROFILE_ONLY = new Set([
    "layoutAssignments", "loginHours", "loginIpRanges", "passwordPolicies",
    "sessionSettings", "userLicense", "custom", "description"
  ]);
  const PORTABLE_CATEGORIES = new Set([
    "System permission", "Object permission", "Field access", "Apex class access",
    "Visualforce page access", "Custom permission", "Record type access",
    "Tab visibility", "Application visibility"
  ]);
  const HIGH_IMPACT_NAMES = [
    "ModifyAllData", "ViewAllData", "ManageUsers", "CustomizeApplication",
    "AuthorApex", "ModifyMetadata", "ManageProfilesPermissionsets",
    "ManageIpAddresses", "ManagePasswordPolicies", "ViewAllRecords", "ModifyAllRecords",
    "ViewSetup", "ApiEnabled"
  ];
  const SENSITIVE_FIELD_HINTS = /ssn|social.?security|tax.?id|bank|salary|compensation|date.?of.?birth|birth.?date|credit.?card|card.?number|password|secret|token|national.?id|passport/i;

  const state = { rows: [], filtered: [], page: 0, profiles: null };
  const byId = (id) => document.getElementById(id);
  const ui = {
    aFile: byId("file-a"), bFile: byId("file-b"),
    aXml: byId("xml-a"), bXml: byId("xml-b"),
    aLabel: byId("label-a"), bLabel: byId("label-b"),
    aFileName: byId("name-a"), bFileName: byId("name-b"),
    compare: byId("compare-button"), clear: byId("clear-button"),
    message: byId("input-message"), results: byId("results"),
    summary: byId("summary"), plan: byId("plan-content"), alert: byId("license-alert"),
    view: byId("view-filter"), category: byId("category-filter"), search: byId("search-input"),
    rows: byId("comparison-rows"), resultCount: byId("result-count"),
    prev: byId("prev-page"), next: byId("next-page"), pageLabel: byId("page-label"),
    download: byId("download-button")
  };

  function setMessage(message, error = false) {
    ui.message.textContent = message;
    ui.message.classList.toggle("error", error);
  }

  function leaf(node, tag) {
    return Array.from(node.children).find((child) => child.localName === tag)?.textContent.trim() || "";
  }

  function children(node, tag) {
    return Array.from(node.children).filter((child) => child.localName === tag);
  }

  function fileLabel(file) {
    return file.name.replace(/\.profile-meta\.xml$/i, "").replace(/\.xml$/i, "");
  }

  async function readFile(file, side) {
    if (!file) return;
    if (file.size > 25 * 1024 * 1024) {
      setMessage("That file is over 25 MB. Please choose a smaller Profile XML file.", true);
      return;
    }
    const text = await file.text();
    if (side === "a") {
      ui.aXml.value = text;
      ui.aFileName.textContent = `Loaded: ${file.name}`;
      if (!ui.aLabel.value.trim()) ui.aLabel.value = fileLabel(file);
    } else {
      ui.bXml.value = text;
      ui.bFileName.textContent = `Loaded: ${file.name}`;
      if (!ui.bLabel.value.trim()) ui.bLabel.value = fileLabel(file);
    }
    setMessage("Files are loaded locally. Select Compare profiles when ready.");
  }

  function installDropZone(side) {
    const zone = byId(`drop-${side}`);
    zone.addEventListener("dragover", (event) => {
      event.preventDefault();
      zone.classList.add("dragging");
    });
    zone.addEventListener("dragleave", () => zone.classList.remove("dragging"));
    zone.addEventListener("drop", (event) => {
      event.preventDefault();
      zone.classList.remove("dragging");
      const file = Array.from(event.dataTransfer.files || []).find((item) => /\.xml$/i.test(item.name) || /xml/i.test(item.type));
      if (!file) {
        setMessage("Please drop a Salesforce Profile XML file.", true);
        return;
      }
      readFile(file, side).catch(() => setMessage("The selected file could not be read.", true));
    });
  }

  function parseBoolean(value) {
    if (/^true$/i.test(value)) return true;
    if (/^false$/i.test(value)) return false;
    return null;
  }

  function createItem(items, category, member, property, value, grant, movable, risk = "", note = "") {
    const key = `${category}\u0000${member}\u0000${property}`;
    items.set(key, {
      key, category, member, property, value, grant, movable, risk, note,
      label: property ? `${member} — ${property}` : member
    });
  }

  function permissionDescription(name) {
    return name.replace(/(?<=[a-z0-9])(?=[A-Z])/g, " ").replace(/__c$/i, " (custom)");
  }

  function isHighImpact(name) {
    return HIGH_IMPACT_NAMES.some((marker) => name.toLowerCase().includes(marker.toLowerCase()));
  }

  function parseProfile(xmlText, fallbackName) {
    if (/<!DOCTYPE|<!ENTITY/i.test(xmlText)) throw new Error("DOCTYPE and entity declarations are not accepted. Use a standard Salesforce Profile XML export.");
    const documentXml = new DOMParser().parseFromString(xmlText, "application/xml");
    const parserError = documentXml.querySelector("parsererror");
    if (parserError) throw new Error("This file is not valid XML. Check that the complete Salesforce Profile XML was copied.");
    const root = documentXml.documentElement;
    if (!root || root.localName !== "Profile") throw new Error("The XML root must be a Salesforce <Profile> element.");

    const name = leaf(root, "fullName") || fallbackName || "Profile";
    const profile = {
      name,
      license: leaf(root, "userLicense") || "Not specified in XML",
      custom: leaf(root, "custom") || "Not specified in XML",
      permissions: new Map(),
      meta: new Map(),
      unknownTopLevel: []
    };
    const handled = new Set([
      "userPermissions", "objectPermissions", "fieldPermissions", "classAccesses", "pageAccesses",
      "recordTypeVisibilities", "tabVisibilities", "applicationVisibilities", "customPermissions",
      "customMetadataTypeAccesses", "customSettingAccesses", "externalDataSourceAccesses",
      "loginHours", "loginIpRanges", "layoutAssignments", "passwordPolicies", "sessionSettings",
      "userLicense", "custom", "description"
    ]);

    for (const node of Array.from(root.children)) {
      const tag = node.localName;
      if (tag === "userLicense" || tag === "custom") continue;
      if (tag === "description") {
        profile.meta.set("Profile description", { value: node.textContent.trim(), profileOnly: true });
        continue;
      }

      if (tag === "userPermissions") {
        const nameValue = leaf(node, "name");
        const enabled = parseBoolean(leaf(node, "enabled"));
        if (nameValue) createItem(profile.permissions, "System permission", permissionDescription(nameValue), "Enabled", enabled === null ? leaf(node, "enabled") : enabled, enabled, true, isHighImpact(nameValue) ? "Review" : "", "A system-level feature permission.");
      } else if (tag === "objectPermissions") {
        const objectName = leaf(node, "object");
        for (const [element, label] of [
          ["allowRead", "Read"], ["allowCreate", "Create"], ["allowEdit", "Edit"],
          ["allowDelete", "Delete"], ["viewAllRecords", "View All records"], ["modifyAllRecords", "Modify All records"]
        ]) {
          const raw = leaf(node, element);
          if (raw === "") continue;
          const value = parseBoolean(raw);
          createItem(profile.permissions, "Object permission", objectName || "Object not named", label, value === null ? raw : value, value, true,
            ["View All records", "Modify All records"].includes(label) && value ? "High impact" : "",
            "Object-level access; record sharing can still limit which individual records are visible.");
        }
      } else if (tag === "fieldPermissions") {
        const fieldName = leaf(node, "field");
        for (const [element, label] of [["readable", "Can view"], ["editable", "Can edit"]]) {
          const raw = leaf(node, element);
          if (raw === "") continue;
          const value = parseBoolean(raw);
          const sensitive = value === true && SENSITIVE_FIELD_HINTS.test(fieldName);
          createItem(profile.permissions, "Field access", fieldName || "Field not named", label, value === null ? raw : value, value, true, sensitive ? "Sensitive field review" : "",
            "Field-level security; record and object access must also allow the action.");
        }
      } else if (tag === "classAccesses" || tag === "pageAccesses") {
        const isClass = tag === "classAccesses";
        const itemName = leaf(node, isClass ? "apexClass" : "apexPage");
        const raw = leaf(node, "enabled");
        const enabled = parseBoolean(raw);
        createItem(profile.permissions, isClass ? "Apex class access" : "Visualforce page access", itemName || "Component not named", "Enabled", enabled === null ? raw : enabled, enabled, true, "",
          "Direct access to this Salesforce component.");
      } else if (tag === "customPermissions" || tag === "customMetadataTypeAccesses" || tag === "customSettingAccesses" || tag === "externalDataSourceAccesses") {
        const nameTag = ["externalDataSourceAccesses"].includes(tag) ? "externalDataSource" : "name";
        const itemName = leaf(node, nameTag) || leaf(node, "customPermission");
        const property = tag === "customPermissions" ? "Enabled" : "Access enabled";
        const raw = leaf(node, "enabled");
        const enabled = parseBoolean(raw);
        const category = tag === "customPermissions" ? "Custom permission" : tag === "customMetadataTypeAccesses" ? "Custom metadata access" : tag === "customSettingAccesses" ? "Custom setting access" : "External data source access";
        createItem(profile.permissions, category, itemName || category, property, enabled === null ? raw : enabled, enabled, true, "", "Additional access-bearing profile setting.");
      } else if (tag === "tabVisibilities") {
        const tab = leaf(node, "tab");
        const visibility = leaf(node, "visibility");
        const grantsTab = ["DefaultOn", "DefaultOff", "Available"].includes(visibility);
        createItem(profile.permissions, "Tab visibility", tab || "Tab not named", "Visibility", visibility || "Not specified", grantsTab, true, "",
          "Tab setting affects navigation; it does not grant access to the underlying records.");
      } else if (tag === "applicationVisibilities") {
        const application = leaf(node, "application");
        const visible = parseBoolean(leaf(node, "visible"));
        const isDefault = parseBoolean(leaf(node, "default"));
        createItem(profile.permissions, "Application visibility", application || "Application not named", "Visible", visible === null ? leaf(node, "visible") : visible, visible, true, "",
          "Makes the application available to this profile.");
        if (isDefault !== null) createItem(profile.permissions, "Application setting", application || "Application not named", "Default app", isDefault, null, "review", "Default app choice is a setting to preserve and review.");
      } else if (tag === "recordTypeVisibilities") {
        const recordType = leaf(node, "recordType");
        const visible = parseBoolean(leaf(node, "visible"));
        const isDefault = parseBoolean(leaf(node, "default"));
        createItem(profile.permissions, "Record type access", recordType || "Record type not named", "Available", visible === null ? leaf(node, "visible") : visible, visible, true, "",
          "Record type availability; layouts are assigned separately.");
        if (isDefault !== null) createItem(profile.permissions, "Record type setting", recordType || "Record type not named", "Default", isDefault, null, "review", "Default record type choice is a setting to preserve and review.");
      } else if (PROFILE_ONLY.has(tag)) {
        const value = Array.from(node.children).map((child) => `${permissionDescription(child.localName)}: ${child.textContent.trim()}`).join("; ") || node.textContent.trim() || "Present in XML";
        const label = tag === "layoutAssignments"
          ? `${leaf(node, "layout") || "Layout"}${leaf(node, "recordType") ? ` (${leaf(node, "recordType")})` : ""}`
          : tag === "loginIpRanges"
            ? `Allowed IP: ${leaf(node, "startAddress")}–${leaf(node, "endAddress")}`
            : tag === "loginHours" ? "Allowed login hours" : permissionDescription(tag);
        profile.meta.set(`${permissionDescription(tag)}: ${label}`, { value, profileOnly: true });
        createItem(profile.permissions, "Profile-only setting", label, permissionDescription(tag), value, null, false, "Review",
          "Keep or redesign as a profile-level setting; it cannot be assumed to move into a Permission Set.");
      } else if (!handled.has(tag)) {
        const serialized = new XMLSerializer().serializeToString(node);
        createItem(profile.permissions, "Other profile setting", permissionDescription(tag), "Present", serialized.slice(0, 700), null, false, "review",
          "Unrecognized profile element. Review platform support before moving it.");
        profile.unknownTopLevel.push(tag);
      }
    }
    return profile;
  }

  function settingFor(profile, key) {
    return profile.permissions.get(key);
  }

  function compareProfiles(a, b) {
    const keys = new Set([...a.permissions.keys(), ...b.permissions.keys()]);
    const rows = [];
    for (const key of keys) {
      const left = settingFor(a, key);
      const right = settingFor(b, key);
      const sample = left || right;
      const hasA = Boolean(left);
      const hasB = Boolean(right);
      const grantA = Boolean(left && left.grant === true);
      const grantB = Boolean(right && right.grant === true);
      const equal = hasA && hasB && left.value === right.value;
      let comparison;
      let view;
      if (grantA && grantB && equal) {
        comparison = "Shared grant";
        view = "shared";
      } else if (grantA && grantB) {
        comparison = "Access on both; setting differs";
        view = "conflicts";
      } else if (grantA && !hasB) {
        comparison = `${a.name} explicitly grants; other XML does not specify`;
        view = "a-only";
      } else if (grantB && !hasA) {
        comparison = `${b.name} explicitly grants; other XML does not specify`;
        view = "b-only";
      } else if (grantA && hasB && right.grant === false) {
        comparison = `${a.name} grants; ${b.name} explicitly sets off`;
        view = "conflicts";
      } else if (grantB && hasA && left.grant === false) {
        comparison = `${b.name} grants; ${a.name} explicitly sets off`;
        view = "conflicts";
      } else if (hasA && !hasB) {
        comparison = "Setting appears only in this XML; it is not a grant";
        view = "conflicts";
      } else if (hasB && !hasA) {
        comparison = "Setting appears only in this XML; it is not a grant";
        view = "conflicts";
      } else if (equal && sample.grant === false) {
        comparison = "Both XMLs explicitly set this off";
        view = "conflicts";
      } else if (equal) {
        comparison = "Same setting in both XMLs";
        view = "shared";
      } else {
        comparison = "Setting differs";
        view = "conflicts";
      }

      let recommendation;
      const hasPositiveDelta = grantA !== grantB;
      const licenseMatches = a.license === b.license;
      const customProfiles = a.custom.toLowerCase() === "true" && b.custom.toLowerCase() === "true";
      if (sample.movable === false) {
        recommendation = "Keep on the profile or review separately; not a Permission Set candidate.";
      } else if (sample.movable === "review") {
        recommendation = "Review manually; do not assume this setting can move to a Permission Set.";
      } else if (!licenseMatches) {
        recommendation = "License mismatch: do not plan a shared profile from these files.";
      } else if (!customProfiles) {
        recommendation = "Standard profile involved: confirm platform limits before planning any move.";
      } else if (hasPositiveDelta) {
        const grantSide = grantA ? a.name : b.name;
        const deniedSide = grantA ? right : left;
        recommendation = deniedSide?.grant === false
          ? `Candidate for a ${grantSide}-only Permission Set; the other XML explicitly sets this off. Permission Sets add access and cannot enforce a denial, so confirm the target profile and assignment.`
          : `Potential ${grantSide}-only Permission Set candidate. Confirm the other XML is complete; a missing entry is not assumed to be a denial. Map users and get business approval before designing the set.`;
      } else if (grantA && grantB && !equal) {
        recommendation = "Keep both grants in the baseline candidate, but preserve the differing setting and confirm its behavior.";
      } else {
        recommendation = "No unique positive grant to move. Review this setting if the profiles are consolidated.";
      }

      const display = (entry) => entry ? String(entry.value) : "Not specified in XML";
      rows.push({
        key, category: sample.category, label: sample.label,
        aValue: display(left), bValue: display(right),
        comparison, view, recommendation,
        grantA, grantB, movable: sample.movable,
        risk: sample.risk || left?.risk || right?.risk || "",
        note: sample.note || left?.note || right?.note || ""
      });
    }
    return rows.sort((x, y) => x.category.localeCompare(y.category) || x.label.localeCompare(y.label));
  }

  function addSummaryCard(label, value, detail) {
    const card = document.createElement("article");
    card.className = "summary-card";
    const labelNode = document.createElement("div");
    labelNode.className = "label";
    labelNode.textContent = label;
    const valueNode = document.createElement("div");
    valueNode.className = "value";
    valueNode.textContent = String(value);
    const detailNode = document.createElement("div");
    detailNode.className = "detail";
    detailNode.textContent = detail;
    card.append(labelNode, valueNode, detailNode);
    ui.summary.append(card);
  }

  function countByCategory(rows) {
    const counts = new Map();
    for (const row of rows) counts.set(row.category, (counts.get(row.category) || 0) + 1);
    return counts;
  }

  function suggestedPermissionSetName(profileName) {
    let base = profileName.normalize("NFKD").replace(/[^A-Za-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
    if (!base || /^[0-9]/.test(base)) base = `Access_${base}`;
    const suffix = "_Delta_Access";
    return `${base.slice(0, 40 - suffix.length)}${suffix}`;
  }

  function createPlan(a, b, rows) {
    const movableA = rows.filter((row) => row.grantA && !row.grantB && PORTABLE_CATEGORIES.has(row.category) && row.movable === true);
    const movableB = rows.filter((row) => row.grantB && !row.grantA && PORTABLE_CATEGORIES.has(row.category) && row.movable === true);
    const countsA = countByCategory(movableA);
    const countsB = countByCategory(movableB);
    const deltaCount = movableA.length + movableB.length;
    const canPlan = a.license === b.license && a.custom.toLowerCase() === "true" && b.custom.toLowerCase() === "true";
    const sameLicenseText = a.license === b.license ? `Both files specify the ${a.license} license.` : `License mismatch: ${a.license} vs ${b.license}. Resolve license compatibility before considering a consolidated profile.`;

    ui.plan.replaceChildren();
    const callout = document.createElement("div");
    callout.className = "plan-callout";
    callout.textContent = canPlan
      ? `Possible design: use only the shared positive grants as a baseline candidate. Put profile-specific additive grants into separate Permission Set candidates, then assign those sets only to the matching users. ${sameLicenseText}`
      : `This comparison is useful for review, but it does not support a consolidation plan yet. ${sameLicenseText} Both files must be custom profiles before this tool suggests profile-specific Permission Sets.`;
    ui.plan.append(callout);

    const columns = document.createElement("div");
    columns.className = "plan-columns";
    const addPlanCard = (name, title, candidates, counts) => {
      const card = document.createElement("article");
      card.className = "plan-card";
      const heading = document.createElement("h3");
      heading.textContent = title;
      card.append(heading);
      const p = document.createElement("p");
      p.textContent = canPlan
        ? (candidates.length ? `${candidates.length} positive grant${candidates.length === 1 ? "" : "s"} may be candidates for this set.` : "No one-sided positive grants meet the move-to-set rules.")
        : "No Permission Set plan suggested until the profile/license constraint is resolved.";
      card.append(p);
      const setName = document.createElement("div");
      setName.className = "permission-set-name";
      setName.textContent = name;
      card.append(setName);
      const list = document.createElement("ul");
      for (const [category, count] of counts) {
        const li = document.createElement("li");
        li.textContent = `${category}: ${count}`;
        list.append(li);
      }
      if (candidates.length) card.append(list);
      columns.append(card);
    };
    addPlanCard(suggestedPermissionSetName(a.name), `${a.name} extras`, movableA, countsA);
    addPlanCard(suggestedPermissionSetName(b.name), `${b.name} extras`, movableB, countsB);

    const foot = document.createElement("p");
    foot.className = "plan-footnote";
    foot.textContent = deltaCount
      ? "These are Permission Set candidates, not ready-to-deploy sets. Review explicit false settings and high-impact permissions, confirm business need and user assignments, then validate effective access in a sandbox. Consider a Permission Set Group only when multiple reusable Permission Sets need to be bundled for a stable job persona; two XML files alone do not identify those personas."
      : "No additive Permission Set candidates were found under the current rules. Differences in defaults, hidden settings, layouts, or login restrictions still need profile-level review. A Permission Set Group is not suggested from XML alone.";
    ui.plan.append(columns, foot);
  }

  function renderSummary(a, b, rows) {
    ui.summary.replaceChildren();
    const shared = rows.filter((r) => r.grantA && r.grantB && r.view === "shared").length;
    const aOnly = rows.filter((r) => r.grantA && !r.grantB).length;
    const bOnly = rows.filter((r) => r.grantB && !r.grantA).length;
    const conflicts = rows.filter((r) => r.view === "conflicts").length;
    addSummaryCard("Shared grants", shared, "Explicitly granted in both XML files");
    addSummaryCard(`${a.name} extra grants`, aOnly, "Granted only or explicitly granted on the first profile");
    addSummaryCard(`${b.name} extra grants`, bOnly, "Granted only or explicitly granted on the second profile");
    addSummaryCard("Needs review", conflicts, "Conflicting, non-grant, or special settings");
  }

  function renderAlert(a, b) {
    const warnings = [];
    if (a.license !== b.license) warnings.push(`Different user licenses (${a.license} and ${b.license}) can limit which users and features a profile supports. Do not treat this as a merge recommendation.`);
    if (a.custom.toLowerCase() !== "true" || b.custom.toLowerCase() !== "true") warnings.push("At least one file is a standard profile. Standard-profile consolidation has platform constraints and needs administrator review.");
    ui.alert.hidden = warnings.length === 0;
    ui.alert.textContent = warnings.join(" ");
  }

  function setFilters(rows) {
    const categories = Array.from(new Set(rows.map((row) => row.category))).sort();
    ui.category.replaceChildren();
    const all = document.createElement("option");
    all.value = "all";
    all.textContent = "All categories";
    ui.category.append(all);
    for (const category of categories) {
      const option = document.createElement("option");
      option.value = category;
      option.textContent = category;
      ui.category.append(option);
    }
    ui.search.value = "";
    ui.view.value = "all";
    filterRows();
  }

  function filterRows() {
    const view = ui.view.value;
    const category = ui.category.value;
    const query = ui.search.value.trim().toLowerCase();
    state.filtered = state.rows.filter((row) => {
      const viewMatch = view === "all" || (view === "a-only" ? row.grantA && !row.grantB : view === "b-only" ? row.grantB && !row.grantA : view === "shared" ? row.grantA && row.grantB : row.view === "conflicts");
      const categoryMatch = category === "all" || row.category === category;
      const textMatch = !query || [row.category, row.label, row.aValue, row.bValue, row.comparison, row.recommendation].join(" ").toLowerCase().includes(query);
      return viewMatch && categoryMatch && textMatch;
    });
    state.page = 0;
    renderPage();
  }

  function addTextCell(rowNode, text) {
    const cell = document.createElement("td");
    cell.textContent = text;
    rowNode.append(cell);
    return cell;
  }

  function renderPage() {
    const start = state.page * PAGE_SIZE;
    const visible = state.filtered.slice(start, start + PAGE_SIZE);
    ui.rows.replaceChildren();
    for (const item of visible) {
      const tr = document.createElement("tr");
      addTextCell(tr, item.category);
      const label = addTextCell(tr, item.label);
      label.title = item.note;
      addTextCell(tr, item.aValue);
      addTextCell(tr, item.bValue);
      const statusCell = document.createElement("td");
      const chip = document.createElement("span");
      chip.className = `status-chip ${item.view === "shared" ? "shared" : item.view === "conflicts" ? "conflict" : "delta"}`;
      chip.textContent = item.comparison;
      statusCell.append(chip);
      if (item.risk) {
        const risk = document.createElement("span");
        risk.className = "status-chip high";
        risk.textContent = item.risk;
        statusCell.append(risk);
      }
      tr.append(statusCell);
      addTextCell(tr, item.recommendation);
      ui.rows.append(tr);
    }
    const pages = Math.max(1, Math.ceil(state.filtered.length / PAGE_SIZE));
    ui.resultCount.textContent = `Showing ${state.filtered.length ? start + 1 : 0}–${Math.min(start + PAGE_SIZE, state.filtered.length)} of ${state.filtered.length} findings`;
    ui.pageLabel.textContent = `Page ${state.page + 1} of ${pages}`;
    ui.prev.disabled = state.page === 0;
    ui.next.disabled = state.page + 1 >= pages;
  }

  function csvSafe(value) {
    let text = String(value ?? "");
    if (/^[\s]*[=+@\-]/.test(text)) text = `'${text}`;
    return `"${text.replace(/"/g, '""')}"`;
  }

  function downloadCsv() {
    const headers = ["Category", "Permission or setting", "First profile XML", "Second profile XML", "Comparison", "Recommendation", "High-impact review", "Notes"];
    const lines = [headers, ...state.filtered.map((row) => [row.category, row.label, row.aValue, row.bValue, row.comparison, row.recommendation, row.risk, row.note])]
      .map((row) => row.map(csvSafe).join(",")).join("\r\n");
    const blob = new Blob(["\uFEFF", lines], { type: "text/csv;charset=utf-8" });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    const base = (state.profiles?.a.name || "Profile_A").replace(/[^a-z0-9_-]+/gi, "_");
    link.download = `${base}_profile_comparison.csv`;
    document.body.append(link);
    link.click();
    link.remove();
    const url = link.href;
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }

  function compare() {
    try {
      if (!ui.aXml.value.trim() || !ui.bXml.value.trim()) throw new Error("Choose or paste both Profile XML files first.");
      const a = parseProfile(ui.aXml.value, ui.aLabel.value.trim() || "First profile");
      const b = parseProfile(ui.bXml.value, ui.bLabel.value.trim() || "Second profile");
      if (a.name.toLowerCase() === b.name.toLowerCase()) throw new Error("Both profiles have the same comparison label. Rename one label or choose another file.");
      const rows = compareProfiles(a, b);
      state.profiles = { a, b };
      state.rows = rows;
      byId("head-a").textContent = a.name;
      byId("head-b").textContent = b.name;
      renderAlert(a, b);
      renderSummary(a, b, rows);
      createPlan(a, b, rows);
      setFilters(rows);
      ui.results.hidden = false;
      setMessage(`Compared ${a.name} and ${b.name}. XML was processed locally in your browser.`);
      ui.results.scrollIntoView({ behavior: "smooth", block: "start" });
    } catch (error) {
      ui.results.hidden = true;
      setMessage(error.message || "Unable to compare these files.", true);
    }
  }

  function clearAll() {
    ui.aFile.value = ""; ui.bFile.value = "";
    ui.aXml.value = ""; ui.bXml.value = "";
    ui.aLabel.value = ""; ui.bLabel.value = "";
    ui.aFileName.textContent = "No file selected";
    ui.bFileName.textContent = "No file selected";
    ui.results.hidden = true;
    ui.alert.hidden = true;
    state.rows = []; state.filtered = []; state.profiles = null; state.page = 0;
    setMessage("Select or paste two profile XML files to begin.");
  }

  ui.aFile.addEventListener("change", () => readFile(ui.aFile.files[0], "a").catch(() => setMessage("The selected file could not be read.", true)));
  ui.bFile.addEventListener("change", () => readFile(ui.bFile.files[0], "b").catch(() => setMessage("The selected file could not be read.", true)));
  installDropZone("a");
  installDropZone("b");
  ui.compare.addEventListener("click", compare);
  ui.clear.addEventListener("click", clearAll);
  ui.view.addEventListener("change", filterRows);
  ui.category.addEventListener("change", filterRows);
  ui.search.addEventListener("input", filterRows);
  ui.prev.addEventListener("click", () => { if (state.page > 0) { state.page -= 1; renderPage(); } });
  ui.next.addEventListener("click", () => { if ((state.page + 1) * PAGE_SIZE < state.filtered.length) { state.page += 1; renderPage(); } });
  ui.download.addEventListener("click", downloadCsv);
})();
