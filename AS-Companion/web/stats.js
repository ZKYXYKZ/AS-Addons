const STATS_STR = {
  fr: {
    empty: "Aucune partie enregistrée. Les parties lancées depuis le compagnon apparaissent ici à leur fin.",
    all: "Toutes", allModes: "Solo et coop", solo: "Solo", coop: "Coop", allZones: "Toutes les zones", allResults: "Tous les résultats", win: "Victoire", loss: "Défaite",
    runs: "Parties", wins: "Victoires", played: "Temps joué", bestTime: "Meilleure survie", maxLevel: "Niveau max", maxKills: "Victimes max",
    avgDps: "DPS moyen", maxDps: "DPS max", bosses: "Boss tués", guardians: "Gardiens tués",
    timeChart: "Durée de survie par partie", dpsChart: "DPS par partie", classChart: "Survie moyenne par classe", spellChart: "Part des dégâts par sort",
    spellHint: "Sur les parties filtrées, d'après le compteur du jeu (sinon le journal de combat)", bySpec: "Par spécialisation", byBuild: "Par build", takenMin: "Subis / min", byRace: "Par race", recent: "Dernières parties",
    spec: "Spé", race: "Race", cls: "Classe", n: "Parties", winRate: "Victoires", avgTime: "Survie moy.", maxLvl: "Niv. max", dps: "DPS moy.",
    date: "Date", build: "Build", result: "Résultat", time: "Durée", level: "Niv.", kills: "Victimes", run: "Partie", attack: "Attaque", pets: "Familiers", other: "Autres", endless: "Endless", bestEndless: "Meilleur endless",
    noDmg: "Pas encore de données de dégâts : activez le journal de combat (fait automatiquement par l'addon SurvivorsBuilds).",
  },
  en: {
    empty: "No run recorded yet. Runs started from the companion show up here when they end.",
    all: "All", allModes: "Solo and co-op", solo: "Solo", coop: "Co-op", allZones: "All zones", allResults: "All results", win: "Victory", loss: "Defeat",
    runs: "Runs", wins: "Victories", played: "Time played", bestTime: "Best survival", maxLevel: "Max level", maxKills: "Max kills",
    avgDps: "Average DPS", maxDps: "Max DPS", bosses: "Bosses killed", guardians: "Guardians killed",
    timeChart: "Survival time per run", dpsChart: "DPS per run", classChart: "Average survival by class", spellChart: "Damage share by spell",
    spellHint: "Over the filtered runs, from the game meter (else the combat log)", bySpec: "By spec", byBuild: "By build", takenMin: "Taken / min", byRace: "By race", recent: "Latest runs",
    spec: "Spec", race: "Race", cls: "Class", n: "Runs", winRate: "Victories", avgTime: "Avg survival", maxLvl: "Max lvl", dps: "Avg DPS",
    date: "Date", build: "Build", result: "Result", time: "Time", level: "Lvl", kills: "Kills", run: "Run", attack: "Attack", pets: "Pets", other: "Others", endless: "Endless", bestEndless: "Best endless",
    noDmg: "No damage data yet: the combat log must be on (the SurvivorsBuilds addon turns it on).",
  },
};
const ST = (k) => (STATS_STR[lang()] || STATS_STR.en)[k] || k;
const STAT_FILTER = { cls: "", zone: "", result: "", mode: "" };
let RUNS = null;

const mmss = (s) => { s = Math.round(+s || 0); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0"); };
const hms = (s) => { s = Math.round(+s || 0); const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60); return h ? h + " h " + String(m).padStart(2, "0") : m + " min"; };
const num = (v) => Math.round(+v || 0).toLocaleString(lang() === "fr" ? "fr-FR" : "en-US");
const avg = (a) => (a.length ? a.reduce((x, y) => x + y, 0) / a.length : 0);
const className = (k) => { const c = DATA.classes.find((x) => x.key === k); return c ? L(c.name) : k; };
const specName = (k) => {
  if (!k) return "-";
  const [c, i] = k.split("-");
  const cl = DATA.classes.find((x) => x.key === c);
  return cl && cl.trees[+i] ? L(cl.trees[+i].name) + " (" + L(cl.name) + ")" : k;
};
const spellName = (runClass, k) => {
  if (k.startsWith("=")) return k.slice(1);
  if (k === "Attack") return ST("attack");
  if (k === "Pets") return ST("pets");
  const cl = DATA.classes.find((x) => x.key === runClass);
  const s = cl && cl.spells.find((x) => x.key === k);
  return s ? L(s.name) : k;
};

