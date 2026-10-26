local S = SurvivorsUI
local FONT = "Fonts\\ARIALN.TTF"
local WIDTH = 300
local ROW = 24
local CAM_MIN, CAM_MAX, CAM_STEP = 1, 6, 0.5

local function label(parent, size, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(FONT, size, "OUTLINE")
  fs:SetJustifyH(justify or "LEFT")
  fs:SetTextColor(1, 1, 1)
  return fs
end

local function button(parent, caption, w, h, fn)
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(w)
  b:SetHeight(h)
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetTexture(1, 1, 1, 0.12)
  b.bg:SetAllPoints(b)
  b.text = label(b, 12, "CENTER")
  b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
  b.text:SetText(caption)
  b:SetScript("OnEnter", function() this.bg:SetTexture(1, 1, 1, 0.28) end)
  b:SetScript("OnLeave", function() this.bg:SetTexture(1, 1, 1, 0.12) end)
  b:SetScript("OnClick", fn)
  return b
end

function S.ApplyCamera()
  local v = S.DB().camera
  if not v then return end
  SetCVar("cameraDistanceMaxFactor", v)
  SetCVar("cameraDistanceMax", v * 15)
end

local panel, camText, lockButton
local scaleTexts = {}

local function refresh()
  for i = 1, table.getn(S.order) do
    local m = S.order[i]
    if scaleTexts[m.key] then scaleTexts[m.key]:SetText(string.format("%d%%", S.Scale(m) * 100)) end
  end
  local cam = S.DB().camera or tonumber(GetCVar("cameraDistanceMaxFactor")) or 1
  camText:SetText(string.format("%d yd", cam * 15))
  lockButton.text:SetText(S.unlocked and "Lock frames" or "Unlock frames")
end

local lockBar

local function showLockBar()
  if not lockBar then
    lockBar = CreateFrame("Frame", "SurvivorsUILockBar", UIParent)
    lockBar:SetWidth(300)
    lockBar:SetHeight(36)
    lockBar:SetFrameStrata("FULLSCREEN_DIALOG")
    lockBar:SetPoint("TOP", UIParent, "TOP", 0, -90)
    local bg = lockBar:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(0.04, 0.04, 0.05, 0.95)
    bg:SetAllPoints(lockBar)
    local lock = button(lockBar, "Lock frames", 140, 24, function()
      S.SetUnlocked(false)
      lockBar:Hide()
      if SurvivorsHub then SurvivorsHub.Show("ui") end
    end)
    lock:SetPoint("LEFT", lockBar, "LEFT", 6, 0)
    local resetAll = button(lockBar, "Reset all", 140, 24, function()
      for i = 1, table.getn(S.order) do S.Reset(S.order[i]) end
    end)
    resetAll:SetPoint("RIGHT", lockBar, "RIGHT", -6, 0)
  end
  lockBar:Show()
end

local function build(parent)
  if parent then
    panel = CreateFrame("Frame", nil, parent)
    panel:SetWidth(WIDTH + 60)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  else
    panel = CreateFrame("Frame", "SurvivorsUISettings", UIParent)
    panel:SetWidth(WIDTH)
    panel:SetFrameStrata("DIALOG")
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    panel:SetMovable(1)
    panel:EnableMouse(1)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function() this:StartMoving() end)
    panel:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(0.04, 0.04, 0.05, 0.92)
    bg:SetAllPoints(panel)
    local title = label(panel, 14, "LEFT")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -10)
    title:SetText("SurvivorsUI")
    local close = button(panel, "x", 20, 20, function() panel:Hide() end)
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -7)
  end
  local y = parent and -4 or -40
  local head = label(panel, 11, "LEFT")
  head:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, y)
  head:SetTextColor(0.6, 0.6, 0.6)
  head:SetText("Size")
  y = y - 18
  for i = 1, table.getn(S.order) do
    local m = S.order[i]
    local name = label(panel, 12, "LEFT")
    name:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, y - 4)
    name:SetText(m.label)
    local reset = button(panel, "reset", 44, 20, function() S.Reset(this.mover) refresh() end)
    reset.mover = m
    reset:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, y)
    local plus = button(panel, "+", 22, 20, function() S.SetScale(this.mover, S.Scale(this.mover) + 0.05) refresh() end)
    plus.mover = m
    plus:SetPoint("RIGHT", reset, "LEFT", -6, 0)
    local value = label(panel, 12, "CENTER")
    value:SetWidth(44)
    value:SetPoint("RIGHT", plus, "LEFT", -2, 0)
    scaleTexts[m.key] = value
    local minus = button(panel, "-", 22, 20, function() S.SetScale(this.mover, S.Scale(this.mover) - 0.05) refresh() end)
    minus.mover = m
    minus:SetPoint("RIGHT", value, "LEFT", -2, 0)
    y = y - ROW
  end

  y = y - 10
  local camHead = label(panel, 11, "LEFT")
  camHead:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, y)
  camHead:SetTextColor(0.6, 0.6, 0.6)
  camHead:SetText("Camera")
  y = y - 18
  local camName = label(panel, 12, "LEFT")
  camName:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, y - 4)
  camName:SetText("Max zoom out")
  local function camStep(d)
    local db = S.DB()
    local v = (db.camera or tonumber(GetCVar("cameraDistanceMaxFactor")) or 1) + d
    if v < CAM_MIN then v = CAM_MIN end
    if v > CAM_MAX then v = CAM_MAX end
    db.camera = v
    S.ApplyCamera()
    refresh()
  end
  local camPlus = button(panel, "+", 22, 20, function() camStep(CAM_STEP) end)
  camPlus:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -62, y)
  camText = label(panel, 12, "CENTER")
  camText:SetWidth(44)
  camText:SetPoint("RIGHT", camPlus, "LEFT", -2, 0)
  local camMinus = button(panel, "-", 22, 20, function() camStep(-CAM_STEP) end)
  camMinus:SetPoint("RIGHT", camText, "LEFT", -2, 0)
  y = y - ROW

  y = y - 12
  lockButton = button(panel, "Unlock frames", 136, 24, function()
    S.SetUnlocked(not S.unlocked)
    refresh()
    if parent and S.unlocked then
      SurvivorsHub.frame:Hide()
      showLockBar()
    end
  end)
  lockButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, y)
  local resetAll = button(panel, "Reset all", 128, 24, function()
    for i = 1, table.getn(S.order) do S.Reset(S.order[i]) end
    refresh()
  end)
  resetAll:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, y)
  y = y - 32
  local hint = label(panel, 11, "LEFT")
  hint:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, y)
  hint:SetTextColor(0.6, 0.6, 0.6)
  hint:SetText("Unlocked: drag to move, wheel to resize, Shift = no snap.")
  y = y - 22
  panel:SetHeight(-y)
  if parent then return end
  panel:Hide()
  panel:SetScript("OnHide", function()
    if S.unlocked then S.SetUnlocked(false) end
  end)
