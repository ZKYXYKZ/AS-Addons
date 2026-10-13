local FONT = "Fonts\\ARIALN.TTF"
local WIDTH = 190
local ROW = 20
local HEAD = 18
local MAXROWS = 8
local COLORS = {
  { 0.95, 0.35, 0.3 },
  { 0.3, 0.7, 0.95 },
  { 0.95, 0.8, 0.25 },
  { 0.55, 0.9, 0.4 },
  { 0.8, 0.5, 0.95 },
  { 0.95, 0.6, 0.3 },
  { 0.5, 0.9, 0.85 },
  { 0.9, 0.9, 0.9 },
}

local BOSS = { 0.8, 0.45, 1 }

SurvivorsGuardiansDB = SurvivorsGuardiansDB or {}

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
  r.hover = tex(r, "BACKGROUND", 1, 1, 1, 0.12)
  r.hover:SetAllPoints(r)
  r.hover:Hide()
  r:SetScript("OnEnter", function() this.hover:Show() end)
  r:SetScript("OnLeave", function() this.hover:Hide() end)
  r:SetScript("OnClick", function()
    if this.unitName then TargetByName(this.unitName, 1) end
  end)
  r.compass = CreateFrame("Frame", nil, r)
  r.compass:SetWidth(16)
  r.compass:SetHeight(16)
  r.compass:SetPoint("LEFT", r, "LEFT", 6, 0)
  local ring = tex(r.compass, "BACKGROUND", 1, 1, 1, 0.1)
  ring:SetAllPoints(r.compass)
  r.center = tex(r.compass, "BORDER", 1, 1, 1, 0.35)
  r.center:SetWidth(2)
  r.center:SetHeight(2)
  r.center:SetPoint("CENTER", r.compass, "CENTER", 0, 0)
  r.dot = tex(r.compass, "ARTWORK", 1, 1, 1, 1)
  r.dot:SetWidth(4)
  r.dot:SetHeight(4)
  r.name = text(r, 11, "LEFT")
  r.name:SetPoint("LEFT", r.compass, "RIGHT", 6, 1)
  r.name:SetWidth(WIDTH - 80)
  r.name:SetHeight(11)
  r.info = text(r, 11, "RIGHT")
  r.info:SetPoint("RIGHT", r, "RIGHT", -6, 1)
  r.hpbg = tex(r, "BORDER", 0, 0, 0, 0.6)
  r.hpbg:SetHeight(2)
  r.hpbg:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 28, 1)
  r.hpbg:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -6, 1)
  r.hp = tex(r, "ARTWORK", 1, 1, 1, 1)
  r.hp:SetHeight(2)
  r.hp:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 28, 1)
  rows[i] = r
  return r
end

local pins = {}
local function pin(i)
  if pins[i] then return pins[i] end
  local p = CreateFrame("Frame", nil, Minimap)
  p:SetWidth(8)
  p:SetHeight(8)
  p:SetFrameLevel(Minimap:GetFrameLevel() + 3)
  local o = tex(p, "BACKGROUND", 0, 0, 0, 1)
  o:SetAllPoints(p)
  p.fill = tex(p, "ARTWORK", 1, 1, 1, 1)
  p.fill:SetPoint("TOPLEFT", p, "TOPLEFT", 1, -1)
  p.fill:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -1, 1)
  pins[i] = p
  return p
end

local order, byName = {}, {}
local zone = nil
local px, py = 0, 0
local speed = 0
local lastX, lastY, lastT

local function reset()
  order, byName = {}, {}
  speed = 0
  lastX, lastY, lastT = nil, nil, nil
end

local function scan()
  local z = GetRealZoneText()
  if z ~= zone then
    zone = z
    reset()
  end
  if not (WorldMapFrame and WorldMapFrame:IsVisible()) then SetMapToCurrentZone() end
  px, py = GetPlayerMapPosition("player")
  for i = 1, GetNumMapLandmarks() do
    local name, _, _, x, y = GetMapLandmarkInfo(i)
    if name then
      local _, _, alive = string.find(name, "^(.+) %(Guardian%)$")
      local _, _, dead = string.find(name, "^(.+)'s lair %(empty%)$")
      local base = alive or dead
      if base then
        local g = byName[base]
        if not g then
          g = { name = base }
          byName[base] = g
          table.insert(order, g)
        end
        g.x, g.y = x, y
        g.boss = nil
        if dead then
          g.dead = true
          g.hp = nil
        else
          g.dead = false
        end
      end
    end
  end
end

local function addBoss(name)
  if not name or name == "" or byName[name] then return end
  local g = { name = name, boss = true, dead = false }
  byName[name] = g
  table.insert(order, g)
end

local function dropBoss(name)
  local g = name and byName[name]
  if not g or not g.boss then return end
  byName[name] = nil
  for i = 1, table.getn(order) do
    if order[i] == g then
      table.remove(order, i)
      break
    end
  end
end

local function readChat(msg, speaker)
  if not msg then return end
  if event == "CHAT_MSG_MONSTER_YELL" then
    addBoss(speaker)
    return
  end
  local _, _, came = string.find(msg, "^(.+) has come!$")
  local _, _, near = string.find(msg, "^(.+) approaches!$")
  if came or near then
    addBoss(came or near)
    return
  end
  local _, _, a = string.find(msg, "^(.+) dies%.$")
  local _, _, b = string.find(msg, "^(.+) is defeated!")
  local _, _, c = string.find(msg, "^(.+) is slain!")
  local _, _, d = string.find(msg, "^You have slain (.+)!$")
  dropBoss(a or b or c or d)
end

