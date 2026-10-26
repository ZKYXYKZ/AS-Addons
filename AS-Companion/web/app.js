const ICON = (n) => "https://wow.zamimg.com/images/wow/icons/large/" + String(n).toLowerCase() + ".jpg";
const MAX_POINTS = 51;
const SLOTS = 6;
const CLASS_COLORS = { warrior: "#c79c6e", paladin: "#f58cba", hunter: "#abd473", rogue: "#fff569", priest: "#ffffff", shaman: "#2459ff", mage: "#69ccf0", warlock: "#9482c9", druid: "#ff7d0a" };
const RARITY_COLORS = ["#d9d9d9", "#1eff00", "#0070dd", "#a335ee", "#ff8000"];

const STR = {
  fr: {
    new: "Nouveau", dup: "Dupliquer", ren: "Renommer", del: "Supprimer", delConfirm: "Supprimer ce build ?", imp: "Importer", exp: "Exporter",
    launch: "Lancer le jeu", running: "Jeu en cours", build: "Build", talents: "Talents", spells: "Sorts", jewels: "Bijoux", rules: "Règles", options: "Options",
    none: "Aucun build pour cette classe. Cliquez sur Nouveau.", spec: "Spé", baseVal: "Valeurs de base, plus fortes aux raretés supérieures", pts: "points", rank: "Rang", next: "Rang suivant", locked: "Rangée verrouillée : {n} points requis dans cet arbre",
    clickTalent: "Clic gauche : +1 · Clic droit : -1", reset: "Réinitialiser les talents",
    pool: "Sorts de la classe", poolHint: "Clic : ajouter · Clic droit : bannir", prio: "Ordre de priorité", prioHint: "Un run garde 6 sorts : les 6 premiers sont visés, les suivants servent de repli. Le poids (1 à 5) entre dans le score avec la rareté.",
    weight: "Poids", banned: "Banni", fallbackSep: "Repli (au-delà de 6 sorts)", emptyPrio: "Cliquez un sort à gauche pour l'ajouter.",
    rings: "Anneaux", trinkets: "Bijoux", amulets: "Amulette", legendary: "Légendaires de la classe (une par sort)", target: "visé", fallback: "repli",
    jewelHint: "Clic : ajouter / retirer · Clic droit : bannir. Les premiers sont visés, les suivants servent de repli. Anneaux et bijoux ne se changent plus une fois pris ; l'amulette se remplace.",
    rarity: "Influence de la rareté", rarityHelp: "0 % : seule la priorité compte. 100 % : une légendaire vaut 5 fois une commune.",
    reserve: "Relances gardées en réserve", banishes: "Bannissements disponibles par run", reroll: "Rien du build : relancer avant de skip",
    fallbackLevel: "Anneaux et bijoux de repli à partir du niveau", fallbackHelp: "Avant ce niveau, seuls les anneaux et bijoux visés sont pris : ils ne se remplacent plus ensuite.",
    boost: "Bonus de synergie", boostHelp: "Multiplie le poids d'un sort dont vous portez l'amulette légendaire ou que vous avez déjà monté.",
    adapt: "Adapter le build à la run", adaptHelp: "Tient compte des sorts déjà pris (6 emplacements) et de l'amulette portée.",
    gamePath: "Chemin du jeu", browse: "Parcourir", lang: "Langue", auto: "Auto", autoPick: "Sélection auto des cartes", autoPickHelp: "Le compagnon choisit et relance à votre place (touches 1, 2, 3, R). Skip et bannir restent manuels.",
    overlay: "Bandeau de conseil par-dessus le jeu", importTitle: "Collez un build (texte d'export) puis validez", exportTitle: "Copiez ce texte pour partager le build", ok: "Importer", close: "Fermer", bad: "Texte de build invalide",
    renamePrompt: "Nouveau nom du build", saved: "Enregistré", gameOff: "Jeu fermé", advice: "Conseil",
  },
  en: {
    new: "New", dup: "Duplicate", ren: "Rename", del: "Delete", delConfirm: "Delete this build?", imp: "Import", exp: "Export",
    launch: "Launch game", running: "Game running", build: "Build", talents: "Talents", spells: "Spells", jewels: "Jewelry", rules: "Rules", options: "Options",
    none: "No build for this class. Click New.", spec: "Spec", baseVal: "Base values, stronger at higher rarities", pts: "points", rank: "Rank", next: "Next rank", locked: "Row locked: {n} points required in this tree",
    clickTalent: "Left click: +1 · Right click: -1", reset: "Reset talents",
    pool: "Class spells", poolHint: "Click: add · Right click: ban", prio: "Priority order", prioHint: "A run holds 6 spells: the first 6 are targets, the rest are fallbacks. Weight (1 to 5) counts in the score with rarity.",
    weight: "Weight", banned: "Banned", fallbackSep: "Fallback (beyond 6 spells)", emptyPrio: "Click a spell on the left to add it.",
    rings: "Rings", trinkets: "Trinkets", amulets: "Amulet", legendary: "Class legendaries (one per spell)", target: "target", fallback: "fallback",
    jewelHint: "Click: add / remove · Right click: ban. The first ones are targets, the rest are fallbacks. Rings and trinkets can't be swapped once taken; the amulet can.",
    rarity: "Rarity influence", rarityHelp: "0%: only priority counts. 100%: a legendary is worth 5 commons.",
    reserve: "Rerolls kept in reserve", banishes: "Banishes available per run", reroll: "Nothing from the build: reroll before skipping",
    fallbackLevel: "Fallback rings and trinkets from level", fallbackHelp: "Before this level, only target rings and trinkets are taken: they can't be swapped later.",
    boost: "Synergy bonus", boostHelp: "Multiplies the weight of a spell whose legendary amulet you wear or that you already ranked up.",
    adapt: "Adapt the build to the run", adaptHelp: "Accounts for spells already taken (6 slots) and the worn amulet.",
    gamePath: "Game path", browse: "Browse", lang: "Language", auto: "Auto", autoPick: "Auto-pick cards", autoPickHelp: "The companion picks and rerolls for you (keys 1, 2, 3, R). Skip and banish stay manual.",
    overlay: "Advice banner over the game", importTitle: "Paste a build (export text) then confirm", exportTitle: "Copy this text to share the build", ok: "Import", close: "Close", bad: "Invalid build text",
    renamePrompt: "New build name", saved: "Saved", gameOff: "Game closed", advice: "Advice",
  },
};

