SurvivorsUI = { movers = {}, order = {}, unlocked = false }
local S = SurvivorsUI
local FONT = "Fonts\\ARIALN.TTF"

function S.DB()
  SurvivorsUIDB = SurvivorsUIDB or {}
  SurvivorsUIDB.frames = SurvivorsUIDB.frames or {}
  return SurvivorsUIDB
end

local function entry(m)
  local frames = S.DB().frames
  frames[m.key] = frames[m.key] or {}
  return frames[m.key]
end

function S.Scale(m)
  local e = S.DB().frames[m.key]
  return (e and e.scale) or m.scale
end

function S.Apply(m)
  local e = S.DB().frames[m.key]
  local f = m.frame
  f:SetScale(S.Scale(m))
  f:ClearAllPoints()
  if e and e.x then
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", e.x, e.y)
  else
    f:SetPoint(m.point, UIParent, m.point, m.x, m.y)
  end
end

function S.Save(m)
  local e = entry(m)
  e.x, e.y = m.frame:GetLeft(), m.frame:GetTop()
  S.Apply(m)
end

function S.SetScale(m, v)
  if v < 0.5 then v = 0.5 end
  if v > 2.5 then v = 2.5 end
  v = math.floor(v * 20 + 0.5) / 20
  local f = m.frame
  local old = f:GetScale()
  local l, t = f:GetLeft(), f:GetTop()
  local e = entry(m)
  e.scale = v
  if l and t then
    e.x, e.y = l * old / v, t * old / v
  end
  S.Apply(m)
  if m.tag then m.tag:SetText(m.label .. "  " .. string.format("%d%%", v * 100)) end
end

function S.Reset(m)
  S.DB().frames[m.key] = nil
  S.Apply(m)
  if m.tag then m.tag:SetText(m.label .. "  " .. string.format("%d%%", S.Scale(m) * 100)) end
end

local GRID = 32
local SNAP = 8
local grid

local function buildGrid()
  grid = CreateFrame("Frame", "SurvivorsUIGrid", UIParent)
  grid:SetFrameStrata("BACKGROUND")
  grid:SetAllPoints(UIParent)
  local w, h = UIParent:GetWidth(), UIParent:GetHeight()
  local shade = grid:CreateTexture(nil, "BACKGROUND")
  shade:SetTexture(0, 0, 0, 0.35)
  shade:SetAllPoints(grid)
  local function line(vertical, offset)
    local t = grid:CreateTexture(nil, "BORDER")
    if offset == 0 then
      t:SetTexture(1, 0.8, 0.2, 0.7)
    else
      t:SetTexture(1, 1, 1, 0.14)
    end
    if vertical then
      t:SetWidth(1)
      t:SetPoint("TOP", grid, "TOP", offset, 0)
      t:SetPoint("BOTTOM", grid, "BOTTOM", offset, 0)
    else
      t:SetHeight(1)
      t:SetPoint("LEFT", grid, "LEFT", 0, offset)
      t:SetPoint("RIGHT", grid, "RIGHT", 0, offset)
    end
  end
  line(true, 0)
  line(false, 0)
  for i = 1, math.floor(w / 2 / GRID) do
    line(true, i * GRID)
    line(true, -i * GRID)
  end
  for i = 1, math.floor(h / 2 / GRID) do
    line(false, i * GRID)
    line(false, -i * GRID)
  end
end

local function snapAxis(v, size, lines, origin)
  local best, bd = nil, SNAP
  for k = 0, 2 do
    local p = v + size * k / 2
    for i = 1, table.getn(lines) do
      local d = lines[i] - p
      if math.abs(d) < bd then
        bd = math.abs(d)
        best = d
      end
    end
  end
  if best then return v + best end
  for k = 0, 2, 2 do
    local p = v + size * k / 2
    local d = origin + math.floor((p - origin) / GRID + 0.5) * GRID - p
    if math.abs(d) < bd then
      bd = math.abs(d)
      best = d
    end
  end
  return v + (best or 0)
end

