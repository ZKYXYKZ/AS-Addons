SB = {}
BINDING_HEADER_SURVIVORS = "Survivors"
BINDING_NAME_SURVIVORS_HUB = "Survivors"
BINDING_NAME_SURVIVORS_BUILDS = "Survivors : Builds"

local CLASSES = {
  warrior = { "Warrior", "Guerrier" }, paladin = { "Paladin", "Paladin" }, hunter = { "Hunter", "Chasseur" },
  rogue = { "Rogue", "Voleur" }, priest = { "Priest", "Prêtre" }, shaman = { "Shaman", "Chaman" },
  mage = { "Mage", "Mage" }, warlock = { "Warlock", "Démoniste" }, druid = { "Druid", "Druide" },
}

function SB.DB()
  SurvivorsBuildsDB = SurvivorsBuildsDB or {}
  return SurvivorsBuildsDB
end

function SB.Link()
  return SB.DB().link
end

function SB.Lang()
  local l = SB.Link() and SB.Link().lang
  if l then return l end
  local cname = AZS_ZONE and AZS_ZONE.cname
  for _, n in pairs(CLASSES) do
    if cname == n[2] and n[1] ~= n[2] then return "fr" end
  end
  return "en"
end

function SB.PlayerClass()
  local cls = AZS_ZONE and AZS_ZONE.class
  if cls and CLASSES[cls] then return cls end
  local _, token = UnitClass("player")
  if token and CLASSES[string.lower(token)] then return string.lower(token) end
  return "warrior"
end

function SB.Build()
  if SB.alt then return SB.alt end
  local link = SB.Link()
  return link and link.builds and link.builds[SB.PlayerClass()]
end

function SB.Fresh()
  local link = SB.Link()
  return link and link.launched and time and math.abs(time() - link.launched) < 120
end

function SB.Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffe6b84cBuilds|r " .. msg)
end

local luckFrame = CreateFrame("Frame")
local luckSeen = false
luckFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
luckFrame:RegisterEvent("CHAT_MSG_ADDON")
luckFrame:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    luckSeen = false
    return
  end
  if luckSeen or arg1 ~= "AZS" or not arg2 then return end
  local _, _, v = string.find(arg2, "luck=([%-%d%.]+)")
  if not v then return end
  local db = SB.DB()
  db.luck = db.luck or {}
  db.luck[SB.PlayerClass()] = math.floor(tonumber(v) * 1000 + 0.5) / 10
  luckSeen = true
end)

local logFrame = CreateFrame("Frame")
logFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
logFrame:SetScript("OnEvent", function()
  if SB.Fresh() and LoggingCombat then LoggingCombat(1) end
end)

local SPEC = { fr = "Spé détectée, build « %s »", en = "Spec detected, build \"%s\"" }
local runId, lastPhase, specDone = nil, nil, false

local function detectSpec()
  if specDone or not AZS_SPELLS then return end
  local link = SB.Link()
  local alts = link and link.alts and link.alts[SB.PlayerClass()]
  if not alts or not alts.caps then return end
  if AZS_RUN and (tonumber(AZS_RUN.lvl) or 1) > 1 then
    specDone = true
    return
  end
  for i = 1, table.getn(AZS_SPELLS) do
    local t = AZS_SPELLS[i].key and alts.caps[AZS_SPELLS[i].key]
    if t then
      specDone = true
      local b = alts[t]
      local cur = link.builds and link.builds[SB.PlayerClass()]
      if b and (not cur or cur.name ~= b.name) then
        SB.alt = b
        SB.Print(string.format(SPEC[SB.Lang()] or SPEC.en, b.name))
      end
      return
    end
  end
end

local function encodeRun()
  local lines, total = AZS_GetMeter()
  local m = {}
  lines = lines or {}
  for i = 1, math.min(table.getn(lines), 25) do
    local l = lines[i]
    table.insert(m, (l.name or "?") .. "," .. math.floor(tonumber(l.dmg) or 0) .. "," .. (tonumber(l.proc) or 0))
  end
  local st = {}
  for k, v in pairs(AZS_STATS or {}) do
    if tonumber(v) then table.insert(st, k .. "=" .. v) end
  end
  local r = AZS_RUN or {}
  return "AZR1|" .. ((AZS_ZONE and AZS_ZONE.class) or SB.PlayerClass()) .. "|" .. (tonumber(r.lvl) or 0) .. "|" .. (tonumber(r.kills) or 0) .. "|" .. string.format("%.1f", AZS_GetRunTime() or 0) .. "|" .. math.floor(tonumber(r.dealt) or 0) .. "|" .. math.floor(tonumber(total) or 0) .. "|" .. table.concat(m, ";") .. "|" .. table.concat(st, ";")
end

local function saveRun()
  local db = SB.DB()
  db.runs = db.runs or {}
  db.runs[runId] = encodeRun()
  local n, oldest = 0, nil
  for k in pairs(db.runs) do
    n = n + 1
    if not oldest or k < oldest then oldest = k end
  end
  if n > 30 then db.runs[oldest] = nil end
end

local runFrame = CreateFrame("Frame")
local acc = 0
runFrame:RegisterEvent("CHAT_MSG_ADDON")
runFrame:SetScript("OnEvent", function()
  if arg1 == "AZSSPELLS" then detectSpec() end
end)
runFrame:SetScript("OnUpdate", function()
  acc = acc + arg1
  if acc < 0.5 then return end
  acc = 0
  if not AZS_GetPhase then return end
  local phase = AZS_GetPhase()
  if phase == "ready" or phase == nil then
    runId, specDone, SB.alt = nil, false, nil
  elseif phase == "playing" and not runId then
    runId = time()
    detectSpec()
  end
  if runId and (phase == "dead" or phase == "victory") and phase ~= lastPhase and AZS_GetMeter then
    pcall(saveRun)
  end
  lastPhase = phase
end)
