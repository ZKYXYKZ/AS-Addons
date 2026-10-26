const fs = require("fs");
const [dataJson, legJson, out, jewelJson] = process.argv.slice(2);
const d = JSON.parse(fs.readFileSync(dataJson, "utf8"));
d.legendaries = JSON.parse(fs.readFileSync(legJson, "utf8"));
if (jewelJson) {
  const jw = JSON.parse(fs.readFileSync(jewelJson, "utf8"));
  for (const cat of ["rings", "trinkets"]) for (const j of d[cat]) if (jw[cat][j.key]) j.desc = { en: [jw[cat][j.key].en], fr: [jw[cat][j.key].fr] };
  for (const j of d.amulets) if (jw.amulets[j.key]) { j.desc = jw.amulets[j.key].lines; j.tier = jw.amulets[j.key].tier; }
}
fs.writeFileSync(out, JSON.stringify(d));
console.log(out, fs.statSync(out).size);
