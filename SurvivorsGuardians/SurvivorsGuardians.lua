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
  r.strike = tex(r, "OVERLAY", 0.6, 0.6, 0.6, 0.9)
  r.strike:SetHeight(1)
  r.strike:SetPoint("LEFT", r.name, "LEFT", -2, 0)
  r.strike:Hide()
  r.shade = tex(r, "BACKGROUND", 0, 0, 0, 0.35)
  r.shade:SetAllPoints(r)
  r.shade:Hide()
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

local clock, lastAct, bossSync, lastBoss = 0, 0, 0, nil
local tail = 0
local BOSS_EVERY = 180

local function reset()
  order, byName = {}, {}
  speed = 0
  lastX, lastY, lastT = nil, nil, nil
  clock, bossSync, lastBoss = 0, 0, nil
end

local function known()
  SurvivorsGuardiansDB.zones = SurvivorsGuardiansDB.zones or {}
  if not zone or zone == "" then return {} end
  SurvivorsGuardiansDB.zones[zone] = SurvivorsGuardiansDB.zones[zone] or {}
  return SurvivorsGuardiansDB.zones[zone]
end

local function keyOf(name, x, y)
  return string.format("%s@%.3f,%.3f", name, x, y)
end

local function find(name, state)
  local best, bd
  for i = 1, table.getn(order) do
    local g = order[i]
    if g.name == name and (not state or (state == "dead") == (g.dead and true or false)) then
      local d = 0
      if g.x then
        local dx, dy = (g.x - px) * 1.5, g.y - py
        d = dx * dx + dy * dy
      end
      if not best or d < bd then best, bd = g, d end
    end
  end
  return best
end

local function preload()
  local keys = {}
  for key, k in pairs(known()) do
    if k.name then table.insert(keys, key) end
  end
  table.sort(keys)
  for i = 1, table.getn(keys) do
    local k = known()[keys[i]]
    local g = { name = k.name, x = k.x, y = k.y, dead = false }
    byName[keys[i]] = g
    table.insert(order, g)
  end
end

local function revive(g)
  if g.deadClock and clock - g.deadClock > 20 then
    SurvivorsGuardiansDB.respawn = math.floor(clock - g.deadClock + 0.5)
  end
  g.dead = false
  g.lock = nil
  g.deadClock = nil
end

local function scan()
  local z = GetRealZoneText()
  if z ~= zone then
    zone = z
    reset()
    preload()
  end
  if not (WorldMapFrame and WorldMapFrame:IsVisible()) then SetMapToCurrentZone() end
  px, py = GetPlayerMapPosition("player")
  local stamp = GetTime()
  for i = 1, GetNumMapLandmarks() do
    local name, _, _, x, y = GetMapLandmarkInfo(i)
    if name then
      local _, _, alive = string.find(name, "^(.+) %(Guardian%)$")
      local _, _, dead = string.find(name, "^(.+)'s lair %(empty%)$")
      local base = alive or dead
      if base then
        local key = keyOf(base, x, y)
        local g
        for j = 1, table.getn(order) do
          local o = order[j]
          if o.name == base and not o.boss and o.claim ~= stamp and math.abs(o.x - x) < 0.03 and math.abs(o.y - y) < 0.03 then
            g = o
            break
          end
        end
        if g then
          g.claim = stamp
          if not g.dead or dead then g.x, g.y = x, y end
        else
          g = { name = base, x = x, y = y, claim = stamp }
          byName[key] = g
          table.insert(order, g)
          known()[key] = { name = base, x = x, y = y }
        end
        if dead then
          if not g.dead then
            g.dead = true
            g.deadClock = clock
          end
          g.hp = nil
          g.lock = nil
        elseif g.dead and not (g.lock and GetTime() < g.lock) then
          revive(g)
        end
      end
    end
  end
end

local function addBoss(name)
  if not name or name == "" or find(name) then return end
  local g = { name = name, boss = true, dead = false }
  table.insert(order, g)
  if lastBoss and clock - lastBoss > 60 then
    SurvivorsGuardiansDB.bossEvery = math.floor((clock - lastBoss) / 30 + 0.5) * 30
  end
  if not lastBoss or clock - lastBoss > 60 then
    lastBoss = clock
    bossSync = clock
  end
end

local function dropBoss(g)
  for i = 1, table.getn(order) do
    if order[i] == g then
      table.remove(order, i)
      break
    end
  end
end

