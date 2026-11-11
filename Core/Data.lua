-- EzWoW - Data : shared game data for the EzWoW addons (core API).
--
-- The core folder (always loaded) holds this API and the small instance tables.
-- Everything else lives in load-on-demand folders that ship in the same package:
--   EzWoW-Data-Items, -Dungeons, -Rares, -Recipes, -Quests, -Spawns,
--   EzWoW-Data-Names-<locale> (koKR, enUS, deDE, frFR, esES, ruRU, zhCN, zhTW).
-- The table shapes are documented at the top of each data file.
--
-- Usage from another addon (add "## OptionalDeps: EzWoW-Data" to its .toc):
--   local Data = EzWoW_Data
--   if Data and Data.Load("Items") then
--       local records = Data.GetItemSources(itemID)
--   end
-- Load() never loads a module during combat; it queues the load and runs the
-- optional callback after combat instead. Getters load their module on first use
-- (out of combat) and return nil while it is not available.

local D = EzWoW_Data or {}
EzWoW_Data = D

D.formatVersion = 1
D.modules = D.modules or {}

local MODULES = { Items = true, Dungeons = true, Rares = true, Recipes = true, Quests = true, Spawns = true }
local NAME_LOCALES = { koKR = true, enUS = true, deDE = true, frFR = true, esES = true, ruRU = true, zhCN = true, zhTW = true }
local LOCALE_ALIAS = { enGB = "enUS", esMX = "esES" }
for loc in pairs(NAME_LOCALES) do MODULES["Names-" .. loc] = true end

-- ---------------------------------------------------------------------------
-- Used by the data files while they load
-- ---------------------------------------------------------------------------
function D._Begin(name, version, formatVersion)
    local m = D.modules[name] or {}
    D.modules[name] = m
    m.version = version
    m.formatVersion = formatVersion
    m.compatible = (formatVersion == D.formatVersion)
    m.loaded = false
end

function D._Table(name, tableName)
    local m = D.modules[name]
    if not m then
        m = {}
        D.modules[name] = m
    end
    local t = m[tableName]
    if t == nil then
        t = {}
        m[tableName] = t
    end
    return t
end

function D._Set(name, tableName, value)
    D._Table(name, tableName)
    D.modules[name][tableName] = value
end

function D._Done(name)
    local m = D.modules[name]
    if m then m.loaded = true end
end

-- ---------------------------------------------------------------------------
-- Loading
-- ---------------------------------------------------------------------------
function D.ClientLocale()
    local loc = type(GetLocale) == "function" and GetLocale() or "enUS"
    loc = LOCALE_ALIAS[loc] or loc
    if not NAME_LOCALES[loc] then loc = "enUS" end
    return loc
end

-- "Names" means the client's locale; "Names-xxXX" a given one.
local function resolve(name)
    if name == "Names" then name = "Names-" .. D.ClientLocale() end
    return name, "EzWoW-Data-" .. tostring(name)
end

function D.IsLoaded(name)
    local key = resolve(name)
    if key == "Core" then return true end
    local m = D.modules[key]
    return (m and m.loaded) and true or false
end

function D.GetModuleVersion(name)
    local key = resolve(name)
    local m = D.modules[key]
    return m and m.version or nil
end

local failed, queue, callbacks = {}, {}, {}
local eventFrame

local function inCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown() and true or false
end

local function runCallbacks(key, ok)
    local list = callbacks[key]
    callbacks[key] = nil
    if not list then return end
    for _, fn in ipairs(list) do
        pcall(fn, key, ok)
    end
end

local function loadNow(key, addon)
    local loadFn = (C_AddOns and C_AddOns.LoadAddOn) or (type(LoadAddOn) == "function" and LoadAddOn) or nil
    if not loadFn then
        failed[key] = "NO_API"
        return false
    end
    local ok, loaded, reason = pcall(loadFn, addon)
    if not ok then
        failed[key] = "ERROR"
        return false
    end
    if not D.IsLoaded(key) then
        failed[key] = (not loaded and reason) or "NOT_LOADED"
        return false
    end
    return true
end

local function onCombatEnd()
    if eventFrame then pcall(eventFrame.UnregisterEvent, eventFrame, "PLAYER_REGEN_ENABLED") end
    local pending = queue
    queue = {}
    for key in pairs(pending) do
        local ok = D.IsLoaded(key) or (not failed[key] and loadNow(key, "EzWoW-Data-" .. key))
        runCallbacks(key, ok)
    end
end

local function waitForCombatEnd(key)
    queue[key] = true
    if not eventFrame and type(CreateFrame) == "function" then
        eventFrame = CreateFrame("Frame")
        eventFrame:SetScript("OnEvent", onCombatEnd)
    end
    if eventFrame then pcall(eventFrame.RegisterEvent, eventFrame, "PLAYER_REGEN_ENABLED") end
