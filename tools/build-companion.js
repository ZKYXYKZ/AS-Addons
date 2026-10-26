const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const root = path.join(__dirname, "..", "AS-Companion");
const web = path.join(root, "web");
const out = path.join(__dirname, "..", "dist", "ASCompanion.exe");
const csc = path.join(process.env.WINDIR || "C:\\Windows", "Microsoft.NET", "Framework64", "v4.0.30319", "csc.exe");

const WV2 = "1.0.4258.31";
const cache = path.join(__dirname, ".cache", "webview2-" + WV2);
if (!fs.existsSync(path.join(cache, "lib", "net462", "Microsoft.Web.WebView2.Core.dll"))) {
  fs.mkdirSync(cache, { recursive: true });
  const pkg = path.join(cache, "wv2.nupkg");
  execFileSync("curl", ["-sSL", "-o", pkg, "https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2/" + WV2], { stdio: "inherit" });
  execFileSync(path.join(process.env.WINDIR || "C:\\Windows", "System32", "tar.exe"), ["-xf", pkg, "-C", cache], { stdio: "inherit" });
}
const wvLib = path.join(cache, "lib", "net462");
const libs = [
  [path.join(wvLib, "Microsoft.Web.WebView2.Core.dll"), "lib/Microsoft.Web.WebView2.Core.dll"],
  [path.join(wvLib, "Microsoft.Web.WebView2.WinForms.dll"), "lib/Microsoft.Web.WebView2.WinForms.dll"],
  ...["x86", "x64", "arm64"].map((a) => [path.join(cache, "runtimes", "win-" + a, "native", "WebView2Loader.dll"), "lib/" + a + "/WebView2Loader.dll"]),
];
const files = [];
const walk = (dir) => {
  for (const f of fs.readdirSync(dir)) {
    const p = path.join(dir, f);
    if (fs.statSync(p).isDirectory()) walk(p); else files.push(p);
  }
};
walk(web);

fs.mkdirSync(path.dirname(out), { recursive: true });
const tag = process.env.COMPANION_VERSION || (process.env.GITHUB_REF_NAME || "").replace(/^v/, "");
const version = /^\d+\.\d+\.\d+$/.test(tag) ? tag : "0.0.0";
const versionFile = path.join(path.dirname(out), "Version.cs");
fs.writeFileSync(versionFile, `[assembly: System.Reflection.AssemblyVersion("${version}.0")]\n[assembly: System.Reflection.AssemblyFileVersion("${version}.0")]\n`);
const args = [
  "/nologo", "/target:winexe", "/optimize+", "/platform:anycpu",
  "/out:" + out,
  "/win32icon:" + path.join(root, "src", "icon.ico"),
  "/r:System.Web.Extensions.dll", "/r:System.Windows.Forms.dll", "/r:System.Drawing.dll", "/r:System.Core.dll", "/r:System.Management.dll", "/r:System.IO.Compression.dll", "/r:Microsoft.VisualBasic.dll", "/r:" + path.join(wvLib, "Microsoft.Web.WebView2.Core.dll"), "/r:" + path.join(wvLib, "Microsoft.Web.WebView2.WinForms.dll"),
  ...libs.map(([f, n]) => "/resource:" + f + "," + n),
  ...files.map((f) => "/resource:" + f + ",web/" + path.relative(web, f).split(path.sep).join("/")),
  path.join(root, "src", "Companion.cs"), versionFile,
];
execFileSync(csc, args, { stdio: "inherit" });
console.log(out, fs.statSync(out).size, "version", version);