local function watchUnit(unit)
  if not UnitExists(unit) then return end
  local name = UnitName(unit) or ""
  if not byName[name] and UnitClassification(unit) == "worldboss" and not UnitIsDead(unit) then addBoss(name) end
  local g = byName[name]
  if not g then return end
  if g.boss and UnitIsDead(unit) then
    dropBoss(name)
    return
  end
  local max = UnitHealthMax(unit)
  if max and max > 0 then g.hp = UnitHealth(unit) / max end
end

local function measureSpeed()
  local now = GetTime()
  if lastT and (px ~= 0 or py ~= 0) then
    local dt = now - lastT
    if dt > 0.2 then
      local dx, dy = (px - lastX) * 1.5, py - lastY
      local v = math.sqrt(dx * dx + dy * dy) / dt
      if v > speed and v < 0.05 then speed = v end
      lastX, lastY, lastT = px, py, now
    end
  else
    lastX, lastY, lastT = px, py, now
  end
end

local function render()
  local n = table.getn(order)
  if n == 0 then
    panel:Hide()
    for i = 1, table.getn(pins) do pins[i]:Hide() end
    return
  end
  if n > MAXROWS then n = MAXROWS end
  local slain, total = 0, 0
  local half = Minimap:GetWidth() / 2
  for i = 1, n do
    local g = order[i]
    local r = row(i)
    local c = COLORS[i]
    local d, ux, uy = 0, 0, 0
    if g.boss then
      c = BOSS
      r.compass:Hide()
    else
      total = total + 1
      local dx, dy = (g.x - px) * 1.5, py - g.y
      d = math.sqrt(dx * dx + dy * dy)
      if d > 0 then ux, uy = dx / d, dy / d end
      r.compass:Show()
      r.dot:ClearAllPoints()
      r.dot:SetPoint("CENTER", r.compass, "CENTER", ux * 6, uy * 6)
    end
    r.name:SetText(g.name)
    r.unitName = (not g.dead) and g.name or nil
    local p = pin(i)
    if g.boss then
      r.name:SetTextColor(c[1], c[2], c[3])
      r.info:SetTextColor(c[1], c[2], c[3])
      r.info:SetText("boss")
      if g.hp then
        r.hpbg:Show()
        r.hp:SetTexture(c[1], c[2], c[3], 1)
        r.hp:SetWidth(math.max(1, (WIDTH - 34) * g.hp))
        r.hp:Show()
      else
        r.hp:Hide()
        r.hpbg:Hide()
      end
      p:Hide()
    elseif g.dead then
      slain = slain + 1
      r.dot:SetTexture(0.45, 0.45, 0.45, 1)
      r.name:SetTextColor(0.5, 0.5, 0.5)
      r.info:SetTextColor(0.5, 0.5, 0.5)
      r.info:SetText("slain")
      r.hp:Hide()
      r.hpbg:Hide()
      p:Hide()
    else
      r.dot:SetTexture(c[1], c[2], c[3], 1)
      r.name:SetTextColor(1, 1, 1)
      r.info:SetTextColor(c[1], c[2], c[3])
      if speed > 0 then
        local eta = d / speed
        if eta < 3 then
          r.info:SetText("here")
        elseif eta < 100 then
          r.info:SetText(string.format("%ds", eta))
        else
          r.info:SetText(string.format("%dm", eta / 60))
        end
      else
        r.info:SetText("")
      end
      if g.hp then
        r.hpbg:Show()
        r.hp:SetTexture(c[1], c[2], c[3], 1)
        r.hp:SetWidth(math.max(1, (WIDTH - 34) * g.hp))
        r.hp:Show()
      else
        r.hp:Hide()
        r.hpbg:Hide()
      end
      p.fill:SetTexture(c[1], c[2], c[3], 1)
      local ex, ey
      if SURVIVORSUI_SQUARE_MINIMAP then
        local m = math.max(math.abs(ux), math.abs(uy))
        if m == 0 then m = 1 end
        ex, ey = ux / m * (half - 3), uy / m * (half - 3)
      else
        ex, ey = ux * (half - 6), uy * (half - 6)
      end
      p:ClearAllPoints()
      p:SetPoint("CENTER", Minimap, "CENTER", ex, ey)
      p:Show()
    end
    r:Show()
  end
  for i = n + 1, table.getn(rows) do rows[i]:Hide() end
  for i = n + 1, table.getn(pins) do pins[i]:Hide() end
  title:SetText("Guardians")
  count:SetText(slain .. " / " .. total)
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
driver:RegisterEvent("PLAYER_TARGET_CHANGED")
driver:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
driver:RegisterEvent("CHAT_MSG_SYSTEM")
driver:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
driver:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
driver:RegisterEvent("CHAT_MSG_MONSTER_YELL")
driver:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
local ready, acc = false, 0
driver:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    place()
    ready = true
  elseif event == "PLAYER_TARGET_CHANGED" then
    watchUnit("target")
  elseif event == "UPDATE_MOUSEOVER_UNIT" then
    watchUnit("mouseover")
  else
    readChat(arg1, arg2)
  end
end)
driver:SetScript("OnUpdate", function()
  if not ready then return end
  acc = acc + arg1
  if acc < 0.25 then return end
  acc = 0
  local ok, err = pcall(function()
    scan()
    measureSpeed()
    watchUnit("target")
    render()
  end)
  if not ok then SurvivorsGuardiansDB.error = tostring(err) end
end)

SLASH_SURVIVORSGUARDIANS1 = "/guardians"
SlashCmdList["SURVIVORSGUARDIANS"] = function()
  SurvivorsGuardiansDB.x, SurvivorsGuardiansDB.y = nil, nil
  place()
end
