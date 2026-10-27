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
local orbitA, escape, escapeSide = 0, nil, 1
local BACK = 2
local aimX, aimY
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
    cx, cy = 0, 0
    for j = 1, table.getn(L) do cx, cy = cx + L[j][1], cy + L[j][2] end
    cx, cy = cx / table.getn(L), cy / table.getn(L)
    route = { { cx, cy } }
  else
    route = { { x, y } }
  end
  local bossUp = AZS_GetBosses and table.getn(AZS_GetBosses() or {}) > 0
  local t, k = nil, nil
  if not bossUp then t, k = pickTarget(x, y) end
  if t ~= target then target, kind = t, k if t then log(string.format("target %s %.3f %.3f from %.3f %.3f", k, t.mx, t.my, x, y)) end end
  local tx, ty
  orbitA = orbitA + dt * 0.9
  if bossUp then
    kind = "boss"
    tx, ty = cx + 0.004 * math.cos(orbitA), cy + 0.004 * math.sin(orbitA)
  elseif t and kind == "lair" and (t.mx - x) ^ 2 + (t.my - y) ^ 2 < 0.008 ^ 2 then
    tx, ty = t.mx + 0.004 * math.cos(orbitA), t.my + 0.004 * math.sin(orbitA)
  elseif t then
    tx, ty = t.mx, t.my
  else
    local soon
    for i = 1, table.getn(AZS_LAIRS or {}) do
      local l = AZS_LAIRS[i]
      local left = tonumber(l.left) or -1
      if l.mx and l.mx >= 0 and l.state == "empty" and left >= 0 and left <= 3 then soon = l end
    end
    if soon then
      tx, ty = soon.mx, soon.my
    else
      tx, ty = cx, cy
      if (cx - x) ^ 2 + (cy - y) ^ 2 < 0.0015 ^ 2 then setMask(0) aimX, aimY = cx, cy return end
    end
  end
  aimX, aimY = tx, ty
  local dx, dy = tx - x, ty - y
  local dist = math.sqrt(dx * dx + dy * dy)
  if not arrowTried then findArrow() end
  local h = hist[1]
  local hx, hy = x - h[2], y - h[3]
  local realMoved = math.sqrt(hx * hx + hy * hy)
  local fa = arrow and arrow:GetFacing()
  if escape then
    local e = escape
    if now < e.backUntil then setMask(BACK) return end
    if now < e.turnUntil and fa then
      local d = math.mod(e.face - fa + 3 * math.pi, 2 * math.pi) - math.pi
      if math.abs(d) > 0.2 then setMask(d > 0 and LEFT or RIGHT) return end
      e.turnUntil = 0
    end
    if now < e.fwdUntil then setMask(FWD) return end
    escape = nil
  end
  if mask ~= 0 and math.mod(mask, 64) >= 32 and realMoved < 0.0002 and now - (hist[1][1] or now) > 0.5 then
    stuckT = stuckT + dt
    if stuckT > 1 then
      stuckT = 0
      escapeSide = -escapeSide
      escape = { backUntil = now + 0.5, turnUntil = now + 1.7, fwdUntil = now + 2.7, face = (fa or 0) + escapeSide * math.pi / 2 }
      log("obstacle, escape " .. escapeSide)
      return
    end
  else
    stuckT = 0
  end
  local moved = realMoved
  if fa then hx, hy, moved = -math.sin(fa), -math.cos(fa), 1 end
  if moved < 1e-6 then setMask(FWD) return end
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

local R = CreateFrame("Frame", "AZBotRadar", UIParent)
R:SetWidth(180)
R:SetHeight(180)
R:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 140)
R:SetFrameStrata("HIGH")
R.bg = R:CreateTexture(nil, "BACKGROUND")
R.bg:SetAllPoints(R)
R.bg:SetTexture(0, 0, 0, 0.55)
R.dots = {}
local used = 0
local function dot(px, py, r, g, b, size)
  used = used + 1
  local d = R.dots[used]
  if not d then
    d = R:CreateTexture(nil, "OVERLAY")
    R.dots[used] = d
  end
  d:SetTexture(r, g, b, 1)
  d:SetWidth(size)
  d:SetHeight(size)
  d:ClearAllPoints()
  d:SetPoint("CENTER", R, "TOPLEFT", px, -py)
  d:Show()
end
local box = nil
local function toR(mx, my)
  return 10 + (mx - box[1]) / (box[3] - box[1]) * 160, 10 + (my - box[2]) / (box[4] - box[2]) * 160
end
local function line(ax, ay, bx, by, r, g, b)
  local x1, y1 = toR(ax, ay)
  local x2, y2 = toR(bx, by)
  local n = math.max(2, math.floor(math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) / 5))
  for i = 0, n do dot(x1 + (x2 - x1) * i / n, y1 + (y2 - y1) * i / n, r, g, b, 2) end
