const load = require("./pe.js");
const [exe, ...words] = process.argv.slice(2);
const P = load(exe);
const { buf } = P;
const text = P.sec(".text");
const rd = P.sec(".rdata");
const textVA = Number(P.ib) + text.va;
for (const w of words) {
  const needle = Buffer.from(w);
  let at = rd.raw;
  const targets = [];
  while ((at = buf.indexOf(needle, at)) >= 0 && at < rd.raw + rd.rs) { targets.push(Number(P.toVA(at))); at++; }
  const set = new Set(targets);
  const hits = [];
  for (let i = text.raw; i < text.raw + text.rs - 4; i++) {
    const disp = buf.readInt32LE(i);
    const t = textVA + (i - text.raw) + 4 + disp;
    if (set.has(t)) hits.push({ off: i, va: textVA + (i - text.raw), t });
  }
  console.log(JSON.stringify(w), "strings", targets.length, "code refs", hits.length);
  for (const h of hits.slice(0, 20)) console.log("  ref disp@0x" + h.va.toString(16), "-> 0x" + h.t.toString(16));
}