local function dragUpdate(m)
  local us = UIParent:GetEffectiveScale()
  local cx, cy = GetCursorPosition()
  cx, cy = cx / us, cy / us
  local f = m.frame
  local s = f:GetScale()
  local w, h = f:GetWidth() * s, f:GetHeight() * s
  local l, t = cx - m.dx, cy - m.dy
  if not IsShiftKeyDown() then
    local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
    local xs, ys = { 0, sw / 2, sw }, { 0, sh / 2, sh }
    for i = 1, table.getn(S.order) do
      local o = S.order[i]
      if o ~= m and o.frame:IsVisible() and o.frame:GetLeft() then
        local os = o.frame:GetScale()
        local ol, orr, ot, ob = o.frame:GetLeft() * os, o.frame:GetRight() * os, o.frame:GetTop() * os, o.frame:GetBottom() * os
        table.insert(xs, ol)
        table.insert(xs, orr)
        table.insert(xs, (ol + orr) / 2)
        table.insert(ys, ot)
        table.insert(ys, ob)
        table.insert(ys, (ot + ob) / 2)
      end
    end
    l = snapAxis(l, w, xs, sw / 2)
    t = -snapAxis(-t, h, (function()
      local n = {}
      for i = 1, table.getn(ys) do n[i] = -ys[i] end
      return n
    end)(), -sh / 2)
  end
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l / s, t / s)
end

local function startDrag(mv)
  local us = UIParent:GetEffectiveScale()
  local cx, cy = GetCursorPosition()
  local fs = mv.frame:GetScale()
  mv.dx = cx / us - mv.frame:GetLeft() * fs
  mv.dy = cy / us - mv.frame:GetTop() * fs
  mv.dragging = true
end

local function stopDrag(mv)
  if not mv.dragging then return end
  mv.dragging = nil
  S.Save(mv)
end

local dragger = CreateFrame("Frame")
dragger:SetScript("OnUpdate", function()
  for i = 1, table.getn(S.order) do
    local mv = S.order[i]
    if mv.dragging then dragUpdate(mv) end
  end
end)

function S.Handle(key, region)
  local mv = S.movers[key]
  if not mv then return end
  region:EnableMouse(1)
  region:RegisterForDrag("LeftButton")
  region:SetScript("OnDragStart", function() startDrag(mv) end)
  region:SetScript("OnDragStop", function() stopDrag(mv) end)
end

function S.SetUnlocked(v)
  S.unlocked = v
  if v and not grid then buildGrid() end
  if grid then
    if v then grid:Show() else grid:Hide() end
  end
  for i = 1, table.getn(S.order) do
    local m = S.order[i]
    if v then m.overlay:Show() else m.overlay:Hide() end
  end
end

function S.Register(key, label, frame, point, x, y, scale)
  if S.movers[key] then return S.movers[key] end
  local m = { key = key, label = label, frame = frame, point = point, x = x, y = y, scale = scale or 1 }
  S.movers[key] = m
  table.insert(S.order, m)
  frame:SetMovable(1)
  local o = CreateFrame("Button", nil, frame)
  o:SetAllPoints(frame)
  o:SetFrameStrata("DIALOG")
  local bg = o:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(0.2, 0.8, 0.45, 0.4)
  bg:SetAllPoints(o)
  m.tag = o:CreateFontString(nil, "OVERLAY")
  m.tag:SetFont(FONT, 12, "OUTLINE")
  m.tag:SetPoint("CENTER", o, "CENTER", 0, 0)
  m.tag:SetText(label .. "  " .. string.format("%d%%", S.Scale(m) * 100))
  o.mover = m
  o:RegisterForDrag("LeftButton")
  o:SetScript("OnDragStart", function() startDrag(this.mover) end)
  o:SetScript("OnDragStop", function() stopDrag(this.mover) end)
  o:EnableMouseWheel(1)
  o:SetScript("OnMouseWheel", function()
    S.SetScale(this.mover, S.Scale(this.mover) + arg1 * 0.05)
  end)
  if not S.unlocked then o:Hide() end
  m.overlay = o
  S.Apply(m)
  return m
end
