local module = require(GetScriptDirectory().."/helpers")
local globalState = require(GetScriptDirectory().."/global_state")

-- todo: adjust for dire
--1st tower top 0.42 under == pulled
--

--globalState.state.furthestLane = penis

--1, 2, 3, on destroyed state, 4 on pushed
local pulledPushed = {
	[TEAM_RADIANT] =
	{
		[LANE_TOP] = {0.42, 0.28, 0.19, 0.65},
		[LANE_MID] = {0.52, 0.37, 0.28, 0.61},
		[LANE_BOT] = {0.65, 0.33, 0.19, 0.7}
	},
	[TEAM_DIRE] =
	{
		[LANE_TOP] = {0.65, 0.33, 0.19, 0.7},
		[LANE_MID] = {0.52, 0.37, 0.28, 0.61},
		[LANE_BOT] = {0.42, 0.28, 0.19, 0.65}
	}
}

local lane_state = {
	[LANE_TOP] = 0,
	[LANE_MID] = 0,
	[LANE_BOT] = 0
}

local decided = {}

function LanePushedPulledNotHealing(npcBot)
	local myLane = module.GetLane(npcBot)
	local pID = npcBot:GetPlayerID()
	local percentHealth = module.CalcPerHealth(npcBot)
	local team = GetTeam()
	local time = DotaTime()

	local gankable = {
		[LANE_TOP] = true,
		[LANE_MID] = true,
		[LANE_BOT] = true
	}

	gankable[myLane] = nil

	if time < 1800 and myLane == LANE_TOP then
		gankable[LANE_BOT] = nil
	end
	if time < 1800 and myLane == LANE_BOT then
		gankable[LANE_TOP] = nil
	end

	local myFrontAmount = GetLaneFrontAmount(team, myLane, false)
	if myFrontAmount > pulledPushed[team][myLane][4] then
		lane_state[myLane] = 1
	end
	if	((time < 1800 or module.GetTower1(npcBot)) ~= nil and myFrontAmount < pulledPushed[team][myLane][1]) or
		(module.GetTower2(npcBot) ~= nil and myFrontAmount < pulledPushed[team][myLane][2]) or 
		(myFrontAmount < pulledPushed[team][myLane][3]) then
		lane_state[myLane] = 0
	end

	if lane_state[myLane] == 0 or percentHealth < 0.5 or npcBot:DistanceFromFountain() == 0 or npcBot:HasModifier("modifier_flask_healing") then
		return false
	end

	if time < 1800 then
		if decided[pID] == nil or decided[pID] + 30 < time then
			local pulledLane = false
			for lane, exist in pairs(gankable) do
				if exist ~= nil and GetLaneFrontAmount(team, lane, false) < pulledPushed[team][lane][1] and
					globalState.state.laneInfo[lane].numEnemies > 0 and globalState.state.laneInfo[lane].numAllies > 0 then
					pulledLane = true
				end
			end
			if pulledLane == false then
				return false
			end
		end
		decided[pID] = time
		return true
	end
	return true
end

--function EnemiesInLane()
--	local enemiesTop = globalState.state.laneInfo[1].numEnemies
--	local alliesTop = globalState.state.laneInfo[1].numAllies
--end
--
--function AlliesInLane()
--end

function GoGank(npcBot)
	return 25
end

local gank_weight = {
    settings =
    {
        name = "gank",

        components = {
            --{func=<calculate>, weight=<n>},
        },

        conditionals = {
        	{func=GoGank, condition=LanePushedPulledNotHealing, weight=1}
        }
    }
}

return gank_weight