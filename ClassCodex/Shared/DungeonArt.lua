local _, ns = ...

ns.DUNGEON_BG = {
    [161] = 1041999,
    [239] = 1718213,
    [402] = 4742929,
    [556] = 608210,
    [557] = 7464937,
    [558] = 7467174,
    [559] = 7570501,
    [560] = 7478529,
}

local function hslToRgb(h, s, l)
    local function hue(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < 1 / 6 then return p + (q - p) * 6 * t end
        if t < 1 / 2 then return q end
        if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
        return p
    end
    if s == 0 then return l, l, l end
    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    return hue(p, q, h + 1 / 3), hue(p, q, h), hue(p, q, h - 1 / 3)
end

function ns.TintFromKey(key)
    if not key or key == "" then return nil end
    local sum = 0
    for i = 1, #key do
        sum = sum + key:byte(i) * i
    end
    return hslToRgb((sum % 360) / 360, 0.55, 0.52)
end

local currentRaidName
function ns.GetCurrentRaidName()
    if currentRaidName ~= nil then return currentRaidName or nil end
    currentRaidName = false
    if EJ_SelectTier and EJ_GetNumTiers and EJ_GetInstanceByIndex then
        pcall(function()
            EJ_SelectTier(EJ_GetNumTiers())
            local id, name = EJ_GetInstanceByIndex(1, true)
            if id and name then currentRaidName = name end
        end)
    end
    return currentRaidName or nil
end

local function norm(s)
    return s and s:lower():gsub("[^%w]", "") or nil
end

local dungeonByName
local function EnsureDungeonMap()
    if dungeonByName then return end
    if not (C_ChallengeMode and C_ChallengeMode.GetMapUIInfo) then return end
    local ids = {}
    if C_ChallengeMode.GetMapTable then
        local t = C_ChallengeMode.GetMapTable()
        if type(t) == "table" then
            for _, id in ipairs(t) do
                ids[id] = true
            end
        end
    end
    for id in pairs(ns.DUNGEON_BG) do
        ids[id] = true
    end
    local map, any = {}, false
    for id in pairs(ids) do
        local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(id)
        if name and texture then
            map[norm(name)] = { bg = ns.DUNGEON_BG[id], icon = texture, id = id }
            any = true
        end
    end
    if any then dungeonByName = map end
end

function ns.GetDungeonIconByName(name)
    local key = norm(name)
    if not key then return nil end
    EnsureDungeonMap()
    local e = dungeonByName[key]
    return e and e.icon or nil
end

local bossByName
local function EnsureBossMap()
    if bossByName then return end
    if C_AddOns and C_AddOns.LoadAddOn then pcall(C_AddOns.LoadAddOn, "Blizzard_EncounterJournal") end
    if not (EJ_GetInstanceByIndex and EJ_SelectInstance and EJ_GetEncounterInfoByIndex and EJ_GetCreatureInfo) then
        return
    end
    local map, any = {}, false
    local function scanTier(tier)
        EJ_SelectTier(tier)
        local i = 1
        while true do
            local instanceID = EJ_GetInstanceByIndex(i, true)
            if not instanceID then break end
            EJ_SelectInstance(instanceID)
            local instBg = select(6, EJ_GetInstanceInfo(instanceID))
            local j = 1
            while true do
                local bossName, _, encounterID = EJ_GetEncounterInfoByIndex(j, instanceID)
                if not bossName then break end
                local key = norm(bossName)
                if key and not map[key] then
                    local _, _, _, displayID = EJ_GetCreatureInfo(1, encounterID)
                    map[key] = { displayID = displayID, instanceID = instanceID, bg = instBg }
                    any = true
                end
                j = j + 1
            end
            i = i + 1
        end
    end
    pcall(function()
        local n = (EJ_GetNumTiers and EJ_GetNumTiers()) or 1
        for tier = n, 1, -1 do
            scanTier(tier)
        end
    end)
    if any then bossByName = map end
end

function ns.GetBossArtByName(name)
    local key = norm(name)
    if not key then return nil end
    EnsureBossMap()
    return bossByName[key]
end
