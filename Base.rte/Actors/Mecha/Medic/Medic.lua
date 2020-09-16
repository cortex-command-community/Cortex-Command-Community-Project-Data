function Create(self)
	self.healTimer = Timer();
	self.baseHealDelay = 150;
	self.healIncrementPerTarget = 100;
	self.healIncrementPerWound = 50;
	self.healTimer:SetSimTimeLimitMS(self.baseHealDelay);
	self.crossTimer = Timer();
	self.crossTimer:SetSimTimeLimitMS(800);
	
	self.colors = {135, 133, 149, 148, 145};
	self.maxHealRange = 100 + self.Radius;
	self.healStrength = 1;
	self.healTargets = {};
end
function Update(self)
	local parent = self:GetParent();
	if parent and IsActor(parent) then
		parent = ToActor(parent);
		local healRange = self.maxHealRange * (1 - (self.WoundCount/self.GibWoundLimit));
		if (parent:IsPlayerControlled() and parent:GetController():IsState(Controller.WEAPON_FIRE)) or #self.healTargets > 0 then
			local screen = ActivityMan:GetActivity():ScreenOfPlayer(parent:GetController().Player);
			if screen ~= -1 then
				PrimitiveMan:DrawCirclePrimitive(screen, self.Pos, healRange, self.colors[math.random(#self.colors)]);
				for i = 1, math.random(10, 20) do
					local vector = Vector(healRange, 0):RadRotate(6.28 * math.random());
					PrimitiveMan:DrawLinePrimitive(screen, self.Pos + vector * RangeRand(0.66, 0.99), self.Pos + vector, self.colors[math.random(#self.colors)]);
				end
			end
		end
		if self.healTimer:IsPastSimTimeLimit() then
			self.healTimer:Reset();
			for i = 1, #self.healTargets do
				local targetFound = false;
				local healTarget = self.healTargets[i];
				if healTarget and IsActor(healTarget) and (healTarget.Health < healTarget.MaxHealth or healTarget.TotalWoundCount > 0) and healTarget.Vel.Largest < 10 then
					local trace = SceneMan:ShortestDistance(self.Pos, healTarget.Pos, false);
					if (trace.Magnitude - healTarget.Radius) < healRange then
						if SceneMan:CastObstacleRay(self.Pos, trace, Vector(), Vector(), parent.ID, parent.IgnoresWhichTeam, rte.grassID, 5) < 0 then
							targetFound = true;
						end
					end
				end
				if targetFound then
					healTarget.Health = math.min(healTarget.Health + self.healStrength, healTarget.MaxHealth);
					if self.crossTimer:IsPastSimTimeLimit() then
						local cross = CreateMOSParticle("Particle Heal Effect", "Base.rte");
						if cross then
							cross.Pos = healTarget.AboveHUDPos + Vector(0, 4);
							MovableMan:AddParticle(cross);
						end
						if healTarget.Health >= healTarget.MaxHealth then
							healTarget:RemoveAnyRandomWounds(self.healStrength);
						end
					end
				end
			end
			if self.crossTimer:IsPastSimTimeLimit() then
				self.crossTimer:Reset();
			end
			self.healTargets = {};
			for act in MovableMan.Actors do
				if act.Team == parent.Team and act.ID ~= parent.ID and (act.Health < act.MaxHealth or act.TotalWoundCount > 0) and act.Vel.Largest < 5 then
					local trace = SceneMan:ShortestDistance(self.Pos, act.Pos, false);
					if (trace.Magnitude - act.Radius) < (healRange * 0.9) then
						if SceneMan:CastObstacleRay(self.Pos, trace, Vector(), Vector(), parent.ID, parent.IgnoresWhichTeam, rte.airID, 3) < 0 then
							table.insert(self.healTargets, act);
						end
					end
				end
			end
			self.healTimer:SetSimTimeLimitMS(self.baseHealDelay + (self.healIncrementPerWound * self.WoundCount) + (#self.healTargets * self.healIncrementPerTarget));
		end
	end
end