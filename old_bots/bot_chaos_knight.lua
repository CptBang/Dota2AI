local module = require(GetScriptDirectory().."/helpers")
local bot_generic = require(GetScriptDirectory().."/bot_generic")

local SKILL_Q = "chaos_knight_chaos_bolt"
local SKILL_W = "chaos_knight_reality_rift"
local SKILL_E = "chaos_knight_chaos_strike"
local SKILL_R = "chaos_knight_phantasm"
local TALENT1 = "special_bonus_all_stats_5"
local TALENT2 = "special_bonus_movement_speed_20"
local TALENT3 = "special_bonus_strength_15"
local TALENT4 = "special_bonus_cooldown_reduction_12"
local TALENT5 = "special_bonus_gold_income_25"
local TALENT6 = "special_bonus_unique_chaos_knight"
local TALENT7 = "special_bonus_unique_chaos_knight_2"
local TALENT8 = "special_bonus_unique_chaos_knight_3"

local Ability = {
	SKILL_Q,
	SKILL_W,
	SKILL_E,
	SKILL_Q,
	SKILL_E,
	SKILL_R,
	SKILL_W,
	SKILL_Q,
	SKILL_Q,
	TALENT1,
	SKILL_W,
	SKILL_R,
	SKILL_E,
	SKILL_W,
	TALENT3,
	SKILL_E,
	"nil",
	SKILL_R,
	"nil",
	TALENT5,
	"nil",
	"nil",
	"nil",
	"nil",
	TALENT7
}

local npcBot = GetBot()

----Function pointers----
local AP_AttackUnit = npcBot.ActionPush_AttackUnit
local AP_MoveDirectly = npcBot.ActionPush_MoveDirectly
local AP_MoveToUnit = npcBot.ActionPush_MoveToUnit
local UseAbilityEnemy = npcBot.ActionPush_UseAbilityOnEntity
local UseAbility = npcBot.ActionPush_UseAbility

function IsBotCasting()
	return npcBot:IsChanneling()
		  or npcBot:IsUsingAbility()
		  or npcBot:IsCastingAbility()
end

function ConsiderItem(Item)
	if (Item == nil or not Item:IsFullyCastable()) then
		return 0
	end

		return 1
end

function ConsiderCast(ability)
	if (not ability:IsFullyCastable()) then
		return 0
	end

	return 1
end

----Murder closest enemy hero----
function Murder(eHero)
	local perHealth = module.CalcPerHealth(npcBot)
	local manaPer = module.CalcPerMana(npcBot)
	local hRange = npcBot:GetAttackRange() - 50
	--local spamSkill = comboList[npcBot:GetUnitName()]

	local abilityQ = npcBot:GetAbilityByName(SKILL_Q)
	local abilityW = npcBot:GetAbilityByName(SKILL_W)
	local abilityE = npcBot:GetAbilityByName(SKILL_E)
	local abilityR = npcBot:GetAbilityByName(SKILL_R)
	local arcane = module.ItemSlot(npcBot, "item_arcane_boots")

	if (not IsBotCasting() and ConsiderCast(abilityR) == 1 and ConsiderCast(abilityW) == 1 and ConsiderCast(abilityQ) == 1 and manaPer >= 0.5 and GetUnitToUnitDistance(npcBot,eHero) <= abilityW:GetCastRange()) then
			npcBot:ActionPush_UseAbilityOnEntity(abilityQ, eHero)
			npcBot:ActionPush_UseAbilityOnEntity(abilityW, eHero)
			npcBot:ActionPush_UseAbility(abilityR)
	elseif (not IsBotCasting() and ConsiderCast(abilityW) == 1 and ConsiderCast(abilityQ) == 1 and GetUnitToUnitDistance(npcBot,eHero) <= abilityW:GetCastRange() and manaPer >= 0.4) then
		npcBot:ActionPush_UseAbilityOnEntity(abilityQ, eHero)
		npcBot:ActionPush_UseAbilityOnEntity(abilityW, eHero)
	elseif (not IsBotCasting() and ConsiderCast(abilityQ) == 1 and GetUnitToUnitDistance(npcBot, eHero) <= abilityQ:GetCastRange() and manaPer >= 0.3) then
		npcBot:ActionPush_UseAbilityOnEntity(abilityQ, eHero)
	elseif (not IsBotCasting() and ConsiderCast(abilityW) == 1 and GetUnitToUnitDistance(npcBot, eHero) <= abilityW:GetCastRange() and manaPer >= 0.3) then
		npcBot:ActionPush_UseAbilityOnEntity(abilityW, eHero)
	end

	----Fuck'em up!----
	if (not IsBotCasting()) then
		if (GetUnitToUnitDistance(npcBot, eHero) <= hRange) then
			AP_AttackUnit(npcBot, eHero, true)
		else
			AP_AttackUnit(npcBot, eHero, true)
			AP_MoveToUnit(npcBot, eHero)
		end
	end
end

----Pokes hero if within range----
function Poke(eHero)
	local perHealth = module.CalcPerHealth(npcBot)
	local eHeroClose = module.CalcPerHealth(eHero)
	local hRange = npcBot:GetAttackRange() - 50

	if (GetUnitToUnitDistance(npcBot, eHero) <= hRange and npcBot:NumQueuedActions() == 0) then
		AP_AttackUnit(npcBot, eHero, true)
	end
end

function Hunt()
	local perHealth = module.CalcPerHealth(npcBot)

	local aHero = npcBot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
	local aCreeps = npcBot:GetNearbyLaneCreeps(1600, false)
	local aTowers = npcBot:GetNearbyTowers(700, false)

	local eHero = npcBot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
	local eCreeps = npcBot:GetNearbyLaneCreeps(1600, true)
	local eTowers = npcBot:GetNearbyTowers(1000, true)


	local powerRatio = module.CalcPowerRatio(npcBot, aHero, eHero)

	if (eHero == nil or #eHero == 0) then
		return
	elseif (etowers ~= nil or #eTowers ~= 0) then
		if (GetUnitToUnitDistance(npcBot, eTowers[1]) <= 725) then
			return
		end
	else
		local ePerHealth = module.CalcPerHealth(eHero[1])
		if ((ePerHealth <= 0.6 or powerRatio <= 1 or #aTowers ~= 0) and eTowers == nil) then
			Murder(eHero[1])
		elseif (ePerHealth > 0.6) then
			Poke(eHero[1])
		end
	end
end

function Think()
	----Level up Abilities in order----
	module.AbilityLevelUp(Ability)
	----Determine and execute whether to poke or hunt the enemy----
	Hunt()
	----After executing Hunt, go back to generic state machines----
	bot_generic.Think()
end