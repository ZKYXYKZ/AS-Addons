local VERSION = 1
if SurvivorsHub and SurvivorsHub.version >= VERSION then return end

local H = SurvivorsHub or {}
SurvivorsHub = H
H.version = VERSION
H.tabs = H.tabs or {}
H.FONT = "Fonts\\ARIALN.TTF"

function H.Text(parent, size, justify, layer)
  local fs = parent:CreateFontString(nil, layer or "OVERLAY")
  fs:SetFont(H.FONT, size, "OUTLINE")
  fs:SetJustifyH(justify or "LEFT")
  fs:SetTextColor(1, 1, 1)
  return fs
end

function H.Fill(parent, layer, r, g, b, a)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  t:SetTexture(r, g, b, a or 1)
  return t
end

function H.Button(parent, caption, w, h, fn)
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(w)
  b:SetHeight(h)
  b.bg = H.Fill(b, "BACKGROUND", 1, 1, 1, 0.1)
  b.bg:SetAllPoints(b)
  b.text = H.Text(b, 12, "CENTER")
  b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
  b.text:SetText(caption)
  b.SetActive = function(self, on)
    self.active = on
    if on then self.bg:SetTexture(0.85, 0.65, 0.2, 0.45) else self.bg:SetTexture(1, 1, 1, 0.1) end
  end
  b:SetScript("OnEnter", function()
    if not this.active then this.bg:SetTexture(1, 1, 1, 0.22) end
    if this.tip then
      GameTooltip:SetOwner(this, "ANCHOR_TOP")
      GameTooltip:SetText(this.tip, 1, 1, 1, 1, 1)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function()
    if not this.active then this.bg:SetTexture(1, 1, 1, 0.1) end
    GameTooltip:Hide()
  end)
  b:SetScript("OnClick", fn)
  return b
end

function H.Icon(parent, size)
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(size)
  b:SetHeight(size)
  b.border = H.Fill(b, "BACKGROUND", 0, 0, 0, 1)
  b.border:SetAllPoints(b)
  b.icon = b:CreateTexture(nil, "BORDER")
  b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
  b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
  b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  b.SetBorder = function(self, r, g, bl, a) self.border:SetTexture(r, g, bl, a or 1) end
  b.SetIcon = function(self, name) self.icon:SetTexture("Interface\\Icons\\" .. name) end
  return b
end

local function build()
  local f = CreateFrame("Frame", "SurvivorsHubFrame", UIParent)
  f:SetWidth(1000)
  f:SetHeight(620)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(1)
  f:EnableMouse(1)
  f:SetClampedToScreen(1)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() this:StartMoving() end)
  f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  local bg = H.Fill(f, "BACKGROUND", 0.05, 0.05, 0.06, 0.95)
  bg:SetAllPoints(f)
  local line = H.Fill(f, "BORDER", 1, 1, 1, 0.08)
  line:SetHeight(1)
  line:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -40)
  line:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -40)
  local title = H.Text(f, 15, "LEFT")
  title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -13)
  title:SetText("Survivors")
  local close = H.Button(f, "x", 22, 22, function() f:Hide() end)
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -9, -9)
  f.content = CreateFrame("Frame", nil, f)
  f.content:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -50)
  f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 12)
  f.buttons = {}
  f:Hide()
  table.insert(UISpecialFrames, "SurvivorsHubFrame")
  H.frame = f
  return f
end

local function layout()
  local f = H.frame or build()
  table.sort(H.tabs, function(a, b) return a.order < b.order end)
  local x = 110
  for i = 1, table.getn(H.tabs) do
    local t = H.tabs[i]
    if not t.button then
      t.button = H.Button(f, t.label, 100, 24, function() H.Show(this.tabId) end)
      t.button.tabId = t.id
    end
    t.button:ClearAllPoints()
    t.button:SetPoint("TOPLEFT", f, "TOPLEFT", x, -8)
    x = x + 104
  end
end

function H.RegisterTab(id, label, order, builder)
  for i = 1, table.getn(H.tabs) do
    if H.tabs[i].id == id then return end
  end
  table.insert(H.tabs, { id = id, label = label, order = order or 50, builder = builder })
  layout()
end

function H.Show(id)
  local f = H.frame or build()
  id = id or H.current or (H.tabs[1] and H.tabs[1].id)
  for i = 1, table.getn(H.tabs) do
    local t = H.tabs[i]
    if t.id == id then
      if not t.panel then
        t.panel = CreateFrame("Frame", nil, f.content)
        t.panel:SetAllPoints(f.content)
        t.builder(t.panel)
      end
      t.panel:Show()
      if t.panel.Refresh then t.panel:Refresh() end
      t.button:SetActive(true)
    else
      if t.panel then t.panel:Hide() end
      if t.button then t.button:SetActive(false) end
    end
  end
  H.current = id
  f:Show()
end

function H.Toggle(id)
  local f = H.frame
  if f and f:IsShown() and (not id or id == H.current) then
    f:Hide()
  else
    H.Show(id)
  end
end

function H.MinimapButton()
  if H.mm or not Minimap then return end
  local b = CreateFrame("Button", "SurvivorsHubMinimapButton", Minimap)
  b:SetWidth(24)
  b:SetHeight(24)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(Minimap:GetFrameLevel() + 6)
  local bg = H.Fill(b, "BACKGROUND", 0, 0, 0, 0.8)
  bg:SetAllPoints(b)
  local border = H.Fill(b, "BORDER", 0.85, 0.65, 0.2, 0.9)
  border:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
  border:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
  local inner = H.Fill(b, "ARTWORK", 0.06, 0.06, 0.07, 1)
  inner:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
  inner:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
  local txt = H.Text(b, 12, "CENTER")
  txt:SetPoint("CENTER", b, "CENTER", 0, 0)
  txt:SetText("S")
  txt:SetTextColor(0.95, 0.75, 0.3)
  b:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 3, 3)
  b:SetScript("OnClick", function() H.Toggle() end)
  b:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("Survivors", 1, 1, 1)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  H.mm = b
end

if not H.driver then
  H.driver = CreateFrame("Frame")
  H.driver:RegisterEvent("PLAYER_ENTERING_WORLD")
  H.driver:SetScript("OnEvent", function() SurvivorsHub.MinimapButton() end)
end

SLASH_SURVIVORSHUB1 = "/survivors"
SLASH_SURVIVORSHUB2 = "/sv"
SlashCmdList["SURVIVORSHUB"] = function() SurvivorsHub.Toggle() end
