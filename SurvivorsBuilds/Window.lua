local H = SurvivorsHub
local W = {}
SB.W = W

local L = {
  fr = {
    class = "Classe", build = "Build", new = "Nouveau", dup = "Dupliquer", del = "Supprimer", rename = "Renommer",
    talents = "Talents", spells = "Sorts", jewels = "Bijoux", rules = "Règles", none = "Aucun build",
    spec = "Spé", points = "points", confirm = "Cliquez encore pour supprimer",
  },
  en = {
    class = "Class", build = "Build", new = "New", dup = "Duplicate", del = "Delete", rename = "Rename",
    talents = "Talents", spells = "Spells", jewels = "Jewelry", rules = "Rules", none = "No build",
    spec = "Spec", points = "points", confirm = "Click again to delete",
  },
}
function SB.L(k)
  return (L[SB.Lang()] or L.en)[k] or k
end

local function popup(anchor, items, onPick)
  local p = W.popup
  if not p then
    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN")
    catcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    catcher:SetScript("OnClick", function() W.popup:Hide() end)
    catcher:Hide()
    p = CreateFrame("Frame", nil, UIParent)
    p.catcher = catcher
    p:SetScript("OnShow", function() this.catcher:Show() end)
    p:SetScript("OnHide", function() this.catcher:Hide() end)
    p:Hide()
    p:SetFrameStrata("FULLSCREEN_DIALOG")
    p:EnableMouse(1)
    local bg = H.Fill(p, "BACKGROUND", 0.08, 0.08, 0.09, 0.98)
    bg:SetAllPoints(p)
    p.rows = {}
    W.popup = p
  end
  if p:IsShown() and p.anchor == anchor then
    p:Hide()
    return
  end
  p.anchor = anchor
  for i = 1, table.getn(p.rows) do p.rows[i]:Hide() end
  local w = 200
  for i = 1, table.getn(items) do
    local r = p.rows[i]
    if not r then
      r = H.Button(p, "", w - 8, 20, function()
        W.popup:Hide()
        if this.pick then this.pick(this.value) end
      end)
      r.text:SetJustifyH("LEFT")
      r.text:ClearAllPoints()
      r.text:SetPoint("LEFT", r, "LEFT", 6, 0)
      p.rows[i] = r
    end
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", p, "TOPLEFT", 4, -4 - (i - 1) * 22)
    r.text:SetText(items[i].label)
    if items[i].color then r.text:SetTextColor(items[i].color[1], items[i].color[2], items[i].color[3]) else r.text:SetTextColor(1, 1, 1) end
    r.value = items[i].value
    r.pick = onPick
    r:Show()
  end
  p:SetWidth(w)
  p:SetHeight(table.getn(items) * 22 + 8)
  p:ClearAllPoints()
  p:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
  p:Show()
end
W.Popup = popup

function W.Build()
  return W.classKey and SB.Active(W.classKey)
end

function W.Changed()
  if W.panel and W.panel:IsVisible() then W.Refresh() end
  if SB.Guide and SB.Guide.Refresh then SB.Guide.Refresh() end
end

W.labels = {}
function W.Label(btn, key, fn)
  table.insert(W.labels, { btn = btn, key = key, fn = fn })
  return btn
end

function W.Refresh()
  local p = W.panel
  for i = 1, table.getn(W.labels) do
    local l = W.labels[i]
    if not l.btn.armed then l.btn.text:SetText(l.fn and l.fn(l.key) or SB.L(l.key)) end
  end
  local c = SB.Class(W.classKey)
  local col = SB.CLASS_COLORS[c.key]
  p.classBtn.text:SetText(SB.T(c.name))
  p.classBtn.text:SetTextColor(col[1], col[2], col[3])
  local b = W.Build()
  if b then
    p.buildBtn.text:SetText(b.name)
    local spec, parts = SB.Spec(b)
    p.specText:SetText(string.format("%s : %s   %d/%d/%d   (%d/51)", SB.L("spec"), spec and SB.T(spec.name) or "-", parts[1], parts[2], parts[3], SB.TotalPoints(b)))
  else
    p.buildBtn.text:SetText(SB.L("none"))
    p.specText:SetText("")
  end
  for i = 1, table.getn(W.views) do
    local v = W.views[i]
    if v.id == W.view then
      v.button:SetActive(true)
      if b then
        v.frame:Show()
        v.refresh(v.frame, b)
      else
        v.frame:Hide()
      end
    else
      v.button:SetActive(false)
      v.frame:Hide()
    end
  end
  p.empty:SetText(b and "" or SB.L("none"))
end

W.views = {}
function W.AddView(id, order, builder, refresh)
  table.insert(W.views, { id = id, order = order, builder = builder, refresh = refresh })
end

