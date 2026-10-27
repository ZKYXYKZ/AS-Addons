const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const data = JSON.parse(fs.readFileSync(path.join(root, "AS-Companion/web/data.json"), "utf8"));
const out = path.join(root, "AS-Companion/web/jewelups.json");
const dirs = process.argv.slice(2).filter((d) => fs.existsSync(d));

const keyOf = {};
for (const cat of ["rings", "trinkets", "amulets"]) for (const j of data[cat]) keyOf[j.name.en] = keyOf[j.name.fr] = j.key;
const roman = (v) => { let n = 0, prev = 0; for (let i = v.length - 1; i >= 0; i--) { const d = v[i] === "X" ? 10 : v[i] === "V" ? 5 : 1; n += d < prev ? -d : d; prev = Math.max(prev, d); } return n; };
const num = (s) => parseFloat(String(s).replace(",", "."));

const seen = {};
for (const dir of dirs)
  for (const f of fs.readdirSync(dir).filter((x) => x.endsWith(".jsonl"))) {
    for (const line of fs.readFileSync(path.join(dir, f), "utf8").split("\n")) {
      if (!line.includes('"choices"')) continue;
      let e;
      try { e = JSON.parse(line); } catch (x) { continue; }
      for (const c of (e.data && e.data.choices) || []) {
        const m = (c.title || "").match(/^(.*) ([IVX]+)(\+?)$/);
        if (!m || !keyOf[m[1]] || m[3]) continue;
        const rank = roman(m[2]);
        const first = (c.lines || "").split("\n")[0];
        const v = first.match(/([+-]?[\d.,]+)\s*%?\s*»\s*([+-]?[\d.,]+)/);
        if (!v) continue;
        const k = keyOf[m[1]];
        const base = num(v[1]);
        if (!base) continue;
        seen[k] = seen[k] || {};
        (seen[k].abs = seen[k].abs || {})[rank - 1] = base;
        seen[k].abs[rank] = num(v[2]);
      }
    }
  }

const table = {};
for (const [k, s] of Object.entries(seen)) {
  const abs = s.abs || {};
  const r1 = abs[1];
  if (!r1) continue;
  table[k] = {};
  let best = 0;
  for (const [r, v] of Object.entries(abs).sort((a, b) => a[0] - b[0])) { best = Math.max(best, v / r1); table[k][r] = Math.round(best * 100) / 100; }
}
fs.writeFileSync(out, JSON.stringify(table, null, 1) + "\n");
console.log(Object.keys(table).length + " bijoux -> " + path.relative(process.cwd(), out));
for (const [k, t] of Object.entries(table)) console.log(k.padEnd(18), Object.entries(t).sort((a, b) => a[0] - b[0]).map(([r, v]) => r + ":" + v).join(" "));