function svgEl(tag, attrs) {
  const e = document.createElementNS("http://www.w3.org/2000/svg", tag);
  for (const [k, v] of Object.entries(attrs || {})) e.setAttribute(k, v);
  return e;
}

function niceMax(v) {
  if (v <= 0) return 1;
  const p = Math.pow(10, Math.floor(Math.log10(v)));
  for (const m of [1, 2, 2.5, 5, 10]) if (m * p >= v) return m * p;
  return 10 * p;
}

function chartBox(title, hint) {
  const box = el("div", "chart");
  box.appendChild(el("h3", "", esc(title)));
  if (hint) box.appendChild(el("div", "hint", esc(hint)));
  return box;
}

function legend(box, entries) {
  if (entries.length < 2) return;
  const lg = el("div", "legend");
  entries.forEach((e) => lg.appendChild(el("span", "", `<i style="background:${e.color}"></i>${esc(e.label)}`)));
  box.appendChild(lg);
}

function lineChart(title, points, fmt, tip, entries) {
  const box = chartBox(title);
  const W = 560, H = 200, PL = 46, PR = 12, PT = 10, PB = 26;
  const svg = svgEl("svg", { viewBox: `0 0 ${W} ${H}`, class: "plot", role: "img", "aria-label": title });
  const max = niceMax(Math.max(...points.map((p) => p.y)));
  const x = (i) => PL + (points.length > 1 ? (i * (W - PL - PR)) / (points.length - 1) : (W - PL - PR) / 2);
  const y = (v) => PT + (H - PT - PB) * (1 - v / max);
  for (let k = 0; k <= 4; k++) {
    const v = (max * k) / 4;
    svg.appendChild(svgEl("line", { x1: PL, x2: W - PR, y1: y(v), y2: y(v), class: "grid" }));
    const t = svgEl("text", { x: PL - 6, y: y(v) + 4, class: "tick", "text-anchor": "end" });
    t.textContent = fmt(v);
    svg.appendChild(t);
  }
  const step = Math.max(1, Math.ceil(points.length / 8));
  points.forEach((p, i) => {
    if (i % step && i !== points.length - 1) return;
    const t = svgEl("text", { x: x(i), y: H - 8, class: "tick", "text-anchor": "middle" });
    t.textContent = p.label;
    svg.appendChild(t);
  });
  if (points.length > 1) svg.appendChild(svgEl("polyline", { points: points.map((p, i) => x(i) + "," + y(p.y)).join(" "), class: "line" }));
  points.forEach((p, i) => {
    svg.appendChild(svgEl("circle", { cx: x(i), cy: y(p.y), r: 4, class: "dot", style: p.color ? `fill:${p.color}` : "" }));
    const hit = svgEl("circle", { cx: x(i), cy: y(p.y), r: 11, class: "hit" });
    tipOn(hit, () => tip(p));
    svg.appendChild(hit);
  });
  box.appendChild(svg);
  legend(box, entries || []);
  return box;
}

