const fs = require("fs");
const [inJson, outLua, legJson] = process.argv.slice(2);
const d = JSON.parse(fs.readFileSync(inJson, "utf8"));
const legs = legJson ? JSON.parse(fs.readFileSync(legJson, "utf8")) : {};
const q = (s) => '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n") + '"';
const loc = (o) => `{ en = ${q(o.en)}, fr = ${q(o.fr)} }`;
const L = [];
L.push(`SB_DATA = {`);
L.push(`  version = ${q(d.version)},`);
L.push(`  rarity = { ${d.rarity.map(loc).join(", ")} },`);
L.push(`  classes = {`);
for (const c of d.classes) {
  L.push(`    {`);
  L.push(`      key = ${q(c.key)}, name = ${loc(c.name)},`);
  L.push(`      trees = {`);
  for (const t of c.trees) {
    L.push(`        { name = ${loc(t.name)}, talents = {`);
    for (const x of t.talents) {
      const f = [`key = ${q(x.key)}`, `icon = ${q(x.icon)}`, `row = ${x.row}`, `col = ${x.col}`, `max = ${x.max}`, `name = ${loc(x.name)}`, `desc = ${loc(x.desc)}`];
      if (x.req) f.push(`req = ${q(x.req)}`);
      if (x.v !== undefined) f.push(`v = ${x.v}`);
      if (x.milestone) f.push(`milestone = 1`);
      if (x.capstone) f.push(`capstone = 1`);
      L.push(`          { ${f.join(", ")} },`);
    }
    L.push(`        } },`);
  }
  L.push(`      },`);
  L.push(`      spells = {`);
  for (const s of c.spells) L.push(`        { key = ${q(s.key)}, icon = ${q(s.icon)}, spell = ${s.spell}, name = ${loc(s.name)}, upgrades = { ${s.upgrades.map(q).join(", ")} } },`);
  L.push(`      },`);
  L.push(`    },`);
}
L.push(`  },`);
for (const cat of ["rings", "trinkets", "amulets"]) {
  L.push(`  ${cat} = {`);
  for (const j of d[cat]) L.push(`    { key = ${q(j.key)}, icon = ${q(j.icon)}, name = ${loc(j.name)}${j.desc && j.desc.length > 2 ? `, desc = ${q(j.desc)}` : ""} },`);
  L.push(`  },`);
}
L.push(`  legendaries = {`);
for (const [k, x] of Object.entries(legs)) {
  L.push(`    [${q(k)}] = { family = ${loc(x.family)}, icon = ${q(x.icon)}, lines = { en = { ${x.lines.en.map(q).join(", ")} }, fr = { ${x.lines.fr.map(q).join(", ")} } } },`);
}
L.push(`  },`);
L.push(`}`);
fs.writeFileSync(outLua, L.join("\n") + "\n");
console.log(outLua, fs.statSync(outLua).size);
