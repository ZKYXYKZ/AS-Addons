const fs = require("fs");
const path = require("path");
const [exe, outDir] = process.argv.slice(2);
const buf = fs.readFileSync(exe);
fs.mkdirSync(outDir, { recursive: true });
const needle = Buffer.from('"game.title"');
let from = 0;
let n = 0;
while (true) {
  const at = buf.indexOf(needle, from);
  if (at < 0) break;
  from = at + 1;
  let start = at;
  while (start > 0 && buf[start] !== 0x7b) start--;
  let depth = 0, inStr = false, esc = false, end = -1;
  for (let i = start; i < buf.length; i++) {
    const c = buf[i];
    if (inStr) {
      if (esc) esc = false;
      else if (c === 0x5c) esc = true;
      else if (c === 0x22) inStr = false;
      continue;
    }
    if (c === 0x22) inStr = true;
    else if (c === 0x7b) depth++;
    else if (c === 0x7d) {
      depth--;
      if (depth === 0) { end = i + 1; break; }
    }
  }
  if (end < 0) continue;
  const text = buf.slice(start, end).toString("utf8");
  let obj;
  try { obj = JSON.parse(text); } catch (e) { console.log("parse fail at", start, e.message); continue; }
  n++;
  const name = `loc-${n}.json`;
  fs.writeFileSync(path.join(outDir, name), JSON.stringify(obj, null, 1));
  console.log(name, Object.keys(obj).length, obj["picker.language"], obj["class.mage.name"]);
}
