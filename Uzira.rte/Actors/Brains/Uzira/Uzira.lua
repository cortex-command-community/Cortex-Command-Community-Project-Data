function Create(self)
	self.minion = CreateAHuman("Skeleton", "Uzira.rte");
	self.weapons = {"Uzira.rte/Blunderpop", "Uzira.rte/Blunderbuss", "Uzira.rte/Musket"};
	self.spawnRadius = math.max(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight) * 0.1;
	self.boundsRadius = self.spawnRadius * 4 + self.minion.Radius;
	self.spawnTerrainTolerance = 70;
	self.spawnCost = self.minion:GetGoldValue(0, 1, 1);
	
	self.baseSpawnTime = 1000;
	self.spawnTime = 1000;
	self.spawnTimer = Timer();
	self.minion.Team = self.Team;
	self.minion.PinStrength = self.minion.Mass;
	self.minion:AddScript("Uzira.rte/Actors/Shared/Undead.lua");
	self.minions = {};
	
	self.regenTimer = Timer();
	self.regenTimer:SetSimTimeLimitMS(1000);
	self.prevHealth = self.Health;
end
function Update(self)
	if self.regenTimer:IsPastSimTimeLimit() then
		if self.Health < self.MaxHealth and self.Health + 2 > self.prevHealth then
			self.Health = math.min(self.Health + 1, self.MaxHealth);
		end
		self.prevHealth = self.Health;
		self.regenTimer:Reset();
	end
	if self.spawnTimer:IsPastSimMS(self.spawnTime) then
		self.spawnTimer:Reset();
		self.spawnTime = self.baseSpawnTime;
		local funds = ActivityMan:GetActivity():GetTeamFunds(self.Team);
		local enemyCount = 0;
		for actor in MovableMan.Actors do
			if actor.Team ~= self.Team and actor.Team ~= Activity.NOTEAM and actor.ClassName ~= "ADoor" then
				enemyCount = enemyCount + 1;
			end
		end
		for i = 1, #self.minions do
			local minion = self.minions[i];
			if not MovableMan:IsActor(minion) then
				table.remove(self.minions, i);
			elseif minion.Health > 0 then
				if SceneMan:ShortestDistance(self.Pos, minion.Pos, SceneMan.SceneWrapsX).Magnitude > self.boundsRadius then
					minion.Health = minion.Health - 1;
					if minion.Health <= 0 then
						for attachable in minion.Attachables do
							if math.random() < 0.5 then
								minion:RemoveAttachable(attachable, true, true);
							end
						end
						ActivityMan:GetActivity():ReportDeath(self.Team, -1);
					end
				end
				if self:IsPlayerControlled() then
					self.playerInControl = true;
				elseif not self.playerInControl and math.random() < 0.5 and #self.minions > enemyCount and minion.AIMode ~= Actor.AIMODE_GOTO and minion.AIMode ~= Actor.AIMODE_BRAINHUNT then
					local target = MovableMan:GetClosestEnemyActor(minion.Team, minion.Pos, math.huge, Vector());
					if target then
						minion:ClearMovePath();
						minion:AddAIMOWaypoint(target);
						minion:UpdateMovePath();
					end
				end
			end
		end
		if funds > self.spawnCost then
			local spawnPos = self.Pos + Vector(0, self.Radius + RangeRand(0, self.spawnRadius)):RadRotate(RangeRand(-1, 1));
			if SceneMan:CastMaxStrengthRay(self.Pos, spawnPos, 8) < self.spawnTerrainTolerance * 2 then

				local pointCount = 10;
				local radius = self.minion.Radius/math.sqrt(pointCount);
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
					local weapon = CreateHDFirearm(self.weapons[math.random(#self.weapons)]);
					weapon.DeleteWhenRemovedFromParent = true;
					local skeleton = self.minion:Clone();
					skeleton:AddInventoryItem(weapon);
					skeleton.Pos = spawnPos;
					skeleton.HFlipped = self.HFlipped;
					skeleton.RotAngle = RangeRand(-1.5, 1.5);
					skeleton.AIMode = math.random(Actor.AIMODE_SENTRY, Actor.AIMODE_BRAINHUNT);
					if skeleton.AIMode == Actor.AIMODE_GOTO then
						local target = MovableMan:GetClosestEnemyActor(skeleton.Team, self.Pos, self.boundsRadius, Vector());
						skeleton:ClearMovePath();
						skeleton:AddAIMOWaypoint(target or self);
					end
					MovableMan:AddActor(skeleton);
					table.insert(self.minions, skeleton);
		
					ActivityMan:GetActivity():SetTeamFunds(funds - self.spawnCost, self.Team);
					self.spawnTime = self.baseSpawnTime + self.baseSpawnTime * #self.minions;
				end
			end
		end
	end
end