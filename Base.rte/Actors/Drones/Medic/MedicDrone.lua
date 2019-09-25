function Create(self)
	self.HealTimer = Timer()
	self.HealTimer:SetSimTimeLimitMS(100)
	self.CrossTimer = Timer()
	self.CrossTimer:SetSimTimeLimitMS(800)
end

function Update(self)
	if self.HealTimer:IsPastSimTimeLimit() then
		self.HealTimer:Reset()
		
		if self.HealTarget then
			-- Check if we can see our target
			local targetFound = false
			if MovableMan:IsActor(self.HealTarget) and self.HealTarget.Health < 100 and self.HealTarget.Vel.Largest < 6 then
				local Trace = SceneMan:ShortestDistance(self.Pos, self.HealTarget.Pos, false)
				if Trace.Magnitude - self.HealTarget.Radius < 100 then
					if SceneMan:CastObstacleRay(self.EyePos, Trace, Vector(), Vector(), self.ID, self.IgnoresWhichTeam, rte.grassID, 5) < 0 then
						-- We have LOS to the target
						targetFound = true
					end
				end
			end
			
			if targetFound then
				-- Start healing
				self.HealTarget.Health = math.min(self.HealTarget.Health+1, 100)
				
				-- Draw the healing icon
				if self.CrossTimer:IsPastSimTimeLimit() then
					self.CrossTimer:Reset()
					
					local Cross = CreateMOSParticle("Particle Heal Effect", "Base.rte")
					if Cross then
						Cross.Pos = self.HealTarget.AboveHUDPos + Vector(0, 4)	-- Set the particle's position to just over the actor's head
						MovableMan:AddParticle(Cross)
					end
				end
			else
				self.HealTarget = nil
			end
		else
			-- Look for actors to heal
			for Act in MovableMan.Actors do
				if Act.Team == self.Team and Act.Health < 100 and Act.Vel.Largest < 4 then
					local Trace = SceneMan:ShortestDistance(self.Pos, Act.Pos, false)
					if Trace.Magnitude - Act.Radius < 80 then
						if SceneMan:CastObstacleRay(self.EyePos, Trace, Vector(), Vector(), self.ID, self.IgnoresWhichTeam, 0, 3) < 0 then
							-- We have LOS to this actor
							self.HealTarget = Act
							break
						end
					end
				end
			end
		end
	end
end