local function markDead(name)
  local g = name and find(name, "alive")
  if not g then return end
  g.dead = true
  g.hp = nil
  g.diedAt = GetTime()
  g.deadClock = clock
  g.lock = GetTime() + 6
end

local function readChat(msg, speaker)
  if not msg then return end
  if speaker and speaker ~= "" then
    msg = string.gsub(msg, "%%s", speaker)
  end
  if event == "CHAT_MSG_MONSTER_YELL" then
    addBoss(speaker)
    return
  end
  local _, _, came = string.find(msg, "^(.+) has come!$")
  local _, _, near = string.find(msg, "^(.+) approaches!$")
  if came or near then
    local name = came or near
    if not string.find(name, "%%") then addBoss(name) end
    return
  end
  local _, _, back = string.find(msg, "^(.+) claims its lair once more")
  if back then
    local g = find(back, "dead")
    if g then revive(g) end
    return
  end
  local _, _, a = string.find(msg, "^(.+) dies%.$")
  local _, _, b = string.find(msg, "^(.+) is defeated!")
  local _, _, c = string.find(msg, "^(.+) is slain!")
  local _, _, d = string.find(msg, "^You have slain (.+)!$")
  local soft = a or d
  local sg = soft and find(soft)
  if sg and not sg.boss then soft = nil end
  markDead(b or c or soft)
end

local function watchUnit(unit)
  if not UnitExists(unit) then return end
  local name = UnitName(unit) or ""
  if not find(name) and UnitClassification(unit) == "worldboss" and not UnitIsDead(unit) then addBoss(name) end
  local g = find(name, "alive") or find(name)
  if not g then return end
  local level = UnitLevel(unit)
  if level and level > 0 then g.level = level end
  g.seenAt = GetTime()
  if UnitIsDead(unit) then
    if g.boss then markDead(name) end
    return
  end
  if g.dead and g.boss then return end
  local max = UnitHealthMax(unit)
  if max and max > 0 then g.hp = UnitHealth(unit) / max end
end

local peekIndex, peekAcc = 0, 0
local pending, release

local function peek()
  if SurvivorsGuardiansDB.peek == false then return end
  local n = table.getn(order)
  if n == 0 then return end
  local current = UnitName("target")
  if current and find(current) then return end
  if not current and not ClearTarget then return end
  for k = 1, n do
    peekIndex = peekIndex + 1
    if peekIndex > n then peekIndex = 1 end
    local g = order[peekIndex]
    if not g.dead and not (g.seenAt and GetTime() - g.seenAt < 30) then
      pending = { g = g, had = current, ticks = 0 }
      SURVIVORS_PEEKING = 1
      TargetByName(g.name, 1)
      return
    end
  end
end

local function finishPeek()
  pending.ticks = pending.ticks + 1
  local arrived = UnitName("target") == pending.g.name
  if not arrived and pending.ticks < 3 then return end
  pending.g.seenAt = GetTime()
  if arrived then
    watchUnit("target")
    if pending.had then TargetLastTarget() else ClearTarget() end
  end
  pending = nil
  release = 2
end