let DATA, STATE, CLASS = null, TAB = "build";
const $ = (id) => document.getElementById(id);
const lang = () => {
  const l = STATE.settings.lang || "auto";
  if (l !== "auto") return l;
  return (STATE.settings.gameLang || navigator.language || "en").slice(0, 2) === "fr" ? "fr" : "en";
};
const T = (k, vars) => {
  let s = (STR[lang()] || STR.en)[k] || STR.en[k] || k;
  for (const [a, b] of Object.entries(vars || {})) s = s.split("{" + a + "}").join(b);
  return s;
};
const L = (o) => (o && typeof o === "object" ? o[lang()] || o.en : o);
const el = (tag, cls, html) => { const e = document.createElement(tag); if (cls) e.className = cls; if (html !== undefined) e.innerHTML = html; return e; };
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

const cls = (key) => DATA.classes.find((c) => c.key === key);
const spellOf = (c, key) => c.spells.find((s) => s.key === key);
const builds = (key) => STATE.builds.filter((b) => b.class === key);
const active = () => {
  const list = builds(CLASS);
  return list.find((b) => b.id === STATE.active[CLASS]) || list[0] || null;
};
function legendary(c, spellKey) {
  const l = DATA.legendaries[spellKey];
  const s = spellOf(c, spellKey);
  if (!l || !s) return null;
  return { key: "leg:" + spellKey, icon: l.icon, sub: s.icon, legendary: true, lines: l.lines, name: { en: l.family.en + " : " + s.name.en, fr: l.family.fr + " : " + s.name.fr } };
}
function jewel(cat, key, c) {
  if (cat === "amulets" && key.startsWith("leg:")) return legendary(c, key.slice(4));
  return DATA[cat].find((j) => j.key === key);
}

