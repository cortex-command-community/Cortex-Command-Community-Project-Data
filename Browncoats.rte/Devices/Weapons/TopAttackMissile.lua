function Create(self)
	self.AimPoint = Vector()
	self.TargetPoint = Vector(self.Sharpness, self.Mass)
	self.Sharpness = 1
	self.Mass = 5
	self.LastVel = Vector(self.Vel.X, self.Vel.Y)
	self.emissionDelay = 14
	self.ascending = true
	
	-- find the enemy actor that is closest to Aim Pos
	if self.OnlyLinearForces then
		self.OnlyLinearForces = false
		
		local bestRange = math.huge
		for Act in MovableMan.Actors do
			if Act.Team ~= self.Team then
				local range = SceneMan:ShortestDistance(Act.Pos, self.TargetPoint, false).Largest
				if range < bestRange then
					bestRange = range
					self.Target = Act
				end
			end
		end
	end
	
	local Dist = SceneMan:ShortestDistance(self.TargetPoint, self.Pos, false)
	local StartOffset = Vector(Dist.X, Dist.Y):CapMagnitude(30)
	local AboveTarget = SceneMan:ShortestDistance(self.TargetPoint+StartOffset, self.TargetPoint+Dist*0.65+Vector(0, -Dist.Magnitude*0.5), false)
	
	-- find a point above us where the missile should go before homing in on the target
	SceneMan:CastStrengthRay(self.TargetPoint, AboveTarget, 5, self.AimPoint, 9, rte.grassID, true)
	SceneMan:CastStrengthRay(self.Pos, SceneMan:ShortestDistance(self.Pos, self.AimPoint, false), 5, self.AimPoint, 9, rte.grassID, true)
end

function Update(self)
	local allowEmission = false
	if self.AimPoint then
		self.emissionDelay = self.emissionDelay - 1
		if self.emissionDelay == 0 then
			self:TriggerBurst()
			allowEmission = true
		elseif self.emissionDelay < 0 then
			-- Find the velocity vector that will take the missile to the target
			local FutureVel = self.Vel + (self.Vel - self.LastVel) * 15
			local OptimalVel = SceneMan:ShortestDistance(self.Pos, self.AimPoint, false)
			local angError = math.asin(OptimalVel.Normalized:Cross(FutureVel.Normalized))	-- The angle between FutureVel and OptimalVel
			
			-- Gradually turn towards the optimal velocity vector
			self.RotAngle = self.RotAngle + math.min(math.max(angError, -0.025), 0.025)
			self.AngularVel = self.AngularVel + math.min(math.max(angError, -0.2), 0.2)
			
			-- Gradually return the thruster to the starting position if the missile is facing the target
			if math.abs(angError) < 0.05 then
				self.AngularVel = self.AngularVel * 0.7
				self.EmitAngle = self.EmitAngle * 0.8 + math.pi * 0.2
				
				if self.ascending then
					if self.Vel.Y > -3 and SceneMan:ShortestDistance(self.Pos+FutureVel*10, self.AimPoint, false).Largest > 40 then
						allowEmission = true
					end
				elseif self.Vel.Y < 0 then
					allowEmission = true
				end
			else
				self.AngularVel = self.AngularVel * 0.9
				self.EmitAngle = math.max(math.min(self.EmitAngle+angError*0.08, 4.24), 2.04)	-- Vector thrust
				
				-- turn off the thruster if we are rotating in the right direction
				if not self.ascending and ((angError > 0 and self.AngularVel > 0.7) or (angError < 0 and self.AngularVel < -0.7)) then
					allowEmission = false
				else
					allowEmission = true
					self.AngularVel = self.AngularVel + (self.EmitAngle - math.pi) * 0.2	-- The vector thrust will cause the missile to rotate
				end
			end
		end
		
		self.LastVel = self.LastVel * 0.6 + self.Vel * 0.4	-- Used to calculate the acceleration of the missile
	end
	
	if self.ascending then
		if SceneMan:ShortestDistance(self.Pos, self.AimPoint, false).Largest < 50 then
			self.ascending = false
			self.AimPoint = self.TargetPoint
		end
	elseif self.Target then
		if MovableMan:IsActor(self.Target) then
			-- Detonate the missile when appropriate
			local range = SceneMan:ShortestDistance(self.Pos, self.Target.Pos, false).Magnitude
			if self.proximityFuze then
				if range < 20 then
					self:GibThis()	-- The target is close enough; detonate
				elseif range > self.proximityFuze then	-- The missile is moving away from the target: detonate
					self:GibThis()
				else
					self.proximityFuze = range
				end
			elseif range < 100 then	-- The target is close: arm the proximity fuze
				self.proximityFuze = range
			end
			
			self.AimPoint = self.AimPoint * 0.6 + (self.Target.Pos+self.Target.Vel*math.min(range/50, 20)) * 0.4	-- Filter the AimPos to reduce noise
		else
			self.Target = nil
			self.AimPoint = nil
		end
	end
	
	self:EnableEmission(allowEmission)
end
