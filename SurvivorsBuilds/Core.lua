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