let saveTimer;
function save() {
  clearTimeout(saveTimer);
  saveTimer = setTimeout(() => fetch("/api/state", { method: "POST", body: JSON.stringify(STATE) }), 300);
}
function changed() { save(); render(); }

function newBuild(classKey, name) {
  const b = { id: STATE.nextId++, class: classKey, name: name || "Build " + (STATE.nextId - 1), talents: {}, spells: [], ban: {}, rings: [], trinkets: [], amulets: [],
    rules: { rarity: 50, reserve: 1, reroll: 1, banishes: 3, fallbackLevel: 10, boost: 2, adapt: 1 } };
  STATE.builds.push(b);
  STATE.active[classKey] = b.id;
  return b;
}

function treePoints(b, tree) { return tree.talents.reduce((n, t) => n + (b.talents[t.key] || 0), 0); }
function totalPoints(b) { return cls(b.class).trees.reduce((n, t) => n + treePoints(b, t), 0); }
function treeValid(b, tree) {
  for (const t of tree.talents) {
    if ((b.talents[t.key] || 0) > 0) {
      const below = tree.talents.filter((o) => o.row < t.row).reduce((n, o) => n + (b.talents[o.key] || 0), 0);
      if (below < t.row * 5) return false;
    }
  }
  return true;
}
function tryRank(b, tree, t, d) {
  const r = b.talents[t.key] || 0;
  const n = r + d;
  if (n < 0 || n > t.max) return false;
  if (d > 0 && totalPoints(b) >= MAX_POINTS) return false;
  if (n) b.talents[t.key] = n; else delete b.talents[t.key];
  if (treeValid(b, tree)) return true;
  if (r) b.talents[t.key] = r; else delete b.talents[t.key];
  return false;
}
function canAdd(b, tree, t) {
  const r = b.talents[t.key] || 0;
  if (r >= t.max || totalPoints(b) >= MAX_POINTS) return false;
  b.talents[t.key] = r + 1;
  const ok = treeValid(b, tree);
  if (r) b.talents[t.key] = r; else delete b.talents[t.key];
  return ok;
}
function spec(b) {
  const c = cls(b.class);
  const parts = c.trees.map((t) => treePoints(b, t));
  const max = Math.max(...parts);
  return { tree: max > 0 ? c.trees[parts.indexOf(max)] : null, parts };
}

function showTip(e, html) { const t = $("tip"); t.innerHTML = html; t.style.display = "block"; moveTip(e); }
function moveTip(e) { const t = $("tip"); t.style.left = Math.min(e.clientX + 16, innerWidth - 380) + "px"; t.style.top = Math.min(e.clientY + 12, innerHeight - t.offsetHeight - 10) + "px"; }
function hideTip() { $("tip").style.display = "none"; }
function tipOn(node, fn) { node.onmouseenter = (e) => showTip(e, fn()); node.onmousemove = moveTip; node.onmouseleave = hideTip; }
const fmtV = (desc, v) => (v === undefined ? desc : desc.split("{v}").join(Number.isInteger(v) ? v : +v.toFixed(1)));

function iconNode(icon, extra) {
  const d = el("div", "ic " + (extra || ""));
  const img = el("img"); img.src = ICON(icon); img.loading = "lazy";
  d.appendChild(img);
  return d;
}

