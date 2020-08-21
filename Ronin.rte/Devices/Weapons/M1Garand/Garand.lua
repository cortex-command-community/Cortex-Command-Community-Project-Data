function Create(self)
	self.setAngle = 0;
	self.tilt = 0.5/math.sqrt(self.Radius);
end
function Update(self)
	if self.setAngle > 0 then
		self.setAngle = self.setAngle - 0.02 * (1 + self.setAngle);
		if self.setAngle < 0 then
			self.setAngle = 0;
		end
	end
	if self.FiredFrame then
		self.setAngle = self.setAngle + self.tilt;
	end
	self.RotAngle = self.RotAngle + self.setAngle * self.FlipFactor;
	local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
	self.Pos = self.Pos - jointOffset + Vector(jointOffset.X, jointOffset.Y):RadRotate(-self.setAngle * self.FlipFactor);
	
	self.lastMag = self.Magazine;
	if self.FiredFrame and self.RoundInMagCount == 0 then
		self:Reload();
		if MovableMan:IsParticle(self.lastMag) then
			self.lastMag.Vel = self.lastMag.Vel + Vector(-4 * self.FlipFactor, -7):RadRotate(self.RotAngle);
			AudioMan:PlaySound("Ronin.rte/Devices/Weapons/M1Garand/Sounds/Ping.wav", self.Pos);
		end
	end
end