end

-- Load(name [, callback]) -> loaded (boolean), reason
--   name: "Items", "Dungeons", "Rares", "Recipes", "Quests", "Spawns", "Names" or "Names-<locale>"
--   callback(name, ok) runs once the module is loaded (right away, or after combat).
function D.Load(name, callback)
    local key, addon = resolve(name)
    if key == "Core" or D.IsLoaded(key) then
        if callback then pcall(callback, key, true) end
        return true
    end
    if not MODULES[key] then
        if callback then pcall(callback, key, false) end
        return false, "UNKNOWN"
    end
    if failed[key] then
        if callback then pcall(callback, key, false) end
        return false, failed[key]
    end
    if callback then
        callbacks[key] = callbacks[key] or {}
        table.insert(callbacks[key], callback)
    end
    if inCombat() then
        waitForCombatEnd(key)
        return false, "COMBAT"
    end
    local ok = loadNow(key, addon)
    runCallbacks(key, ok)
    return ok, failed[key]
end

-- Module table, loading it out of combat when needed (nil if not available).
local function need(name)
    local key = resolve(name)
    if key == "Core" then return D.modules.Core end
    if not D.IsLoaded(key) then
        if failed[key] or inCombat() then return nil end
        D.Load(key)
    end
    local m = D.modules[key]
    return (m and m.loaded) and m or nil
end

-- Whole table of a module (for addons that iterate it). nil if not available.
function D.GetTable(module, tableName)
    local m = need(module)
    return m and m[tableName] or nil
end

-- One entry of a module table.
function D.Get(module, tableName, key)
    local t = D.GetTable(module, tableName)
    if type(t) ~= "table" then return nil end
    return t[key]
end

-- ---------------------------------------------------------------------------
-- Core tables
-- ---------------------------------------------------------------------------
-- { uiMapID, areaID, koName, enName } for a journal instance ID
function D.GetInstance(instanceID)
    return D.Get("Core", "instances", instanceID)
end

-- Korean instance name for an instance map ID (e.g. 36 = The Deadmines)
function D.GetInstanceMapName(mapID)
    return D.Get("Core", "instanceMaps", mapID)
end

-- ---------------------------------------------------------------------------
-- Names
-- ---------------------------------------------------------------------------
-- GetName(kind, id [, locale [, englishFallback]])
--   kind: "item", "npc", "object", "quest", "spell", "subname"
function D.GetName(kind, id, locale, englishFallback)
    locale = locale and (LOCALE_ALIAS[locale] or locale) or D.ClientLocale()
    local t = D.GetTable("Names-" .. locale, kind)
    local name = t and t[id]
    if name == nil and englishFallback and locale ~= "enUS" then
        t = D.GetTable("Names-enUS", kind)
        name = t and t[id]
    end
    return name
end

-- Korean text for an English title, boss or zone name (any letter case)
function D.GetKoreanFromEnglish(text)
    if type(text) ~= "string" then return nil end
    local t = D.GetTable("Names-koKR", "fromEn")
    return t and t[text:lower()] or nil
end

-- ---------------------------------------------------------------------------
-- Items
-- ---------------------------------------------------------------------------
-- quality, iconFileID (only for items the data knows)
function D.GetItemInfo(itemID)
    local row = D.Get("Items", "info", itemID)
    if row then return row[1], row[2] end
    return nil
end

-- Raw source records "kind:loc:sub:extra:text;..." (see the Items data files)
function D.GetItemSources(itemID)
    return D.Get("Items", "sources", itemID)
end

-- Split a record string into { {kind=, loc=, sub=, extra=, text=}, ... }
function D.ParseItemSources(records)
    local out = {}
    if type(records) ~= "string" then return out end
    for rec in records:gmatch("[^;]+") do
        local kind, loc, sub, extra, text = strsplit(":", rec)
        out[#out + 1] = { kind = kind, loc = tonumber(loc) or loc, sub = tonumber(sub) or sub,
                          extra = tonumber(extra) or extra, text = text }
    end
    return out
end

-- Dungeon/boss drop rows with chances: { {inst, boss, minLvl, chance, creature, map, n}, ... }
function D.GetGearDrops(itemID)
    return D.Get("Items", "gearDrops", itemID)
end

-- ---------------------------------------------------------------------------
-- Spawns
-- ---------------------------------------------------------------------------
-- GetSpawns(kind, id) -> { {map, x, y, z}, ... }, flags
--   kind: "npc", "object", "item" (where it lies or drops), "quest" (giver/turn-in spots)
function D.GetSpawns(kind, id)
    local t = D.GetTable("Spawns", kind)
    local spots = t and t[id]
    if spots == nil then return nil end
    local f = D.GetTable("Spawns", kind .. "Flags")
    return spots, (f and f[id]) or 0
