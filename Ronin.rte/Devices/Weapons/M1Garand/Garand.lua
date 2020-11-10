function Update(self)
	self.lastMag = self.Magazine;
	if self.FiredFrame and self.RoundInMagCount == 0 then
		self:Reload();
		if MovableMan:IsParticle(self.lastMag) then
			self.lastMag.Vel = self.lastMag.Vel + Vector(-4 * self.FlipFactor, -7):RadRotate(self.RotAngle);
			AudioMan:PlaySound("Ronin.rte/Devices/Weapons/M1Garand/Sounds/Ping.wav", self.Pos);
		end
	end
end