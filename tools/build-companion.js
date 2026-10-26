const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const root = path.join(__dirname, "..", "AS-Companion");
const web = path.join(root, "web");
const out = path.join(__dirname, "..", "dist", "ASCompanion.exe");
const csc = path.join(process.env.WINDIR || "C:\\Windows", "Microsoft.NET", "Framework64", "v4.0.30319", "csc.exe");

const files = [];
const walk = (dir) => {
  for (const f of fs.readdirSync(dir)) {
    const p = path.join(dir, f);
    if (fs.statSync(p).isDirectory()) walk(p); else files.push(p);
  }
};
walk(web);

fs.mkdirSync(path.dirname(out), { recursive: true });
const args = [
  "/nologo", "/target:winexe", "/optimize+", "/platform:anycpu",
  "/out:" + out,
  "/win32icon:" + path.join(root, "src", "icon.ico"),
  "/r:System.Web.Extensions.dll", "/r:System.Windows.Forms.dll", "/r:System.Drawing.dll", "/r:System.Core.dll", "/r:System.Management.dll",
  ...files.map((f) => "/resource:" + f + ",web/" + path.relative(web, f).split(path.sep).join("/")),
  path.join(root, "src", "Companion.cs"),
];
execFileSync(csc, args, { stdio: "inherit" });
console.log(out, fs.statSync(out).size);
