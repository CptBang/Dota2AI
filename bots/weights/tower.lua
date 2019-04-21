local module = require(GetScriptDirectory().."/helpers")
local geneList = require(GetScriptDirectory().."/genes/gene")

local searchRange = 1200

function towerHealth(npcBot)
    local eTower = npcBot:GetNearbyTowers(searchRange, true)
    local towerHealth = module.CalcPerHealth(eTower[1])
    return RemapValClamped(towerHealth, 0.12, 0, geneList.GetWeight(npcBot:GetUnitName(), "towerWeight"), 100)
end

function towerNearby(npcBot)
	local eTower = npcBot:GetNearbyTowers(searchRange, true)
	local nearbyAcreeps = module.GetAllyCreepInTowerRange(npcBot, searchRange)
    if eTower ~= nil and #eTower > 0 and #nearbyAcreeps ~= 0 then
        return true
    end
end

function buildingDesire(npcBot)
    return geneList.GetWeight(npcBot:GetUnitName(), "buildingWeight")
end

function buildingNearby(npcBot)
    local eTower = npcBot:GetNearbyTowers(searchRange, true)
    if eTower ~= nil and #eTower > 0 and #module.GetAllyCreepInTowerRange(npcBot, 800) ~= 0 then
        return true
    end
    local eBarracks = npcBot:GetNearbyBarracks(searchRange, true)
    if (eBarracks ~= nil and #eBarracks > 0) then
        return true
    end
    local eAncient
	if npcBot:GetTeam() == 2 then
		eAncient = GetAncient(3)
	else
		eAncient = GetAncient(2)
    end
    if (eAncient ~= nil and GetUnitToUnitDistance(npcBot, eAncient) <= searchRange) then
        return true
    end
    return false
end



--function ratioEnemy(npcBot)
--    local enemy = npcBot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
--    local allies = npcBot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
--
--    if (#enemy >= #allies) then
--        return 0
--    else
--        return 1
--    end
--end
--
--function enemyNearby(npcBot)
--    local enemy = npcBot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
--    return enemy ~= nil and #enemy > 0
--end

local tower_weight = {
    settings =
    {
        name = "tower",

        components = {
            --{func=<calculate>, weight=<n>},
        },

        conditionals = {
            --{func=<calculate>, condition=<condition>, weight=<n>},
            --{func=ratioEnemy, condition=enemyNearby, weight=1},
            {func=buildingDesire, condition=buildingNearby, weight=1},
            {func=towerHealth, condition=towerNearby, weight=1}
        }
    }
}

return tower_weight