const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const root = path.join(__dirname, "..");
const cache = path.join(__dirname, ".cache", "luacheck");
if (!fs.existsSync(path.join(cache, "node_modules", "luaparse"))) {
  fs.mkdirSync(cache, { recursive: true });
  execSync("npm install luaparse@0.3.1 --no-save --silent --prefix .", { cwd: cache, stdio: "inherit" });
}
const luaparse = require(path.join(cache, "node_modules", "luaparse"));

let files = 0, bad = 0;
for (const dir of fs.readdirSync(root)) {
  if (!dir.startsWith("Survivors")) continue;
  for (const f of fs.readdirSync(path.join(root, dir))) {
    if (!f.endsWith(".lua")) continue;
    files++;
    const file = path.join(root, dir, f);
    try {
      luaparse.parse(fs.readFileSync(file, "utf8"), { luaVersion: "5.1" });
    } catch (e) {
      bad++;
      console.error(`${dir}/${f}: ${e.message}`);
    }
  }
}
console.log(`${files} fichiers Lua, ${bad} en erreur`);
process.exit(bad ? 1 : 0);
