local FONT = "Fonts\\ARIALN.TTF"
local W = 360
local ICON = 34
local GAP = 3
local SLOTS = 12

SURVIVORSUI_SQUARE_MINIMAP = 1

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

local function short(v)
  if v >= 1000000 then return string.format("%.1fm", v / 1000000) end
  if v >= 10000 then return string.format("%.0fk", v / 1000) end
  if v >= 1000 then return string.format("%.1fk", v / 1000) end
  return string.format("%d", v)
end

local function bar(name, parent, w, h)
  local f = CreateFrame("Frame", name, parent)
  f:SetWidth(w)
  f:SetHeight(h)
  local bg = tex(f, "BACKGROUND", 0, 0, 0, 0.7)
  bg:SetAllPoints(f)
  f.fill = tex(f, "BORDER", 1, 1, 1, 1)
  f.fill:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
  f.fill:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
  f.inner = w - 2
  return f
end

local function setBar(f, cur, max)
  local p = 0
  if max and max > 0 then p = cur / max end
  if p > 1 then p = 1 end
  if p <= 0 then
    f.fill:Hide()
  else
    f.fill:SetWidth(f.inner * p)
    f.fill:Show()
  end
  return p
end

local function kill(f)
  if not f then return end
  if f.UnregisterAllEvents then f:UnregisterAllEvents() end
  f:Hide()
  f.Show = function() end
end

local POWER = {
  [0] = { 0.25, 0.45, 0.95 },
  [1] = { 0.85, 0.2, 0.2 },
  [2] = { 1, 0.6, 0.2 },
  [3] = { 1, 0.9, 0.3 },
}

local S = SurvivorsUI
local player, power, target, xp, actions, buttons

local function box(name, w, h)
  local f = CreateFrame("Frame", name, UIParent)
  f:SetWidth(w)
  f:SetHeight(h)
  return f
end

local function buildUnits()
  local actionsBox = box("SurvivorsUIActionsBox", W, ICON + 8)
  xp = bar("SurvivorsUIXP", actionsBox, W, 5)
  xp:SetPoint("BOTTOM", actionsBox, "BOTTOM", 0, 0)
  xp.fill:SetTexture(0.55, 0.3, 0.85, 1)
  actions = CreateFrame("Frame", "SurvivorsUIActions", actionsBox)
  actions:SetWidth(W)
  actions:SetHeight(ICON)
  actions:SetPoint("BOTTOM", xp, "TOP", 0, 3)
  S.Register("actions", "Spells", actionsBox, "BOTTOM", 0, 12)

  local playerBox = box("SurvivorsUIPlayerBox", W, 33)
  power = bar("SurvivorsUIPower", playerBox, W, 6)
  power:SetPoint("BOTTOM", playerBox, "BOTTOM", 0, 0)
  player = bar("SurvivorsUIPlayer", playerBox, W, 26)
  player:SetPoint("BOTTOM", power, "TOP", 0, 1)
  player.left = text(player, 14, "LEFT")
  player.left:SetPoint("LEFT", player, "LEFT", 8, 0)
  player.right = text(player, 14, "RIGHT")
  player.right:SetPoint("RIGHT", player, "RIGHT", -8, 0)
  S.Register("player", "Player", playerBox, "BOTTOM", 0, 57)

  local targetBox = box("SurvivorsUITargetBox", W, 24)
  target = bar("SurvivorsUITarget", targetBox, W, 24)
  target:SetAllPoints(targetBox)
  S.Register("target", "Target", targetBox, "BOTTOM", 0, 100)
  target.left = text(target, 13, "LEFT")
  target.left:SetPoint("LEFT", target, "LEFT", 8, 0)
  target.right = text(target, 13, "RIGHT")
  target.right:SetPoint("RIGHT", target, "RIGHT", -8, 0)
  target:Hide()

  local _, class = UnitClass("player")
  local c = RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class]
  if c then
    player.fill:SetTexture(c.r, c.g, c.b, 1)
  else
    player.fill:SetTexture(0.2, 0.75, 0.3, 1)
  end
end

local function buildActions()
  buttons = {}
  for i = 1, SLOTS do
    local b = CreateFrame("Button", "SurvivorsUIAction" .. i, actions)
    b:SetWidth(ICON)
    b:SetHeight(ICON)
    b.slot = i
    local bg = tex(b, "BACKGROUND", 0, 0, 0, 0.9)
    bg:SetAllPoints(b)
    b.icon = b:CreateTexture(nil, "BORDER")
    b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.cd = tex(b, "ARTWORK", 0, 0, 0, 0.6)
    b.cd:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 1, 1)
    b.cd:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    b.cd:Hide()
    b.time = text(b, 12, "CENTER")
    b.time:SetPoint("CENTER", b, "CENTER", 0, 0)
    b:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_TOP")
      GameTooltip:SetAction(this.slot)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnClick", function() UseAction(this.slot, 0) end)
    b:Hide()
    buttons[i] = b
  end