function renderTalents(sec, b) {
  const c = cls(b.class);
  const sp = spec(b);
  const wrap = el("div", "trees");
  c.trees.forEach((tree, ti) => {
    const pts = treePoints(b, tree);
    const box = el("div", "tree" + (sp.tree === tree ? " spec" : ""));
    box.style.backgroundImage = `linear-gradient(rgba(14,14,16,.5), rgba(14,14,16,.82)), url(img/${b.class}-${ti}.jpg)`;
    box.appendChild(el("div", "head", `<span>${esc(L(tree.name))}</span><span>${pts} ${T("pts")}</span>`));
    const grid = el("div", "grid");
    grid.style.gridTemplateRows = "repeat(7, 58px)";
    const miles = tree.talents.filter((t) => t.milestone || t.capstone);
    for (let i = 1; i < miles.length; i++) {
      const a = miles[i - 1], z = miles[i];
      if (a.col !== z.col) continue;
      const ln = el("div", "line" + ((b.talents[a.key] || 0) >= a.max ? " on" : ""));
      ln.style.left = `calc(${(a.col + 0.5) * 25}% - 1px)`;
      ln.style.top = a.row * 58 + 50 + "px";
      ln.style.height = (z.row - a.row) * 58 - 42 + "px";
      grid.appendChild(ln);
    }
    tree.talents.forEach((t) => {
      const r = b.talents[t.key] || 0;
      const state = r >= t.max ? "full" : r > 0 ? "some" : canAdd(b, tree, t) ? "" : "locked";
      const n = iconNode(t.icon, state);
      n.style.gridRow = t.row + 1;
      n.style.gridColumn = t.col + 1;
      n.appendChild(el("span", "rk", `${r}/${t.max}`));
      n.onclick = () => { if (tryRank(b, tree, t, 1)) changed(); };
      n.oncontextmenu = (e) => { e.preventDefault(); if (tryRank(b, tree, t, -1)) changed(); };
      tipOn(n, () => {
        const rr = b.talents[t.key] || 0;
        const d = L(t.desc);
        let h = `<div class="t">${esc(L(t.name))}</div><div class="r">${T("rank")} ${rr}/${t.max}</div><div>${esc(fmtV(d, t.v !== undefined ? t.v * Math.max(rr, 1) : undefined))}</div>`;
        if (rr > 0 && rr < t.max && t.v !== undefined) h += `<div class="r" style="margin-top:6px">${T("next")}</div><div>${esc(fmtV(d, t.v * (rr + 1)))}</div>`;
        const below = tree.talents.filter((o) => o.row < t.row).reduce((x, o) => x + (b.talents[o.key] || 0), 0);
        if (below < t.row * 5) h += `<div class="warn">${T("locked", { n: t.row * 5 })}</div>`;
        return h + `<div class="r" style="margin-top:6px">${T("clickTalent")}</div>`;
      });
      grid.appendChild(n);
    });
    box.appendChild(grid);
    const ml = el("div", "miles");
    miles.forEach((t) => ml.appendChild(el("div", (b.talents[t.key] || 0) > 0 ? "on" : "", `${t.row * 5} ${T("pts")} · ${esc(L(t.name))}`)));
    box.appendChild(ml);
    wrap.appendChild(box);
  });
  sec.appendChild(wrap);
  const reset = el("button", "", T("reset"));
  reset.style.marginTop = "12px";
  reset.onclick = () => { b.talents = {}; changed(); };
  sec.appendChild(reset);
}

