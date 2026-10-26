local H = SurvivorsHub
local W = SB.W
local ICON = 38
local DX, DY = 66, 56
local TREE_W = 316

local T = {
  fr = { rank = "Rang", next = "Rang suivant :", pts = "points", locked = "Rangée verrouillée : %d points requis dans cet arbre", reset = "Réinitialiser", left = "Clic gauche : +1 · Clic droit : -1" },
  en = { rank = "Rank", next = "Next rank:", pts = "points", locked = "Row locked: %d points required in this tree", reset = "Reset", left = "Left click: +1 · Right click: -1" },
}
local function tl(k) return (T[SB.Lang()] or T.en)[k] end

local function tooltip(btn)
  local b, tree, t = W.Build(), btn.tree, btn.talent
  local r = b.talents[t.key] or 0
  GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
  GameTooltip:SetText(SB.T(t.name), 1, 0.82, 0.2)
  GameTooltip:AddLine(string.format("%s %d/%d", tl("rank"), r, t.max), 1, 1, 1)
  local desc = SB.T(t.desc)
  GameTooltip:AddLine(SB.Format(desc, t.v and t.v * math.max(r, 1)), 0.9, 0.9, 0.9, 1)
  if r > 0 and r < t.max and t.v then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(tl("next"), 1, 1, 1)
    GameTooltip:AddLine(SB.Format(desc, t.v * (r + 1)), 0.9, 0.9, 0.9, 1)
  end
  if t.row > 0 then
    local below = 0
    for i = 1, table.getn(tree.talents) do
      local o = tree.talents[i]
      if o.row < t.row then below = below + (b.talents[o.key] or 0) end
    end
    if below < t.row * 5 then GameTooltip:AddLine(string.format(tl("locked"), t.row * 5), 1, 0.3, 0.3, 1) end
  end
  GameTooltip:AddLine(tl("left"), 0.5, 0.5, 0.5)
  GameTooltip:Show()
end

local function createTree(parent, index)
  local f = CreateFrame("Frame", nil, parent)
  f:SetWidth(TREE_W)
  f:SetHeight(500)
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", (index - 1) * (TREE_W + 14), 0)
  local bg = H.Fill(f, "BACKGROUND", 1, 1, 1, 0.04)
  bg:SetAllPoints(f)
  f.title = H.Text(f, 15, "LEFT")
  f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)
  f.points = H.Text(f, 13, "RIGHT")
  f.points:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -9)
  f.grid = CreateFrame("Frame", nil, f)
  f.grid:SetWidth(4 * DX)
  f.grid:SetHeight(7 * DY)
  f.grid:SetPoint("TOP", f, "TOP", 0, -34)
  f.buttons = {}
  f.lines = {}
  f.miles = {}
  for i = 1, 3 do
    local m = H.Text(f, 12, "LEFT")
    m:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -34 - 7 * DY - 6 - (i - 1) * 18)
    f.miles[i] = m
  end
  return f
end