end

local shownKey = ""

local function layoutActions()
  local list, key = {}, ""
  for i = 1, SLOTS do
    local b = buttons[i]
    local t = HasAction(i) and GetActionTexture(i)
    if t then
      b.icon:SetTexture(t)
      table.insert(list, b)
      key = key .. i .. ","
    else
      b:Hide()
    end
  end
  if key == shownKey then return end
  shownKey = key
  local n = table.getn(list)
  local total = n * ICON + (n - 1) * GAP
  for k = 1, n do
    local b = list[k]
    b:ClearAllPoints()
    b:SetPoint("LEFT", actions, "CENTER", -total / 2 + (k - 1) * (ICON + GAP), 0)
    b:Show()
  end
end

local function updateCooldowns()
  local now = GetTime()
  for i = 1, SLOTS do
    local b = buttons[i]
    if b:IsShown() then
      local start, dur, enable = GetActionCooldown(i)
      local rem = 0
      if start and dur and start > 0 and dur > 1.5 then rem = start + dur - now end
      if rem > 0 then
        b.cd:SetHeight((ICON - 2) * rem / dur)
        b.cd:Show()
        if dur >= 8 and rem >= 3 then
          b.time:SetText(string.format("%d", rem))
        else
          b.time:SetText("")
        end
      else
        b.cd:Hide()
        b.time:SetText("")
      end
    end
  end
end

local function updateUnits()
  local hp, hpMax = UnitHealth("player"), UnitHealthMax("player")
  setBar(player, hp, hpMax)
  player.left:SetText(UnitLevel("player") .. "  " .. (UnitName("player") or ""))
  player.right:SetText(short(hp) .. " / " .. short(hpMax))

  local pc = POWER[UnitPowerType("player") or 0] or POWER[0]
  power.fill:SetTexture(pc[1], pc[2], pc[3], 1)
  setBar(power, UnitMana("player"), UnitManaMax("player"))

  setBar(xp, UnitXP("player"), UnitXPMax("player"))

  if UnitExists("target") and not UnitIsDead("target") then
    local thp, tmax = UnitHealth("target"), UnitHealthMax("target")
    local p = setBar(target, thp, tmax)
    local cls = UnitClassification("target")
    if cls == "worldboss" then
      target.fill:SetTexture(0.75, 0.25, 0.9, 1)
    elseif cls == "elite" or cls == "rareelite" then
      target.fill:SetTexture(0.95, 0.7, 0.15, 1)
    elseif UnitIsFriend("player", "target") then
      target.fill:SetTexture(0.2, 0.75, 0.3, 1)
    else
      target.fill:SetTexture(0.8, 0.2, 0.2, 1)
    end
    target.left:SetText(UnitName("target") or "")
    target.right:SetText(short(thp) .. " / " .. short(tmax) .. "   " .. string.format("%d%%", p * 100))
    target:Show()
  elseif S.unlocked then
    setBar(target, 1, 1)
    target.fill:SetTexture(0.8, 0.2, 0.2, 1)
    target.left:SetText("Target")
    target.right:SetText("")
    target:Show()
  else
    target:Hide()
  end
end

local function buildMicro()
  local holder = CreateFrame("Frame", "SurvivorsUIMicro", UIParent)
  holder:SetWidth(170)
  holder:SetHeight(40)
  S.Register("micro", "Menu", holder, "BOTTOM", 340, 12, 0.8)
  local names = { "CharacterMicroButton", "TalentMicroButton", "WorldMapMicroButton", "MainMenuMicroButton", "HelpMicroButton" }
  for i = 1, table.getn(names) do
    local b = getglobal(names[i])
    if b then b:SetParent(holder) end
  end
  if CharacterMicroButton then
    CharacterMicroButton:ClearAllPoints()
    CharacterMicroButton:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
  end
  if MainMenuBarBackpackButton then
    MainMenuBarBackpackButton:SetParent(holder)
    MainMenuBarBackpackButton:ClearAllPoints()
    MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 2)
  end
  holder:SetAlpha(0.25)
  holder:SetScript("OnUpdate", function()
    if S.unlocked or MouseIsOver(this) then
      this:SetAlpha(1)
    else
      this:SetAlpha(0.25)
    end
  end)
end

local function hideStock()
  kill(PlayerFrame)
  kill(TargetFrame)
  kill(MainMenuBar)
  kill(MultiBarBottomLeft)
  kill(MultiBarBottomRight)
  kill(MultiBarLeft)
  kill(MultiBarRight)
