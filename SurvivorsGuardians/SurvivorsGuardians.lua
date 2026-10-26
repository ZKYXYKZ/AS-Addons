local FONT = "Fonts\\ARIALN.TTF"
local WIDTH = 200
local ROW = 20
local HEAD = 18
local COLORS = {
  { 0.95, 0.35, 0.3 },
  { 0.3, 0.7, 0.95 },
  { 0.95, 0.8, 0.25 },
  { 0.55, 0.9, 0.4 },
  { 0.8, 0.5, 0.95 },
  { 0.95, 0.6, 0.3 },
}
local BOSS = { 0.8, 0.45, 1 }
local ENGLISH = { warrior = "Warrior", paladin = "Paladin", hunter = "Hunter", rogue = "Rogue", priest = "Priest",
  shaman = "Shaman", mage = "Mage", warlock = "Warlock", druid = "Druid" }
local T = {
  en = { title = "Guardians", asleep = "asleep", awake = "fighting", empty = "back in %s", gone = "empty", boss = "boss", next = "%s in %s", final = "final" },
  fr = { title = "Gardiens", asleep = "endormi", awake = "en combat", empty = "retour %s", gone = "vide", boss = "boss", next = "%s dans %s", final = "final" },
}

SurvivorsGuardiansDB = SurvivorsGuardiansDB or {}

local function lang()
  if SB and SB.Lang then return T[SB.Lang()] or T.en end
  local z = AZS_ZONE
  if not z then return T.en end
  if z.class and z.cname and ENGLISH[z.class] and z.cname ~= ENGLISH[z.class] then return T.fr end
  if z.race and z.rname and z.race ~= z.rname then return T.fr end
  return T.en
end

local function tex(parent, layer, r, g, b, a)
  local t = parent:CreateTexture(nil, layer)
  t:SetTexture(r, g, b, a or 1)
  return t
end

local function text(parent, size, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(FONT, size, "OUTLINE")
  fs:SetJustifyH(justify or "LEFT")
  fs:SetTextColor(1, 1, 1)
  return fs
end

local function clock(s)
  s = math.max(0, math.floor(s + 0.5))
  return string.format("%d:%02d", math.floor(s / 60), math.mod(s, 60))
end

local panel = CreateFrame("Frame", "SurvivorsGuardiansFrame", UIParent)
panel:SetWidth(WIDTH)
panel:SetHeight(HEAD)
panel:SetFrameStrata("LOW")
panel:SetMovable(1)
panel:EnableMouse(1)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", function() this:StartMoving() end)
panel:SetScript("OnDragStop", function()
  this:StopMovingOrSizing()
  SurvivorsGuardiansDB.x = this:GetLeft()
  SurvivorsGuardiansDB.y = this:GetTop()
end)
local bg = tex(panel, "BACKGROUND", 0, 0, 0, 0.55)
bg:SetAllPoints(panel)
local title = text(panel, 11, "LEFT")
title:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -4)
title:SetTextColor(0.75, 0.75, 0.75)
local count = text(panel, 11, "RIGHT")
count:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6, -4)
panel:Hide()

local rows = {}
local function row(i)
  if rows[i] then return rows[i] end
  local r = CreateFrame("Button", "SurvivorsGuardiansRow" .. i, panel)
  r:SetWidth(WIDTH)
  r:SetHeight(ROW)
  r:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -HEAD - (i - 1) * ROW)
  if SurvivorsUI and SurvivorsUI.Handle and SurvivorsUI.movers.guardians then
    SurvivorsUI.Handle("guardians", r)
  else
    r:RegisterForDrag("LeftButton")
    r:SetScript("OnDragStart", function() panel:StartMoving() end)
    r:SetScript("OnDragStop", function()
      panel:StopMovingOrSizing()
      SurvivorsGuardiansDB.x = panel:GetLeft()
      SurvivorsGuardiansDB.y = panel:GetTop()
    end)
  end
  r.hover = tex(r, "BACKGROUND", 1, 1, 1, 0.12)
  r.hover:SetAllPoints(r)
  r.hover:Hide()
  r:SetScript("OnEnter", function() this.hover:Show() end)
  r:SetScript("OnLeave", function() this.hover:Hide() end)
  r:SetScript("OnClick", function()
    if this.unitName then TargetByName(this.unitName, 1) end
  end)
  r.name = text(r, 11, "LEFT")
  r.name:SetPoint("LEFT", r, "LEFT", 8, 1)
  r.name:SetWidth(WIDTH - 76)
  r.name:SetHeight(11)
  r.shade = tex(r, "BACKGROUND", 0, 0, 0, 0.35)
  r.shade:SetAllPoints(r)
  r.shade:Hide()
  r.info = text(r, 11, "RIGHT")
  r.info:SetPoint("RIGHT", r, "RIGHT", -6, 1)
  r.hpbg = tex(r, "BORDER", 0, 0, 0, 0.6)
  r.hpbg:SetHeight(2)
  r.hpbg:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 8, 1)
  r.hpbg:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -6, 1)
  r.hp = tex(r, "ARTWORK", 1, 1, 1, 1)
  r.hp:SetHeight(2)
  r.hp:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 8, 1)
  rows[i] = r
  return r
end

local function units()
  local out = {}
  if not AZS_UNITS then return out end
  for i = 1, table.getn(AZS_UNITS) do
    local u = AZS_UNITS[i]
    if u.id then out[u.id] = u end
  end
  return out
end