end

local idLists = {}
-- Sorted id list of one spawn kind (the order the old per-addon data used)
function D.GetSpawnIDs(kind)
    if idLists[kind] then return idLists[kind] end
    local t = D.GetTable("Spawns", kind)
    if not t then return nil end
    local ids = {}
    for id in pairs(t) do ids[#ids + 1] = id end
    table.sort(ids)
    idLists[kind] = ids
    return ids
end

-- "locID:x,y|itemID[:drop%],...|questID,..."
function D.GetNpcInfo(npcID)
    return D.Get("Spawns", "npcInfo", npcID)
end

-- ---------------------------------------------------------------------------
-- Rares
-- ---------------------------------------------------------------------------
local rareIndex
function D.GetRare(npcID)
    if not rareIndex then
        local list = D.GetTable("Rares", "list")
        if not list then return nil end
        rareIndex = {}
        for _, r in ipairs(list) do
            if rareIndex[r.id] == nil then rareIndex[r.id] = r end
        end
    end
    return rareIndex[npcID]
end

-- ---------------------------------------------------------------------------
-- Recipes
-- ---------------------------------------------------------------------------
local recipeIndex
-- GetRecipe(spellID) -> recipe row, skillLineID
function D.GetRecipe(spellID)
    if not recipeIndex then
        local profs = D.GetTable("Recipes", "professions")
        if not profs then return nil end
        recipeIndex = {}
        for skillLine, p in pairs(profs) do
            for _, row in ipairs(p.recipes or {}) do
                if recipeIndex[row[1]] == nil then recipeIndex[row[1]] = { row, skillLine } end
            end
        end
    end
    local hit = recipeIndex[spellID]
    if hit then return hit[1], hit[2] end
    return nil
end

function D.GetProfession(skillLineID)
    return D.Get("Recipes", "professions", skillLineID)
end

-- "spellID|skillLineID|skill|catKo|catEn|reagents|sourceKo|sourceEn" for a crafted item
function D.GetCraftedBy(itemID)
    return D.Get("Recipes", "crafted", itemID)
end

-- ---------------------------------------------------------------------------
-- Dungeons
-- ---------------------------------------------------------------------------
local dungeonByKey, dungeonByInstance
local function indexDungeons()
    if dungeonByKey then return true end
    local list = D.GetTable("Dungeons", "list")
    if not list then return false end
    dungeonByKey, dungeonByInstance = {}, {}
    for _, d in ipairs(list) do
        dungeonByKey[d.key] = d
        for _, id in ipairs(d.instanceIDs or {}) do
            local list2 = dungeonByInstance[id]
            if not list2 then
                list2 = {}
                dungeonByInstance[id] = list2
            end
            list2[#list2 + 1] = d
        end
    end
    return true
end

function D.GetDungeons()
    return D.GetTable("Dungeons", "list")
end

function D.GetDungeon(key)
    if not indexDungeons() then return nil end
    return dungeonByKey[key]
end

-- GetDungeonByInstance(instanceID) -> first dungeon, all dungeons with that ID
--   instanceID is the one from GetInstanceInfo(). Wings of one instance (e.g. the
--   Scarlet Monastery wings) share an ID; pick the wing by name or subzone.
function D.GetDungeonByInstance(instanceID)
    if not indexDungeons() then return nil end
    local list = dungeonByInstance[instanceID]
    if not list then return nil end
    return list[1], list
end

-- ---------------------------------------------------------------------------
-- Quests
-- ---------------------------------------------------------------------------
-- { lvl, min, sort, next?, races?, obj } (quests seen with objectives)
function D.GetQuest(questID)
    return D.Get("Quests", "quests", questID)
end

-- { level, required level, side, class mask, category, done first?, in log?, blocked by? }
function D.GetQuestLevels(questID)
    return D.Get("Quests", "levels", questID)
end

-- { titleEn, level, min level, class mask, race mask, {choice}, {fixed} }
-- (titleEn is filled from the English names when the row does not carry its own)
function D.GetQuestRewards(questID)
    local row = D.Get("Quests", "rewards", questID)
    if row and row[1] == false then
        local copy = { D.GetName("quest", questID, "enUS") or "" }
        for i = 2, #row do copy[i] = row[i] end
        return copy
    end
    return row
end

-- giver/turn-in records seen in game: { "npc"/"object", id, continent?, x?, y? }
function D.GetQuestGiver(questID)
    return D.Get("Quests", "givers", questID)
end

function D.GetQuestTurnIn(questID)
    return D.Get("Quests", "turnIns", questID)
end
