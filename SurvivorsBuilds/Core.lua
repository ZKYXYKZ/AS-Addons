SB = {}
BINDING_HEADER_SURVIVORS = "Survivors"
BINDING_NAME_SURVIVORS_HUB = "Survivors"
BINDING_NAME_SURVIVORS_BUILDS = "Survivors : Builds"
local MAX_POINTS = 51
local ROW_POINTS = 5

SB.CLASS_COLORS = {
  warrior = { 0.78, 0.61, 0.43 }, paladin = { 0.96, 0.55, 0.73 }, hunter = { 0.67, 0.83, 0.45 },
  rogue = { 1, 0.96, 0.41 }, priest = { 1, 1, 1 }, shaman = { 0.14, 0.35, 1 },
  mage = { 0.41, 0.8, 0.94 }, warlock = { 0.58, 0.51, 0.79 }, druid = { 1, 0.49, 0.04 },
}
SB.RARITY_COLORS = { { 0.85, 0.85, 0.85 }, { 0.12, 1, 0 }, { 0, 0.44, 0.87 }, { 0.64, 0.21, 0.93 }, { 1, 0.5, 0 } }

function SB.DB()
  SurvivorsBuildsDB = SurvivorsBuildsDB or {}
  local db = SurvivorsBuildsDB
  db.builds = db.builds or {}
  db.active = db.active or {}
  db.nextId = db.nextId or 1
  return db
end

function SB.Lang()
  local db = SB.DB()
  if db.lang then return db.lang end
  local cname = AZS_ZONE and AZS_ZONE.cname
  if cname and cname ~= db.seenName then
    db.seenName = cname
    db.detected = "en"
    for i = 1, table.getn(SB_DATA.classes) do
      local n = SB_DATA.classes[i].name
      if n.fr == cname and n.en ~= cname then db.detected = "fr" end
    end
  end
  return db.detected or "en"
end

function SB.T(o)
  if type(o) ~= "table" then return o end
  return o[SB.Lang()] or o.en
end

function SB.Format(desc, value)
  if not value then return desc end
  local s
  if value == math.floor(value) then s = string.format("%d", value) else s = string.format("%.1f", value) end
  return (string.gsub(desc, "{v}", s))
end

function SB.Class(key)
  for i = 1, table.getn(SB_DATA.classes) do
    if SB_DATA.classes[i].key == key then return SB_DATA.classes[i], i end
  end
end

function SB.PlayerClass()
  local cls = AZS_ZONE and AZS_ZONE.class
  if cls and SB.Class(cls) then return cls end
  local _, token = UnitClass("player")
  if token then
    token = string.lower(token)
    if SB.Class(token) then return token end
  end
  return "warrior"
end

function SB.Spell(classKey, key)
  local c = SB.Class(classKey)
  if not c then return end
  for i = 1, table.getn(c.spells) do
    if c.spells[i].key == key then return c.spells[i] end
  end
end

function SB.Jewel(cat, key)
  local list = SB_DATA[cat]
  for i = 1, table.getn(list) do
    if list[i].key == key then return list[i] end
  end
end

function SB.NewBuild(classKey, name)
  local db = SB.DB()
  local b = {
    id = db.nextId, class = classKey, name = name or "Build " .. db.nextId,
    talents = {}, spells = {}, ban = {}, rings = {}, trinkets = {}, amulets = {},
    rules = { rarity = 50, reserve = 1, reroll = 1, banishes = 3 },
  }
  db.nextId = db.nextId + 1
  table.insert(db.builds, b)
  db.active[classKey] = b.id
  return b
end

function SB.Copy(t)
  if type(t) ~= "table" then return t end
  local o = {}
  for k, v in pairs(t) do o[k] = SB.Copy(v) end
  return o
end

function SB.Duplicate(b)
  local db = SB.DB()
  local c = SB.Copy(b)
  c.id = db.nextId
  c.name = b.name .. " (2)"
  db.nextId = db.nextId + 1
  table.insert(db.builds, c)
  db.active[c.class] = c.id
  return c
end

function SB.Delete(b)
  local db = SB.DB()
  for i = table.getn(db.builds), 1, -1 do
    if db.builds[i] == b then table.remove(db.builds, i) end
  end
  if db.active[b.class] == b.id then db.active[b.class] = nil end
end

function SB.BuildsOf(classKey)
  local out = {}
  local db = SB.DB()
  for i = 1, table.getn(db.builds) do
    if db.builds[i].class == classKey then table.insert(out, db.builds[i]) end
  end
  return out
end

function SB.Active(classKey)
  local db = SB.DB()
  local list = SB.BuildsOf(classKey)
  for i = 1, table.getn(list) do
    if list[i].id == db.active[classKey] then return list[i] end
  end
  if list[1] then
    db.active[classKey] = list[1].id
    return list[1]
  end
end

function SB.TreePoints(b, tree)
  local n = 0
  for i = 1, table.getn(tree.talents) do n = n + (b.talents[tree.talents[i].key] or 0) end
  return n
end

function SB.TotalPoints(b)
  local c = SB.Class(b.class)
  local n = 0
  for t = 1, 3 do n = n + SB.TreePoints(b, c.trees[t]) end
  return n
end

local function treeValid(b, tree)
  for i = 1, table.getn(tree.talents) do
    local t = tree.talents[i]
    local r = b.talents[t.key] or 0
    if r > 0 then
      local below = 0
      for j = 1, table.getn(tree.talents) do
        local o = tree.talents[j]
        if o.row < t.row then below = below + (b.talents[o.key] or 0) end
      end
      if below < t.row * ROW_POINTS then return false end
    end
  end
  return true
end

function SB.CanAdd(b, tree, t)
  local r = b.talents[t.key] or 0
  if r >= t.max or SB.TotalPoints(b) >= MAX_POINTS then return false end
  b.talents[t.key] = r + 1
  local ok = treeValid(b, tree)
  b.talents[t.key] = r > 0 and r or nil
  return ok
end

function SB.CanRemove(b, tree, t)
  local r = b.talents[t.key] or 0
  if r <= 0 then return false end
  b.talents[t.key] = r - 1 > 0 and r - 1 or nil
  local ok = treeValid(b, tree)
  b.talents[t.key] = r
  return ok
end

function SB.AddPoint(b, tree, t)
  if not SB.CanAdd(b, tree, t) then return false end
  b.talents[t.key] = (b.talents[t.key] or 0) + 1
  return true
end

function SB.RemovePoint(b, tree, t)
  if not SB.CanRemove(b, tree, t) then return false end
  local r = b.talents[t.key] - 1
  b.talents[t.key] = r > 0 and r or nil
  return true
end

function SB.Spec(b)
  local c = SB.Class(b.class)
  local best, bi = -1, nil
  local parts = {}
  for t = 1, 3 do
    local n = SB.TreePoints(b, c.trees[t])
    table.insert(parts, n)
    if n > best then best, bi = n, t end
  end
  if best <= 0 then return nil, parts end
  return c.trees[bi], parts
end

function SB.SpellIndex(b, key)
  for i = 1, table.getn(b.spells) do
    if b.spells[i].key == key then return i end
  end
end

function SB.ListIndex(list, key)
  for i = 1, table.getn(list) do
    if list[i] == key then return i end
  end
end

function SB.Score(b, spellKey, rarity)
  local i = SB.SpellIndex(b, spellKey)
  if not i or b.ban[spellKey] then return 0 end
  local w = b.spells[i].w or 3
  local influence = (b.rules.rarity or 50) / 100
  return w * (1 + influence * (rarity or 0))
end

function SB.Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffe6b84cBuilds|r " .. msg)
end