function renderSpells(sec, b) {
  const c = cls(b.class);
  const cols = el("div", "cols");
  const left = el("div", "list");
  left.appendChild(el("h3", "", T("pool")));
  left.appendChild(el("div", "hint", T("poolHint")));
  c.spells.forEach((s) => {
    const idx = b.spells.findIndex((x) => x.key === s.key);
    const it = el("div", "item pool");
    it.appendChild(iconNode(s.icon, b.ban[s.key] ? "ban" : ""));
    it.appendChild(el("div", "name", esc(L(s.name))));
    it.appendChild(el("div", "tag" + (b.ban[s.key] ? " ban" : ""), b.ban[s.key] ? T("banned") : idx >= 0 ? "#" + (idx + 1) : ""));
    it.onclick = () => { delete b.ban[s.key]; if (idx < 0) b.spells.push({ key: s.key, w: 3 }); changed(); };
    it.oncontextmenu = (e) => { e.preventDefault(); if (b.ban[s.key]) delete b.ban[s.key]; else { b.ban[s.key] = true; if (idx >= 0) b.spells.splice(idx, 1); } changed(); };
    left.appendChild(it);
  });
  const right = el("div", "list");
  right.appendChild(el("h3", "", T("prio")));
  right.appendChild(el("div", "hint", T("prioHint")));
  if (!b.spells.length) right.appendChild(el("div", "hint", T("emptyPrio")));
  b.spells.forEach((e, i) => {
    const s = spellOf(c, e.key);
    if (!s) return;
    if (i === SLOTS) right.appendChild(el("div", "sep", T("fallbackSep")));
    const it = el("div", "item" + (i >= SLOTS ? " extra" : ""));
    it.appendChild(el("div", "num", i + 1));
    it.appendChild(iconNode(s.icon));
    it.appendChild(el("div", "name", esc(L(s.name))));
    const btn = (txt, fn) => { const x = el("button", "small", txt); x.onclick = fn; it.appendChild(x); };
    btn("▲", () => { if (i > 0) { [b.spells[i - 1], b.spells[i]] = [b.spells[i], b.spells[i - 1]]; changed(); } });
    btn("▼", () => { if (i < b.spells.length - 1) { [b.spells[i + 1], b.spells[i]] = [b.spells[i], b.spells[i + 1]]; changed(); } });
    it.appendChild(el("span", "hint", T("weight")));
    btn("−", () => { e.w = Math.max(1, (e.w || 3) - 1); changed(); });
    it.appendChild(el("b", "", e.w || 3));
    btn("+", () => { e.w = Math.min(5, (e.w || 3) + 1); changed(); });
    btn("✕", () => { b.spells.splice(i, 1); changed(); });
    right.appendChild(it);
  });
  cols.appendChild(left);
  cols.appendChild(right);
  sec.appendChild(cols);
}

function jewelIcon(b, cat, j, want, c) {
  const list = b[cat];
  const idx = list.indexOf(j.key);
  let state = j.legendary ? "leg" : "";
  if (b.ban[j.key]) state = "ban"; else if (idx >= 0) state = idx < want ? "target" : "fallback";
  const n = iconNode(j.icon, state);
  if (idx >= 0 && !b.ban[j.key]) n.appendChild(el("span", "badge", idx + 1)).style.color = idx < want ? "var(--gold)" : "var(--blue)";
  if (j.sub) { const s = el("img", "sub"); s.src = ICON(j.sub); n.appendChild(s); }
  n.onclick = () => { delete b.ban[j.key]; if (idx >= 0) list.splice(idx, 1); else list.push(j.key); changed(); };
  n.oncontextmenu = (e) => { e.preventDefault(); if (idx >= 0) list.splice(idx, 1); if (b.ban[j.key]) delete b.ban[j.key]; else b.ban[j.key] = true; changed(); };
  tipOn(n, () => {
    if (j.legendary) return `<div class="t leg">${esc(L(j.name))}</div>` + (j.lines[lang()] || j.lines.en).map((x) => `<div>${esc(x)}</div>`).join("");
    const lines = j.desc && typeof j.desc === "object" ? j.desc[lang()] || j.desc.en : [];
    const rar = j.tier ? `<div class="mute">${esc(L(DATA.rarity[j.tier[0]]))}</div>` : "";
    return `<div class="t">${esc(L(j.name))}</div>` + rar + lines.map((x) => `<div>${esc(x)}</div>`).join("") + (lines.length ? `<div class="mute">${T("baseVal")}</div>` : "");
  });
  return n;
}

