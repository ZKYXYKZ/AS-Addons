const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const args = process.argv.slice(2);
if (!args.length) {
  console.log("node tools/replay.js <dossier ou fichier .jsonl> [state.json]");
  console.log("Rejoue les écrans de cartes d'une partie collectée avec le compagnon de dist\\ et liste les choix qui changent.");
  process.exit(0);
}
const exe = path.join(__dirname, "..", "dist", "ASCompanion.exe");
if (!fs.existsSync(exe)) {
  console.error("Compilez d'abord : node tools/build-companion.js");
  process.exit(1);
}
const target = args[0];
const files = fs.statSync(target).isDirectory()
  ? fs.readdirSync(target).filter((f) => f.endsWith(".jsonl")).sort().map((f) => path.join(target, f))
  : [target];
let same = 0, diff = 0;
for (const f of files) {
  const out = execFileSync(exe, ["--replay", f].concat(args[1] ? [args[1]] : []), { encoding: "utf8" });
  process.stdout.write(out);
  const m = out.match(/: (\d+) identiques, (\d+) différents/);
  if (m) { same += +m[1]; diff += +m[2]; }
}
console.log(`\nTotal : ${same} écrans identiques, ${diff} différents sur ${files.length} partie(s)`);
