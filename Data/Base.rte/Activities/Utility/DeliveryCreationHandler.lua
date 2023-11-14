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
	
	self.teamTechTable = {};
	self.teamTechIDTable = {};
	
	for i = 0, self.Activity.TeamCount do
		self.teamTechTable[i] = self.Activity:GetTeamTech(i);
		self.teamTechIDTable[i] = PresetMan:GetModuleID(self.teamTechTable[i]);
	end
	
end

function DeliveryCreationHandler:CreateCrab(team)
	local actor = RandomACrab("Actors - Mecha", self.teamTechTable[team]);
	if actor then
		actor.AIMode = Actor.AIMODE_BRAINHUNT;
		actor.Team = team;
		return actor;
	end
end

function DeliveryCreationHandler:CreateRandomInfantry(team)
	local actor = RandomAHuman("Any", self.teamTechTable[team]);
	if actor then
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Primary", self.teamTechTable[team]));
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.teamTechTable[team]));

		local rand = math.random();
		if rand < 0.25 then
			actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", self.teamTechTable[team]));
		elseif rand < 0.50 then
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.teamTechTable[team]));
		elseif rand < 0.75 then
			actor:AddInventoryItem(RandomHeldDevice("Shields", self.teamTechTable[team]));
		else
			actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
		end
		if math.random() < 0.1 then
			if math.random() < 0.75 then
				actor:AddInventoryItem(RandomHDFirearm("Tools - Breaching", self.teamTechTable[team]));
			else
				actor:AddInventoryItem(RandomTDExplosive("Tools - Breaching", self.teamTechTable[team]));
			end
		end

		actor.AIMode = Actor.AIMODE_BRAINHUNT;
		actor.Team = team;
		return actor;
	end
end

function DeliveryCreationHandler:CreateLightInfantry(team)
	local actor = RandomAHuman("Actors - Light", self.teamTechTable[team]);
	if actor.ModuleID ~= self.teamTechIDTable[team] then
		actor = RandomAHuman("Actors", self.teamTechIDTable[team]);
	end

	if actor then
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", self.teamTechTable[team]));

		local rand = math.random();
		if rand < 0.33 then
			actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", self.teamTechTable[team]));
		elseif rand < 0.66 then
			actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
		else
			if math.random() < 0.75 then
				actor:AddInventoryItem(RandomHDFirearm("Tools - Breaching", self.teamTechTable[team]));
			else
				actor:AddInventoryItem(RandomTDExplosive("Tools - Breaching", self.teamTechTable[team]));
			end
		end

		actor.AIMode = Actor.AIMODE_BRAINHUNT;
		actor.Team = team;
		return actor;
	end
end

function DeliveryCreationHandler:CreateHeavyInfantry(team)
	local actor = RandomAHuman("Actors - Heavy", self.teamTechTable[team]);
	if actor.ModuleID ~= self.teamTechIDTable[team] then
		actor = RandomAHuman("Actors", self.teamTechIDTable[team]);
	end

	if actor then
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Heavy", self.teamTechTable[team]));

		if math.random() < 0.3 then
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", self.teamTechTable[team]));
			if math.random() < 0.25 then
				actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", self.teamTechTable[team]));
			elseif math.random() < 0.35 then
				actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
			end
		else
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.teamTechTable[team]));
			if math.random() < 0.3 then
				actor:AddInventoryItem(RandomHeldDevice("Shields", self.teamTechTable[team]));
				actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
			else
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.teamTechTable[team]));
			end
		end

		actor.AIMode = Actor.AIMODE_BRAINHUNT;
		actor.Team = team;
		return actor;
	end
end

function DeliveryCreationHandler:CreateMediumInfantry(team)
	local actor = RandomAHuman("Actors - Heavy", self.teamTechTable[team]);
	if actor.ModuleID ~= self.teamTechIDTable[team] then
		actor = RandomAHuman("Actors", self.teamTechIDTable[team]);
	end

	if actor then
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", self.teamTechTable[team]));
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.teamTechTable[team]));

		if math.random() < 0.3 then
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.teamTechTable[team]));
		else
			actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", self.teamTechTable[team]));
		end
		if math.random() < 0.5 then
			actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
		end
		if math.random() < 0.1 then
			if math.random() < 0.75 then
				actor:AddInventoryItem(RandomHDFirearm("Tools - Breaching", self.teamTechTable[team]));
			else
				actor:AddInventoryItem(RandomTDExplosive("Tools - Breaching", self.teamTechTable[team]));
			end
		end

		actor.AIMode = Actor.AIMODE_BRAINHUNT;
		actor.Team = team;
		return actor;
	end
end

function DeliveryCreationHandler:CreateScoutInfantry(team)
	local actor = RandomAHuman("Actors - Light", self.teamTechTable[team]);
	if actor.ModuleID ~= self.teamTechIDTable[team] then
		actor = RandomAHuman("Actors", self.teamTechIDTable[team]);
	end

	if actor then
		if math.random() < 0.15 then
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Sniper", self.teamTechTable[team]));
		end
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.teamTechTable[team]));

		if math.random() < 0.3 then
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.teamTechTable[team]));
		else
			actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", self.teamTechTable[team]));
			actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
		end

		actor.AIMode = Actor.AIMODE_BRAINHUNT;
		actor.Team = team;
		return actor;
	end
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
		if infantryType then
			actor = self:CreateInfantry(team, infantryType);
		elseif math.random() < crabToHumanSpawnRatio then
			actor = self:CreateCrab(team);
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

function DeliveryCreationHandler:CreateSquadWithCraft(team, forceRocketUsage, squadCount, squadType)

	local craft = forceRocketUsage and RandomACRocket("Craft", self.teamTechTable[team]) or RandomACDropShip("Craft", self.teamTechTable[team]);
	if not craft or craft.MaxInventoryMass <= 0 then
		craft = forceRocketUsage and RandomACRocket("Craft", "Base.rte") or RandomACDropShip("Craft", "Base.rte");
	end
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

return DeliveryCreationHandler:Create();