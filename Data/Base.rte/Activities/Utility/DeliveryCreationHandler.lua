--------------------------------------- Instructions ---------------------------------------

--

--------------------------------------- Misc. Information ---------------------------------------

--




local DeliveryCreationHandler = {};

function DeliveryCreationHandler:Create()
	local Members = {};

	setmetatable(Members, self);
	self.__index = self;

	return Members;
end

function DeliveryCreationHandler:Initialize(activity)
	
	print("DeliveryCreationHandlerinited")
	
	self.Activity = activity;
	
	self.infantryTypeFunctionTable = {};
	self.infantryTypeFunctionTable.Light = self.CreateLightInfantry;
	self.infantryTypeFunctionTable.Medium = self.CreateMediumInfantry;
	self.infantryTypeFunctionTable.Heavy = self.CreateHeavyInfantry;
	self.infantryTypeFunctionTable.CQB = self.CreateCQBInfantry;
	self.infantryTypeFunctionTable.Scout = self.CreateScoutInfantry;
	self.infantryTypeFunctionTable.Sniper = self.CreateSniperInfantry;
	self.infantryTypeFunctionTable.Grenadier = self.CreateGrenadierInfantry;
	self.infantryTypeFunctionTable.Engineer = self.CreateEngineerInfantry;
	
	self.indexedInfantryTypeFunctionTable = {};

	for k, v in pairs(self.infantryTypeFunctionTable) do
		table.insert(self.indexedInfantryTypeFunctionTable, v);
	end
	
	self.teamTechTable = {};
	self.teamTechIDTable = {};
	
	self.teamExtraItemChances = {};
	
	for i = 0, self.Activity.TeamCount - 1 do
		local moduleID = PresetMan:GetModuleID(self.Activity:GetTeamTech(i));
		self.teamTechTable[i] = PresetMan:GetDataModule(moduleID);
		self.teamTechIDTable[i] = moduleID;
		
		self.teamExtraItemChances[i] = {};
		self.teamExtraItemChances[i].Medikit = 0.5;
		self.teamExtraItemChances[i].BreachingTool = 0.25;
		self.teamExtraItemChances[i].Grenade = 0.25;
		self.teamExtraItemChances[i].Digger = 0.15;
			
	end
	
	-- Commence painful setting up of preset lists
	
	self.teamPresetTables = {};
	
	-- Base module items too
	-- If the player tries to set the tech of team -1 and this goes wonky as a result
	-- it's his own damn fault

	for module in PresetMan.Modules do
		if module.FileName == "Base.rte" then
			self.teamTechTable[-1] = module;
			self.teamTechIDTable[-1] = PresetMan:GetModuleID(module.FileName);
		end
	end
	
	for team, module in pairs(self.teamTechTable) do
	
		self.teamPresetTables[team] = {};
		
		self.teamPresetTables[team]["Craft - Dropships"] = {};
		self.teamPresetTables[team]["Craft - Rockets"] = {};
		
		self.teamPresetTables[team]["Weapons - Primary"] = {};
		self.teamPresetTables[team]["Weapons - Secondary"] = {};
		self.teamPresetTables[team]["Weapons - Light"] = {};
		self.teamPresetTables[team]["Weapons - Heavy"] = {};
		self.teamPresetTables[team]["Weapons - Sniper"] = {};
		self.teamPresetTables[team]["Weapons - CQB"] = {};
		self.teamPresetTables[team]["Weapons - Explosive"] = {};
		
		self.teamPresetTables[team]["Shields"] = {};

		self.teamPresetTables[team]["Bombs"] = {};	
		self.teamPresetTables[team]["Bombs - Grenades"] = {};
		
		self.teamPresetTables[team]["Tools"] = {};
		self.teamPresetTables[team]["Tools - Diggers"] = {};
		self.teamPresetTables[team]["Tools - Breaching"] = {};
		
		self.teamPresetTables[team]["Actors - AHuman"] = {};
		self.teamPresetTables[team]["Actors - ACrab"] = {};
		self.teamPresetTables[team]["Actors - Light"] = {};
		self.teamPresetTables[team]["Actors - Heavy"] = {};
		self.teamPresetTables[team]["Actors - Mecha"] = {};
		self.teamPresetTables[team]["Actors - Turrets"] = {};
		
		for entity in module.Presets do
			if IsMOSRotating(entity) and ToMOSRotating(entity).IsBuyable then
			
				local entityInfoTable = {};
			
				for group in entity.Groups do
					if self.teamPresetTables[team][group] then
						entityInfoTable.PresetName = entity.PresetName;
						entityInfoTable.ClassName = entity.ClassName;
						table.insert(self.teamPresetTables[team][group], entityInfoTable);
					end
				end
				
				if IsAHuman(entity) then
					entityInfoTable.PresetName = entity.PresetName;
					entityInfoTable.ClassName = entity.ClassName;
					table.insert(self.teamPresetTables[team]["Actors - AHuman"], entityInfoTable);
				elseif IsACrab(entity) then
					entityInfoTable.PresetName = entity.PresetName;
					entityInfoTable.ClassName = entity.ClassName;
					table.insert(self.teamPresetTables[team]["Actors - ACrab"], entityInfoTable);	
				elseif IsACDropShip(entity) then
					entityInfoTable.PresetName = entity.PresetName;
					entityInfoTable.ClassName = entity.ClassName;
					table.insert(self.teamPresetTables[team]["Craft - Dropships"], entityInfoTable);
					print("found dropship:")
					print(entity)
				elseif IsACRocket(entity) then
					print("found acrocket:")
					print(entity)
					entityInfoTable.PresetName = entity.PresetName;
					entityInfoTable.ClassName = entity.ClassName;
					table.insert(self.teamPresetTables[team]["Craft - Rockets"], entityInfoTable);	
				end
				
			end
		end
	end
	
