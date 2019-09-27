function Create(self)
	self.AimPoint = Vector(self.Sharpness, self.Mass)
	self.TargetPoint = Vector(self.Sharpness, self.Mass)
	self.Sharpness = 1
	self.Mass = 5
	self.LastVel = Vector(self.Vel.X, self.Vel.Y)
	self.emissionDelay = 11
	
	-- Find the enemy actor that is closest to Aim Pos
	if self.OnlyLinearForces then
		self.OnlyLinearForces = false
		
		local bestRange = math.huge
		for Act in MovableMan.Actors do
			if Act.Team ~= self.Team then
				local range = SceneMan:ShortestDistance(Act.Pos, self.TargetPoint, false).Largest
				if range < bestRange then
					bestRange = range
					self.Target = Act
					self.AimPoint:SetXY(Act.Pos.X, Act.Pos.Y)
				end
			end
		end
	end
end

function Update(self)
	if self.AimPoint then
		self.emissionDelay = self.emissionDelay - 1
		if self.emissionDelay == 0 then
			self:TriggerBurst()
			self:EnableEmission(true)
		elseif self.emissionDelay < 0 then
			-- Find the velocity vector that will take the missile to the target
			local FutureVel = self.Vel + (self.Vel - self.LastVel) * 10
			local OptimalVel = SceneMan:ShortestDistance(self.Pos, self.AimPoint, false)
			local angError = math.asin(OptimalVel.Normalized:Cross(FutureVel.Normalized))	-- The angle between FutureVel and OptimalVel
			
			-- Gradually turn towards the optimal velocity vector
			self.RotAngle = self.RotAngle + math.min(math.max(angError, -0.025), 0.025)
			self.AngularVel = self.AngularVel + math.min(math.max(angError, -0.2), 0.2)
			
			-- Gradually return the thruster to the starting position if the missile is facing the target
			if math.abs(angError) < 0.05 then
				self.AngularVel = self.AngularVel * 0.9
				self.EmitAngle = self.EmitAngle * 0.8 + math.pi * 0.2
			else
				self.AngularVel = self.AngularVel * 0.95
				self.EmitAngle = math.max(math.min(self.EmitAngle+angError*0.08, 4.24), 2.04)	-- Vector thrust
			end
			
			self.AngularVel = self.AngularVel + (self.EmitAngle - math.pi) * 0.2	-- The vector thrust will cause the missile to rotate
		end
		
		self.LastVel = self.LastVel * 0.6 + self.Vel * 0.4	-- Used to calculate the acceleration of the missile
	end
	
	if self.Target then
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
			self.TargetPoint:SetXY(self.AimPoint.X, self.AimPoint.Y) -- Update the TargetPoint just in case we lose track of the target actor
		else
			self.Target = nil
			self.AimPoint = self.TargetPoint
		end
	end
end