end

local function styleChat()
  for i = 1, 7 do
    local cf = getglobal("ChatFrame" .. i)
    if cf then
      cf:SetFont(FONT, 12)
      cf:SetShadowOffset(1, -1)
      cf:SetFading(1)
      cf:SetTimeVisible(15)
      kill(getglobal("ChatFrame" .. i .. "UpButton"))
      kill(getglobal("ChatFrame" .. i .. "DownButton"))
      kill(getglobal("ChatFrame" .. i .. "BottomButton"))
    end
  end
  kill(ChatFrameMenuButton)
  ChatFrame1:SetWidth(340)
  ChatFrame1:SetHeight(100)
  ChatFrame1:SetUserPlaced(1)
  S.Register("chat", "Chat", ChatFrame1, "BOTTOMLEFT", 14, 14)
  ChatFrameEditBox:ClearAllPoints()
  ChatFrameEditBox:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", -5, 4)
  ChatFrameEditBox:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 5, 4)
  ChatFrame1:EnableMouseWheel(1)
  ChatFrame1:SetScript("OnMouseWheel", function()
    if arg1 > 0 then this:ScrollUp() else this:ScrollDown() end
  end)
  local stock = ChatFrame1.AddMessage
  ChatFrame1.AddMessage = function(self, msg, r, g, b, id)
    if msg and string.find(msg, "^You have gained 0 ") then return end
    stock(self, msg, r, g, b, id)
  end
end

local function styleMinimap()
  local size = 150
  kill(MinimapBorder)
  kill(MinimapBorderTop)
  kill(MinimapToggleButton)
  kill(MinimapZoomIn)
  kill(MinimapZoomOut)
  kill(GameTimeFrame)
  kill(MiniMapMailFrame)
  kill(MiniMapTrackingFrame)
  kill(MinimapNorthTag)
  Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8X8")
  Minimap:SetWidth(size)
  Minimap:SetHeight(size)
  S.Register("minimap", "Minimap", Minimap, "TOPRIGHT", -14, -14)
  S.BuildMinimapButton()
  local edge = CreateFrame("Frame", "SurvivorsUIMinimapEdge", Minimap)
  edge:SetFrameLevel(Minimap:GetFrameLevel() + 1)
  edge:SetAllPoints(Minimap)
  local function side(p1, p2, w, h)
    local t = tex(edge, "OVERLAY", 0, 0, 0, 0.9)
    t:SetPoint(p1, Minimap, p1, 0, 0)
    t:SetPoint(p2, Minimap, p2, 0, 0)
    if w then t:SetWidth(w) end
    if h then t:SetHeight(h) end
  end
  side("TOPLEFT", "TOPRIGHT", nil, 1)
  side("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
  side("TOPLEFT", "BOTTOMLEFT", 1, nil)
  side("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
  if MinimapZoneTextButton then
    MinimapZoneTextButton:SetParent(Minimap)
    MinimapZoneTextButton:ClearAllPoints()
    MinimapZoneTextButton:SetPoint("TOP", Minimap, "BOTTOM", 0, -3)
  end
  if MinimapZoneText then
    MinimapZoneText:SetFont(FONT, 11, "OUTLINE")
  end
  Minimap:EnableMouseWheel(1)
  Minimap:SetScript("OnMouseWheel", function()
    local z = Minimap:GetZoom()
    if arg1 > 0 and z < Minimap:GetZoomLevels() - 1 then
      Minimap:SetZoom(z + 1)
    elseif arg1 < 0 and z > 0 then
      Minimap:SetZoom(z - 1)
    end
  end)
end

local function step(name, f)
  local ok, err = pcall(f)
  if not ok and DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("SurvivorsUI " .. name .. ": " .. tostring(err), 1, 0.3, 0.3)
  end
  SurvivorsUIErrors = SurvivorsUIErrors or {}
  if not ok then table.insert(SurvivorsUIErrors, name .. ": " .. tostring(err)) end
end

local driver = CreateFrame("Frame", "SurvivorsUIDriver", UIParent)
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
local ready, acc = false, 0
driver:SetScript("OnEvent", function()
  if ready then return end
  SurvivorsUIErrors = {}
  step("units", buildUnits)
  step("actions", buildActions)
  step("micro", buildMicro)
  step("stock", hideStock)
  step("chat", styleChat)
  step("minimap", styleMinimap)
  step("camera", function()
    if not S.DB().camera then S.DB().camera = 3 end
    S.ApplyCamera()
  end)
  ready = true
end)
driver:SetScript("OnUpdate", function()
  if not ready then return end
  acc = acc + arg1
  if acc < 0.1 then return end
  acc = 0
  layoutActions()
  updateCooldowns()
  updateUnits()
end)
