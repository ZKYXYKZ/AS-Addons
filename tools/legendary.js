const makeEmu = require("./emu.js");
const [exe, outJson] = process.argv.slice(2);
const E = makeEmu(exe);
const P = E.P;
const ABIL = 0x729e408;
const N = 113;
const START = 0x145ad7f1b;
const TAIL = 0x145ad936a;
const str = (addr, len) => {
  const o = P.toOff(BigInt(addr));
  return o < 0 ? null : P.buf.toString("utf8", o, o + Number(len));
};
const results = [];
for (let i = 0; i < N; i++) {
  const off = ABIL + i * 120;
  const va = P.toVA(off);
  const key = P.str(off, 40);
  try {
    const r = E.run({
      start: START,
      stopAt: new Set([TAIL, 0x145ad9245]),
      regs: { RDX: va, RCX: 0x100000000800n },
      calls: {
        0x145fc4880: (api) => {
          const v = api.regs[api.Register.RCX];
          const cap = api.rdInt(v, 8), ptr = api.rdInt(v + 8n, 8), len = api.rdInt(v + 16n, 8);
          const ncap = cap * 2n > 4n ? cap * 2n : 4n;
          const np = api.alloc(Number(ncap) * 64);
          if (cap > 0n && ptr >= api.HEAP) api.wr(np, Buffer.from(api.rd(ptr, Number(len) * 64)));
          api.wrInt(v, 8, ncap);
          api.wrInt(v + 8n, 8, np);
          api.regs[api.Register.RAX] = np;
        },
        0x145b29ab0: (api) => { api.regs[api.Register.RAX] = 0n; },
        0x145f66f30: (api) => {
          const p = api.regs[api.Register.RCX];
          api.wrInt(p, 8, 0n);
          api.wrInt(p + 8n, 8, api.alloc(16));
          api.wrInt(p + 16n, 8, 0n);
        },
      },
    });
    const a = r.api;
    const R = a.Register;
    const rbp = a.regs[R.RBP];
    const vptr = a.rdInt(rbp + 0x38n, 8), vlen = Number(a.rdInt(rbp + 0x40n, 8));
    const effects = [];
    for (let k = 0; k < vlen; k++) effects.push(Buffer.from(a.rd(vptr + BigInt(k * 64), 64)).toString("hex"));
    const legion = r.ip === 0x145ad9245;
    const fam = legion ? "The Legionlord's Medallion" : str(a.regs[R.RBX], a.regs[R.RDX]);
    const icon = legion ? "INV_Jewelry_Necklace_13" : str(a.regs[R.RAX], a.regs[R.RSI]);
    results.push({ i, key, family: fam, icon, effects });
    console.log(i, key, "|", fam, "|", icon, "|", effects.length, "effects");
  } catch (e) {
    console.log(i, key, "ERROR", e.message);
    results.push({ i, key, error: e.message });
  }
}
require("fs").writeFileSync(outJson, JSON.stringify(results, null, 1));