function barChart(title, bars, fmt, tip) {
  const box = chartBox(title);
  const W = 560, H = 200, PL = 46, PR = 12, PT = 18, PB = 30;
  const svg = svgEl("svg", { viewBox: `0 0 ${W} ${H}`, class: "plot", role: "img", "aria-label": title });
  const max = niceMax(Math.max(...bars.map((b) => b.v)));
  const y = (v) => PT + (H - PT - PB) * (1 - v / max);
  for (let k = 0; k <= 4; k++) {
    const v = (max * k) / 4;
    svg.appendChild(svgEl("line", { x1: PL, x2: W - PR, y1: y(v), y2: y(v), class: "grid" }));
    const t = svgEl("text", { x: PL - 6, y: y(v) + 4, class: "tick", "text-anchor": "end" });
    t.textContent = fmt(v);
    svg.appendChild(t);
  }
  const slot = (W - PL - PR) / bars.length;
  const bw = Math.min(48, slot * 0.6);
  bars.forEach((b, i) => {
    const cx = PL + slot * (i + 0.5);
    const top = y(b.v), base = y(0);
    const h = Math.max(1, base - top);
    const r = Math.min(4, h, bw / 2);
    const d = `M${cx - bw / 2},${base} V${top + r} Q${cx - bw / 2},${top} ${cx - bw / 2 + r},${top} H${cx + bw / 2 - r} Q${cx + bw / 2},${top} ${cx + bw / 2},${top + r} V${base} Z`;
    svg.appendChild(svgEl("path", { d, style: `fill:${b.color}`, class: "bar" }));
    const v = svgEl("text", { x: cx, y: top - 5, class: "val", "text-anchor": "middle" });
    v.textContent = fmt(b.v);
    svg.appendChild(v);
    const l = svgEl("text", { x: cx, y: H - 10, class: "tick", "text-anchor": "middle" });
    l.textContent = b.label;
    svg.appendChild(l);
    const hit = svgEl("rect", { x: cx - slot / 2, y: PT, width: slot, height: H - PT - PB, class: "hit" });
    tipOn(hit, () => tip(b));
    svg.appendChild(hit);
  });
  box.appendChild(svg);
  return box;
}

function shareBars(title, hint, rows) {
  const box = chartBox(title, hint);
  const list = el("div", "share");
  rows.forEach((r) => {
    const row = el("div", "srow");
    row.appendChild(el("span", "sname", esc(r.label)));
    const track = el("span", "strack");
    const fill = el("span", "sfill");
    fill.style.width = Math.max(1, r.share * 100) + "%";
    track.appendChild(fill);
    row.appendChild(track);
    row.appendChild(el("span", "sval", Math.round(r.share * 100) + " %"));
    tipOn(row, () => `<div class="t">${esc(r.label)}</div><div>${num(r.v)} ${lang() === "fr" ? "dégâts" : "damage"}</div><div class="mute">${Math.round(r.share * 100)} %</div>`);
    list.appendChild(row);
  });
  box.appendChild(list);
  return box;
}

function table(title, head, rows) {
  const box = el("div", "chart");
  box.appendChild(el("h3", "", esc(title)));
  const t = el("table", "stable");
  t.appendChild(el("tr", "", head.map((h) => `<th>${esc(h)}</th>`).join("")));
  rows.forEach((r) => t.appendChild(el("tr", "", r.map((c) => `<td>${c}</td>`).join(""))));
  const wrap = el("div", "twrap");
  wrap.appendChild(t);
  box.appendChild(wrap);
  return box;
}

function groupBy(runs, key) {
  const g = {};
  runs.forEach((r) => { const k = key(r); (g[k] = g[k] || []).push(r); });
  return Object.entries(g).sort((a, b) => b[1].length - a[1].length);
}

function tile(label, value, sub) {
  return el("div", "tile", `<div class="tl">${esc(label)}</div><div class="tv">${value}</div>${sub ? `<div class="ts">${sub}</div>` : ""}`);
}

