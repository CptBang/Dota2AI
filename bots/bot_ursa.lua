local module = require(GetScriptDirectory().."/helpers")
local behavior = require(GetScriptDirectory().."/behavior")
local stateMachine = require(GetScriptDirectory().."/state_machine")
local minionBehavior = require(GetScriptDirectory().."/minion_behavior")
local minionStateMachine = require(GetScriptDirectory().."/minion_state_machine")

local SKILL_Q = "ursa_earthshock"
local SKILL_W = "ursa_overpower"
local SKILL_E = "ursa_fury_swipes"
local SKILL_R = "ursa_enrage"
local TALENT1 = "special_bonus_mp_regen_3"
local TALENT2 = "special_bonus_strength_8"
local TALENT3 = "special_bonus_agility_14"
local TALENT4 = "special_bonus_unique_ursa_4"
local TALENT5 = "special_bonus_unique_ursa_3"
local TALENT6 = "special_bonus_unique_ursa"
local TALENT7 = "special_bonus_unique_ursa_5"
local TALENT8 = "special_bonus_unique_ursa_6"


local Ability = {
	SKILL_E,
	SKILL_W,
	SKILL_E,
	SKILL_W,
	SKILL_E,
	SKILL_R,
	SKILL_E,
	SKILL_W,
	SKILL_W,
	TALENT2,
	SKILL_Q,
	SKILL_R,
	SKILL_Q,
	SKILL_Q,
	TALENT3,
	SKILL_Q,
	"nil",
	SKILL_R,
	"nil",
	TALENT6,
	"nil",
	"nil",
	"nil",
	"nil",
	TALENT7
}

local npcBot = GetBot()


----Function pointers----
--local npcBot:Action_AttackUnit = npcBot:ActionPush_AttackUnit
--local AP_MoveDirectly = npcBot:ActionPush_MoveDirectly
--local AP_MoveToUnit = npcBot:ActionPush_MoveToUnit
--local UseAbilityEnemy = npcBot:Action_UseAbilityOnEntity
--local UseAbility = npcBot:ActionPush_UseAbility

----Checks whether bot is in process of casting an ability----
function IsBotCasting()
	return npcBot:IsChanneling()
		  or npcBot:IsUsingAbility()
		  or npcBot:IsCastingAbility()
end


function ConsiderCast(...)
	for k,v in pairs({...}) do
		if (v == nil or not v:IsFullyCastable()) then
			return false
		end
	end
	return true
end

--function CompareEnemyHealth(eHero, )
--	local eHeroList = npcBot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
--
--	return target
--end

----Murder closest enemy hero----
function Murder()
	local manaPer = module.CalcPerMana(npcBot)
	local currentMana = npcBot:GetMana()
	local hRange = npcBot:GetAttackRange() - 25

	local eHeroList = npcBot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

	local abilityQ = npcBot:GetAbilityByName(SKILL_Q)
	local abilityW = npcBot:GetAbilityByName(SKILL_W)
	local abilityE = npcBot:GetAbilityByName(SKILL_E)
	local abilityR = npcBot:GetAbilityByName(SKILL_R)
	local phase = module.ItemSlot(npcBot, "item_phase_boots")
	local bkb = module.ItemSlot(npcBot, "item_black_king_bar")
	local abyssal = module.ItemSlot(npcBot, "item_abyssal_blade")

	local manaQ = abilityQ:GetManaCost()
	local manaW = abilityW:GetManaCost()


	if (eHeroList ~= nil and #eHeroList > 0) then
	local target = module.SmartTarget(npcBot)

		if (not IsBotCasting() and phase ~= nil and ConsiderCast(phase)) then
			npcBot:Action_UseAbility(phase)
		end

		----Try various combos on weakened enemy unit----
		if (not IsBotCasting() and ConsiderCast(abilityR, abilityW) and GetUnitToUnitDistance(npcBot, target) <= 300
				and currentMana >= module.CalcManaCombo(manaW)) then
			npcBot:ActionPush_UseAbility(abilityW)
			npcBot:ActionPush_UseAbility(abilityR)

		elseif (not IsBotCasting() and ConsiderCast(abilityR) and GetUnitToUnitDistance(npcBot, target) <= 300) then
			npcBot:Action_UseAbility(abilityR)

		elseif (not IsBotCasting() and ConsiderCast(abilityW) and GetUnitToUnitDistance(npcBot, target) <= 300
				and currentMana >= module.CalcManaCombo(manaW)) then
			npcBot:Action_UseAbility(abilityW)

		elseif (not IsBotCasting() and ConsiderCast(abilityQ) and GetUnitToUnitDistance(npcBot, target) <= 150
				and currentMana >= module.CalcManaCombo(manaQ)) then
			npcBot:Action_UseAbility(abilityQ)
		end
		----Fuck'em up!----
		--ranged, wait til attack finish
		if (not IsBotCasting()) then
			if npcBot:GetCurrentActionType() ~= BOT_ACTION_TYPE_ATTACK then
				if GetUnitToUnitDistance(npcBot, target) <= hRange then
					npcBot:Action_AttackUnit(target, true)
				else
					npcBot:Action_MoveToUnit(target)
				end
			end
		end
	end
end

function Think()
	npcBot = GetBot()
	local state = stateMachine.calculateState(npcBot)

	module.AbilityLevelUp(Ability)
	if state.state == "hunt" then
		Murder()
	else
		behavior.generic(npcBot, state)
	end
end

function MinionThink(hMinionUnit)
	local state = minionStateMachine.calculateState(hMinionUnit)
	local master = GetBot()
	if (hMinionUnit == nil) then
		return
	end

	if hMinionUnit:IsIllusion() then
		minionBehavior.generic(hMinionUnit, master, state)
	else
		return
	end
end