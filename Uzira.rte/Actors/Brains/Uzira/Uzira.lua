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
end
function Update(self)
	if self.spawnTimer:IsPastSimMS(self.spawnTime) then
		self.spawnTimer:Reset();
		self.spawnTime = self.baseSpawnTime;
		local funds = ActivityMan:GetActivity():GetTeamFunds(self.Team);
		for i = 1, #self.minions do
			local minion = self.minions[i];
			if not MovableMan:IsActor(minion) then
				table.remove(self.minions, i);
			elseif minion.Health > 0 and SceneMan:ShortestDistance(self.Pos, minion.Pos, SceneMan.SceneWrapsX).Magnitude > self.boundsRadius then
				minion.Health = 0;
				for attachable in minion.Attachables do
					if math.random() < 0.5 then
						minion:RemoveAttachable(attachable, true, true);
					end
				end
				--ActivityMan:GetActivity():ReportDeath(self.Team, -1);	--Disregard deaths of spawned minions?
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
					skeleton.AIMode = math.random(Actor.AIMODE_SENTRY, Actor.AIMODE_GOTO);
					if skeleton.AIMode == Actor.AIMODE_GOTO then
						local target = MovableMan:GetClosestEnemyActor(skeleton.Team, self.Pos, self.boundsRadius * 0.5, Vector());
						skeleton:AddAIMOWaypoint(target or self);
					end
					MovableMan:AddActor(skeleton);
					skeleton.Status = Actor.UNSTABLE;
					table.insert(self.minions, skeleton);
		
					ActivityMan:GetActivity():SetTeamFunds(funds - self.spawnCost, self.Team);
					self.spawnTime = self.baseSpawnTime + self.baseSpawnTime * #self.minions;
				end
			end
		end
	end
end