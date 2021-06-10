function Create(self)

	self.turnStrength = 5;
	self.lifeTimer = Timer();
	
	if self:NumberValueExists("TargetID") then
		local mo = MovableMan:GetMOFromID(self:GetNumberValue("TargetID"));
		if mo and IsMOSRotating(mo) then
			self.target = ToMOSRotating(mo);
			AudioMan:PlaySound("Base.rte/Devices/Explosives/AntiPersonnelMine/Sounds/MineDetonate.flac", self.Pos);
		end
	end
	self.lifeTimer:SetSimTimeLimitMS(self.Lifetime - math.ceil(TimerMan.DeltaTimeMS));
end
function Update(self)
	self.GlobalAccScalar = 1/math.sqrt(1 + math.abs(self.Vel.X) * 0.1);
	if self.target and self.target.ID ~= rte.NoMOID then
		local targetDist = SceneMan:ShortestDistance(self.Pos, self.target.Pos, SceneMan.SceneWrapsX);
		if targetDist.Magnitude < self.Diameter then
			self:GibThis();
		else
			local targetVel = targetDist:SetMagnitude(self.turnStrength);

			local turnAngle = self.Vel.AbsRadAngle - targetVel.AbsRadAngle;
			turnAngle = turnAngle > math.pi and turnAngle - (math.pi * 2) or (turnAngle < -math.pi and turnAngle + (math.pi * 2) or turnAngle);

			self.Vel = (self.Vel + targetVel):SetMagnitude(self.Vel.Magnitude);
			self.AngularVel = self.AngularVel * 0.5 - (turnAngle * self.turnStrength);
		end
	end
	if self.lifeTimer:IsPastSimTimeLimit() then
		self:GibThis();
	end
end