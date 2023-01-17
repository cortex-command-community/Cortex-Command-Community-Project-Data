local setupMinionAIMode = function(self, minion)
	if self.minionsShouldGather then
		minion.AIMode = Actor.AIMODE_GOTO;
		minion:ClearMovePath();
		minion:AddAIMOWaypoint(self);
	else
		minion.AIMode = Actor.AIMODE_SENTRY;
		if math.random() < 0.25 then
			minion.AIMode = Actor.AIMODE_PATROL;
		elseif math.random() < 0.1 then
			local target = MovableMan:GetClosestEnemyActor(minion.Team, self.Pos, self.enemySearchRadius, Vector());
			if target then
				minion.AIMode = Actor.AIMODE_GOTO;
				minion:ClearMovePath();
				minion:AddAIMOWaypoint(target);
			end
		elseif math.random() < 0.1 then
			minion.AIMode = Actor.AIMODE_BRAINHUNT;
		end
	end
end

local handleMinionSpawning = function(self)
	if self.spawnTimer:IsPastSimTimeLimit() then
		self.spawnTimer:Reset();
		self.spawnTimer:SetSimTimeLimitMS(self.baseSpawnTime);
		local funds = ActivityMan:GetActivity():GetTeamFunds(self.Team);
		local enemyCount = 0;
		if funds > self.spawnCost then
			local spawnPos = self.Pos + Vector(0, self.Radius + RangeRand(0, self.spawnRadius)):RadRotate(RangeRand(-1, 1));
			if SceneMan:CastMaxStrengthRay(self.Pos, spawnPos, 8) < self.spawnTerrainTolerance * 2 then

				local pointCount = 10;
				local radius = self.minionTemplate.Radius/math.sqrt(pointCount);
				local totalSurroundingTerrain = 0;
				local totalTolerance = self.spawnTerrainTolerance * pointCount;
				
				for i = 0, pointCount do
					local checkPos = spawnPos + Vector(math.sqrt(i) * radius, 0):RadRotate(i * 2.39996);
					local terrCheck = SceneMan:GetTerrMatter(checkPos.X, checkPos.Y);
					if terrCheck == rte.airID then
						totalSurroundingTerrain = totalSurroundingTerrain + self.spawnTerrainTolerance * 2;	--Treat air as unsuitable terrain to spawn from
					else
						totalSurroundingTerrain = totalSurroundingTerrain + SceneMan:GetMaterialFromID(terrCheck).StructuralIntegrity;
					end
					if totalSurroundingTerrain > totalTolerance then
						break;
					end
				end
				if totalSurroundingTerrain < totalTolerance then
					local weapon = self.weapons[math.random(#self.weapons)]:Clone();
					weapon.DeleteWhenRemovedFromParent = true;
					
					local newMinion = self.minionTemplate:Clone();
					newMinion:AddInventoryItem(weapon);
					newMinion.Pos = spawnPos;
					newMinion.HFlipped = self.HFlipped;
					newMinion.RotAngle = RangeRand(-1.5, 1.5);
					self:setupMinionAIMode(newMinion);
					MovableMan:AddActor(newMinion);
					table.insert(self.minions, newMinion);
		
					ActivityMan:GetActivity():SetTeamFunds(funds - self.spawnCost, self.Team);
					self.spawnTimer:SetSimTimeLimitMS(self.baseSpawnTime * #self.minions);
				end
			end
		end
	end
end

local cleanupDeadMinions = function(self)
	for i = 1, #self.minions do
		if not MovableMan:IsActor(self.minions[i]) or self.minions[i].Health <= 0 then
			table.remove(self.minions, i);
		end
	end
	for i = 1, #self.frenziedMinions do
		if not MovableMan:IsActor(self.frenziedMinions[i]) or self.frenziedMinions[i].Health <= 0 then
			table.remove(self.frenziedMinions, i);
		end
	end
end

local updateMinions = function(self)
	self:cleanupDeadMinions();
	
	local enemyCount = 0;
	for actor in MovableMan.Actors do
		if actor.Team ~= self.Team and actor.Team ~= Activity.NOTEAM and (actor.ClassName == "AHuman" or actor.ClassName == "ACrab") then
			enemyCount = enemyCount + 1;
		end
	end
	
	for i = 1, #self.minions do
		local minion = self.minions[i];
		
		if SceneMan:ShortestDistance(self.Pos, minion.Pos, SceneMan.SceneWrapsX).Magnitude > self.minionDecayRadius then
			minion.Health = minion.Health - 1;
			if minion.Health <= 0 or math.random() < ((1 - (minion.Health / minion.MaxHealth)) * 0.1) then
				for attachable in minion.Attachables do
					if math.random() < 0.5 then
						minion:RemoveAttachable(attachable, true, true);
						if minion.Health > 0 then
							break;
						end
					end
				end
				if minion.Health <= 0 then
					ActivityMan:GetActivity():ReportDeath(self.Team, -1);
				end
			end
		end
		
		if self.isAITeam and #self.minions > enemyCount and self.minionFrenzyTimer:IsPastSimTimeLimit() then
			self:frenzyMinions();
			self.minionFrenzyTimer:Reset();
		end
	end
end

local updateFrenziedMinions = function(self)
	for i = 1, #self.frenziedMinions do
		local frenziedMinion = self.frenziedMinions[i];
		local isBrainhunting = frenziedMinion.AIMode == Actor.AIMODE_BRAINHUNT;
		
		if math.random() < 0.25 then
			frenziedMinion.AIMode = isBrainhunting and Actor.AIMODE_GOTO or Actor.AIMODE_BRAINHUNT;
			isBrainhunting = not isBrainhunting;
			if not isBrainhunting then
				local target = MovableMan:GetClosestEnemyActor(frenziedMinion.Team, self.Pos, self.enemySearchRadius, Vector());
				if target then
					frenziedMinion.AIMode = Actor.AIMODE_GOTO;
					frenziedMinion:AddAIMOWaypoint(target);
				else
					frenziedMinion.AIMode = Actor.AIMODE_BRAINHUNT;
				end
			end
		end
		if not isBrainhunting then
			if not frenziedMinion.MOMoveTarget or not MovableMan:IsActor(frenziedMinion.MOMoveTarget) then
				frenziedMinion.AIMode = Actor.AIMODE_BRAINHUNT;
				isBrainhunting = true;
			end
		end
	end
end

function Create(self)
	self.setupMinionAIMode = setupMinionAIMode;
	self.handleMinionSpawning = handleMinionSpawning;
	self.cleanupDeadMinions = cleanupDeadMinions;
	self.updateMinions = updateMinions;
	self.updateFrenziedMinions = updateFrenziedMinions;

	self.isAITeam = not ActivityMan:GetActivity():PlayerHuman(self:GetController().Player);
	if self.isAITeam then
		self.enableMinionSpawning = true;
		self:RemoveNumberValue("EnableNecromancy");
		self.minionsShouldGather = false;
		self:RemoveNumberValue("MinionsGather");
	end

	self.minionTemplate = CreateAHuman("Skeleton", "Uzira.rte");
	self.minionTemplate.Team = self.Team;
	self.minionTemplate.HUDVisible = false;
	self.minionTemplate.PlayerControllable = false;
	-- TODO minions need to be unselectable when swapping actors!
	self.minionTemplate.PinStrength = self.minionTemplate.Mass;
	self.minionTemplate:AddScript("Uzira.rte/Actors/Shared/Undead.lua");

	self.weapons = {CreateHDFirearm("Blunderpop", "Uzira.rte"), CreateHDFirearm("Blunderbuss", "Uzira.rte"), CreateHDFirearm("Musket", "Uzira.rte"), CreateHDFirearm("Boomstick", "Uzira.rte"), CreateHDFirearm("Crossbow", "Uzira.rte")};
	
	self.spawnRadius = math.max(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight) * 0.1;
	self.minionDecayRadius = self.spawnRadius * 4 + self.minionTemplate.Radius;
	self.enemySearchRadius = self.minionDecayRadius;
	self.spawnTerrainTolerance = 70;
	self.spawnCost = self.minionTemplate:GetGoldValue(0, 1, 1);
	
	self.minions = {};
	self.frenziedMinions = {};

	self.spawnTimer = Timer();
	self.baseSpawnTime = 1000;
	self.spawnTimer:SetSimTimeLimitMS(self.baseSpawnTime);
	
	self.updateMinionTimer = Timer();
	self.updateMinionTimer:SetSimTimeLimitMS(500);
	
	self.minionFrenzyTimer = Timer();
	self.minionFrenzyTimer:SetSimTimeLimitMS(60000);
	
	self.regenTimer = Timer();
	self.regenTimer:SetSimTimeLimitMS(1000);
	self.prevHealth = self.Health;
	
	self.minionManagementSubPieMenu = self.PieMenu:GetFirstPieSliceByPresetName("MinionManagement").SubPieMenu;
	self.minionManagementPieSliceTemplates = {
		EnableMinionSpawning = CreatePieSlice("EnableMinionSpawning", "Uzira.rte"),
		DisableMinionSpawning = CreatePieSlice("DisableMinionSpawning", "Uzira.rte"),
		MinionsGather = CreatePieSlice("MinionsGather", "Uzira.rte"),
		MinionsStandby = CreatePieSlice("MinionsStandby", "Uzira.rte"),
	};
	self.minionsFrenzyPieSlice = self.minionManagementSubPieMenu:GetFirstPieSliceByPresetName("MinionsFrenzy");
	self.minionsFrenzyPieSliceDescriptions = {[false] = "I Must Recharge My Powers!", [true] = self.minionsFrenzyPieSlice.Description};
end

function Update(self)
	if self.regenTimer:IsPastSimTimeLimit() then
		if self.Health < self.MaxHealth and self.Health + 2 > self.prevHealth then
			self.Health = math.min(self.Health + 1, self.MaxHealth);
		end
		self.prevHealth = self.Health;
		self.regenTimer:Reset();
	end
	
	if self:NumberValueExists("EnableMinionSpawning") then
		self.enableMinionSpawning = self:GetNumberValue("EnableMinionSpawning") ~= 0;
		self:RemoveNumberValue("EnableMinionSpawning");
		
		local sliceNameToRemove = self.enableMinionSpawning and "EnableMinionSpawning" or "DisableMinionSpawning";
		local sliceNameToAdd = self.enableMinionSpawning and "DisableMinionSpawning" or "EnableMinionSpawning";
		self.minionManagementSubPieMenu:RemovePieSlicesByPresetName(sliceNameToRemove);
		self.minionManagementSubPieMenu:AddPieSliceIfPresetNameIsUnique(self.minionManagementPieSliceTemplates[sliceNameToAdd]:Clone(), self);
	end
	
	if self:NumberValueExists("MinionsGather") then
		self.minionsShouldGather = self:GetNumberValue("MinionsGather") ~= 0;
		self:RemoveNumberValue("MinionsGather");
		
		local sliceNameToRemove = self.minionsShouldGather and "MinionsGather" or "MinionsStandby";
		local sliceNameToAdd = self.minionsShouldGather and "MinionsStandby" or "MinionsGather";
		self.minionManagementSubPieMenu:RemovePieSlicesByPresetName(sliceNameToRemove);
		self.minionManagementSubPieMenu:AddPieSliceIfPresetNameIsUnique(self.minionManagementPieSliceTemplates[sliceNameToAdd]:Clone(), self);
		
		self:cleanupDeadMinions();
		for i = 1, #self.minions do
			self:setupMinionAIMode(self.minions[i]);
		end
	end
	
	if self.minionsFrenzyPieSlice.Enabled ~= self.minionFrenzyTimer:IsPastSimTimeLimit() then
		self.minionsFrenzyPieSlice.Enabled = self.minionFrenzyTimer:IsPastSimTimeLimit();
		self.minionsFrenzyPieSlice.Description = self.minionsFrenzyPieSliceDescriptions[self.minionsFrenzyPieSlice.Enabled];
	end
	
	if self:NumberValueExists("MinionsFrenzy") then
		self:RemoveNumberValue("MinionsFrenzy");
		self.minionFrenzyTimer:Reset();
	
		self:cleanupDeadMinions();
		for i = 1, #self.minions do
			self.frenziedMinions[#self.frenziedMinions + 1] = self.minions[i];
			
			--TODO give frenzied minions eyetrails or glows or something, and buffs
		end
		self.minions = {};
		self:updateFrenziedMinions();
	end
	
	if self.enableMinionSpawning then
		self:handleMinionSpawning();
	else
		self.spawnTimer:Reset();
	end
	
	if self.updateMinionTimer:IsPastSimTimeLimit() then
		self.updateMinionTimer:Reset();
		self:updateMinions();
		self:updateFrenziedMinions();
	end
end