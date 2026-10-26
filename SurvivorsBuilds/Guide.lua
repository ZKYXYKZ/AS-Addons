local H = SurvivorsHub
local G = {}
SB.Guide = G

local T = {
  fr = {
    title = "Build : %s", none = "Aucun build reçu du compagnon pour cette classe", learn = "à prendre", rank = "rang %d",
    ban = "À bannir (%d) : %s", rerolls = "Relances : %d (garder %d)", rule = "Rien du build : %s", reroll = "relancer puis skip", skip = "skip",
    jewels = "Bijoux visés : %s", newSpell = "Nouveau sort : %s%s", upSpell = "%s rang %d%s", prio = " (priorité %d)", out = " (hors build)",
    auto = "Sélection auto active (compagnon)", worn = "porté", target = "visé", fallback = "repli",
  },
  en = {
    title = "Build: %s", none = "No build received from the companion for this class", learn = "to take", rank = "rank %d",
    ban = "Banish (%d): %s", rerolls = "Rerolls: %d (keep %d)", rule = "Nothing from the build: %s", reroll = "reroll then skip", skip = "skip",
    jewels = "Target jewelry: %s", newSpell = "New spell: %s%s", upSpell = "%s rank %d%s", prio = " (priority %d)", out = " (off build)",
    auto = "Auto-pick on (companion)", worn = "worn", target = "target", fallback = "fallback",
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

local ROWH = 18
local WIDTH = 230

local function makeRow(f, i)
  local r = CreateFrame("Frame", nil, f)
  r:SetHeight(ROWH)
  r:SetWidth(WIDTH - 12)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -1)
  r.icon:SetPoint("BOTTOMRIGHT", r, "TOPLEFT", 16, -17)
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  r.name = H.Text(r, 12, "LEFT")
  r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
  r.name:SetWidth(WIDTH - 80)
  r.name:SetHeight(12)
  r.info = H.Text(r, 12, "RIGHT")
  r.info:SetPoint("RIGHT", r, "RIGHT", 0, 0)
  return r
end

local function build()
  local f = CreateFrame("Frame", "SurvivorsBuildsGuide", UIParent)
  f:SetWidth(WIDTH)
  f:SetHeight(100)
  f:SetFrameStrata("MEDIUM")
  local bg = H.Fill(f, "BACKGROUND", 0.04, 0.04, 0.05, 0.8)
  bg:SetAllPoints(f)
  f.title = H.Text(f, 13, "LEFT")
  f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -7)
  f.title:SetWidth(WIDTH - 16)
  f.title:SetTextColor(1, 0.82, 0.2)
  f.rows = {}
  f.body = H.Text(f, 12, "LEFT")
  f.body:SetWidth(WIDTH - 16)
  f.body:SetJustifyV("TOP")
  f:Hide()
  if SurvivorsUI and SurvivorsUI.Register then
    SurvivorsUI.Register("buildguide", "Build", f, "LEFT", 20, 60)
    if SurvivorsUI.Handle then SurvivorsUI.Handle("buildguide", f) end
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

local SLOTS = { 2, 11, 12, 13, 14 }

local function worn()
  local out = {}
  for i = 1, table.getn(SLOTS) do
    local link = GetInventoryItemLink("player", SLOTS[i])
    if link then
      local _, _, color, name = string.find(link, "|c(%x+)|H.-|h%[(.-)%]|h")
      if name then table.insert(out, { name = name, color = color, icon = GetInventoryItemTexture("player", SLOTS[i]) }) end
    end
  end
  return out
end

local function matches(name, t)
  return t.item and t.item ~= "" and (name == t.item or string.find(name, t.item, 1, 1))
end

local function choiceLines(b)
  local lines = ""
  if b.bans and table.getn(b.bans) > 0 then
    lines = lines .. "|cffff6666" .. string.format(tl("ban"), b.banishes or 3, table.concat(b.bans, ", ")) .. "|r\n"
  end
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
  local unlocked = SurvivorsUI and SurvivorsUI.unlocked
  if SB.DB().guide == "never" or not (phase or unlocked) then
    f:Hide()
    return
  end
  local b = SB.Build()
  if not b then
    f.title:SetText(tl("none"))
    for i = 1, table.getn(f.rows) do f.rows[i]:Hide() end
    f.body:SetText("")
    f:SetHeight(30)
    f:Show()
    return
  end
  f.title:SetText(string.format(tl("title"), b.name))
  local have = ranks()
  local items = worn()
  local n, y = 0, -26
  local function nextRow()
    n = n + 1
    local r = f.rows[n] or makeRow(f, n)
    f.rows[n] = r
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", f, "TOPLEFT", 6, y)
    y = y - ROWH
    r:Show()
    return r
  end
  for i = 1, math.min(6, table.getn(b.spells)) do
    local e = b.spells[i]
    local r = nextRow()
    local rank = have[e.key]
    r.icon:SetTexture(e.icon and ("Interface/Icons/" .. e.icon) or nil)
    r.icon:SetAlpha(rank and 1 or 0.35)
    r.name:SetText(e.name)
    if rank then
      r.name:SetTextColor(1, 1, 1)
      r.info:SetText("|cffe6b84c" .. string.format(tl("rank"), rank) .. "|r")
    else
      r.name:SetTextColor(0.55, 0.55, 0.55)
      r.info:SetText("|cff66ff66" .. tl("learn") .. "|r")
    end
  end
  local targets = b.targets or {}
  local found = {}
  if table.getn(items) > 0 or table.getn(targets) > 0 then y = y - 6 end
  for i = 1, table.getn(items) do
    local it = items[i]
    local r = nextRow()
    local target
    for k = 1, table.getn(targets) do
      if not found[k] and matches(it.name, targets[k]) then target = k break end
    end
    if target then found[target] = true end
    r.icon:SetTexture(it.icon)
    r.icon:SetAlpha(1)
    r.name:SetText("|c" .. it.color .. it.name .. "|r")
    r.info:SetText(target and ("|cffe6b84c" .. tl("target") .. "|r") or ("|cff8899aa" .. tl("fallback") .. "|r"))
  end
  for k = 1, table.getn(targets) do
    if not found[k] then
      local t = targets[k]
      local r = nextRow()
      r.icon:SetTexture(t.icon and t.icon ~= "" and ("Interface/Icons/" .. t.icon) or nil)
      r.icon:SetAlpha(0.35)
      r.name:SetText(t.name)
      r.name:SetTextColor(0.55, 0.55, 0.55)
      r.info:SetText("")
    end
  end
  for i = n + 1, table.getn(f.rows) do f.rows[i]:Hide() end
  local h = -y + 6
  if phase == "choosing" then
    f.body:ClearAllPoints()
    f.body:SetPoint("TOPLEFT", f, "TOPLEFT", 8, y - 4)
    f.body:SetText(choiceLines(b))
    f.body:Show()
    h = h + f.body:GetHeight() + 8
  else
    f.body:SetText("")
    f.body:Hide()
  end
  f:SetHeight(h)
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