function renderJewels(sec, b) {
  const c = cls(b.class);
  sec.appendChild(el("div", "hint", T("jewelHint")));
  const cols = el("div", "jcols");
  [["rings", 2], ["trinkets", 2], ["amulets", 1]].forEach(([cat, want]) => {
    const col = el("div", "jcol");
    col.appendChild(el("h3", "", T(cat)));
    const g = el("div", "jgrid");
    DATA[cat].forEach((j) => g.appendChild(jewelIcon(b, cat, j, want, c)));
    col.appendChild(g);
    if (cat === "amulets") {
      col.appendChild(el("div", "legtitle", T("legendary")));
      const lg = el("div", "jgrid");
      c.spells.forEach((s) => { const j = legendary(c, s.key); if (j) lg.appendChild(jewelIcon(b, cat, j, want, c)); });
      col.appendChild(lg);
    }
    const jl = el("div", "jlist");
    b.jw = b.jw || {};
    b[cat].forEach((k, i) => {
      const j = jewel(cat, k, c);
      if (!j) return;
      const row = el("div", "jrow", `<span class="jn">${i + 1}. ${esc(L(j.name))} <span>${i < want ? T("target") : T("fallback")}</span></span>`);
      const w = () => b.jw[k] || (i < want ? 5 : 3);
      const btn = (txt, fn) => { const x = el("button", "small", txt); x.onclick = fn; row.appendChild(x); };
      row.appendChild(el("span", "hint", T("weight")));
      btn("−", () => { b.jw[k] = Math.max(1, w() - 1); changed(); });
      row.appendChild(el("b", "", w()));
      btn("+", () => { b.jw[k] = Math.min(5, w() + 1); changed(); });
      jl.appendChild(row);
    });
    col.appendChild(jl);
    cols.appendChild(col);
  });
  sec.appendChild(cols);
}

function field(form, label, input, help) {
  form.appendChild(el("label", "", label));
  form.appendChild(input);
  if (help) form.appendChild(el("div", "help", help));
}
function rangeInput(get, set, min, max, step, fmt) {
  const w = el("div");
  const r = el("input"); r.type = "range"; r.min = min; r.max = max; r.step = step; r.value = get();
  const v = el("span", "val", fmt(get()));
  r.oninput = () => { set(+r.value); v.textContent = fmt(+r.value); save(); };
  w.appendChild(r); w.appendChild(v);
  return w;
}
function checkInput(get, set) {
  const c = el("input"); c.type = "checkbox"; c.checked = !!get();
  c.onchange = () => { set(c.checked ? 1 : 0); save(); };
  const w = el("div"); w.appendChild(c); return w;
}

function renderRules(sec, b) {
  const r = b.rules;
  const f = el("div", "form");
  field(f, T("rarity"), rangeInput(() => r.rarity ?? 50, (x) => (r.rarity = x), 0, 100, 10, (x) => x + " %"), T("rarityHelp"));
  field(f, T("reserve"), rangeInput(() => r.reserve ?? 1, (x) => (r.reserve = x), 0, 6, 1, String));
  field(f, T("banishes"), rangeInput(() => r.banishes ?? 3, (x) => (r.banishes = x), 0, 3, 1, String));
  field(f, T("reroll"), checkInput(() => r.reroll ?? 1, (x) => (r.reroll = x)));
  field(f, T("fallbackLevel"), rangeInput(() => r.fallbackLevel ?? 10, (x) => (r.fallbackLevel = x), 1, 40, 1, String), T("fallbackHelp"));
  field(f, T("boost"), rangeInput(() => r.boost ?? 2, (x) => (r.boost = x), 1, 4, 0.5, (x) => "x" + x), T("boostHelp"));
  field(f, T("adapt"), checkInput(() => r.adapt ?? 1, (x) => (r.adapt = x)), T("adaptHelp"));
  sec.appendChild(f);
}

function renderOptions(sec) {
  const s = STATE.settings;
  const f = el("div", "form");
  const p = el("input"); p.type = "text"; p.value = s.gamePath || ""; p.onchange = () => { s.gamePath = p.value; save(); };
  const br = el("button", "", T("browse"));
  br.onclick = async () => {
    const r = await (await fetch("/api/browse", { method: "POST", body: p.value })).json();
    if (r.path) { p.value = r.path; s.gamePath = r.path; save(); }
  };
  const pw = el("div", "pathrow"); pw.appendChild(p); pw.appendChild(br);
  field(f, T("gamePath"), pw);
  const sel = el("select");
  [["auto", T("auto")], ["fr", "Français"], ["en", "English"]].forEach(([v, l]) => { const o = el("option", "", l); o.value = v; if ((s.lang || "auto") === v) o.selected = true; sel.appendChild(o); });
  sel.onchange = () => { s.lang = sel.value; changed(); };
  field(f, T("lang"), sel);
  field(f, T("autoPick"), checkInput(() => s.autoPick, (x) => (s.autoPick = x)), T("autoPickHelp"));
  field(f, T("overlay"), checkInput(() => s.overlay ?? 1, (x) => (s.overlay = x)));
  sec.appendChild(f);
}

