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
    if c.mx and c.mx >= 0 and not reached["c" .. c.id] then
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
  if t then tx, ty = t.mx, t.my else wander = wander + dt * 0.15 tx, ty = 0.5 + 0.2 * math.cos(wander), 0.5 + 0.2 * math.sin(wander) end
  local dx, dy = tx - x, ty - y
  local dist = math.sqrt(dx * dx + dy * dy)
  if t and kind == "chest" and dist < 0.0025 then reached["c" .. t.id] = true log("chest reached " .. t.id) end
  if t and kind == "lair" and dist < 0.006 then
    local a = math.atan2(dy, dx) + 1.7
    dx, dy = math.cos(a), math.sin(a)
  end
  local h = hist[1]
  local hx, hy = x - h[2], y - h[3]
  local moved = math.sqrt(hx * hx + hy * hy)
  if moved < 0.0003 then
    stuckT = stuckT + dt
    if stuckT > 2 then setMask(FWD + LEFT) if stuckT > 2.8 then stuckT = 0 end return end
    setMask(FWD)
    return
  end
  stuckT = 0
  local cross = (hx * dy - hy * dx) / (moved * math.max(dist, 1e-6))
  local dot = (hx * dx + hy * dy) / (moved * math.max(dist, 1e-6))
  local err = math.atan2(cross, dot)
  if lastTurn and lastErr and math.abs(err) > math.abs(lastErr) + 0.35 and math.abs(lastErr) > 0.5 then
    turnSign = -turnSign
    log("turn sign " .. turnSign)
  end
  local m = FWD
  if err > 0.25 then m = m + (turnSign > 0 and RIGHT or LEFT) lastTurn = true
  elseif err < -0.25 then m = m + (turnSign > 0 and LEFT or RIGHT) lastTurn = true
  else lastTurn = nil end
  lastErr = err
  setMask(m)
end)
