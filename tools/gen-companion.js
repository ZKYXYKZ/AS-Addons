const fs = require("fs");
const [dataJson, legJson, out] = process.argv.slice(2);
const d = JSON.parse(fs.readFileSync(dataJson, "utf8"));
d.legendaries = JSON.parse(fs.readFileSync(legJson, "utf8"));
fs.writeFileSync(out, JSON.stringify(d));
console.log(out, fs.statSync(out).size);