function encode(b) {
  const c = cls(b.class);
  const trees = c.trees.map((t) => t.talents.map((x) => b.talents[x.key] || 0).join("")).join("/");
  const r = b.rules;
  return ["SB1", b.class, b.name.replace(/[;|/,:]/g, " "), trees, b.spells.map((s) => s.key + ":" + (s.w || 3)).join(","), Object.keys(b.ban).sort().join(","),
    ...["rings", "trinkets", "amulets"].map((cat) => b[cat].map((k) => (b.jw && b.jw[k] ? k + ":" + b.jw[k] : k)).join(",")),
    [r.rarity ?? 50, r.reserve ?? 1, r.reroll ?? 1, r.banishes ?? 3, r.fallbackLevel ?? 10, r.boost ?? 2, r.adapt ?? 1].join(",")].join(";");
}
function decode(text) {
  const f = text.trim().split(";");
  if (f[0] !== "SB1" || f.length < 10) return null;
  const c = cls(f[1]);
  if (!c) return null;
  const b = newBuild(c.key, f[2] || undefined);
  f[3].split("/").forEach((s, ti) => { const tree = c.trees[ti]; if (!tree) return; tree.talents.forEach((t, i) => { const r = +s[i]; if (r > 0) b.talents[t.key] = Math.min(r, t.max); }); });
  f[4].split(",").filter(Boolean).forEach((p) => { const [k, w] = p.split(":"); if (spellOf(c, k)) b.spells.push({ key: k, w: Math.max(1, Math.min(5, +w || 3)) }); });
  f[5].split(",").filter(Boolean).forEach((k) => (b.ban[k] = true));
  b.jw = {};
  ["rings", "trinkets", "amulets"].forEach((cat, i) => f[6 + i].split(",").filter(Boolean).forEach((p) => {
    const m = p.match(/^(.*?)(?::([1-5]))?$/);
    const k = m[1];
    if (!jewel(cat, k, c)) return;
    b[cat].push(k);
    if (m[2]) b.jw[k] = Math.max(1, Math.min(5, +m[2]));
  }));
  const r = f[9].split(",").map(Number);
  Object.assign(b.rules, { rarity: r[0] ?? 50, reserve: r[1] ?? 1, reroll: r[2] ?? 1, banishes: r[3] ?? 3, fallbackLevel: r[4] || 10, boost: r[5] || 2, adapt: r[6] ?? 1 });
  return b;
}

function modal(title, text, okLabel, onOk) {
  $("modalTitle").textContent = title;
  $("modalText").value = text;
  $("modalOk").textContent = okLabel || "";
  $("modalOk").style.display = okLabel ? "" : "none";
  $("modalClose").textContent = T("close");
  $("modal").classList.remove("hidden");
  $("modalText").focus();
  $("modalText").select();
  $("modalOk").onclick = () => onOk($("modalText").value);
}

function renderHeader() {
  const cs = $("classSel");
  cs.innerHTML = "";
  DATA.classes.forEach((c) => { const o = el("option", "", esc(L(c.name))); o.value = c.key; o.style.color = CLASS_COLORS[c.key]; if (c.key === CLASS) o.selected = true; cs.appendChild(o); });
  cs.style.color = CLASS_COLORS[CLASS];
  const bs = $("buildSel");
  bs.innerHTML = "";
  const b = active();
  builds(CLASS).forEach((x) => { const o = el("option", "", esc(x.name)); o.value = x.id; if (b && x.id === b.id) o.selected = true; bs.appendChild(o); });
  bs.disabled = !b;
  [["newBtn", "new"], ["dupBtn", "dup"], ["renBtn", "ren"], ["delBtn", "del"], ["impBtn", "imp"], ["expBtn", "exp"]].forEach(([id, k]) => ($(id).textContent = T(k)));
  const tabs = $("tabs");
  tabs.innerHTML = "";
  ["build", "rules", "options"].forEach((t) => {
    const x = el("button", t === TAB ? "active" : "", T(t));
    x.onclick = () => { TAB = t; render(); };
    tabs.appendChild(x);
  });
  if (b) {
    const s = spec(b);
    tabs.appendChild(el("div", "right hint", `${T("spec")} : ${s.tree ? esc(L(s.tree.name)) : "-"} &nbsp; ${s.parts.join("/")} &nbsp; (${totalPoints(b)}/51)`));
  }
}