local function hpBar(r, frac, c)
  if frac then
    r.hpbg:Show()
    r.hp:SetTexture(c[1], c[2], c[3], 1)
    r.hp:SetWidth(math.max(1, (WIDTH - 14) * frac))
    r.hp:Show()
  else
    r.hp:Hide()
    r.hpbg:Hide()
  end
end

local function render()
  local L = lang()
  local lairs = AZS_GetLairs and AZS_GetLairs() or {}
  local bosses = AZS_GetBosses and AZS_GetBosses() or {}
  local phase = AZS_GetPhase and AZS_GetPhase()
  if not phase or table.getn(lairs) == 0 and table.getn(bosses) == 0 then
    for i = 1, table.getn(rows) do rows[i]:Hide() end
    if SurvivorsUI and SurvivorsUI.unlocked then
      title:SetText(L.title)
      count:SetText("")
      panel:SetHeight(HEAD + ROW)
      panel:Show()
    else
      panel:Hide()
    end
    return
  end
  local byId = units()
  local elapsed = AZS_LAIRS_UPDATED and phase == "playing" and (GetTime() - AZS_LAIRS_UPDATED) or 0
  local n, held = 0, 0
  for i = 1, table.getn(lairs) do
    local l = lairs[i]
    n = n + 1
    local r = row(n)
    local c = COLORS[math.mod(n - 1, table.getn(COLORS)) + 1]
    local u = l.id and byId[l.id]
    r.name:SetText(l.name or "?")
    if l.state == "empty" then
      r.unitName = nil
      r.name:SetTextColor(0.42, 0.42, 0.42)
      r.info:SetTextColor(0.6, 0.6, 0.6)
      local left = (tonumber(l.left) or -1) - elapsed
      r.info:SetText(left > 0 and string.format(L.empty, clock(left)) or L.gone)
      r.shade:Show()
      hpBar(r, nil)
    else
      held = held + 1
      r.unitName = l.name
      r.name:SetTextColor(c[1], c[2], c[3])
      r.shade:Hide()
      local frac = u and u.hpm and u.hpm > 0 and u.hp / u.hpm
      if l.state == "awake" then
        r.info:SetTextColor(1, 0.45, 0.35)
        r.info:SetText(frac and string.format("%d%%", frac * 100) or L.awake)
      else
        r.info:SetTextColor(c[1], c[2], c[3])
        r.info:SetText(frac and frac < 1 and string.format("%d%%", frac * 100) or L.asleep)
      end
      hpBar(r, frac, c)
    end
    r:Show()
  end
  for i = 1, table.getn(bosses) do
    local b = bosses[i]
    n = n + 1
    local r = row(n)
    r.unitName = b.name
    r.shade:Hide()
    r.name:SetText(b.name)
    r.name:SetTextColor(BOSS[1], BOSS[2], BOSS[3])
    local frac = b.hpm and b.hpm > 0 and b.hp / b.hpm
    r.info:SetTextColor(BOSS[1], BOSS[2], BOSS[3])
    r.info:SetText(frac and string.format("%d%%", frac * 100) or (b.final and L.final or L.boss))
    hpBar(r, frac, BOSS)
    r:Show()
  end
  for i = n + 1, table.getn(rows) do rows[i]:Hide() end
  title:SetText(L.title .. "  " .. held .. "/" .. table.getn(lairs))
  local up = AZS_GetUpcomingBosses and AZS_GetUpcomingBosses() or {}
  local nextBoss
  for i = 1, table.getn(up) do
    if up[i].left and up[i].left > 0 and (not nextBoss or up[i].left < nextBoss.left) then nextBoss = up[i] end
  end
  if nextBoss then
    count:SetText("|cffcc77ff" .. string.format(L.next, nextBoss.name, clock(nextBoss.left)) .. "|r")
  else
    count:SetText("")
  end
  local need = title:GetStringWidth() + count:GetStringWidth() + 24
  panel:SetWidth(math.max(WIDTH, need))
  panel:SetHeight(HEAD + n * ROW + 3)
  panel:Show()
end

local function place()
  panel:ClearAllPoints()
  if SurvivorsGuardiansDB.x and SurvivorsGuardiansDB.y then
    panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", SurvivorsGuardiansDB.x, SurvivorsGuardiansDB.y)
  else
    panel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -14, -200)
  end
end

local driver = CreateFrame("Frame", "SurvivorsGuardiansDriver", UIParent)
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
local ready, acc = false, 0
driver:SetScript("OnEvent", function()
  if SurvivorsUI and SurvivorsUI.Register then
    panel:SetScript("OnDragStart", nil)
    panel:SetScript("OnDragStop", nil)
    SurvivorsUI.Register("guardians", "Guardians", panel, "TOPRIGHT", -14, -200)
    if SurvivorsUI.Handle then SurvivorsUI.Handle("guardians", panel) end
  else
    place()
  end
  ready = true
end)
driver:SetScript("OnUpdate", function()
  if not ready then return end
  acc = acc + arg1
  if acc < 0.25 then return end
  acc = 0
  local ok, err = pcall(render)
  if not ok then SurvivorsGuardiansDB.error = tostring(err) end
end)

SLASH_SURVIVORSGUARDIANS1 = "/guardians"
SlashCmdList["SURVIVORSGUARDIANS"] = function()
  if SurvivorsUI and SurvivorsUI.movers.guardians then
    SurvivorsUI.Reset(SurvivorsUI.movers.guardians)
    return
  end
  SurvivorsGuardiansDB.x, SurvivorsGuardiansDB.y = nil, nil
  place()
end
