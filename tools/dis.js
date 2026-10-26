const load = require("./pe.js");
const { Decoder, DecoderOptions, Formatter, FormatterSyntax } = require("iced-x86");
const [exe, vaHex, beforeArg, afterArg] = process.argv.slice(2);
const P = load(exe);
const { buf } = P;
const text = P.sec(".text");
const textVA = Number(P.ib) + text.va;
const va = parseInt(vaHex, 16);
const start = va - Number(beforeArg || 0x100);
const end = va + Number(afterArg || 0x200);
const off = start - textVA + text.raw;
const code = buf.slice(off, off + (end - start));
const dec = new Decoder(64, code, DecoderOptions.None);
dec.ip = BigInt(start);
const fmt = new Formatter(FormatterSyntax.Nasm);
fmt.ripRelativeAddresses = true;
const strAt = (t, len) => {
  const o = P.toOff(BigInt(t));
  if (o < 0) return null;
  const s = buf.toString("utf8", o, o + (len || 60));
  return s.replace(/[\x00-\x1f]/g, ".");
};
while (dec.canDecode) {
  const ins = dec.decode();
  const ip = Number(ins.ip);
  let s = fmt.format(ins);
  let note = "";
  if (ins.isIpRelMemoryOperand) {
    const t = Number(ins.ipRelMemoryAddress);
    const o = P.toOff(BigInt(t));
    if (o >= 0) {
      const f = buf.readFloatLE(o), d = buf.readDoubleLE(o);
      note = `  ; [${t.toString(16)}] "${strAt(t, 50)}" f32=${+f.toPrecision(5)} f64=${+d.toPrecision(5)}`;
    }
  }
  console.log(ip.toString(16), s, note);
  ins.free();
}