end

function DeliveryCreationHandler:CheckTwoGroupIntersections(team, group1, group2, returnRandomSelection)

	local groupTable1 = self.teamPresetTables[team][group1];
	local groupTable2 = self.teamPresetTables[team][group2];
	
	local intersectedPresetNameTable = {};
	
	for k1, v1 in pairs(groupTable1) do
		for k2, v2 in pairs(groupTable2) do
			if v1.PresetName == v2.PresetName then
				table.insert(intersectedPresetNameTable, v1);
			end
		end
	end
	
	if #intersectedPresetNameTable > 0 then	
		if returnRandomSelection then
			return intersectedPresetNameTable[math.random(1, #intersectedPresetNameTable)];
		else
			return intersectedPresetNameTable;
		end
	else
		return false;
	end
	
end

function DeliveryCreationHandler:GiveActorRandomAdditions(team, actor, multiplier)

	-- Random additions based on team-wide chances, multiplied by magic numbers for each infantry type
	-- Given chances low enough, an infantry type can have an addition disabled

	local rand = math.random();
	if rand < self.teamExtraItemChances[team].Grenade * multiplier then
		actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", self.teamTechTable[team].FileName))
		return;
	end
	
	if rand < self.teamExtraItemChances[team].Medikit * multiplier then
		actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
		return;
	end
	
	if rand < self.teamExtraItemChances[team].Digger * multiplier then
		presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Tools - Diggers", "Tools - Diggers", "Tools - Diggers", "Tools - Diggers");
		
		local weapon = _G[createFunc](presetName, techName);
		actor:AddInventoryItem(weapon)
		return;
	end
	
	if rand < self.teamExtraItemChances[team].BreachingTool * multiplier then
		if math.random() < 0.75 then
			actor:AddInventoryItem(RandomHDFirearm("Tools - Breaching", self.teamTechTable[team].FileName));
		else
			actor:AddInventoryItem(RandomTDExplosive("Tools - Breaching", self.teamTechTable[team].FileName));
		end
	end
	
end

function DeliveryCreationHandler:SelectPresetByGroupPair(team, primaryGroup, secondaryGroup, fallbackGroup, baseFallbackGroup)

	-- This will attempt to find one preset of both groups
	-- Then one preset of the primary group
	-- Then one preset of the secondary group, etc.
	
	-- Having one of the later groups be the same as an earlier group will in practice
	-- skip that step
	
	local actingTech = self.teamTechTable[team];
	
	local presetTable = self:CheckTwoGroupIntersections(team, primaryGroup, secondaryGroup, true)
	if not presetTable then
		actingTech = self.teamTechTable[team];
		actingGroupTable = self.teamPresetTables[team][primaryGroup];
		
		if #actingGroupTable == 0 then
			actingGroupTable = self.teamPresetTables[team][secondaryGroup];
		end
		if #actingGroupTable == 0 then
			actingGroupTable = self.teamPresetTables[team][fallbackGroup];
		end
		if #actingGroupTable == 0 then
			-- Base.rte has to have something, we are in trouble otherwise
			actingGroupTable = self.teamPresetTables[-1][baseFallbackGroup];
			actingTech = self.teamTechTable[-1];
		end
		
		presetTable = actingGroupTable[math.random(1, #actingGroupTable)];
	end
	
	local presetName = presetTable.PresetName;
	local className = presetTable.ClassName;
	local createFunc = "Create" .. className;	
	local techName = actingTech.FileName;
	
	
	print(presetName)
	print(createFunc)
	print(techName)
	print("FALLBACK GROUP: " .. baseFallbackGroup); 
	
	return presetName, createFunc, techName;

end

function DeliveryCreationHandler:CreateCrab(team)
	local actor = RandomACrab("Actors - Mecha", self.teamTechTable[team].FileName);
	if actor then
		actor.AIMode = Actor.AIMODE_BRAINHUNT;
		actor.Team = team;
		return actor;
	end
end

function DeliveryCreationHandler:CreateRandomInfantry(team)

	-- just pick one lol
	
	self.infantryFunc = self.indexedInfantryTypeFunctionTable[math.random(1, #self.indexedInfantryTypeFunctionTable)];
	actor = self:infantryFunc(team);
	
	return actor;
	
end

function DeliveryCreationHandler:CreateLightInfantry(team)
	
	local presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Actors - Light", "Actors - AHuman", "Actors - AHuman", "Actors - AHuman");
	local actor = _G[createFunc](presetName, techName);
	
	-- Weapons
	
	-- Primary light
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - Light", "Weapons - Primary", "Weapons - Primary", "Weapons - Primary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	-- Secondary light
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - Secondary", "Weapons - Light", "Weapons - Secondary", "Weapons - Secondary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	self:GiveActorRandomAdditions(team, actor, 1.5);

	actor.AIMode = Actor.AIMODE_BRAINHUNT;
	actor.Team = team;
	return actor;
	
end

function DeliveryCreationHandler:CreateHeavyInfantry(team)
	
	local presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Actors - Heavy", "Actors - AHuman", "Actors - AHuman", "Actors - AHuman");
	local actor = _G[createFunc](presetName, techName);
	
	-- Weapons
	
	-- Primary heavy
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - Heavy", "Weapons - Primary", "Weapons - Primary", "Weapons - Primary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	-- Secondary
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - Secondary", "Weapons - Secondary", "Weapons - Secondary", "Weapons - Secondary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	if math.random() < 0.1 then
		-- Extra shield
		presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Shields", "Shields", "Shields", "Shields");
		
		local shield = _G[createFunc](presetName, techName);
		actor:AddInventoryItem(shield)
	end
	
	self:GiveActorRandomAdditions(team, actor, 1);

	actor.AIMode = Actor.AIMODE_BRAINHUNT;
	actor.Team = team;
	return actor;
	
end

function DeliveryCreationHandler:CreateMediumInfantry(team)
	
	local presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Actors - Heavy", "Actors - AHuman", "Actors - AHuman", "Actors - AHuman");
	local actor = _G[createFunc](presetName, techName);
	
	-- Weapons
	
	-- Primary light
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - Light", "Weapons - Primary", "Weapons - Primary", "Weapons - Primary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	-- Secondary
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - Secondary", "Weapons - Secondary", "Weapons - Secondary", "Weapons - Secondary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	self:GiveActorRandomAdditions(team, actor, 1);

	actor.AIMode = Actor.AIMODE_BRAINHUNT;
	actor.Team = team;
	return actor;
	
end

function DeliveryCreationHandler:CreateCQBInfantry(team)
	
	local actorGroup = math.random() < 0.5 and "Actors - Heavy" or "Actors - Light";
	local presetName, createFunc, techName = self:SelectPresetByGroupPair(team, actorGroup, "Actors - AHuman", "Actors - AHuman", "Actors - AHuman");
	local actor = _G[createFunc](presetName, techName);
	
	-- Weapons
	
	-- Primary CQB
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - CQB", "Weapons - Primary", "Weapons - Primary", "Weapons - Primary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	-- Secondary
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - Secondary", "Weapons - Secondary", "Weapons - Secondary", "Weapons - Secondary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	-- Extra breaching tool
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Tools - Breaching", "Tools - Breaching", "Tools - Breaching", "Tools - Breaching");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	self:GiveActorRandomAdditions(team, actor, 1);

	actor.AIMode = Actor.AIMODE_BRAINHUNT;
	actor.Team = team;
	return actor;
	
end

function DeliveryCreationHandler:CreateScoutInfantry(team)
	local presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Actors - Light", "Actors - AHuman", "Actors - AHuman", "Actors - AHuman");
	local actor = _G[createFunc](presetName, techName);
	
	-- Weapons
	
	-- Secondary
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - Secondary", "Weapons - Secondary", "Weapons - Secondary", "Weapons - Secondary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	-- Extra medikit
	actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
	
	self:GiveActorRandomAdditions(team, actor, 1.7);

	actor.AIMode = Actor.AIMODE_BRAINHUNT;
	actor.Team = team;
	return actor;
end

function DeliveryCreationHandler:CreateSniperInfantry(team)
	
	local actorGroup = math.random() < 0.25 and "Actors - Heavy" or "Actors - Light";
	local presetName, createFunc, techName = self:SelectPresetByGroupPair(team, actorGroup, "Actors - AHuman", "Actors - AHuman", "Actors - AHuman");
	local actor = _G[createFunc](presetName, techName);
	
	-- Weapons
	
	-- Primary Sniper
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - Sniper", "Weapons - Primary", "Weapons - Primary", "Weapons - Primary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	-- Secondary
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - Secondary", "Weapons - Secondary", "Weapons - Secondary", "Weapons - Secondary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	self:GiveActorRandomAdditions(team, actor, 1);

	actor.AIMode = Actor.AIMODE_BRAINHUNT;
	actor.Team = team;
	return actor;
	
end

function DeliveryCreationHandler:CreateGrenadierInfantry(team)
	local actorGroup = math.random() < 0.5 and "Actors - Heavy" or "Actors - Light";
	local presetName, createFunc, techName = self:SelectPresetByGroupPair(team, actorGroup, "Actors - AHuman", "Actors - AHuman", "Actors - AHuman");
	local actor = _G[createFunc](presetName, techName);
	
	-- Weapons
	
	-- Primary explosive
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - Explosive", "Weapons - Primary", "Weapons - Primary", "Weapons - Primary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	-- Secondary explosive (like the imperatus one!)
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - Secondary", "Weapons - Explosive", "Weapons - Secondary", "Weapons - Secondary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	-- Extra grenade
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Bombs - Grenades", "Bombs - Grenades", "Bombs - Grenades", "Bombs - Grenades");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	self:GiveActorRandomAdditions(team, actor, 0.75);

	actor.AIMode = Actor.AIMODE_BRAINHUNT;
	actor.Team = team;
	return actor;
end

function DeliveryCreationHandler:CreateEngineerInfantry(team)

	local presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Actors - Light", "Actors - AHuman", "Actors - AHuman", "Actors - AHuman");
	local actor = _G[createFunc](presetName, techName);
	
	-- Weapons
	
	-- Primary light
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Weapons - Primary", "Weapons - Light", "Weapons - Primary", "Weapons - Primary");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	-- Digger
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Tools - Diggers", "Tools - Diggers", "Tools - Diggers", "Tools - Diggers");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	-- Breaching tool
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, "Tools - Breaching", "Tools - Breaching", "Tools - Breaching", "Tools - Breaching");
	
	local weapon = _G[createFunc](presetName, techName);
	actor:AddInventoryItem(weapon)
	
	-- No additions
	--self:GiveActorRandomAdditions(team, actor, 0.75);

	actor.AIMode = Actor.AIMODE_BRAINHUNT;
	actor.Team = team;
	return actor;
end

function DeliveryCreationHandler:CreateSquad(team, squadCount, squadType)

	local squadTable = {};
	local goldCost = 0;
	
	local crabToHumanSpawnRatio = self.Activity:GetCrabToHumanSpawnRatio(self.teamTechIDTable[team]);
	
	if squadCount == nil then
		squadCount = math.random(2, 3);
	end

	for i = 1, squadCount do
		local actor;
		if squadType then
			self.infantryFunc = self.infantryTypeFunctionTable[squadType];
			actor = self:infantryFunc(team);
		elseif math.random() < crabToHumanSpawnRatio then
			-- TODO make crabs not suck
			--actor = self:CreateCrab(team);
			actor = self:CreateRandomInfantry(team);
		else
			actor = self:CreateRandomInfantry(team);
		end
		if actor then
			table.insert(squadTable, actor)
			goldCost = goldCost + ToSceneObject(actor):GetTotalValue(self.teamTechIDTable[team], 1);
		end
	end
	
	--print("buydoor goldcost: " .. goldCost);
	return squadTable, goldCost

end

function DeliveryCreationHandler:CreateEliteSquad(team, squadCount, squadType)

	local squadTable, goldCost = self:CreateSquad(team, squadCount, squadType)
	
	for k, actor in pairs(squadTable) do
		actor:SetNumberValue("AIAimSpeed", 0.04);
		actor:SetNumberValue("AIAimSkill", 0.04);
		actor:SetNumberValue("AISkill", 100);
		actor.MaxHealth = actor.MaxHealth * 1.25;
		actor.Health = actor.MaxHealth;
	end
	
	return squadTable, goldCost
	
end

function DeliveryCreationHandler:CreateSquadWithCraft(team, forceRocketUsage, squadCount, squadType)

	local craftGroup = "Craft - Dropships";
	presetName, createFunc, techName = self:SelectPresetByGroupPair(team, craftGroup, craftGroup, craftGroup, craftGroup);
	
	local craft = _G[createFunc](presetName, techName);
	print(craft)
	craft.Team = team;
	
	local squad = self:CreateSquad(team, squadCount, squadType);
	for i = 1, #squad do
		craft:AddInventoryItem(squad[i]);
		if craft.InventoryMass > craft.MaxInventoryMass then
			break;
		end
	end
	
	local goldCost = ToSceneObject(craft):GetTotalValue(self.teamTechIDTable[team], 1);
	
	return craft, squad, goldCost
end

function DeliveryCreationHandler:CreateEliteSquadWithCraft(team, forceRocketUsage, squadCount, squadType)

	local craft, squad, goldCost = self:CreateSquadWithCraft(team, forceRocketUsage, squadCount, squadType)
	
	for k, actor in pairs(squad) do
		actor:SetNumberValue("AIAimSpeed", 0.04);
		actor:SetNumberValue("AIAimSkill", 0.04);
		actor:SetNumberValue("AISkill", 100);
		actor.MaxHealth = actor.MaxHealth * 1.25;
		actor.Health = actor.MaxHealth;
	end
	
	return craft, squad, goldCost
end

return DeliveryCreationHandler:Create();