local function renameBox(p)
  local e = CreateFrame("EditBox", nil, p)
  e:SetWidth(200)
  e:SetHeight(22)
  e:SetFontObject(GameFontHighlight)
  e:SetFont(H.FONT, 12)
  e:SetAutoFocus(1)
  e:SetMaxLetters(40)
  local bg = H.Fill(e, "BACKGROUND", 0, 0, 0, 0.9)
  bg:SetAllPoints(e)
  e:SetTextInsets(6, 6, 0, 0)
  e:SetScript("OnEnterPressed", function()
    local b = W.Build()
    local t = this:GetText()
    if b and t and t ~= "" then b.name = t end
    this:Hide()
    W.Changed()
  end)
  e:SetScript("OnEscapePressed", function() this:Hide() end)
  e:Hide()
  return e
end

function W.Create(p)
  W.panel = p
  W.classKey = W.classKey or SB.PlayerClass()
  W.view = W.view or "talents"
  p.classBtn = H.Button(p, "", 130, 24, function()
    local items = {}
    for i = 1, table.getn(SB_DATA.classes) do
      local c = SB_DATA.classes[i]
      table.insert(items, { label = SB.T(c.name), value = c.key, color = SB.CLASS_COLORS[c.key] })
    end
    popup(this, items, function(v)
      W.classKey = v
      W.Changed()
    end)
  end)
  p.classBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 0, 0)
  p.buildBtn = H.Button(p, "", 200, 24, function()
    local items = {}
    local list = SB.BuildsOf(W.classKey)
    for i = 1, table.getn(list) do table.insert(items, { label = list[i].name, value = list[i].id }) end
    if table.getn(items) == 0 then return end
    popup(this, items, function(v)
      SB.DB().active[W.classKey] = v
      W.Changed()
    end)
  end)
  p.buildBtn:SetPoint("LEFT", p.classBtn, "RIGHT", 6, 0)
  p:SetScript("OnHide", function() if W.popup then W.popup:Hide() end end)
  local new = H.Button(p, SB.L("new"), 80, 24, function()
    SB.NewBuild(W.classKey)
    W.Changed()
  end)
  new:SetPoint("LEFT", p.buildBtn, "RIGHT", 6, 0)
  W.Label(new, "new")
  local dup = H.Button(p, SB.L("dup"), 80, 24, function()
    local b = W.Build()
    if b then SB.Duplicate(b) W.Changed() end
  end)
  dup:SetPoint("LEFT", new, "RIGHT", 4, 0)
  W.Label(dup, "dup")
  p.rename = renameBox(p)
  p.rename:SetPoint("TOPLEFT", p.buildBtn, "TOPLEFT", 0, 0)
  local ren = H.Button(p, SB.L("rename"), 80, 24, function()
    local b = W.Build()
    if not b then return end
    p.rename:SetText(b.name)
    p.rename:Show()
    p.rename:HighlightText()
  end)
  ren:SetPoint("LEFT", dup, "RIGHT", 4, 0)
  W.Label(ren, "rename")
  local del = H.Button(p, SB.L("del"), 80, 24, function()
    local b = W.Build()
    if not b then return end
    if this.armed and this.armed > GetTime() then
      this.armed = nil
      this.text:SetText(SB.L("del"))
      SB.Delete(b)
      W.Changed()
    else
      this.armed = GetTime() + 3
      this.text:SetText("?")
      this.tip = SB.L("confirm")
    end
  end)
  del:SetPoint("LEFT", ren, "RIGHT", 4, 0)
  W.Label(del, "del")
  del:SetScript("OnUpdate", function()
    if this.armed and this.armed < GetTime() then
      this.armed = nil
      this.text:SetText(SB.L("del"))
    end
  end)
  p.specText = H.Text(p, 13, "RIGHT")
  p.specText:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, -6)
  p.specText:SetTextColor(0.85, 0.85, 0.85)
  table.sort(W.views, function(a, b) return a.order < b.order end)
  for i = 1, table.getn(W.views) do
    local v = W.views[i]
    v.button = H.Button(p, SB.L(v.id), 110, 24, function()
      W.view = this.viewId
      W.Refresh()
    end)
    v.button.viewId = v.id
    W.Label(v.button, v.id)
    v.button:SetPoint("TOPLEFT", p, "TOPLEFT", (i - 1) * 114, -32)
    v.frame = CreateFrame("Frame", nil, p)
    v.frame:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -64)
    v.frame:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 0)
    v.builder(v.frame)
  end
  SB.ShareButtons(p)
  p.empty = H.Text(p, 16, "CENTER")
  p.empty:SetPoint("CENTER", p, "CENTER", 0, 0)
  p.empty:SetTextColor(0.6, 0.6, 0.6)
  p.Refresh = function() W.Refresh() end
end

H.RegisterTab("builds", "Builds", 10, function(p) W.Create(p) end)
