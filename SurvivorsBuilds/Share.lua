local H = SurvivorsHub
local W = SB.W
local PREFIX = "SB1"

local T = {
  fr = { export = "Exporter", import = "Importer", exportTitle = "Copiez ce texte (Ctrl+C) pour partager le build", importTitle = "Collez un build (Ctrl+V) puis validez", ok = "Importer", close = "Fermer", bad = "Texte de build invalide", done = "Build importé : %s" },
  en = { export = "Export", import = "Import", exportTitle = "Copy this text (Ctrl+C) to share the build", importTitle = "Paste a build (Ctrl+V) then confirm", ok = "Import", close = "Close", bad = "Invalid build text", done = "Build imported: %s" },
}
local function tl(k) return (T[SB.Lang()] or T.en)[k] end

local function clean(s)
  return (string.gsub(s or "", "[;|/,:]", " "))
end

local function split(s, sep)
  local out = {}
  if not s or s == "" then return out end
  local pos = 1
  while true do
    local a, b = string.find(s, sep, pos, 1)
    if not a then
      table.insert(out, string.sub(s, pos))
      break
    end
    table.insert(out, string.sub(s, pos, a - 1))
    pos = b + 1
  end
  return out
end

function SB.Encode(b)
  local c = SB.Class(b.class)
  local trees = {}
  for t = 1, 3 do
    local s = ""
    for i = 1, table.getn(c.trees[t].talents) do s = s .. (b.talents[c.trees[t].talents[i].key] or 0) end
    table.insert(trees, s)
  end
  local spells = {}
  for i = 1, table.getn(b.spells) do table.insert(spells, b.spells[i].key .. ":" .. (b.spells[i].w or 3)) end
  local bans = {}
  for k in pairs(b.ban) do table.insert(bans, k) end
  table.sort(bans)
  local r = b.rules
  return table.concat({
    PREFIX, b.class, clean(b.name), table.concat(trees, "/"), table.concat(spells, ","), table.concat(bans, ","),
    table.concat(b.rings, ","), table.concat(b.trinkets, ","), table.concat(b.amulets, ","),
    (r.rarity or 50) .. "," .. (r.reserve or 1) .. "," .. (r.reroll or 1) .. "," .. (r.banishes or 3),
  }, ";")
end

function SB.Decode(text)
  text = string.gsub(text or "", "%s+$", "")
  text = string.gsub(text, "^%s+", "")
  local f = split(text, ";")
  if f[1] ~= PREFIX or table.getn(f) < 10 then return nil end
  local c = SB.Class(f[2])
  if not c then return nil end
  local b = SB.NewBuild(c.key, f[3] ~= "" and f[3] or nil)
  local trees = split(f[4], "/")
  for t = 1, 3 do
    local s = trees[t] or ""
    for i = 1, table.getn(c.trees[t].talents) do
      local r = tonumber(string.sub(s, i, i))
      local tal = c.trees[t].talents[i]
      if r and r > 0 then b.talents[tal.key] = math.min(r, tal.max) end
    end
  end
  local spells = split(f[5], ",")
  for i = 1, table.getn(spells) do
    local p = split(spells[i], ":")
    if SB.Spell(c.key, p[1]) then table.insert(b.spells, { key = p[1], w = math.max(1, math.min(5, tonumber(p[2]) or 3)) }) end
  end
  local bans = split(f[6], ",")
  for i = 1, table.getn(bans) do if bans[i] ~= "" then b.ban[bans[i]] = true end end
  local cats = { "rings", "trinkets", "amulets" }
  for ci = 1, 3 do
    local list = split(f[6 + ci], ",")
    for i = 1, table.getn(list) do
      if SB.Jewel(cats[ci], list[i]) then table.insert(b[cats[ci]], list[i]) end
    end
  end
  local r = split(f[10], ",")
  b.rules.rarity = tonumber(r[1]) or 50
  b.rules.reserve = tonumber(r[2]) or 1
  b.rules.reroll = tonumber(r[3]) or 1
  b.rules.banishes = tonumber(r[4]) or 3
  return b
end

local function dialog()
  if W.share then return W.share end
  local d = CreateFrame("Frame", "SurvivorsBuildsShare", UIParent)
  d:SetWidth(560)
  d:SetHeight(200)
  d:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
  d:SetFrameStrata("FULLSCREEN_DIALOG")
  d:EnableMouse(1)
  local bg = H.Fill(d, "BACKGROUND", 0.05, 0.05, 0.06, 0.98)
  bg:SetAllPoints(d)
  local edge = H.Fill(d, "BORDER", 0.85, 0.65, 0.2, 0.6)
  edge:SetHeight(1)
  edge:SetPoint("TOPLEFT", d, "TOPLEFT", 0, 0)
  edge:SetPoint("TOPRIGHT", d, "TOPRIGHT", 0, 0)
  d.title = H.Text(d, 13, "LEFT")
  d.title:SetPoint("TOPLEFT", d, "TOPLEFT", 12, -12)
  local box = CreateFrame("EditBox", nil, d)
  box:SetMultiLine(1)
  box:SetWidth(536)
  box:SetHeight(110)
  box:SetPoint("TOPLEFT", d, "TOPLEFT", 12, -36)
  box:SetFont(H.FONT, 12)
  box:SetMaxLetters(4000)
  box:SetAutoFocus(nil)
  box:SetTextInsets(6, 6, 6, 6)
  local bbg = H.Fill(box, "BACKGROUND", 0, 0, 0, 0.9)
  bbg:SetAllPoints(box)
  box:SetScript("OnEscapePressed", function() d:Hide() end)
  d.box = box
  d.ok = H.Button(d, "", 120, 24, function()
    local b = SB.Decode(d.box:GetText())
    if not b then
      SB.Print(tl("bad"))
      return
    end
    W.classKey = b.class
    SB.Print(string.format(tl("done"), b.name))
    d:Hide()
    W.Changed()
  end)
  d.ok:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -140, 12)
  d.close = H.Button(d, "", 120, 24, function() d:Hide() end)
  d.close:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -12, 12)
  d:Hide()
  table.insert(UISpecialFrames, "SurvivorsBuildsShare")
  W.share = d
  return d
end

function SB.ShowExport(b)
  local d = dialog()
  d.title:SetText(tl("exportTitle"))
  d.close.text:SetText(tl("close"))
  d.ok:Hide()
  d.box:SetText(SB.Encode(b))
  d:Show()
  d.box:SetFocus()
  d.box:HighlightText()
end

function SB.ShowImport()
  local d = dialog()
  d.title:SetText(tl("importTitle"))
  d.close.text:SetText(tl("close"))
  d.ok.text:SetText(tl("ok"))
  d.ok:Show()
  d.box:SetText("")
  d:Show()
  d.box:SetFocus()
end

function SB.ShareButtons(p)
  local imp = H.Button(p, tl("import"), 90, 24, function() SB.ShowImport() end)
  imp:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, -32)
  W.Label(imp, "import", tl)
  local exp = H.Button(p, tl("export"), 90, 24, function()
    local b = W.Build()
    if b then SB.ShowExport(b) end
  end)
  exp:SetPoint("RIGHT", imp, "LEFT", -4, 0)
  W.Label(exp, "export", tl)
end