local function talentButton(tf, tree, t)
  local btn = H.Icon(tf.grid, ICON)
  btn:SetPoint("TOPLEFT", tf.grid, "TOPLEFT", t.col * DX + (DX - ICON) / 2, -t.row * DY)
  btn:SetIcon(t.icon)
  btn.rank = H.Text(btn, 11, "RIGHT")
  btn.rank:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -6)
  btn.tree, btn.talent = tree, t
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn:SetScript("OnClick", function()
    local b = W.Build()
    if not b then return end
    if arg1 == "RightButton" then SB.RemovePoint(b, this.tree, this.talent) else SB.AddPoint(b, this.tree, this.talent) end
    W.Changed()
    tooltip(this)
  end)
  btn:SetScript("OnEnter", function() tooltip(this) end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return btn
end

local function mileLines(tf, tree)
  local prev
  for i = 1, table.getn(tree.talents) do
    local t = tree.talents[i]
    if t.milestone or t.capstone then
      if prev and prev.col == t.col then
        local line = H.Fill(tf.grid, "BACKGROUND", 0.5, 0.5, 0.5, 0.6)
        line:SetWidth(3)
        line:SetPoint("TOP", tf.grid, "TOPLEFT", prev.col * DX + DX / 2, -prev.row * DY - ICON)
        line:SetHeight((t.row - prev.row) * DY - ICON)
        line.from, line.to = prev, t
        table.insert(tf.lines, line)
      end
      prev = t
    end
  end
end

local function build(f)
  f.trees = {}
  for i = 1, 3 do f.trees[i] = createTree(f, i) end
  f.reset = H.Button(f, tl("reset"), 110, 22, function()
    local b = W.Build()
    if b then b.talents = {} W.Changed() end
  end)
  f.reset:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
end

local function refresh(f, b)
  local c = SB.Class(b.class)
  if f.classKey ~= c.key then
    for i = 1, 3 do
      local tf = f.trees[i]
      for j = 1, table.getn(tf.buttons) do tf.buttons[j]:Hide() end
      for j = 1, table.getn(tf.lines) do tf.lines[j]:Hide() end
      tf.buttons, tf.lines = {}, {}
      local tree = c.trees[i]
      for j = 1, table.getn(tree.talents) do
        table.insert(tf.buttons, talentButton(tf, tree, tree.talents[j]))
      end
      mileLines(tf, tree)
      tf.tree = tree
    end
    f.classKey = c.key
  end
  local spec = SB.Spec(b)
  for i = 1, 3 do
    local tf = f.trees[i]
    local tree = tf.tree
    local pts = SB.TreePoints(b, tree)
    tf.title:SetText(SB.T(tree.name))
    if spec == tree then tf.title:SetTextColor(1, 0.82, 0.2) else tf.title:SetTextColor(0.85, 0.85, 0.85) end
    tf.points:SetText(pts .. " " .. tl("pts"))
    for j = 1, table.getn(tf.buttons) do
      local btn = tf.buttons[j]
      local t = btn.talent
      local r = b.talents[t.key] or 0
      btn.rank:SetText(r .. "/" .. t.max)
      if r >= t.max then
        btn:SetBorder(1, 0.82, 0.2)
        btn.icon:SetDesaturated(nil)
        btn.icon:SetAlpha(1)
        btn.rank:SetTextColor(1, 0.82, 0.2)
      elseif r > 0 or SB.CanAdd(b, tree, t) then
        btn:SetBorder(r > 0 and 0.3 or 0.15, r > 0 and 0.85 or 0.15, r > 0 and 0.3 or 0.15)
        btn.icon:SetDesaturated(nil)
        btn.icon:SetAlpha(1)
        btn.rank:SetTextColor(r > 0 and 0.3 or 1, r > 0 and 1 or 1, r > 0 and 0.3 or 1)
      else
        btn:SetBorder(0, 0, 0)
        btn.icon:SetDesaturated(1)
        btn.icon:SetAlpha(0.45)
        btn.rank:SetTextColor(0.5, 0.5, 0.5)
      end
    end
    for j = 1, table.getn(tf.lines) do
      local l = tf.lines[j]
      if (b.talents[l.from.key] or 0) >= l.from.max then l:SetTexture(1, 0.82, 0.2, 0.9) else l:SetTexture(0.5, 0.5, 0.5, 0.5) end
      l:Show()
    end
    local m = 0
    for j = 1, table.getn(tree.talents) do
      local t = tree.talents[j]
      if t.milestone or t.capstone then
        m = m + 1
        if tf.miles[m] then
          local done = (b.talents[t.key] or 0) > 0
          tf.miles[m]:SetText(string.format("%d %s · %s", t.row * 5, tl("pts"), SB.T(t.name)))
          if done then tf.miles[m]:SetTextColor(0.4, 0.8, 1) else tf.miles[m]:SetTextColor(0.6, 0.6, 0.6) end
        end
      end
    end
  end
end

W.AddView("talents", 1, build, refresh)
