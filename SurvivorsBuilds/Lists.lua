local H = SurvivorsHub
local W = SB.W

local T = {
  fr = {
    pool = "Sorts de la classe", prio = "Ordre de priorité", weight = "Poids", ban = "Banni", hintPool = "Clic gauche : ajouter · Clic droit : bannir",
    hintPrio = "Un run garde 6 sorts : les 6 premiers sont visés, les suivants servent de repli. Le poids (1 à 5) entre dans le score avec la rareté.", empty = "Cliquez un sort à gauche pour l'ajouter.",
    rings = "Anneaux", trinkets = "Bijoux", amulets = "Amulette", hintJewel = "Clic gauche : ajouter / retirer · Clic droit : bannir. Les premiers sont visés, les suivants servent de repli.",
    target = "visé", fallback = "repli",
    rarity = "Influence de la rareté", rarityTip = "0 % : seule la priorité compte. 100 % : une légendaire vaut 5 fois une commune.",
    reserve = "Relances gardées en réserve", banishes = "Bannissements disponibles par run", reroll = "Aucune carte du build : relancer avant de skip", store = "Stocker les montées de niveau (réglage du jeu : le combat ne s'arrête plus, un bouton Level Up! les ouvre)", lang = "Langue", auto = "Auto",
    example = "Exemple : %s poids %d en %s = %.1f",
  },
  en = {
    pool = "Class spells", prio = "Priority order", weight = "Weight", ban = "Banned", hintPool = "Left click: add · Right click: ban",
    hintPrio = "A run holds 6 spells: the first 6 are targets, the rest are fallbacks. Weight (1 to 5) counts in the score with rarity.", empty = "Click a spell on the left to add it.",
    rings = "Rings", trinkets = "Trinkets", amulets = "Amulet", hintJewel = "Left click: add / remove · Right click: ban. The first ones are targets, the rest are fallbacks.",
    target = "target", fallback = "fallback",
    rarity = "Rarity influence", rarityTip = "0%: only priority counts. 100%: a legendary is worth 5 commons.",
    reserve = "Rerolls kept in reserve", banishes = "Banishes available per run", reroll = "No card from the build: reroll before skipping", store = "Store level-ups (game setting: the fight no longer stops, a Level Up! button opens them)", lang = "Language", auto = "Auto",
    example = "Example: %s weight %d as %s = %.1f",
  },
}
local function tl(k) return (T[SB.Lang()] or T.en)[k] end
local SLOTS = 6
local UP = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up"
local DOWN = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up"

local function arrow(parent, tex, fn)
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(24)
  b:SetHeight(24)
  b:SetNormalTexture(tex)
  b:SetScript("OnClick", fn)
  return b
end

local function header(parent, x, y, key)
  local t = H.Text(parent, 14, "LEFT")
  t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  t:SetTextColor(1, 0.82, 0.2)
  t.key = key
  return t
end

local function hint(parent, x, y, w)
  local t = H.Text(parent, 11, "LEFT")
  t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  t:SetWidth(w)
  t:SetTextColor(0.6, 0.6, 0.6)
  return t
end

