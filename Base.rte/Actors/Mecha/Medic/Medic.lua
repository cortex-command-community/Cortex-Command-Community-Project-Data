function Create(self)
	self.healTimer = Timer();
	self.healTimer:SetSimTimeLimitMS(100);
	self.crossTimer = Timer();
	self.crossTimer:SetSimTimeLimitMS(800);
	
	self.healRange = 100 + self.Radius;
	self.healStrength = 1;
	self.healTargets = {};
end

function Update(self)
	if self.healTimer:IsPastSimTimeLimit() then
		self.healTimer:Reset();
		local parent = self:GetParent();
		if parent and IsActor(parent) then	-- Must be attached to the actor
			parent = ToActor(parent);
			for i = 1, #self.healTargets do
				local targetFound = false;
				local healTarget = self.healTargets[i];
				if healTarget and IsActor(healTarget) and (healTarget.Health < healTarget.MaxHealth or healTarget.TotalWoundCount > 0) and healTarget.Vel.Largest < 10 then
					local trace = SceneMan:ShortestDistance(self.Pos, healTarget.Pos, false);
					if (trace.Magnitude - healTarget.Radius) < self.healRange then
						if SceneMan:CastObstacleRay(self.Pos, trace, Vector(), Vector(), parent.ID, parent.IgnoresWhichTeam, rte.grassID, 5) < 0 then
							-- We have LOS to the target
							targetFound = true;
						end
					end
				end
				if targetFound then
					-- Start healing
					healTarget.Health = math.min(healTarget.Health + self.healStrength, healTarget.MaxHealth);
					-- Draw the healing icon
					if self.crossTimer:IsPastSimTimeLimit() then
						local cross = CreateMOSParticle("Particle Heal Effect", "Base.rte");
						if cross then
							cross.Pos = healTarget.AboveHUDPos + Vector(0, 4);	-- Set the particle's position to just over the actor's head
							MovableMan:AddParticle(cross);
						end
						-- Start removing wounds if health is full
						if healTarget.Health >= healTarget.MaxHealth then
							healTarget:RemoveAnyRandomWounds(self.healStrength);
						end
					end
				end
			end
			if self.crossTimer:IsPastSimTimeLimit() then
				self.crossTimer:Reset();
			end
			self.healTargets = {};	-- Reset table
			-- Look for actors to heal
			for act in MovableMan.Actors do
				if act.Team == parent.Team and act.ID ~= parent.ID and (act.Health < act.MaxHealth or act.TotalWoundCount > 0) and act.Vel.Largest < 5 then
					local trace = SceneMan:ShortestDistance(self.Pos, act.Pos, false);
					if (trace.Magnitude - act.Radius) < (self.healRange * 0.9) then
						if SceneMan:CastObstacleRay(self.Pos, trace, Vector(), Vector(), parent.ID, parent.IgnoresWhichTeam, 0, 3) < 0 then
							-- We have LOS to this actor
							table.insert(self.healTargets, act);
						end
					end
				end
			end
			self.healTimer:SetSimTimeLimitMS(50 + #self.healTargets * 50);
		end
	end
end