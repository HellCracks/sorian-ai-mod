do

function ExecutePlan(aiBrain)
    aiBrain:SetConstantEvaluate(false)
	local behaviors = import('/lua/ai/AIBehaviors.lua')
    WaitSeconds(1)
    if not aiBrain.BuilderManagers.MAIN.FactoryManager:HasBuilderList() then
        aiBrain:SetResourceSharing(true)
		
		local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
		
		if string.find(per, 'sorian') then
			aiBrain:SetupUnderEnergyStatTriggerSorian(0.1)
			aiBrain:SetupUnderMassStatTriggerSorian(0.1)		
		else        
			aiBrain:SetupUnderEnergyStatTrigger(0.1)
			aiBrain:SetupUnderMassStatTrigger(0.1)
		end
        
        SetupMainBase(aiBrain)
        
        # Get units out of pool and assign them to the managers
        local mainManagers = aiBrain.BuilderManagers.MAIN
        
        local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
        for k,v in pool:GetPlatoonUnits() do
            if EntityCategoryContains( categories.ENGINEER, v ) then
                mainManagers.EngineerManager:AddUnit(v)
            elseif EntityCategoryContains( categories.FACTORY * categories.STRUCTURE, v ) then
                mainManagers.FactoryManager:AddFactory( v )
            end
        end

		if string.find(per, 'sorian') then
			ForkThread(UnitCapWatchThreadSorian, aiBrain)
			ForkThread(behaviors.NukeCheck, aiBrain)
		else
			ForkThread(UnitCapWatchThread, aiBrain)
		end
    end
    if aiBrain.PBM then
        aiBrain:PBMSetEnabled(false)
    end
end

function SetupMainBase(aiBrain)
    local base, returnVal, baseType = GetHighestBuilder(aiBrain)

    local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
	ScenarioInfo.ArmySetup[aiBrain.Name].AIBase = base
    if per != 'adaptive' and per != 'sorianadaptive' then
        ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality = baseType
    end

    LOG('*AI DEBUG: ARMY ', repr(aiBrain:GetArmyIndex()), ': Initiating Archetype using ' .. base)
    AIAddBuilderTable.AddGlobalBaseTemplate(aiBrain, 'MAIN', base)
    aiBrain:ForceManagerSort()
end

#Modeled after GPGs LowMass and LowEnergy functions
function UnitCapWatchThreadSorian(aiBrain)
	#LOG('*AI DEBUG: UnitCapWatchThreadSorian started')
	while true do
		WaitSeconds(30)
		if GetArmyUnitCostTotal(aiBrain:GetArmyIndex()) > (GetArmyUnitCap(aiBrain:GetArmyIndex()) - 20) then
			local underCap = false
			
			# More than 1 T3 Power
			underCap = GetAIUnderUnitCap(aiBrain, 1, categories.TECH3 * categories.ENERGYPRODUCTION * categories.STRUCTURE, categories.TECH1 * categories.ENERGYPRODUCTION * categories.STRUCTURE * categories.DRAGBUILD)
			
			# More than 14 T3 Defense
			if underCap ~= true then
				underCap = GetAIUnderUnitCap(aiBrain, 14, categories.TECH3 * categories.DEFENSE * categories.STRUCTURE, categories.TECH1 * categories.DEFENSE * categories.STRUCTURE)
			end
			
			# More than 6 T2/T3 Engineers
			if underCap ~= true then
				underCap = GetAIUnderUnitCap(aiBrain, 6, categories.ENGINEER * (categories.TECH2 + categories.TECH3), categories.TECH1 * categories.ENGINEER)
			end
			
			# More than 9 T3 Engineers
			if underCap ~= true then
				underCap = GetAIUnderUnitCap(aiBrain, 9, categories.ENGINEER * categories.TECH3, categories.TECH2 * categories.ENGINEER - categories.ENGINEERSTATION)
			end
			
			# More than 39 T3 Land Units minus Engineers
			if underCap ~= true then
				underCap = GetAIUnderUnitCap(aiBrain, 39, categories.TECH3 * categories.MOBILE * categories.LAND - categories.ENGINEER, categories.TECH1 * categories.MOBILE * categories.LAND)
			end
			
			# More than 9 T3 Air Units minus Scouts
			if underCap ~= true then
				underCap = GetAIUnderUnitCap(aiBrain, 9, categories.TECH3 * categories.MOBILE * categories.AIR - categories.INTELLIGENCE, categories.TECH1 * categories.MOBILE * categories.AIR - categories.SCOUT)
			end
			
			# More than 9 T3 AntiAir
			if underCap ~= true then
				underCap = GetAIUnderUnitCap(aiBrain, 9, categories.TECH3 * categories.DEFENSE * categories.ANTIAIR, categories.TECH2 * categories.DEFENSE * categories.ANTIAIR)
			end
		end
	end
end

function GetAIUnderUnitCap(aiBrain, num, checkCat, killCat)
	if aiBrain:GetCurrentUnits(checkCat) > num then
		local units = aiBrain:GetListOfUnits(killCat, true)
		for k, v in units do
			v:Kill()
		end
	end
	if GetArmyUnitCostTotal(aiBrain:GetArmyIndex()) <= (GetArmyUnitCap(aiBrain:GetArmyIndex()) - 20) then
		return true
	end
	return false
end

end