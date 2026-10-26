const fs = require("fs");
module.exports = function load(exe) {
  const buf = fs.readFileSync(exe);
  const pe = buf.readUInt32LE(0x3c);
  const nsec = buf.readUInt16LE(pe + 6);
  const optSize = buf.readUInt16LE(pe + 20);
  const opt = pe + 24;
  const ib = buf.readBigUInt64LE(opt + 24);
  const secs = [];
  for (let i = 0; i < nsec; i++) {
    const o = opt + optSize + i * 40;
    secs.push({
      name: buf.toString("ascii", o, o + 8).replace(/\0/g, ""),
      va: buf.readUInt32LE(o + 12), raw: buf.readUInt32LE(o + 20), rs: buf.readUInt32LE(o + 16),
    });
  }
  const toOff = (va) => {
    if (typeof va !== "bigint") va = BigInt(va);
    const r = Number(va - ib);
    for (const s of secs) if (r >= s.va && r < s.va + s.rs) return r - s.va + s.raw;
    return -1;
  };
  const toVA = (off) => {
    for (const s of secs) if (off >= s.raw && off < s.raw + s.rs) return ib + BigInt(off - s.raw + s.va);
    return null;
  };
  const str = (q, max = 600) => {
    if (q < 0 || q + 16 > buf.length) return null;
    const v = buf.readBigUInt64LE(q);
    const len = buf.readBigUInt64LE(q + 8);
    if (len === 0n || len > BigInt(max)) return null;
    const o = toOff(v);
    if (o < 0) return null;
    const s = buf.toString("utf8", o, o + Number(len));
    if (/[\x00-\x08\x0e-\x1f�]/.test(s)) return null;
    return s;
  };
  const slice = (q) => {
    const v = buf.readBigUInt64LE(q);
    const len = Number(buf.readBigUInt64LE(q + 8));
    return { off: toOff(v), len, va: v };
  };
  const sec = (n) => secs.find((s) => s.name === n);
  return { buf, ib, secs, toOff, toVA, str, slice, sec };
};