async function renderStats(sec) {
  if (!RUNS || sec.dataset.fresh !== "1") {
    try { RUNS = await (await fetch("/api/runs")).json(); } catch (e) { RUNS = []; }
    sec.dataset.fresh = "1";
    setTimeout(() => (sec.dataset.fresh = ""), 5000);
  }
  if (PAGE !== "stats") return;
  sec.innerHTML = "";
  if (!RUNS.length) { sec.appendChild(el("div", "empty", ST("empty"))); return; }
  const runs = RUNS.filter((r) => (!STAT_FILTER.cls || r.class === STAT_FILTER.cls) && (!STAT_FILTER.zone || r.bg === STAT_FILTER.zone) && (!STAT_FILTER.result || r.result === STAT_FILTER.result) && (!STAT_FILTER.mode || (STAT_FILTER.mode === "coop") === !!r.coop));

  const bar = el("div", "row filters");
  const sel = (opts, value, onchange) => {
    const s = el("select");
    opts.forEach(([v, l]) => { const o = el("option", "", esc(l)); o.value = v; if (v === value) o.selected = true; s.appendChild(o); });
    s.onchange = () => { onchange(s.value); renderStats(sec); };
    bar.appendChild(s);
  };
  const classes = [...new Set(RUNS.map((r) => r.class))];
  sel([["", ST("all")], ...classes.map((c) => [c, className(c)])], STAT_FILTER.cls, (v) => (STAT_FILTER.cls = v));
  const zones = [...new Set(RUNS.map((r) => r.bg).filter(Boolean))];
  sel([["", ST("allZones")], ...zones.map((z) => [z, z])], STAT_FILTER.zone, (v) => (STAT_FILTER.zone = v));
  sel([["", ST("allResults")], ["victory", ST("win")], ["defeat", ST("loss")]], STAT_FILTER.result, (v) => (STAT_FILTER.result = v));
  sel([["", ST("allModes")], ["solo", ST("solo")], ["coop", ST("coop")]], STAT_FILTER.mode, (v) => (STAT_FILTER.mode = v));
  sec.appendChild(bar);
  if (!runs.length) { sec.appendChild(el("div", "empty", ST("empty"))); return; }

  const wins = runs.filter((r) => r.result === "victory").length;
  const times = runs.map((r) => +r.time || 0);
  const dps = runs.map((r) => +r.dps || 0);
  const tiles = el("div", "tiles");
  tiles.appendChild(tile(ST("runs"), num(runs.length)));
  tiles.appendChild(tile(ST("wins"), num(wins), Math.round((100 * wins) / runs.length) + " %"));
  tiles.appendChild(tile(ST("played"), hms(times.reduce((a, b) => a + b, 0))));
  tiles.appendChild(tile(ST("bestTime"), mmss(Math.max(...times))));
  tiles.appendChild(tile(ST("maxLevel"), num(Math.max(...runs.map((r) => +r.level || 0)))));
  tiles.appendChild(tile(ST("maxKills"), num(Math.max(...runs.map((r) => +r.kills || 0)))));
  tiles.appendChild(tile(ST("avgDps"), num(avg(dps))));
  tiles.appendChild(tile(ST("maxDps"), num(Math.max(...dps))));
  tiles.appendChild(tile(ST("bosses"), num(runs.reduce((a, r) => a + (+r.bosses || 0), 0))));
  const endless = runs.filter((r) => r.endless);
  if (endless.length) tiles.appendChild(tile(ST("bestEndless"), "+" + mmss(Math.max(...endless.map((r) => +r.endlessTime || 0))), num(endless.length) + " " + ST("runs").toLowerCase()));
  tiles.appendChild(tile(ST("guardians"), num(runs.reduce((a, r) => a + (+r.guardians || 0), 0))));
  sec.appendChild(tiles);

  const last = runs.slice(-40);
  const offset = runs.length - last.length;
  const runTip = (r, i) => `<div class="t">${esc(ST("run"))} ${offset + i + 1} · ${esc(className(r.class))}</div><div>${esc(r.date ? r.date.replace("T", " ").slice(0, 16) : "")}</div><div>${esc(ST("time"))} ${mmss(r.time)} · ${esc(ST("level"))} ${num(r.level)} · ${num(r.kills)} ${esc(ST("kills").toLowerCase())}</div><div>DPS ${num(r.dps)}</div><div class="mute">${esc(r.result === "victory" ? ST("win") : ST("loss"))}${r.endless ? " · " + esc(ST("endless")) + " +" + mmss(r.endlessTime) : ""}${r.coop ? " · " + esc(ST("coop")) + " " + r.coop : ""} · ${esc(r.build || "")}</div>`;
  const grid = el("div", "charts");
  const classEntries = [...new Set(last.map((r) => r.class))].map((c) => ({ label: className(c), color: CLASS_COLORS[c] || "#3987e5" }));
  grid.appendChild(lineChart(ST("timeChart"), last.map((r, i) => ({ y: (+r.time || 0) / 60, label: String(offset + i + 1), r, i, color: CLASS_COLORS[r.class] })), (v) => Math.round(v) + " min", (p) => runTip(p.r, p.i), classEntries));
  grid.appendChild(lineChart(ST("dpsChart"), last.map((r, i) => ({ y: +r.dps || 0, label: String(offset + i + 1), r, i, color: CLASS_COLORS[r.class] })), (v) => num(v), (p) => runTip(p.r, p.i), classEntries));
  const byClass = groupBy(runs, (r) => r.class);
  grid.appendChild(barChart(ST("classChart"), byClass.map(([k, rs]) => ({ v: avg(rs.map((r) => (+r.time || 0) / 60)), label: className(k), color: CLASS_COLORS[k] || "#3987e5", k, rs })), (v) => (v >= 10 || Number.isInteger(v) ? Math.round(v) : v.toFixed(1)) + " min",
    (b) => `<div class="t">${esc(b.label)}</div><div>${num(b.rs.length)} ${esc(ST("runs").toLowerCase())}</div><div>${esc(ST("avgTime"))} ${mmss(avg(b.rs.map((r) => +r.time || 0)))}</div><div>DPS ${num(avg(b.rs.map((r) => +r.dps || 0)))}</div>`));
  const dmg = {};
  let total = 0;
  runs.forEach((r) => {
    if (r.meter && r.meter.length) r.meter.forEach((l) => { const key = r.class + "|=" + l.name; dmg[key] = (dmg[key] || 0) + l.dmg; total += l.dmg; });
    else Object.entries(r.dmg || {}).forEach(([k, v]) => { const key = r.class + "|" + k; dmg[key] = (dmg[key] || 0) + v; total += v; });
  });
  if (total > 0) {
    let rows = Object.entries(dmg).map(([k, v]) => { const [c, s] = k.split("|"); return { label: spellName(c, s) + (STAT_FILTER.cls ? "" : " · " + className(c)), v, share: v / total }; }).sort((a, b) => b.v - a.v);
    if (rows.length > 10) {
      const rest = rows.slice(9).reduce((a, r) => a + r.v, 0);
      rows = rows.slice(0, 9).concat([{ label: ST("other"), v: rest, share: rest / total }]);
    }
    grid.appendChild(shareBars(ST("spellChart"), ST("spellHint"), rows));
  } else {
    const box = chartBox(ST("spellChart"));
    box.appendChild(el("div", "empty", ST("noDmg")));
    grid.appendChild(box);
  }
  sec.appendChild(grid);

  const statRow = (rs) => [num(rs.length), Math.round((100 * rs.filter((r) => r.result === "victory").length) / rs.length) + " %", mmss(avg(rs.map((r) => +r.time || 0))), num(Math.max(...rs.map((r) => +r.level || 0))), num(avg(rs.map((r) => +r.dps || 0)))];
  const head = [ST("n"), ST("winRate"), ST("avgTime"), ST("maxLvl"), ST("dps")];
  const tables = el("div", "charts");
  const takenMin = (rs) => num(avg(rs.filter((r) => +r.time > 0).map((r) => (+r.taken || 0) / (r.time / 60))));
  sec.appendChild(table(ST("byBuild"), [ST("build"), ...head, ST("takenMin")], groupBy(runs.filter((r) => r.build), (r) => r.class + "|" + r.build).map(([k, rs]) => { const [c, b] = k.split("|"); return [`<span style="color:${CLASS_COLORS[c] || "inherit"}">${esc(b)}</span>`, ...statRow(rs), takenMin(rs)]; })));
  tables.appendChild(table(ST("bySpec"), [ST("spec"), ...head], groupBy(runs, (r) => r.spec || r.class).map(([k, rs]) => [esc(k.includes("-") ? specName(k) : className(k)), ...statRow(rs)])));
  tables.appendChild(table(ST("byRace"), [ST("race"), ...head], groupBy(runs, (r) => r.race || "-").map(([k, rs]) => [esc(k), ...statRow(rs)])));
  sec.appendChild(tables);
  sec.appendChild(table(ST("recent"), [ST("date"), ST("cls"), ST("spec"), ST("build"), ST("result"), ST("time"), ST("level"), ST("kills"), "DPS"],
    runs.slice(-20).reverse().map((r) => [esc((r.date || "").replace("T", " ").slice(0, 16)), `<span style="color:${CLASS_COLORS[r.class] || "inherit"}">${esc(className(r.class))}</span>`, esc(r.spec ? specName(r.spec).replace(/ \(.*\)$/, "") : "-"), esc(r.build || "-"),
      r.result === "victory" ? `<span class="good">${esc(ST("win"))}</span>${r.endless ? " · " + esc(ST("endless")) + " +" + mmss(r.endlessTime) : ""}${r.coop ? " · " + esc(ST("coop")) : ""}` : esc(ST("loss")) + (r.coop ? " · " + esc(ST("coop")) : ""), mmss(r.time), num(r.level), num(r.kills), num(r.dps)])));
}