end

function S.ToggleSettings()
  if SurvivorsHub then
    SurvivorsHub.Toggle("ui")
    return
  end
  if not panel then build() end
  if panel:IsShown() then
    panel:Hide()
  else
    refresh()
    panel:Show()
  end
end

function S.BuildMinimapButton()
  if SurvivorsHub then
    SurvivorsHub.MinimapButton()
    return
  end
  local b = button(Minimap, "UI", 22, 16, function() S.ToggleSettings() end)
  b:SetFrameLevel(Minimap:GetFrameLevel() + 5)
  b.bg:SetTexture(0, 0, 0, 0.7)
  b:SetScript("OnEnter", function() this.bg:SetTexture(0.25, 0.25, 0.25, 0.9) end)
  b:SetScript("OnLeave", function() this.bg:SetTexture(0, 0, 0, 0.7) end)
  b.text:SetFont(FONT, 10, "OUTLINE")
  b:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -3, 3)
end

if SurvivorsHub then
  SurvivorsHub.RegisterTab("ui", "Interface", 20, function(p)
    build(p)
    p.Refresh = refresh
  end)
end

SLASH_SURVIVORSUI1 = "/sui"
SLASH_SURVIVORSUI2 = "/survivorsui"
SlashCmdList["SURVIVORSUI"] = function() S.ToggleSettings() end
