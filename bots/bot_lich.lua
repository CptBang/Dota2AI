local module = require(GetScriptDirectory().."/helpers")
local behavior = require(GetScriptDirectory().."/behavior")
local stateMachine = require(GetScriptDirectory().."/state_machine")
local minionBehavior = require(GetScriptDirectory().."/minion_behavior")
local minionStateMachine = require(GetScriptDirectory().."/minion_state_machine")

local SKILL_Q = "lich_frost_nova"
local SKILL_W = "lich_frost_shield"
local SKILL_E = "lich_sinister_gaze"
local SKILL_R = "lich_chain_frost"
local TALENT1 = "special_bonus_hp_200"
local TALENT2 = "special_bonus_movement_speed_20"
local TALENT3 = "special_bonus_attack_damage_120"
local TALENT4 = "special_bonus_unique_lich_3"
local TALENT5 = "special_bonus_cast_range_150"
local TALENT6 = "special_bonus_unique_lich_4"
local TALENT7 = "special_bonus_unique_lich_1"
local TALENT8 = "special_bonus_unique_lich_2"

local Ability = {
	SKILL_W,
	SKILL_Q,
	SKILL_Q,
	SKILL_E,
	SKILL_Q,
	SKILL_R,
	SKILL_Q,
	SKILL_W,
	SKILL_W,
	TALENT1,
	SKILL_W,
	SKILL_R,
	SKILL_E,
	SKILL_E,
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

----Murder closest enemy hero----
function Murder()
	local currentHealth = npcBot:GetHealth()
	local maxHealth = npcBot:GetMaxHealth()
	local perHealth = module.CalcPerHealth(npcBot)
	local currentMana = npcBot:GetMana()
	local manaPer = module.CalcPerMana(npcBot)
    local hRange = npcBot:GetAttackRange() - 25

	local eHeroList = npcBot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
	local aHeroList = npcBot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)

	local abilityQ = npcBot:GetAbilityByName(SKILL_Q)
	local abilityW = npcBot:GetAbilityByName(SKILL_W)
	local abilityE = npcBot:GetAbilityByName(SKILL_E)
	local abilityR = npcBot:GetAbilityByName(SKILL_R)
	local stick = module.ItemSlot(npcBot, "item_magic_stick")
	local wand = module.ItemSlot(npcBot, "item_magic_wand")
	local sheepStick = module.ItemSlot(npcBot, "item_sheepstick")
	local force = module.ItemSlot(npcBot, "item_force_staff")
	local shivas = module.ItemSlot(npcBot, "item_shivas_guard")

	local manaQ = abilityQ:GetManaCost()
	local manaW = abilityW:GetManaCost()
	local manaE = abilityE:GetManaCost()
	local manaR = abilityR:GetManaCost()
	local manaSheepStick = 250
	local manaForce = 100
	local manaShivas = 100

	if (not IsBotCasting() and stick ~= nil and ConsiderCast(stick) and stick:GetCurrentCharges() >= 5 and currentHealth <= (maxHealth - (stick:GetCurrentCharges() * 15))) then
		npcBot:Action_UseAbility(stick)
		return
	end

	if (not IsBotCasting() and wand ~= nil and ConsiderCast(wand) and wand:GetCurrentCharges() >= 5 and currentHealth <= (maxHealth - (wand:GetCurrentCharges() * 15))) then
		npcBot:Action_UseAbility(wand)
		return
	end

	if (eHeroList ~= nil and #eHeroList > 0) then
		local target = module.SmartTarget(npcBot)
		local bounce = module.BounceSpells(npcBot, 600)
		local forceTarget = module.UseForceStaff(npcBot)

		if (not npcBot:IsSilenced()) then
			if (not IsBotCasting() and #eHeroList > 1 and ConsiderCast(abilityR) and GetUnitToUnitDistance(npcBot,eHeroList[1]) <= abilityR:GetCastRange()
					and bounce > 0 and currentMana >= module.CalcManaCombo(manaR)) then
				npcBot:Action_UseAbilityOnEntity(abilityR, eHeroList[1])

			elseif (not IsBotCasting() and sheepStick ~= nil and ConsiderCast(sheepStick) and GetUnitToUnitDistance(npcBot, target) <= sheepStick:GetCastRange()
					and currentMana >= module.CalcManaCombo(manaSheepStick) and not module.IsHardCC(target)) then
				npcBot:Action_UseAbilityOnEntity(sheepStick, target)

			elseif (not IsBotCasting() and #eHeroList > 1 and shivas ~= nil and ConsiderCast(shivas) and GetUnitToUnitDistance(npcBot, target) <= 600
					and currentMana >= module.CalcManaCombo(manaShivas) and not module.IsHardCC(target)) then
				npcBot:Action_UseAbility(shivas)

			elseif (aHeroList ~= nil and #aHeroList > 1 and not IsBotCasting() and ConsiderCast(abilityW) and GetUnitToUnitDistance(npcBot,aHeroList[2]) <= abilityW:GetCastRange()
					and GetUnitToUnitDistance(eHeroList[1], aHeroList[2]) <= 200 and currentMana >= module.CalcManaCombo(manaW)) then
				npcBot:Action_UseAbilityOnEntity(abilityW, aHeroList[2])

			elseif (not IsBotCasting() and ConsiderCast(abilityQ) and GetUnitToUnitDistance(npcBot,target) <= abilityQ:GetCastRange()
					and currentMana >= module.CalcManaCombo(manaQ) and not module.IsHardCC(target)) then
				npcBot:Action_UseAbilityOnEntity(abilityQ, target)

			elseif (not IsBotCasting() and ConsiderCast(abilityW) and GetUnitToUnitDistance(eHeroList[1], aHeroList[1]) <= 200
					and currentMana >= module.CalcManaCombo(manaW)) then
				npcBot:Action_UseAbilityOnEntity(abilityW, aHeroList[1])

			elseif (aHeroList ~= nil and #aHeroList > 1 and forceTarget ~= nil and not IsBotCasting() and force ~= nil and ConsiderCast(force) and GetUnitToUnitDistance(npcBot, forceTarget) <= force:GetCastRange()
					and currentMana >= module.CalcManaCombo(manaForce)) then
				npcBot:Action_UseAbilityOnEntity(force, forceTarget)

			elseif (aHeroList ~= nil and #aHeroList > 1 and not IsBotCasting() and ConsiderCast(abilityE) and GetUnitToUnitDistance(npcBot,target) <= abilityE:GetCastRange()
					and currentMana >= module.CalcManaCombo(manaE) and not module.IsHardCC(target)) then
				npcBot:Action_UseAbilityOnEntity(abilityE, target)
			end
		end
		----Fuck'em up!----
				--melee, miss when over 350
		if (not IsBotCasting()) then
			if npcBot:GetCurrentActionType() ~= BOT_ACTION_TYPE_ATTACK then
				if GetUnitToUnitDistance(npcBot, target) <= hRange then
					npcBot:Action_AttackUnit(target, true)
				else
					npcBot:Action_MoveToUnit(target)
				end
			end
		end

		if (module.CalcPerHealth(target) <= 0.15) then
			local ping = target:GetExtrapolatedLocation(1)
			npcBot:ActionImmediate_Ping(ping.x, ping.y, true)
		end
	end
end

function SpellRetreat()
	local manaPer = module.CalcPerMana(npcBot)
	local currentMana = npcBot:GetMana()
	local hRange = npcBot:GetAttackRange() - 25

	local eHeroList = npcBot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

	local abilityQ = npcBot:GetAbilityByName(SKILL_Q)
	local abilityR = npcBot:GetAbilityByName(SKILL_R)
	local glimmer = module.ItemSlot(npcBot, "item_glimmer_cape")
	local force = module.ItemSlot(npcBot, "item_force_staff")

	local manaQ = abilityQ:GetManaCost()
	local manaR = abilityR:GetManaCost()
	local manaGlimmer = 90
	local manaForce = 100

	local ancient
	if (npcBot:GetTeam() == 2) then
		ancient = GetAncient(2)
	else
		ancient = GetAncient(3)
	end


	if (eHeroList ~= nil and #eHeroList > 0 and not npcBot:IsInvisible()) then
		local target = eHeroList[1]
		local bounce = module.BounceSpells(npcBot, 600)

		if (not IsBotCasting() and glimmer ~= nil and ConsiderCast(glimmer) and currentMana >= module.CalcManaCombo(manaGlimmer)) then
			npcBot:Action_UseAbilityOnEntity(glimmer, npcBot)

		elseif (not IsBotCasting() and force ~= nil and ConsiderCast(force) and currentMana >= module.CalcManaCombo(manaForce)
				and npcBot:IsFacingLocation(ancient:GetLocation(), 30)) then
			npcBot:Action_UseAbilityOnEntity(force, npcBot)

		elseif (not IsBotCasting() and #eHeroList > 1 and ConsiderCast(abilityR) and GetUnitToUnitDistance(npcBot,eHeroList[1]) <= abilityR:GetCastRange()
				and bounce > 0 and currentMana >= module.CalcManaCombo(manaR)) then
			npcBot:Action_UseAbilityOnEntity(abilityR, eHeroList[1])

		elseif (not IsBotCasting() and ConsiderCast(abilityQ) and GetUnitToUnitDistance(npcBot,target) <= abilityQ:GetCastRange()
				and currentMana >= module.CalcManaCombo(manaQ)) then
			npcBot:Action_UseAbilityOnEntity(abilityQ, target)
		end

	end

end

function Think()
	npcBot = GetBot()
	local state = stateMachine.calculateState(npcBot)

	module.AbilityLevelUp(Ability)
	if state.state == "hunt" then
		--implement custom hero hunting here
		Murder()
	elseif state.state == "retreat" then
		behavior.generic(npcBot, state)
		if (not npcBot:IsSilenced()) then
			SpellRetreat()
		end
	elseif state.state == "finishHim" then
		behavior.generic(npcBot, state)
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