end
local racc = 0
R:SetScript("OnUpdate", function()
  racc = racc + arg1
  if racc < 0.2 then return end
  racc = 0
  used = 0
  local L = AZS_LAIRS or {}
  if table.getn(L) == 0 then for i = 1, table.getn(R.dots) do R.dots[i]:Hide() end return end
  local x, y = pos()
  local x0, y0, x1, y1 = x, y, x, y
  for i = 1, table.getn(L) do if L[i].mx and L[i].mx >= 0 then x0, y0, x1, y1 = math.min(x0, L[i].mx), math.min(y0, L[i].my), math.max(x1, L[i].mx), math.max(y1, L[i].my) end end
  local pad = math.max(x1 - x0, y1 - y0) * 0.15 + 0.002
  local side = math.max(x1 - x0, y1 - y0) + 2 * pad
  local cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
  box = { cx - side / 2, cy - side / 2, cx + side / 2, cy + side / 2 }
  if table.getn(route) >= 8 then
    line(route[2][1], route[2][2], route[4][1], route[4][2], 0.9, 0.8, 0.2)
    line(route[6][1], route[6][2], route[8][1], route[8][2], 0.9, 0.8, 0.2)
  end
  for i = 1, table.getn(L) do
    local l = L[i]
    if l.mx and l.mx >= 0 then
      local px, py = toR(l.mx, l.my)
      if l.state == "empty" then dot(px, py, 0.5, 0.5, 0.5, 8) else dot(px, py, 0.9, 0.2, 0.2, 9) end
    end
  end
  for i = 1, table.getn(AZS_CHESTS or {}) do
    local c = AZS_CHESTS[i]
    if c.mx and c.mx >= 0 then local px, py = toR(c.mx, c.my) dot(px, py, 1, 0.82, 0.2, 6) end
  end
  if aimX then
    if kind == "chest" then line(x, y, aimX, aimY, 0.3, 1, 0.3) else line(x, y, aimX, aimY, 0.3, 0.6, 1) end
  end
  local px, py = toR(x, y)
  dot(px, py, 1, 1, 1, 7)
  for i = used + 1, table.getn(R.dots) do R.dots[i]:Hide() end
end)

local sampAcc, runKey = 0, nil
local sampler = CreateFrame("Frame")
sampler:SetScript("OnUpdate", function()
  sampAcc = sampAcc + arg1
  if sampAcc < 5 then return end
  sampAcc = 0
  if not AZS_GetPhase or AZS_GetPhase() ~= "playing" then if AZS_GetPhase and AZS_GetPhase() == "ready" then runKey = nil end return end
  AZBotDB.runs = AZBotDB.runs or {}
  if not runKey then
    runKey = tostring(time())
    AZBotDB.runs[runKey] = { class = AZS_ZONE and AZS_ZONE.class, race = AZS_ZONE and AZS_ZONE.race, zone = AZS_ZONE and AZS_ZONE.zone, samples = {} }
    local n, oldest = 0, nil
    for k in pairs(AZBotDB.runs) do n = n + 1 if not oldest or k < oldest then oldest = k end end
    if n > 40 then AZBotDB.runs[oldest] = nil end
  end
  local sp = {}
  for i = 1, table.getn(AZS_SPELLS or {}) do local s = AZS_SPELLS[i] table.insert(sp, (s.key or "?") .. ":" .. (s.rank or 0) .. ":" .. (s.cdmax or 0)) end
  local st = {}
  for _, k in ipairs({ "dmg", "cd", "crit", "cm", "area", "cnt", "echo", "luck", "hp", "arm", "pet", "dots", "dotd", "spd", "reg", "lch", "heal", "thn", "shd", "liv", "gdmg", "gcrit", "ghp", "garm", "gcd", "gcm", "garea", "gecho", "gspd" }) do if AZS_STATS and AZS_STATS[k] then table.insert(st, k .. "=" .. AZS_STATS[k]) end end
  local m = {}
  if AZS_GetMeter then local lines = AZS_GetMeter() for i = 1, math.min(table.getn(lines or {}), 20) do local l = lines[i] table.insert(m, l.name .. "=" .. math.floor(tonumber(l.dmg) or 0)) end end
  local r = AZS_RUN or {}
  local hl = {}
  if AZS_GetHealing then local lines = AZS_GetHealing() for i = 1, math.min(table.getn(lines or {}), 10) do local l = lines[i] table.insert(hl, l.name .. "=" .. math.floor(tonumber(l.dmg) or 0)) end end
  local tk = {}
  for i = 1, table.getn(AZS_TAKEN or {}) do local x = AZS_TAKEN[i] table.insert(tk, (x.source or "?") .. "=" .. math.floor(tonumber(x.dmg) or 0)) end
  table.insert(AZBotDB.runs[runKey].samples, string.format("%d|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s", math.floor(AZS_GetRunTime() or 0), tostring(r.lvl), tostring(r.en), table.concat(sp, ","), table.concat(st, ","), table.concat(m, ";"), tostring(r.kills), tostring(r.hp), tostring(r.hpm), tostring(r.taken), tostring(r.dealt), table.concat(hl, ";"), table.concat(tk, ";"), tostring(r.xp), tostring(r.xpn), tostring(r.el), tostring(r.gold)))
end)
