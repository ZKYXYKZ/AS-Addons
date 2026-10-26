local H = SurvivorsHub
local G = {}
SB.Guide = G

local T = {
  fr = {
    title = "Build : %s", none = "Aucun build actif pour cette classe", learn = "à prendre", rank = "rang %d",
    ban = "À bannir : %s", rerolls = "Relances : %d (garder %d)", rule = "Rien du build : %s", reroll = "relancer puis skip", skip = "skip",
    jewels = "Bijoux visés : %s", newSpell = "Nouveau sort : %s%s", upSpell = "%s rang %d%s", prio = " (priorité %d)", out = " (hors build)",
  },
  en = {
    title = "Build: %s", none = "No active build for this class", learn = "to take", rank = "rank %d",
    ban = "Banish: %s", rerolls = "Rerolls: %d (keep %d)", rule = "Nothing from the build: %s", reroll = "reroll then skip", skip = "skip",
    jewels = "Target jewelry: %s", newSpell = "New spell: %s%s", upSpell = "%s rank %d%s", prio = " (priority %d)", out = " (off build)",
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

local function announce(b, key, rank, new)
  local cls = SB.PlayerClass()
  local s = SB.Spell(cls, key)
  if not s then return end
  local idx = b and SB.SpellIndex(b, key)
  local suffix = idx and string.format(tl("prio"), idx) or (b and tl("out") or "")
  if new then
    SB.Print(string.format(tl("newSpell"), SB.T(s.name), suffix))
  else
    SB.Print(string.format(tl("upSpell"), SB.T(s.name), rank, suffix))
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
  local b = SB.Active(SB.PlayerClass())
  for key, r in pairs(now) do
    local before = known[key]
    if not before then
      announce(b, key, r, true)
    elseif r > before then
      announce(b, key, r, false)
    end
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

function G.Refresh()
  local f = G.frame
  if not f then return end
  local phase = AZS_GetPhase and AZS_GetPhase()
  local show = SB.DB().guide == "always" and phase or phase == "choosing" or (SurvivorsUI and SurvivorsUI.unlocked)
  if not show or SB.DB().guide == "never" then
    f:Hide()
    return
  end
  local b = SB.Active(SB.PlayerClass())
  if not b then
    f.title:SetText(tl("none"))
    f.body:SetText("")
    f:SetHeight(30)
    f:Show()
    return
  end
  f.title:SetText(string.format(tl("title"), b.name))
  local have = ranks()
  local lines = ""
  for i = 1, math.min(6, table.getn(b.spells)) do
    local e = b.spells[i]
    local s = SB.Spell(b.class, e.key)
    if s then
      local r = have[e.key]
      local state = r and string.format(tl("rank"), r) or ("|cff66ff66" .. tl("learn") .. "|r")
      lines = lines .. i .. ". " .. SB.T(s.name) .. "  |cff999999" .. state .. "|r\n"
    end
  end
  local bans = ""
  for key in pairs(b.ban) do
    local s = SB.Spell(b.class, key)
    if s then bans = bans .. (bans == "" and "" or ", ") .. SB.T(s.name) end
  end
  if bans ~= "" then lines = lines .. "|cffff6666" .. string.format(tl("ban"), bans) .. "|r\n" end
  local wanted = ""
  for _, cat in ipairs({ "rings", "trinkets", "amulets" }) do
    local j = b[cat][1] and SB.Jewel(cat, b[cat][1])
    if j then wanted = wanted .. (wanted == "" and "" or ", ") .. SB.T(j.name) end
  end
  if wanted ~= "" then lines = lines .. string.format(tl("jewels"), wanted) .. "\n" end
  local rr = AZS_RUN and tonumber(AZS_RUN.rr)
  if rr then lines = lines .. string.format(tl("rerolls"), rr, b.rules.reserve or 0) .. "\n" end
  lines = lines .. string.format(tl("rule"), b.rules.reroll == 1 and tl("reroll") or tl("skip"))
  f.body:SetText(lines)
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
