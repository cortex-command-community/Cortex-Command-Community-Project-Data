function Create(self)
	self.dinSound = false;
	self.lastAmmo = self.RoundInMagCount;
end
function Update(self)
	if self.Magazine then
		self.lastMag = self.Magazine;
		self.lastAmmo = self.Magazine.RoundCount;
		self.dingSound = false;
		if self.Magazine.RoundCount <= 0 then
			self:Reload();
		end
	else
		if self.dingSound == false then
			if MovableMan:IsParticle(self.lastMag) then
				self.lastMag.Sharpness = 1;
				self.lastMag.Vel = self.lastMag.Vel + Vector(-12 * self.FlipFactor, 0):RadRotate(self.RotAngle);

				local soundfx = CreateAEmitter("Techion Giga Pulsar Magazine Eject Effect");
				soundfx.Pos = self.lastMag.Pos;
				soundfx.RotAngle = Vector(-1 * self.FlipFactor, 0):RadRotate(self.RotAngle).AbsRadAngle;
				MovableMan:AddParticle(soundfx);
			end
		end
		self.dingSound = true;
	end
end