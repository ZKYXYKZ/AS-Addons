local H = SurvivorsHub
local P = {}
SB.Talents = P

local T = {
  fr = { title = "Talents du build : %s", none = "Pas de talents dans ce build", hint = "À recopier dans la fenêtre des talents", points = "%d pts" },
  en = { title = "Build talents: %s", none = "No talents in this build", hint = "Copy them into the talent window", points = "%d pts" },
}
local function tl(k) return (T[SB.Lang()] or T.en)[k] end

local CELL, GAP, COLS, ROWS = 24, 5, 4, 7
local TREEW = COLS * (CELL + GAP) - GAP
local WIDTH = 3 * TREEW + 2 * 16 + 20

local function build()
  local f = CreateFrame("Frame", "SurvivorsBuildsTalents", UIParent)
  f:SetWidth(WIDTH)
  f:SetHeight(62 + ROWS * (CELL + GAP))
  f:SetFrameStrata("HIGH")
  local bg = H.Fill(f, "BACKGROUND", 0.04, 0.04, 0.05, 0.9)
  bg:SetAllPoints(f)
  f.title = H.Text(f, 13, "LEFT")
  f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)
  f.title:SetWidth(WIDTH - 40)
  f.title:SetTextColor(1, 0.82, 0.2)
  f.hint = H.Text(f, 11, "LEFT")
  f.hint:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
  f.hint:SetTextColor(0.6, 0.6, 0.65)
  local close = H.Button(f, "x", 18, 18, function() f:Hide() end)
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
  f.heads, f.cells = {}, {}
  for t = 1, 3 do
    local x = 10 + (t - 1) * (TREEW + 16)
    local h = H.Text(f, 12, "LEFT")
    h:SetPoint("TOPLEFT", f, "TOPLEFT", x, -44)
    h:SetWidth(TREEW)
    f.heads[t] = h
    f.cells[t] = {}
  end
  f:Hide()
  if SurvivorsUI and SurvivorsUI.Register then
    SurvivorsUI.Register("buildtalents", "Talents", f, "RIGHT", -40, 40)
    if SurvivorsUI.Handle then SurvivorsUI.Handle("buildtalents", f) end
  else
    f:SetPoint("RIGHT", UIParent, "RIGHT", -40, 40)
    f:SetMovable(1)
    f:EnableMouse(1)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  end
  P.frame = f
  return f
end

local function cell(f, t, n)
  local c = f.cells[t][n]
  if c then return c end
  c = CreateFrame("Frame", nil, f)
  c:SetWidth(CELL)
  c:SetHeight(CELL)
  c.border = H.Fill(c, "BACKGROUND", 0.85, 0.65, 0.2, 1)
  c.border:SetAllPoints(c)
  c.icon = c:CreateTexture(nil, "BORDER")
  c.icon:SetPoint("TOPLEFT", c, "TOPLEFT", 1, -1)
  c.icon:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -1, 1)
  c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  c.rank = H.Text(c, 11, "RIGHT")
  c.rank:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 3, -3)
  c:EnableMouse(1)
  c:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(this.name or "", 1, 0.82, 0.2)
    GameTooltip:AddLine(this.info or "", 1, 1, 1)
    GameTooltip:Show()
  end)
  c:SetScript("OnLeave", function() GameTooltip:Hide() end)
  f.cells[t][n] = c
  return c
end

function P.Refresh()
  local f = P.frame or build()
  local b = SB.Build()
  for t = 1, 3 do
    for _, c in pairs(f.cells[t]) do c:Hide() end
    f.heads[t]:SetText("")
  end
  if not b or not b.talents or table.getn(b.talents) == 0 then
    f.title:SetText(b and string.format(tl("title"), b.name) or tl("none"))
    f.hint:SetText(tl("none"))
    return
  end
  f.title:SetText(string.format(tl("title"), b.name))
  f.hint:SetText(tl("hint"))
  local pts, used = { 0, 0, 0 }, { 0, 0, 0 }
  for i = 1, table.getn(b.talents) do
    local e = b.talents[i]
    pts[e.t] = pts[e.t] + e.p
    used[e.t] = used[e.t] + 1
    local c = cell(f, e.t, used[e.t])
    c:ClearAllPoints()
    c:SetPoint("TOPLEFT", f, "TOPLEFT", 10 + (e.t - 1) * (TREEW + 16) + e.c * (CELL + GAP), -62 - e.r * (CELL + GAP))
    c.icon:SetTexture("Interface/Icons/" .. (e.i or "INV_Misc_QuestionMark"))
    c.rank:SetText(e.p .. "/" .. e.m)
    if e.p >= e.m then c.rank:SetTextColor(1, 0.82, 0.2) else c.rank:SetTextColor(0.5, 1, 0.5) end
    c.name = e.n
    c.info = string.format("%d / %d", e.p, e.m)
    c:Show()
  end
  for t = 1, 3 do
    local name = b.trees and b.trees[t] or ""
    f.heads[t]:SetText(name .. "  |cffe6b84c" .. string.format(tl("points"), pts[t]) .. "|r")
  end
end

function P.Toggle(show)
  local f = P.frame or build()
  if show == nil then show = not f:IsShown() end
  if show then
    P.Refresh()
    f:Show()
  else
    f:Hide()
  end
end

local orig = ToggleTalentFrame
function ToggleTalentFrame()
  if orig then orig() end
  P.Toggle()
end
