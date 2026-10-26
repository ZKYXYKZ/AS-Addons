local H = SurvivorsHub
local G = {}
SB.Guide = G

local T = {
  fr = {
    title = "Build : %s", none = "Aucun build reçu du compagnon pour cette classe", learn = "à prendre", rank = "rang %d",
    ban = "À bannir (%d) : %s", rerolls = "Relances : %d (garder %d)", rule = "Rien du build : %s", reroll = "relancer puis skip", skip = "skip",
    jewels = "Bijoux visés : %s", newSpell = "Nouveau sort : %s%s", upSpell = "%s rang %d%s", prio = " (priorité %d)", out = " (hors build)",
    auto = "Sélection auto active (compagnon)",
  },
  en = {
    title = "Build: %s", none = "No build received from the companion for this class", learn = "to take", rank = "rank %d",
    ban = "Banish (%d): %s", rerolls = "Rerolls: %d (keep %d)", rule = "Nothing from the build: %s", reroll = "reroll then skip", skip = "skip",
    jewels = "Target jewelry: %s", newSpell = "New spell: %s%s", upSpell = "%s rank %d%s", prio = " (priority %d)", out = " (off build)",
    auto = "Auto-pick on (companion)",
  },
}
local function tl(k) return (T[SB.Lang()] or T.en)[k] end

local known, lastUpdate, lastLevel = nil, nil, nil

local function ranks()
  local out = {}
  if not AZS_SPELLS then return out end
  for i = 1, table.getn(AZS_SPELLS) do
    local s = AZS_SPELLS[i]
    if s.key then out[s.key] = tonumber(s.rank) or 1 end
  end
  return out
end

local function priority(b, key)
  if not b then return end
  for i = 1, table.getn(b.spells) do
    if b.spells[i].key == key then return i end
  end
end

local function announce(key, rank, new)
  local b = SB.Build()
  local name = b and b.names and b.names[key]
  if not name then return end
  local idx = priority(b, key)
  local suffix = idx and string.format(tl("prio"), idx) or tl("out")
  if new then
    SB.Print(string.format(tl("newSpell"), name, suffix))
  else
    SB.Print(string.format(tl("upSpell"), name, rank, suffix))
  end
end

local function watch()
  if not AZS_SPELLS_UPDATED or AZS_SPELLS_UPDATED == lastUpdate then return end
  lastUpdate = AZS_SPELLS_UPDATED
  local lvl = AZS_RUN and tonumber(AZS_RUN.lvl)
  local now = ranks()
  if not known or (lvl and lastLevel and lvl < lastLevel) then
    known = now
    lastLevel = lvl
    return
  end
  lastLevel = lvl
  for key, r in pairs(now) do
    local before = known[key]
    if not before then announce(key, r, true) elseif r > before then announce(key, r, false) end
  end
  known = now
end

local function build()
  local f = CreateFrame("Frame", "SurvivorsBuildsGuide", UIParent)
  f:SetWidth(260)
  f:SetHeight(100)
  f:SetFrameStrata("HIGH")
  local bg = H.Fill(f, "BACKGROUND", 0.04, 0.04, 0.05, 0.85)
  bg:SetAllPoints(f)
  f.title = H.Text(f, 13, "LEFT")
  f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -7)
  f.title:SetTextColor(1, 0.82, 0.2)
  f.body = H.Text(f, 12, "LEFT")
  f.body:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -26)
  f.body:SetWidth(244)
  f.body:SetJustifyV("TOP")
  f:Hide()
  if SurvivorsUI and SurvivorsUI.Register then
    SurvivorsUI.Register("buildguide", "Build", f, "LEFT", 20, 60)
  else
    f:SetPoint("LEFT", UIParent, "LEFT", 20, 60)
    f:SetMovable(1)
    f:EnableMouse(1)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  end
  G.frame = f
  return f
end

function G.Lines(b)
  local have = ranks()
  local lines = ""
  for i = 1, math.min(6, table.getn(b.spells)) do
    local e = b.spells[i]
    local r = have[e.key]
    local state = r and string.format(tl("rank"), r) or ("|cff66ff66" .. tl("learn") .. "|r")
    lines = lines .. i .. ". " .. e.name .. "  |cff999999" .. state .. "|r\n"
  end
  if b.bans and table.getn(b.bans) > 0 then
    lines = lines .. "|cffff6666" .. string.format(tl("ban"), b.banishes or 3, table.concat(b.bans, ", ")) .. "|r\n"
  end
  if b.jewels and table.getn(b.jewels) > 0 then lines = lines .. string.format(tl("jewels"), table.concat(b.jewels, ", ")) .. "\n" end
  local rr = AZS_RUN and tonumber(AZS_RUN.rr)
  if rr then lines = lines .. string.format(tl("rerolls"), rr, b.reserve or 0) .. "\n" end
  lines = lines .. string.format(tl("rule"), b.reroll == 1 and tl("reroll") or tl("skip"))
  if SB.Fresh() and SB.Link().autoPick then lines = lines .. "\n|cff66ccff" .. tl("auto") .. "|r" end
  return lines
end

function G.Refresh()
  local f = G.frame
  if not f then return end
  local phase = AZS_GetPhase and AZS_GetPhase()
  local show = SB.DB().guide == "always" and phase or phase == "choosing" or (SurvivorsUI and SurvivorsUI.unlocked)
  if not show or SB.DB().guide == "never" then
    f:Hide()
    return
  end
  local b = SB.Build()
  if not b then
    f.title:SetText(tl("none"))
    f.body:SetText("")
    f:SetHeight(30)
    f:Show()
    return
  end
  f.title:SetText(string.format(tl("title"), b.name))
  f.body:SetText(G.Lines(b))
  f:SetHeight(f.body:GetHeight() + 36)
  f:Show()
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
local acc = 0
driver:SetScript("OnEvent", function()
  if not G.frame then build() end
  known, lastUpdate, lastLevel = nil, nil, nil
end)
driver:SetScript("OnUpdate", function()
  acc = acc + arg1
  if acc < 0.5 then return end
  acc = 0
  watch()
  G.Refresh()
end)

SLASH_SURVIVORSBUILDS1 = "/builds"
SlashCmdList["SURVIVORSBUILDS"] = function(msg)
  if msg == "guide" then
    local db = SB.DB()
    if db.guide == "always" then db.guide = "never" elseif db.guide == "never" then db.guide = nil else db.guide = "always" end
    SB.Print("guide: " .. (db.guide or "auto"))
    return
  end
  SurvivorsHub.Toggle("builds")
end
