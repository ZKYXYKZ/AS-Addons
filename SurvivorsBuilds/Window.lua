local H = SurvivorsHub

local T = {
  fr = {
    head = "Build actif de la classe",
    none = "Aucun build reçu. Créez vos builds dans AS Companion, puis lancez le jeu avec son bouton « Lancer le jeu ».",
    autoOn = "Sélection auto des cartes : active", autoOff = "Sélection auto des cartes : désactivée (nécessite le compagnon)",
    fresh = "Jeu lancé par le compagnon", stale = "Jeu non lancé par le compagnon : conseil et sélection auto indisponibles",
    edit = "Talents, sorts, bijoux et règles se modifient dans AS Companion (fichier Start-Companion.cmd dans le dossier du jeu).",
  },
  en = {
    head = "Active build for this class",
    none = "No build received. Create your builds in AS Companion, then start the game with its Launch game button.",
    autoOn = "Card auto-pick: on", autoOff = "Card auto-pick: off (needs the companion)",
    fresh = "Game started by the companion", stale = "Game not started by the companion: advice and auto-pick unavailable",
    edit = "Talents, spells, jewelry and rules are edited in AS Companion (Start-Companion.cmd in the game folder).",
  },
}
local function tl(k) return (T[SB.Lang()] or T.en)[k] end

H.RegisterTab("builds", "Builds", 10, function(p)
  p.title = H.Text(p, 15, "LEFT")
  p.title:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -4)
  p.title:SetTextColor(1, 0.82, 0.2)
  p.state = H.Text(p, 13, "LEFT")
  p.state:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -30)
  p.state:SetWidth(940)
  p.state:SetJustifyV("TOP")
  p.body = H.Text(p, 13, "LEFT")
  p.body:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -80)
  p.body:SetWidth(940)
  p.body:SetJustifyV("TOP")
  p.edit = H.Text(p, 12, "LEFT")
  p.edit:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 0, 4)
  p.edit:SetWidth(940)
  p.edit:SetTextColor(0.6, 0.6, 0.6)
  p.Refresh = function()
    local b = SB.Build()
    local link = SB.Link()
    p.title:SetText(b and (tl("head") .. " : " .. b.name) or tl("head"))
    local st = SB.Fresh() and ("|cff66ff66" .. tl("fresh") .. "|r") or ("|cffff9944" .. tl("stale") .. "|r")
    st = st .. "\n" .. ((link and link.autoPick) and tl("autoOn") or tl("autoOff"))
    p.state:SetText(st)
    p.body:SetText(b and SB.Guide.Lines(b) or tl("none"))
    p.edit:SetText(tl("edit"))
  end
end)