function render() {
  const y = window.scrollY;
  hideTip();
  renderHeader();
  const b = active();
  ["build", "rules", "options"].forEach((t) => {
    const sec = $("tab-" + t);
    sec.innerHTML = "";
    sec.className = t === TAB ? "show" : "";
    if (t !== TAB) return;
    if (t === "options") return renderOptions(sec);
    if (!b) { sec.appendChild(el("div", "empty", T("none"))); return; }
    if (t === "rules") return renderRules(sec, b);
    [["talents", renderTalents], ["spells", renderSpells], ["jewels", renderJewels]].forEach(([k, fn]) => {
      const part = el("div", "part");
      part.appendChild(el("h2", "", T(k)));
      fn(part, b);
      sec.appendChild(part);
    });
  });
  window.scrollTo(0, y);
}

async function poll() {
  try {
    const s = await (await fetch("/api/status")).json();
    const lb = $("launchBtn");
    lb.textContent = s.running ? T("running") : T("launch");
    lb.disabled = !!s.running;
    $("status").innerHTML = s.running ? (s.advice ? `${T("advice")} : <b>${esc(s.advice)}</b>` : T("running")) : s.error ? `<span style="color:var(--red)">${esc(s.error)}</span>` : "";
  } catch (e) {}
  setTimeout(poll, 1500);
}

document.addEventListener("click", (e) => {
  const a = e.target.closest("footer a");
  if (!a) return;
  e.preventDefault();
  fetch("/api/open", { method: "POST", body: a.href }).catch(() => window.open(a.href));
});

async function init() {
  [DATA, STATE] = await Promise.all([fetch("data.json").then((r) => r.json()), fetch("/api/state").then((r) => r.json())]);
  STATE.builds = STATE.builds || [];
  STATE.active = STATE.active || {};
  STATE.settings = STATE.settings || {};
  STATE.nextId = STATE.nextId || 1;
  CLASS = STATE.lastClass || "warrior";
  $("classSel").onchange = (e) => { CLASS = e.target.value; STATE.lastClass = CLASS; changed(); };
  $("buildSel").onchange = (e) => { STATE.active[CLASS] = +e.target.value; changed(); };
  $("newBtn").onclick = () => { newBuild(CLASS); changed(); };
  $("dupBtn").onclick = () => { const b = active(); if (!b) return; const c = JSON.parse(JSON.stringify(b)); c.id = STATE.nextId++; c.name += " (2)"; STATE.builds.push(c); STATE.active[CLASS] = c.id; changed(); };
  $("renBtn").onclick = () => { const b = active(); if (!b) return; const n = prompt(T("renamePrompt"), b.name); if (n) { b.name = n; changed(); } };
  $("delBtn").onclick = () => { const b = active(); if (!b || !confirm(T("delConfirm"))) return; STATE.builds = STATE.builds.filter((x) => x !== b); delete STATE.active[CLASS]; changed(); };
  $("expBtn").onclick = () => { const b = active(); if (b) modal(T("exportTitle"), encode(b)); };
  $("impBtn").onclick = () => modal(T("importTitle"), "", T("ok"), (txt) => {
    const b = decode(txt);
    if (!b) return alert(T("bad"));
    CLASS = b.class; STATE.lastClass = CLASS;
    $("modal").classList.add("hidden");
    changed();
  });
  $("modalClose").onclick = () => $("modal").classList.add("hidden");
  $("launchBtn").onclick = async () => { await fetch("/api/state", { method: "POST", body: JSON.stringify(STATE) }); await fetch("/api/launch", { method: "POST" }); };
  render();
  poll();
}
init();
