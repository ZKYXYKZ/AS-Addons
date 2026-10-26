AZBotDB = { log = {} }
local function log(m) local l = AZBotDB.log table.insert(l, string.format("%.1f %s", GetTime(), m)) if table.getn(l) > 800 then table.remove(l, 1) end end

local px = CreateFrame("Frame", nil, UIParent)
px:SetFrameStrata("TOOLTIP")
px:SetWidth(10)
px:SetHeight(10)
px:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
px.t = px:CreateTexture(nil, "OVERLAY")
px.t:SetAllPoints(px)
local mask = -1
local function setMask(m)
  if m == mask then return end
  mask = m
  px.t:SetTexture((math.mod(m, 16) * 16 + 8) / 255, 1, (math.floor(m / 16) * 16 + 8) / 255, 1)
end
setMask(0)

local FWD, LEFT, RIGHT = 32, 64, 128
local arrow, arrowTried = nil, false
local function findArrow()
  arrowTried = true
  local kids = { Minimap:GetChildren() }
  for i = 1, table.getn(kids) do
    local c = kids[i]
    local m = c.GetModel and c:GetModel()
    local fc = c.GetFacing and c:GetFacing()
    log("minimap child " .. i .. " " .. tostring(c.GetObjectType and c:GetObjectType()) .. " model " .. tostring(m) .. " facing " .. tostring(fc))
    if type(m) == "string" and string.find(string.lower(m), "minimaparrow") and type(fc) == "number" then arrow = c end
  end
  log("arrow " .. tostring(arrow ~= nil))
end
local turnSign = 1
local hist = {}
local function pos()
  if SetMapToCurrentZone then SetMapToCurrentZone() end
  local x, y = GetPlayerMapPosition("player")
  return x or 0, y or 0
end

local reached, target, kind = {}, nil, nil
local function pickTarget(x, y)
  local best, bd, k
  local run = AZS_RUN or {}
  local afford = (tonumber(run.gold) or 0) >= (tonumber(run.chest) or 0)
  for i = 1, (afford and table.getn(AZS_CHESTS or {}) or 0) do
    local c = AZS_CHESTS[i]
    if c.mx and c.mx >= 0 then
      local d = (c.mx - x) ^ 2 + (c.my - y) ^ 2
      if not bd or d < bd then best, bd, k = c, d, "chest" end
    end
  end
  if not best then
    for i = 1, table.getn(AZS_LAIRS or {}) do
      local l = AZS_LAIRS[i]
      if l.mx and l.mx >= 0 and (l.state == "asleep" or l.state == "awake") then
        local d = (l.mx - x) ^ 2 + (l.my - y) ^ 2
        if not bd or d < bd then best, bd, k = l, d, "lair" end
      end
    end
  end
  return best, k
end

local acc, lastErr, lastTurn, stuckT, wander = 0, nil, nil, 0, 0
local route, step = {}, 1
local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function()
  acc = acc + arg1
  if acc < 0.1 then return end
  local dt = acc
  acc = 0
  if not AZS_GetPhase or AZS_GetPhase() ~= "playing" then setMask(0) hist = {} return end
  local now = GetTime()
  local x, y = pos()
  table.insert(hist, { now, x, y })
  while table.getn(hist) > 1 and now - hist[1][1] > 0.6 do table.remove(hist, 1) end
  local t, k = pickTarget(x, y)
  if t ~= target then target, kind = t, k if t then log(string.format("target %s %.3f %.3f from %.3f %.3f", k, t.mx, t.my, x, y)) end end
  local tx, ty
  if t then tx, ty = t.mx, t.my else
    local L = {}
    for i = 1, table.getn(AZS_LAIRS or {}) do local l = AZS_LAIRS[i] if l.mx and l.mx >= 0 then table.insert(L, { l.mx, l.my }) end end
    local cx, cy = x, y
    if table.getn(L) >= 4 then
      local function far(i) local bi, bd = i, -1 for j = 1, table.getn(L) do local d = (L[j][1] - L[i][1]) ^ 2 + (L[j][2] - L[i][2]) ^ 2 if d > bd then bi, bd = j, d end end return bi end
      local a1, b1 = 1, far(1)
      local a2 = 1
      for j = 2, table.getn(L) do if j ~= b1 then a2 = j break end end
      local b2 = far(a2)
      local x1, y1, x2, y2, x3, y3, x4, y4 = L[a1][1], L[a1][2], L[b1][1], L[b1][2], L[a2][1], L[a2][2], L[b2][1], L[b2][2]
      local den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
      if math.abs(den) > 1e-9 then
        local u = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / den
        cx, cy = x1 + u * (x2 - x1), y1 + u * (y2 - y1)
      end
      route = { { cx, cy }, L[a1], { cx, cy }, L[b1], { cx, cy }, L[a2], { cx, cy }, L[b2] }
    elseif table.getn(L) > 0 then
      for j = 1, table.getn(L) do cx, cy = cx + L[j][1], cy + L[j][2] end
      cx, cy = (cx - x) / table.getn(L), (cy - y) / table.getn(L)
      route = { { cx, cy } }
    else
      route = { { x, y } }
    end
    if step > table.getn(route) then step = 1 end
    local w = route[step]
    if (w[1] - x) ^ 2 + (w[2] - y) ^ 2 < 0.003 ^ 2 then step = step + 1 if step > table.getn(route) then step = 1 end w = route[step] end
    tx, ty = w[1], w[2]
  end
  local dx, dy = tx - x, ty - y
  local dist = math.sqrt(dx * dx + dy * dy)
  if t and kind == "lair" and dist < 0.006 then
    setMask(FWD + LEFT)
    return
  end
  if not arrowTried then findArrow() end
  local h = hist[1]
  local hx, hy = x - h[2], y - h[3]
  local realMoved = math.sqrt(hx * hx + hy * hy)
  local moved = realMoved
  if arrow then
    local fa = arrow:GetFacing()
    hx, hy, moved = -math.sin(fa), -math.cos(fa), 1
  end
  if realMoved < 0.0003 then
    stuckT = stuckT + dt
    if stuckT > 2 then setMask(FWD + LEFT) if stuckT > 2.8 then stuckT = 0 end return end
    if not arrow then setMask(FWD) return end
  else
    stuckT = 0
  end
  local cross = (hx * dy - hy * dx) / (moved * math.max(dist, 1e-6))
  local dot = (hx * dx + hy * dy) / (moved * math.max(dist, 1e-6))
  local err = math.atan2(cross, dot)
  if not arrow and lastTurn and lastErr and math.abs(err) > math.abs(lastErr) + 0.35 and math.abs(lastErr) > 0.5 then
    turnSign = -turnSign
    log("turn sign " .. turnSign)
  end
  local m = FWD
  if math.abs(err) > 1.05 and arrow then m = 0 end
  if err > 0.15 then m = m + (turnSign > 0 and RIGHT or LEFT) lastTurn = true
  elseif err < -0.15 then m = m + (turnSign > 0 and LEFT or RIGHT) lastTurn = true
  else lastTurn = nil end
  lastErr = err
  setMask(m)
end)