local function buildSpells(f)
  f.poolTitle = header(f, 0, -4)
  f.poolHint = hint(f, 0, -24, 300)
  f.pool = {}
  for i = 1, 13 do
    local r = CreateFrame("Button", nil, f)
    r:SetWidth(300)
    r:SetHeight(32)
    r:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -44 - (i - 1) * 36)
    r.bg = H.Fill(r, "BACKGROUND", 1, 1, 1, 0.05)
    r.bg:SetAllPoints(r)
    r.ic = H.Icon(r, 30)
    r.ic:SetPoint("LEFT", r, "LEFT", 1, 0)
    r.ic:EnableMouse(nil)
    r.name = H.Text(r, 13, "LEFT")
    r.name:SetPoint("LEFT", r.ic, "RIGHT", 8, 0)
    r.tag = H.Text(r, 11, "RIGHT")
    r.tag:SetPoint("RIGHT", r, "RIGHT", -8, 0)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r:SetScript("OnClick", function()
      local b = W.Build()
      local key = this.key
      if arg1 == "RightButton" then
        if b.ban[key] then b.ban[key] = nil else b.ban[key] = true end
        local idx = SB.SpellIndex(b, key)
        if b.ban[key] and idx then table.remove(b.spells, idx) end
      else
        b.ban[key] = nil
        if not SB.SpellIndex(b, key) then table.insert(b.spells, { key = key, w = 3 }) end
      end
      W.Changed()
    end)
    r:SetScript("OnEnter", function() this.bg:SetTexture(1, 1, 1, 0.12) end)
    r:SetScript("OnLeave", function() this.bg:SetTexture(1, 1, 1, 0.05) end)
    f.pool[i] = r
  end
  f.prioTitle = header(f, 340, -4)
  f.prioHint = hint(f, 340, -24, 600)
  f.empty = H.Text(f, 13, "LEFT")
  f.empty:SetPoint("TOPLEFT", f, "TOPLEFT", 340, -50)
  f.empty:SetTextColor(0.5, 0.5, 0.5)
  f.rows = {}
  for i = 1, 13 do
    local r = CreateFrame("Frame", nil, f)
    r:SetWidth(620)
    r:SetHeight(32)
    r:SetPoint("TOPLEFT", f, "TOPLEFT", 340, -44 - (i - 1) * 36)
    local bg = H.Fill(r, "BACKGROUND", 1, 1, 1, 0.05)
    bg:SetAllPoints(r)
    r.num = H.Text(r, 15, "CENTER")
    r.num:SetWidth(28)
    r.num:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.num:SetTextColor(1, 0.82, 0.2)
    r.ic = H.Icon(r, 30)
    r.ic:SetPoint("LEFT", r, "LEFT", 30, 0)
    r.name = H.Text(r, 13, "LEFT")
    r.name:SetPoint("LEFT", r.ic, "RIGHT", 8, 0)
    r.up = arrow(r, UP, function()
      local b = W.Build()
      local i2 = this:GetParent().index
      if i2 > 1 then b.spells[i2], b.spells[i2 - 1] = b.spells[i2 - 1], b.spells[i2] end
      W.Changed()
    end)
    r.up:SetPoint("RIGHT", r, "RIGHT", -190, 0)
    r.down = arrow(r, DOWN, function()
      local b = W.Build()
      local i2 = this:GetParent().index
      if i2 < table.getn(b.spells) then b.spells[i2], b.spells[i2 + 1] = b.spells[i2 + 1], b.spells[i2] end
      W.Changed()
    end)
    r.down:SetPoint("LEFT", r.up, "RIGHT", 2, 0)
    r.wlabel = H.Text(r, 11, "RIGHT")
    r.wlabel:SetPoint("RIGHT", r, "RIGHT", -112, 0)
    r.wlabel:SetTextColor(0.6, 0.6, 0.6)
    r.minus = H.Button(r, "-", 20, 20, function()
      local s = W.Build().spells[this:GetParent().index]
      s.w = math.max(1, (s.w or 3) - 1)
      W.Changed()
    end)
    r.minus:SetPoint("RIGHT", r, "RIGHT", -80, 0)
    r.w = H.Text(r, 13, "CENTER")
    r.w:SetWidth(20)
    r.w:SetPoint("LEFT", r.minus, "RIGHT", 2, 0)
    r.plus = H.Button(r, "+", 20, 20, function()
      local s = W.Build().spells[this:GetParent().index]
      s.w = math.min(5, (s.w or 3) + 1)
      W.Changed()
    end)
    r.plus:SetPoint("LEFT", r.w, "RIGHT", 2, 0)
    r.del = H.Button(r, "x", 20, 20, function()
      table.remove(W.Build().spells, this:GetParent().index)
      W.Changed()
    end)
    r.del:SetPoint("RIGHT", r, "RIGHT", -6, 0)
    f.rows[i] = r
  end
end

local function refreshSpells(f, b)
  local c = SB.Class(b.class)
  f.poolTitle:SetText(tl("pool"))
  f.poolHint:SetText(tl("hintPool"))
  f.prioTitle:SetText(tl("prio"))
  f.prioHint:SetText(tl("hintPrio"))
  for i = 1, table.getn(f.pool) do
    local r = f.pool[i]
    local s = c.spells[i]
    if s then
      r.key = s.key
      r.ic:SetIcon(s.icon)
      r.name:SetText(SB.T(s.name))
      local idx = SB.SpellIndex(b, s.key)
      if b.ban[s.key] then
        r.tag:SetText(tl("ban"))
        r.tag:SetTextColor(1, 0.3, 0.3)
        r.name:SetTextColor(0.5, 0.5, 0.5)
        r.ic.icon:SetDesaturated(1)
      elseif idx then
        r.tag:SetText("#" .. idx)
        r.tag:SetTextColor(1, 0.82, 0.2)
        r.name:SetTextColor(1, 1, 1)
        r.ic.icon:SetDesaturated(nil)
      else
        r.tag:SetText("")
        r.name:SetTextColor(0.85, 0.85, 0.85)
        r.ic.icon:SetDesaturated(nil)
      end
      r:Show()
    else
      r:Hide()
    end
  end
  for i = 1, table.getn(f.rows) do
    local r = f.rows[i]
    local e = b.spells[i]
    local s = e and SB.Spell(b.class, e.key)
    if s then
      r.index = i
      r.num:SetText(i)
      if i <= SLOTS then
        r.num:SetTextColor(1, 0.82, 0.2)
        r.name:SetTextColor(1, 1, 1)
      else
        r.num:SetTextColor(0.5, 0.5, 0.5)
        r.name:SetTextColor(0.6, 0.6, 0.6)
      end
      r.ic:SetIcon(s.icon)
      r.name:SetText(SB.T(s.name))
      r.wlabel:SetText(tl("weight"))
      r.w:SetText(e.w or 3)
      r:Show()
    else
      r:Hide()
    end
  end
  if table.getn(b.spells) == 0 then f.empty:SetText(tl("empty")) else f.empty:SetText("") end
