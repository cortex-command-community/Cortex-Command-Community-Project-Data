function Create(self)
	self.minion = CreateAHuman("Skeleton", "Uzira.rte");
	self.weapons = {"Uzira.rte/Blunderpop", "Uzira.rte/Blunderbuss", "Uzira.rte/Musket"};
	self.spawnRadius = math.max(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight) * 0.1;
	self.boundsRadius = self.spawnRadius * 2 + self.minion.Radius;
	self.spawnTerrainTolerance = 70;
	self.spawnCost = 30;
	
	self.spawnTime = 1000;
	self.spawnTimer = Timer();
	self.minion.Team = self.Team;
	self.minions = {};
end

function Update(self)
	if self.spawnTimer:IsPastSimMS(self.spawnTime) then
		self.spawnTime = 10 + 10 * MovableMan:GetTeamMOIDCount(self.Team);
		local funds = ActivityMan:GetActivity():GetTeamFunds(self.Team);
		for i = 1, #self.minions do
			local minion = self.minions[i];
			if not MovableMan:IsActor(minion) then
				table.remove(self.minions, i);
			elseif SceneMan:ShortestDistance(self.Pos, minion.Pos, SceneMan.SceneWrapsX).Magnitude > self.boundsRadius then
				for attachable in minion.Attachables do
					if math.random() < 0.5 then
						minion:RemoveAttachable(attachable, true, math.random() < 0.5);
					else
						attachable:GibThis();
					end
				end
				minion.ToDelete = true;
				--table.remove(self.minions, i);
			end
		end
		if funds > self.spawnCost then
			local spawnPos = self.Pos + Vector(0, self.Radius + RangeRand(0, self.spawnRadius)):RadRotate(RangeRand(-1, 1));

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
				local skeleton = self.minion:Clone();
				local weapon = CreateHDFirearm(self.weapons[math.random(#self.weapons)]);
				weapon:AddScript("Uzira.rte/Actors/Brains/Uzira/GibOnDetach.lua");
				weapon.GibSound = nil;
				weapon:EnableDeepCheck(false);
				skeleton:AddInventoryItem(weapon);
				skeleton.Pos = spawnPos;
				skeleton.HFlipped = self.HFlipped;
				skeleton.RotAngle = RangeRand(-1.5, 1.5);
				skeleton.HUDVisible = false;
				skeleton.Status = Actor.INACTIVE;
				skeleton.AIMode = math.random(Actor.AIMODE_SENTRY, Actor.AIMODE_BRAINHUNT);
				if skeleton.AIMode == Actor.AIMODE_GOTO then
					skeleton:AddAISceneWaypoint(self.Pos);
				end
				skeleton.PinStrength = skeleton.Mass;
				MovableMan:AddActor(skeleton);
				table.insert(self.minions, skeleton);
				self.spawnTimer:Reset();
	
				ActivityMan:GetActivity():SetTeamFunds(funds - self.spawnCost, self.Team);
			end
		end
	end
end