const ADDON_STR = {
  fr: {
    intro: "Les addons du jeu, installés dans {dir}. Les nôtres s'installent et se mettent à jour depuis la dernière version publiée sur GitHub.",
    install: "Installer", update: "Mettre à jour", check: "Vérifier les mises à jour", checking: "Vérification…", noUpdate: "Aucune mise à jour", uninstall: "Désinstaller", enable: "Activer", disable: "Désactiver",
    installed: "Installé", notInstalled: "Non installé", latest: "Dernière version", enabled: "Activé", disabled: "Désactivé",
    upToDate: "à jour", third: "Addon tiers", running: "Fermez le jeu pour installer, mettre à jour, activer ou désinstaller un addon.",
    confirmUninstall: "Désinstaller {name} ? Le dossier part à la corbeille.", noRelease: "Aucune version publiée trouvée sur GitHub pour l'instant.",
    reload: "Les changements prennent effet au prochain lancement du jeu.",
  },
  en: {
    intro: "The game addons, installed in {dir}. Ours install and update from the latest version published on GitHub.",
    install: "Install", update: "Update", check: "Check for updates", checking: "Checking…", noUpdate: "No update", uninstall: "Uninstall", enable: "Enable", disable: "Disable",
    installed: "Installed", notInstalled: "Not installed", latest: "Latest version", enabled: "Enabled", disabled: "Disabled",
    upToDate: "up to date", third: "Third-party addon", running: "Close the game to install, update, enable or uninstall an addon.",
    confirmUninstall: "Uninstall {name}? The folder goes to the Recycle Bin.", noRelease: "No published version found on GitHub yet.",
    reload: "Changes apply at the next game launch.",
  },
};
const AT = (k, vars) => {
  let s = (ADDON_STR[lang()] || ADDON_STR.en)[k] || k;
  for (const [a, b] of Object.entries(vars || {})) s = s.split("{" + a + "}").join(b);
  return s;
};
const newer = (a, b) => {
  if (!a || !b) return false;
  const x = a.split(".").map(Number), y = b.split(".").map(Number);
  for (let i = 0; i < 3; i++) if ((x[i] || 0) !== (y[i] || 0)) return (x[i] || 0) > (y[i] || 0);
  return false;
};

const addonChecked = {};
async function renderAddons(sec) {
  let data;
  try { data = await (await fetch("/api/addons")).json(); } catch (e) { return; }
  if (PAGE !== "addons") return;
  sec.innerHTML = "";
  sec.appendChild(el("div", "hint", esc(AT("intro", { dir: data.dir }))));
  if (data.running) sec.appendChild(el("div", "warnline", esc(AT("running"))));
  if (!data.addons.some((a) => a.ours)) sec.appendChild(el("div", "hint", esc(AT("noRelease"))));
  const msg = el("div", "hint");
  const act = async (name, action) => {
    if (action === "uninstall" && !confirm(AT("confirmUninstall", { name }))) return;
    const r = await (await fetch("/api/addons", { method: "POST", body: JSON.stringify({ name, action }) })).json();
    await renderAddons(sec);
    if (r.error) sec.appendChild(el("div", "warnline", esc(r.error)));
    else sec.appendChild(el("div", "hint", esc(AT("reload"))));
  };
  const list = el("div", "addons");
  data.addons.forEach((a) => {
    const card = el("div", "addon" + (a.installed ? "" : " missing"));
    const head = el("div", "ahead");
    head.appendChild(el("div", "atitle", esc(a.title || a.name)));
    const badges = el("div", "abadges");
    if (a.installed) badges.appendChild(el("span", "badge2 " + (a.enabled ? "on" : "off"), esc(a.enabled ? AT("enabled") : AT("disabled"))));
    if (!a.ours) badges.appendChild(el("span", "badge2", esc(AT("third"))));
    head.appendChild(badges);
    card.appendChild(head);
    const notes = lang() === "fr" && a.notesFr ? a.notesFr : a.notes;
    if (notes) card.appendChild(el("div", "anotes", esc(notes)));
    const meta = [];
    meta.push(a.installed ? `${esc(AT("installed"))} ${esc(a.version || "")}` : esc(AT("notInstalled")));
    if (a.latest) meta.push(`${esc(AT("latest"))} ${esc(a.latest)}${a.installed && !newer(a.latest, a.version) ? " · " + esc(AT("upToDate")) : ""}`);
    card.appendChild(el("div", "ameta", meta.join(" &nbsp;·&nbsp; ")));
    if (addonChecked[a.name] && a.installed && !newer(a.latest, a.version)) card.appendChild(el("div", "ameta", esc(AT("noUpdate"))));
    const row = el("div", "row");
    const btn = (label, action, cls) => { const b = el("button", cls || "", esc(label)); b.disabled = data.running; b.onclick = () => act(a.name, action); row.appendChild(b); };
    if (a.ours && !a.installed) btn(AT("install"), "install", "primary");
    if (a.ours && a.installed && newer(a.latest, a.version)) btn(AT("update"), "install", "primary");
    else if (a.ours && a.installed) {
      const c = el("button", "", esc(AT("check")));
      c.onclick = async () => {
        c.disabled = true;
        c.textContent = AT("checking");
        try { await fetch("/api/check?addons=1", { method: "POST" }); } catch (e) {}
        addonChecked[a.name] = true;
        await renderAddons(sec);
      };
      row.appendChild(c);
    }
    if (a.installed) btn(a.enabled ? AT("disable") : AT("enable"), a.enabled ? "disable" : "enable");
    if (a.installed) btn(AT("uninstall"), "uninstall");
    card.appendChild(row);
    list.appendChild(card);
  });
  sec.appendChild(list);
  sec.appendChild(msg);
}