end

local CATS = { { "rings", 2 }, { "trinkets", 2 }, { "amulets", 1 } }

local function buildJewels(f)
  f.hint = hint(f, 0, -4, 960)
  f.cols = {}
  for ci = 1, 3 do
    local col = CreateFrame("Frame", nil, f)
    col:SetWidth(310)
    col:SetHeight(480)
    col:SetPoint("TOPLEFT", f, "TOPLEFT", (ci - 1) * 326, -26)
    local bg = H.Fill(col, "BACKGROUND", 1, 1, 1, 0.04)
    bg:SetAllPoints(col)
    col.title = header(col, 10, -8)
    col.cat, col.want = CATS[ci][1], CATS[ci][2]
    col.items = {}
    for i = 1, table.getn(SB_DATA[col.cat]) do
      local it = H.Icon(col, 40)
      it:SetPoint("TOPLEFT", col, "TOPLEFT", 12 + math.mod(i - 1, 6) * 48, -34 - math.floor((i - 1) / 6) * 56)
      it.data = SB_DATA[col.cat][i]
      it.cat = col.cat
      it:SetIcon(it.data.icon)
      it.badge = H.Text(it, 14, "CENTER")
      it.badge:SetPoint("TOPLEFT", it, "TOPLEFT", 2, -2)
      it:RegisterForClicks("LeftButtonUp", "RightButtonUp")
      it:SetScript("OnClick", function()
        local b = W.Build()
        local list, key = b[this.cat], this.data.key
        local idx = SB.ListIndex(list, key)
        if arg1 == "RightButton" then
          if idx then table.remove(list, idx) end
          if b.ban[key] then b.ban[key] = nil else b.ban[key] = true end
        elseif idx then
          table.remove(list, idx)
        else
          b.ban[key] = nil
          table.insert(list, key)
        end
        W.Changed()
      end)
      it:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(SB.T(this.data.name), 1, 0.82, 0.2)
        if this.data.desc then GameTooltip:AddLine(string.gsub(this.data.desc, "{v}", "x"), 0.9, 0.9, 0.9, 1) end
        GameTooltip:Show()
      end)
      it:SetScript("OnLeave", function() GameTooltip:Hide() end)
      table.insert(col.items, it)
    end
    col.list = H.Text(col, 12, "LEFT")
    col.list:SetPoint("TOPLEFT", col, "TOPLEFT", 12, -34 - 3 * 56 - 6)
    col.list:SetWidth(286)
    col.list:SetJustifyV("TOP")
    f.cols[ci] = col
  end
end

local function refreshJewels(f, b)
  f.hint:SetText(tl("hintJewel"))
  for ci = 1, 3 do
    local col = f.cols[ci]
    local list = b[col.cat]
    col.title:SetText(tl(col.cat))
    for i = 1, table.getn(col.items) do
      local it = col.items[i]
      local key = it.data.key
      local idx = SB.ListIndex(list, key)
      if b.ban[key] then
        it:SetBorder(0.8, 0.15, 0.15)
        it.icon:SetDesaturated(1)
        it.badge:SetText("")
      elseif idx then
        it.icon:SetDesaturated(nil)
        it.badge:SetText(idx)
        if idx <= col.want then it:SetBorder(1, 0.82, 0.2) it.badge:SetTextColor(1, 0.82, 0.2) else it:SetBorder(0.4, 0.6, 0.9) it.badge:SetTextColor(0.5, 0.75, 1) end
      else
        it:SetBorder(0, 0, 0)
        it.icon:SetDesaturated(nil)
        it.badge:SetText("")
      end
    end
    local s = ""
    for i = 1, table.getn(list) do
      local j = SB.Jewel(col.cat, list[i])
      if j then
        local tag = i <= col.want and tl("target") or tl("fallback")
        s = s .. i .. ". " .. SB.T(j.name) .. "  |cff888888" .. tag .. "|r\n"
      end
    end
    col.list:SetText(s)
  end
end

