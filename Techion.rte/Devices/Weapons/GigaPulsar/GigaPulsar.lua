function Create(self)
	self.dinSound = false;
	self.lastAmmo = self.RoundInMagCount;

	self.origActivationDelay = self.ActivationDelay;
	self.origDeactivationDelay = self.DeactivationDelay;
	self.spinTimer = Timer();
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
	if self.FiredFrame then
		self.ActivationDelay = 0;
		self.DeactivationDelay = self.origDeactivationDelay * 5;
		self.spinTimer:Reset();
	elseif self.RoundInMagCount == 0 or self.spinTimer:IsPastSimMS(self.DeactivationDelay * 0.9) then
		self.ActivationDelay = self.origActivationDelay;
		self.DeactivationDelay = self.origDeactivationDelay;
	end
end