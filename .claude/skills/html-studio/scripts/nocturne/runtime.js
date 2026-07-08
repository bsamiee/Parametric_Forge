// --- [NOCTURNE_RUNTIME] --- assembler-stamped byte canon; template-local script composes NOCTURNE and never re-authors a kernel concern
"use strict";
const NOCTURNE = (() => {
  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];
  const esc = value => { const node = document.createElement("span"); node.textContent = String(value); return node.innerHTML; };
  const put = (node, attrs) => {
    if (!attrs) return node;
    for (const key in attrs) {
      const value = attrs[key];
      if (value == null || value === false) continue;
      if (key === "text") node.textContent = value;
      else if (key === "dataset") for (const name in value) { if (value[name] != null) node.dataset[name] = value[name]; }
      else if (key === "style" && typeof value === "object") for (const name in value) node.style.setProperty(name, value[name]);
      else if (value === true) node.setAttribute(key, "");
      else node.setAttribute(key, value);
    }
    return node;
  };
  const el = (tag, attrs, ...kids) => {
    const node = document.createElement(tag);
    put(node, attrs);
    for (const kid of kids.flat(2)) { if (kid != null && kid !== false) node.append(kid.nodeType ? kid : document.createTextNode(String(kid))); }
    return node;
  };
  const SVG_NS = "http://www.w3.org/2000/svg";
  const svg = (tag, attrs, ...kids) => {
    const node = document.createElementNS(SVG_NS, tag);
    put(node, attrs);
    for (const kid of kids.flat(2)) { if (kid != null && kid !== false) node.append(kid.nodeType ? kid : document.createTextNode(String(kid))); }
    return node;
  };
  const clone = (template, fills) => {
    const node = template.content.cloneNode(true);
    if (fills) for (const key in fills) { const slot = node.querySelector(`[data-cell="${CSS.escape(key)}"]`); if (slot) slot.textContent = fills[key]; }
    return node;
  };
  const fmt = { num: new Intl.NumberFormat(), pct: new Intl.NumberFormat(undefined, { style: "percent", maximumFractionDigits: 0 }) };
  const payload = (id = "payload") => JSON.parse($("#" + CSS.escape(id)).textContent);
  const index = (rows, key = "id") => Object.fromEntries(rows.map(row => [typeof key === "function" ? key(row) : row[key], row]));
  const md = {
    cell: value => String(value ?? "").replace(/\|/g, "\\|").replace(/\n/g, " "),
    line: value => String(value ?? "").replace(/\s+/g, " ").trim(),
    table: (headers, rows) => [
      "| " + headers.map(md.cell).join(" | ") + " |",
      "| " + headers.map(() => "---").join(" | ") + " |",
      ...rows.map(row => "| " + row.map(md.cell).join(" | ") + " |"),
    ].join("\n"),
  };
  const debounce = (fn, delay = 120) => {
    let timer = 0;
    return (...args) => {
      clearTimeout(timer);
      timer = setTimeout(() => fn(...args), delay);
    };
  };
  const delegate = (tables, rootNode = document) => {
    const ctl = new AbortController();
    Object.entries(tables).forEach(([type, rows]) => rootNode.addEventListener(type, event => {
      const target = event.target instanceof Element ? event.target : event.target?.parentElement;
      if (!target) return;
      rows.some(([selector, fn]) => {
        const hit = target.closest(selector);
        if (!hit || !rootNode.contains(hit) || hit.disabled) return false;
        fn(hit, event);
        return true;
      });
    }, { signal: ctl.signal }));
    return ctl;
  };
  const idToken = value => String(value).toLowerCase().replace(/[^a-z0-9_-]+/g, "-").replace(/^-|-$/g, "") || "x";
  const opt = row => typeof row === "string" ? { value: row, label: row } : row;
  const formValues = (form = $("#capture-form")) => {
    if (!form) return {};
    const data = new FormData(form);
    return [...new Set(data.keys())].reduce((acc, key) => {
      const all = data.getAll(key);
      acc[key] = all.length > 1 ? all : (all[0] ?? "");
      return acc;
    }, {});
  };
  const choice = ({ name, legend, value = "", options, attrs = {}, input = () => ({}) }) =>
    el("fieldset", { class: "seg no-print", ...attrs },
      el("legend", { class: "sr-only", text: legend }),
      options.map(raw => {
        const row = opt(raw);
        const ident = `${name}-${idToken(row.value)}`;
        return el("label", { for: ident },
          el("input", { id: ident, type: row.type ?? "radio", name, value: row.value, checked: row.value === value || null, form: "capture-form", ...input(row) }),
          row.label ?? row.value);
      }));
  const field = ({ id, label, control, help }) =>
    el("div", { class: "field" }, el("label", { for: id, text: label }), control, help ? el("small", { text: help }) : null);
  const selectField = ({ id, label, value = "", options, attrs = {}, help }) =>
    field({ id, label, help, control: el("select", { id, name: id, form: "capture-form", ...attrs },
      options.map(raw => { const row = opt(raw); return el("option", { value: row.value, selected: row.value === value || null }, row.label ?? row.value); })) });
  const textareaField = ({ id, label, value = "", attrs = {}, help }) =>
    field({ id, label, help, control: el("textarea", { id, name: id, form: "capture-form", ...attrs }, value) });
  const note = ({ id, label, value = "", title = "Annotation", attrs = {}, button = "note", active = "note*" }) => {
    const pid = "note-" + idToken(id);
    const tid = pid + "-text";
    return el("span", { class: "rowline" },
      el("button", { type: "button", class: "btn ghost no-print", popovertarget: pid, "data-note-btn": id, "data-note-empty": button, "data-note-active": active, "aria-label": label }, value ? active : button),
      el("div", { id: pid, class: "pop notepop no-print", popover: "auto" },
        el("span", { class: "eyebrow", text: title }),
        textareaField({ id: tid, label, value, attrs })));
  };
  const drawer = (...nodes) => $("[data-drawer-fields]")?.prepend(...nodes);
  const capture = Object.assign((store, defaults = { verdict: "", note: "", ann: "active" }) => {
    const row = id => (store[id] ??= { ...defaults });
    const decisions = () => Object.entries(store).filter(([, c]) => c.verdict).map(([id, c]) => ({ id, verdict: c.verdict, ...(c.note ? { note: c.note } : {}) }));
    const annotations = (intent = "note") => Object.entries(store).filter(([, c]) => c.note?.trim()).map(([id, c]) => ({ id: "a-" + id, itemId: id, intent, status: c.ann ?? "active", text: c.note.trim() }));
    const markExported = () => Object.values(store).forEach(c => { if (c.note?.trim()) c.ann = "exported"; });
    const keyOf = hit => hit.dataset.id ?? hit.dataset.verdictFor ?? hit.dataset.noteFor ?? "";
    const setVerdict = hit => { const c = row(keyOf(hit)); c.verdict = hit.value; document.getElementById(keyOf(hit))?.setAttribute("data-verdict", hit.value); };
    const setNote = hit => {
      const id = keyOf(hit);
      const c = row(id);
      c.note = hit.value;
      c.ann = "active";
      $$(`[data-note-btn="${CSS.escape(id)}"]`).forEach(btn => { btn.textContent = hit.value ? (btn.dataset.noteActive || "note*") : (btn.dataset.noteEmpty || "note"); });
    };
    return {
      row,
      decisions,
      annotations,
      markExported,
      setVerdict,
      setNote,
      choice: spec => choice(spec),
      note: spec => note(spec),
    };
  }, { formValues, choice, drawer, field, note, select: selectField, textarea: textareaField });
  const exportSvg = (source, filename, clean = () => {}) => {
    const node = typeof source === "string" ? $(source) : source;
    if (!node) return false;
    const copy = node.cloneNode(true);
    const box = node.viewBox?.baseVal;
    copy.setAttribute("xmlns", SVG_NS);
    if (box) {
      copy.setAttribute("width", box.width);
      copy.setAttribute("height", box.height);
    }
    clean(copy);
    const styles = getComputedStyle(node);
    copy.querySelectorAll("[fill^='var('],[stroke^='var(']").forEach(item => ["fill", "stroke"].forEach(attr => {
      const raw = item.getAttribute(attr);
      if (!raw?.startsWith("var(")) return;
      const token = raw.slice(4, -1).split(",")[0].trim();
      item.setAttribute(attr, styles.getPropertyValue(token).trim() || raw);
    }));
    download(filename, "image/svg+xml;charset=utf-8", new XMLSerializer().serializeToString(copy));
    return true;
  };

  const slug = document.title.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  const themeKey = "theme:" + slug;
  const root = document.documentElement;
  const storedTheme = (() => { try { return localStorage.getItem(themeKey); } catch { return null; } })();
  if (storedTheme) root.dataset.theme = storedTheme;
  const toggleTheme = () => {
    const dark = root.dataset.theme ? root.dataset.theme === "dark" : !matchMedia("(prefers-color-scheme: light)").matches;
    const next = dark ? "light" : "dark";
    try { localStorage.setItem(themeKey, root.dataset.theme = next); } catch { root.dataset.theme = next; }
  };

  let toastTimer = 0;
  const flash = message => {
    const toast = $("#toast"); if (!toast?.showPopover) return;
    toast.textContent = message;
    try { toast.showPopover(); } catch { /* already open */ }
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { try { toast.hidePopover(); } catch { /* already hidden */ } }, 1600);
  };

  const mirror = text => { const box = $("#egress"); if (box) { box.value = text; box.focus(); box.select(); } };
  const copyText = async text => {
    mirror(text);
    try { await navigator.clipboard.writeText(text); flash("Copied"); return true; }
    catch { flash("Clipboard denied — mirror selected, copy manually"); return false; }
  };
  const download = (name, mime, text) => {
    const url = URL.createObjectURL(new Blob([text], { type: mime }));
    Object.assign(document.createElement("a"), { href: url, download: name }).click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  };

  const REDACT = [
    /AKIA[0-9A-Z]{16}/g, /ghp_[A-Za-z0-9]{36,}/g, /xox[baprs]-[A-Za-z0-9-]{10,}/g, /sk-[A-Za-z0-9]{20,}/g,
    /-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----/g,
    /eyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]+/g,
    /(\b(?:password|passwd|secret|token|api[_-]?key)\b['"]?\s*[:=]\s*['"]?)[^\s'",;]{6,}/gi,
    /(:\/\/[^\/\s:@]+):[^\/\s@]+@/g,
  ];
  const redact = text => {
    let hits = 0;
    const out = REDACT.reduce((acc, pattern) => acc.replace(pattern, (all, keep) => { hits += 1; return (keep && all.startsWith(keep) ? keep : "") + `«REDACTED:${hits}»`; }), text);
    return { text: out, hits };
  };

  const VOCAB = ["approve", "approve_with_notes", "reject", "defer", "edit", "comment", "dismiss"];
  const validateEnvelope = (env, kind) => {
    const errs = [];
    if (env.kind !== kind) errs.push("kind");
    if (env.version !== 1) errs.push("version");
    if (!env.artifact?.id || !env.artifact?.title) errs.push("artifact");
    if (!VOCAB.includes(env.decision?.status)) errs.push("decision.status");
    for (const key of ["decisions", "changes", "annotations"]) { if (!Array.isArray(env[key])) errs.push(key); }
    (env.decisions ?? []).forEach(row => { if (!row.id || !VOCAB.includes(row.verdict)) errs.push("decision:" + row.id); });
    return errs;
  };

  const returnMeta = document.querySelector('meta[name="artifact-return"]');
  const tokenMeta = document.querySelector('meta[name="artifact-token"]');
  const served = Boolean(returnMeta);
  const send = async env => {
    const res = await fetch(returnMeta.content, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Artifact-Token": tokenMeta?.content ?? "" },
      body: JSON.stringify({ kind: env.kind, artifact: env.artifact.id, version: env.version, data: env }),
    });
    if (!res.ok) throw new Error("submit " + res.status);
    return res.json();
  };

  const view = {
    read: () => { try { return Object.fromEntries(new URLSearchParams(location.hash.slice(1))); } catch { return {}; } },
    write: patch => {
      const params = new URLSearchParams(location.hash.slice(1));
      for (const [key, value] of Object.entries(patch)) { if (value == null || value === "") params.delete(key); else params.set(key, value); }
      history.replaceState(null, "", "#" + params);
    },
  };

  const spy = () => {
    const anchors = $$(".toc a[href^='#']"); if (!anchors.length) return;
    const forId = id => $(`.toc a[href="#${CSS.escape(id)}"]`);
    const watcher = new IntersectionObserver(entries => {
      entries.forEach(entry => { if (entry.isIntersecting) { $$(".toc a.on").forEach(a => a.classList.remove("on")); forId(entry.target.id)?.classList.add("on"); } });
    }, { rootMargin: "-20% 0px -70% 0px" });
    anchors.forEach(anchor => { const target = document.getElementById(anchor.hash.slice(1)); if (target) watcher.observe(target); });
  };

  const boot = config => {
    const { kind, envelope, toMarkdown, filename = slug || kind, isChanged, onExported = () => {}, redactPayload = false, narrative = false } = config;
    addEventListener("beforeprint", () => $$("details").forEach(d => { d.dataset.wasOpen = String(d.open); d.open = true; }));
    addEventListener("afterprint", () => $$("details").forEach(d => { d.open = d.dataset.wasOpen === "true"; }));
    if (narrative) $('[data-export="send"]')?.closest("section")?.remove();
    else if (served) { const sendBtn = $('[data-export="send"]'); if (sendBtn) sendBtn.hidden = false; }
    else $('[data-export="send"]')?.closest("section")?.setAttribute("hidden", "");
    if (narrative || !isChanged) $('[data-export="changed"]')?.remove();
    const changedNow = isChanged ?? (() => false);
    const outbound = text => (redactPayload ? redact(text) : { text, hits: 0 });
    const doExport = async (mode, control) => {
      const env = envelope(mode === "changed");
      const errs = validateEnvelope(env, kind);
      if (errs.length) { mirror("[BLOCKED] invalid payload: " + errs.join(", ")); flash("Export blocked"); return; }
      if (mode === "send") {
        control.disabled = true;
        try { await send(env); control.textContent = "Sent"; flash("Sent to agent"); onExported("sent"); }
        catch {
          control.textContent = "Send failed — copied instead";
          const { text } = outbound(JSON.stringify(env, null, 2));
          if (await copyText(text)) onExported("copied");
        }
        finally { control.disabled = false; refresh(); }
        return;
      }
      const payload = mode === "md" ? toMarkdown(env) : JSON.stringify(env, null, 2);
      const { text, hits } = outbound(payload);
      if (hits) flash(`${hits} value${hits > 1 ? "s" : ""} redacted`);
      if (mode === "json") { mirror(text); download(filename + ".json", "application/json", text); onExported("downloaded"); }
      else if (await copyText(text)) onExported("copied");
      refresh();
    };
    const refresh = () => { const changed = $('[data-export="changed"]'); if (changed) changed.disabled = !changedNow(); };
    document.addEventListener("click", event => {
      if (event.target.closest("[data-toggle-theme]")) { toggleTheme(); return; }
      const hit = event.target.closest("[data-export]");
      if (hit && !hit.disabled) doExport(hit.dataset.export, hit);
    });
    spy();
    refresh();
    return { refresh, flash, copyText };
  };

  return {
    $, $$, el, svg, esc, clone, payload, index, md, fmt, slug, flash, copyText,
    download, exportSvg, debounce, delegate, capture, redact, VOCAB,
    validateEnvelope, served, send, view, boot,
  };
})();