local function stepper(f, y, label, get, set, minv, maxv, step, fmt)
  local t = H.Text(f, 13, "LEFT")
  t:SetPoint("TOPLEFT", f, "TOPLEFT", 0, y)
  local minus = H.Button(f, "-", 22, 22, function() set(math.max(minv, get() - step)) W.Changed() end)
  minus:SetPoint("TOPLEFT", f, "TOPLEFT", 300, y + 4)
  local v = H.Text(f, 13, "CENTER")
  v:SetWidth(60)
  v:SetPoint("LEFT", minus, "RIGHT", 2, 0)
  local plus = H.Button(f, "+", 22, 22, function() set(math.min(maxv, get() + step)) W.Changed() end)
  plus:SetPoint("LEFT", v, "RIGHT", 2, 0)
  return function()
    t:SetText(label())
    v:SetText(string.format(fmt, get()))
  end
end

local function buildRules(f)
  f.updaters = {}
  local function rules() return W.Build().rules end
  table.insert(f.updaters, stepper(f, -10, function() return tl("rarity") end, function() return rules().rarity or 50 end, function(x) rules().rarity = x end, 0, 100, 10, "%d %%"))
  f.rarityTip = hint(f, 0, -32, 900)
  f.example = H.Text(f, 12, "LEFT")
  f.example:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -50)
  f.example:SetWidth(900)
  f.example:SetJustifyV("TOP")
  table.insert(f.updaters, stepper(f, -130, function() return tl("reserve") end, function() return rules().reserve or 1 end, function(x) rules().reserve = x end, 0, 6, 1, "%d"))
  table.insert(f.updaters, stepper(f, -96, function() return tl("banishes") end, function() return rules().banishes or 3 end, function(x) rules().banishes = x end, 0, 3, 1, "%d"))
  f.rerollBtn = H.Button(f, "", 22, 22, function()
    rules().reroll = rules().reroll == 1 and 0 or 1
    W.Changed()
  end)
  f.rerollBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 300, -166)
  f.rerollLabel = H.Text(f, 13, "LEFT")
  f.rerollLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -170)
  f.storeBtn = H.Button(f, "", 22, 22, function()
    if AZS_SetStoringLevels then AZS_SetStoringLevels(not AZS_IsStoringLevels()) end
    W.Changed()
  end)
  f.storeBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 300, -200)
  f.storeLabel = H.Text(f, 13, "LEFT")
  f.storeLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -204)
  f.storeLabel:SetWidth(290)
  f.langLabel = H.Text(f, 13, "LEFT")
  f.langLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -260)
  f.langs = {}
  local opts = { { nil, "auto" }, { "fr", "Français" }, { "en", "English" } }
  for i = 1, 3 do
    local o = opts[i]
    local btn = H.Button(f, o[2], 90, 22, function()
      SB.DB().lang = this.lang
      W.Changed()
    end)
    btn.lang = o[1]
    btn.labelKey = o[2]
    btn:SetPoint("TOPLEFT", f, "TOPLEFT", 300 + (i - 1) * 94, -256)
    f.langs[i] = btn
  end
end

local function refreshRules(f, b)
  for i = 1, table.getn(f.updaters) do f.updaters[i]() end
  f.rarityTip:SetText(tl("rarityTip"))
  local lines = ""
  local first = b.spells[1] and SB.Spell(b.class, b.spells[1].key)
  local second = b.spells[2] and SB.Spell(b.class, b.spells[2].key)
  if first then
    lines = lines .. string.format(tl("example"), SB.T(first.name), b.spells[1].w or 3, SB.T(SB_DATA.rarity[1]), SB.Score(b, first.key, 0)) .. "\n"
  end
  if second then
    lines = lines .. string.format(tl("example"), SB.T(second.name), b.spells[2].w or 3, SB.T(SB_DATA.rarity[5]), SB.Score(b, second.key, 4)) .. "\n"
  end
  f.example:SetText(lines)
  f.rerollLabel:SetText(tl("reroll"))
  f.rerollBtn.text:SetText(b.rules.reroll == 1 and "x" or "")
  f.storeLabel:SetText(tl("store"))
  f.storeBtn.text:SetText(AZS_IsStoringLevels and AZS_IsStoringLevels() and "x" or "")
  f.langLabel:SetText(tl("lang"))
  for i = 1, 3 do
    local btn = f.langs[i]
    if btn.labelKey == "auto" then btn.text:SetText(tl("auto")) end
    btn:SetActive(SB.DB().lang == btn.lang)
  end
end

W.AddView("spells", 2, buildSpells, refreshSpells)
W.AddView("jewels", 3, buildJewels, refreshJewels)
W.AddView("rules", 4, buildRules, refreshRules)