local function expireBosses()
  for i = table.getn(order), 1, -1 do
    local g = order[i]
    if g.boss and g.dead and g.diedAt and GetTime() - g.diedAt > 20 then dropBoss(g) end
  end
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
    for i = 1, table.getn(pins) do pins[i]:Hide() end
    for i = 1, table.getn(rows) do rows[i]:Hide() end
    if SurvivorsUI and SurvivorsUI.unlocked then
      title:SetText("Guardians")
      count:SetText("")
      panel:SetHeight(HEAD + ROW)
      panel:Show()
    else
      panel:Hide()
    end
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
    if g.level then
      r.name:SetText("|cffaaaaaa" .. g.level .. "|r  " .. g.name)
    else
      r.name:SetText(g.name)
    end
    r.unitName = (not g.dead) and g.name or nil
    local p = pin(i)
    if g.dead then
      if not g.boss then slain = slain + 1 end
      r.name:SetText((g.level and (g.level .. "  ") or "") .. g.name)
      r.dot:SetTexture(0.35, 0.35, 0.35, 1)
      r.name:SetTextColor(0.42, 0.42, 0.42)
      r.info:SetTextColor(0.85, 0.3, 0.3)
      local back = (not g.boss) and SurvivorsGuardiansDB.respawn and g.deadClock and (SurvivorsGuardiansDB.respawn - (clock - g.deadClock))
      if back and back > 0 then
        r.info:SetText(string.format("DEAD %d:%02d", back / 60, math.mod(back, 60)))
      else
        r.info:SetText("DEAD")
      end
      r.strike:SetWidth(math.min(r.name:GetStringWidth() + 4, WIDTH - 80))
      r.strike:Show()
      r.shade:Show()
      r.hp:Hide()
      r.hpbg:Hide()
      p:Hide()
    elseif g.boss then
      r.strike:Hide()
      r.shade:Hide()
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
    else
      r.strike:Hide()
      r.shade:Hide()
      r.dot:SetTexture(c[1], c[2], c[3], 1)
      r.name:SetTextColor(1, 1, 1)
      r.info:SetTextColor(c[1], c[2], c[3])
      if g.hp and g.hp < 1 then
        r.info:SetText(string.format("%d%%", g.hp * 100))
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
  local every = SurvivorsGuardiansDB.bossEvery or BOSS_EVERY
  local nextBoss = every - math.mod(clock - bossSync, every)
  count:SetText(string.format("|cffcc77ffboss %d:%02d|r   %d / %d", nextBoss / 60, math.mod(nextBoss, 60), slain, total))
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
local ACTIVITY = {
  UNIT_COMBAT = 1,
  UNIT_HEALTH = 1,
  PLAYER_XP_UPDATE = 1,
  CHAT_MSG_COMBAT_HOSTILE_DEATH = 1,
  CHAT_MSG_COMBAT_SELF_HITS = 1,
  CHAT_MSG_SPELL_SELF_DAMAGE = 1,
  CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS = 1,
}
local CHAT = {
  CHAT_MSG_SYSTEM = 1,
  CHAT_MSG_RAID_BOSS_EMOTE = 1,
  CHAT_MSG_MONSTER_EMOTE = 1,
  CHAT_MSG_MONSTER_YELL = 1,
  CHAT_MSG_COMBAT_HOSTILE_DEATH = 1,
}
for e in pairs(ACTIVITY) do driver:RegisterEvent(e) end
local ready, acc = false, 0
driver:SetScript("OnEvent", function()
  if ACTIVITY[event] then
    lastAct = GetTime()
    tail = 0
  end
  if event == "PLAYER_ENTERING_WORLD" then
    zone = nil
    if SurvivorsUI and SurvivorsUI.Register then
      panel:SetScript("OnDragStart", nil)
      panel:SetScript("OnDragStop", nil)
      SurvivorsUI.Register("guardians", "Guardians", panel, "TOPRIGHT", -14, -200)
    else
      place()
    end
    ready = true
  elseif event == "PLAYER_TARGET_CHANGED" then
    watchUnit("target")
  elseif event == "UPDATE_MOUSEOVER_UNIT" then
    watchUnit("mouseover")
  elseif CHAT[event] then
    readChat(arg1, arg2)
  end
end)
driver:SetScript("OnUpdate", function()
  if not ready then return end
  if GetTime() - lastAct < 2.5 then
    clock = clock + arg1
    tail = tail + arg1
  elseif tail > 0 then
    clock = clock - tail
    tail = 0
  end
  acc = acc + arg1
  if acc < 0.25 then return end
  acc = 0
  local ok, err = pcall(function()
    scan()
    measureSpeed()
    watchUnit("target")
    expireBosses()
    if pending then
      finishPeek()
    elseif release then
      release = release - 1
      if release <= 0 then
        release = nil
        SURVIVORS_PEEKING = nil
      end
    else
      peekAcc = peekAcc + 0.25
      if peekAcc >= 2 then
        peekAcc = 0
        peek()
      end
    end
    render()
  end)
  if not ok then SurvivorsGuardiansDB.error = tostring(err) end
end)

SLASH_SURVIVORSGUARDIANS1 = "/guardians"
SlashCmdList["SURVIVORSGUARDIANS"] = function(msg)
  if msg == "peek" then
    SurvivorsGuardiansDB.peek = (SurvivorsGuardiansDB.peek == false)
    DEFAULT_CHAT_FRAME:AddMessage("Guardians peek: " .. (SurvivorsGuardiansDB.peek and "on" or "off"))
    return
  end
  if SurvivorsUI and SurvivorsUI.movers.guardians then
    SurvivorsUI.Reset(SurvivorsUI.movers.guardians)
    return
  end
  SurvivorsGuardiansDB.x, SurvivorsGuardiansDB.y = nil, nil
  place()
end
