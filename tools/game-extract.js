const fs = require("fs");
const path = require("path");

const exe = process.argv[2] || "C:/Users/ludov/Downloads/AzerothSurvivors/AzerothSurvivors/AzerothSurvivors.exe";
const out = path.join(__dirname, "..", "AS-Companion", "web", "gamedb.json");
const b = fs.readFileSync(exe);

const pe = b.readUInt32LE(0x3c);
const nsec = b.readUInt16LE(pe + 6), optSize = b.readUInt16LE(pe + 20);
const imageBase = b.readBigUInt64LE(pe + 48);
const secs = [];
for (let i = 0; i < nsec; i++) {
  const o = pe + 24 + optSize + i * 40;
  secs.push({ name: b.toString("latin1", o, o + 8).replace(/\0.*/, ""), va: b.readUInt32LE(o + 12), vsize: b.readUInt32LE(o + 8), raw: b.readUInt32LE(o + 20), rsize: b.readUInt32LE(o + 16) });
}
const va2off = (va) => { const r = Number(va - imageBase); const s = secs.find((x) => r >= x.va && r < x.va + x.vsize); return s ? r - s.va + s.raw : null; };
const rdata = secs.find((s) => s.name === ".rdata");
const str = (o, max = 400) => {
  const n = Number(b.readBigUInt64LE(o + 8));
  if (n <= 0 || n > max) return null;
  const off = va2off(b.readBigUInt64LE(o));
  return off == null ? null : b.toString("utf8", off, off + n);
};
const slice = (o) => ({ off: va2off(b.readBigUInt64LE(o)), n: Number(b.readBigUInt64LE(o + 8)) });
const f32 = (o) => +b.readFloatLE(o).toPrecision(6);
const u32 = (o) => b.readUInt32LE(o);
const find = (pred, step = 8) => { for (let o = rdata.raw; o < rdata.raw + rdata.rsize - 256; o += step) if (pred(o)) return o; return -1; };

const abilStart = find((o) => str(o, 40) === "cleave" && str(o + 16, 40) === "Cleave" && str(o + 120, 40) === "whirlwind");
const abilities = {};
for (let o = abilStart; ; o += 120) {
  const key = str(o, 40);
  if (!key || !/^[a-z_]+$/.test(key)) break;
  abilities[key] = {
    spell: u32(o + 64), dmg: f32(o + 68), cd: f32(o + 72), range: f32(o + 76), radius: f32(o + 80), targets: u32(o + 84),
    dur: f32(o + 88), ticks: u32(o + 92), speed: f32(o + 96), effect: u32(o + 104), effectValue: f32(o + 108), effectDur: f32(o + 112), flags: u32(o + 116),
  };
}

const zoneStart = find((o) => str(o, 20) === "elwynn" && str(o + 16, 40) === "Elwynn Forest");
const zones = {};
for (let z = zoneStart; ; z += 240) {
  const key = str(z, 20);
  if (!key || !/^[a-z_]+$/.test(key)) break;
  const en = slice(z + 112), bo = slice(z + 128);
  const enemies = [];
  for (let i = 0; i < en.n; i++) {
    const o = en.off + i * 80;
    enemies.push({ id: u32(o + 32), model: u32(o + 36), weight: u32(o + 24), size: f32(o + 40), kind: u32(o + 44), hp: f32(o + 48), dmg: f32(o + 52), speed: f32(o + 56), xp: f32(o + 60), at: f32(o + 72) });
  }
  const bosses = [];
  for (let i = 0; i < bo.n; i++) {
    const o = bo.off + i * 104;
    bosses.push({ id: u32(o + 64), name: str(o, 80), scale: f32(o + 72), at: f32(o + 80), hp: f32(o + 84), dmg: f32(o + 88), atk: f32(o + 92) });
  }
  zones[key] = { name: str(z + 16, 60), subtitle: str(z + 32, 80), diff: f32(z + 216), growth: f32(z + 220), length: f32(z + 208), enemies, bosses };
}

const classStart = find((o) => str(o, 20) === "warrior" && str(o + 16, 20) === "Warrior" && /^#/.test(str(o + 64, 10) || ""));
const classes = {};
for (let o = classStart; ; o += 144) {
  const key = str(o, 20);
  if (!key || !/^[a-z]+$/.test(key)) break;
  const pool = slice(o + 32);
  const spells = [];
  for (let i = 0; i < pool.n && i < 40; i++) { const k = str(pool.off + i * 16, 40); if (k) spells.push(k); }
  classes[key] = { name: str(o + 16, 20), start: str(o + 48, 40), color: str(o + 64, 10), hp: f32(o + 112), armor: f32(o + 116), extra: f32(o + 120), flag: u32(o + 124), spells };
}

fs.writeFileSync(out, JSON.stringify({ abilities, zones, classes }, null, 1) + "\n");
console.log(`${Object.keys(classes).length} classes, ${Object.keys(abilities).length} sorts, ${Object.keys(zones).length} zones, ${Object.values(zones).reduce((n, z) => n + z.enemies.length, 0)} ennemis, ${Object.values(zones).reduce((n, z) => n + z.bosses.length, 0)} boss -> ${path.relative(process.cwd(), out)}`);
