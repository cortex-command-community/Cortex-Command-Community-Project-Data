function Create(self)
	self.origActivationDelay = self.ActivationDelay;
	self.origDeactivationDelay = self.DeactivationDelay;
	self.maxRateOfFire = self.RateOfFire;
	self.minRateOfFire = self.maxRateOfFire * 0.5;
	self.RateOfFire = self.minRateOfFire;
	self.increasePerShot = 1.05;
	self.decreasePerFrame = 0.99;
	self.spinTimer = Timer();
end
function Update(self)
	if self.FiredFrame then
		self.RateOfFire = math.min(self.RateOfFire * self.increasePerShot, self.maxRateOfFire);
		self.ActivationDelay = 0;
		self.DeactivationDelay = self.origDeactivationDelay * 9;
		self.spinTimer:Reset();
	else
		if not self:IsActivated() then
			self.RateOfFire = math.max(self.RateOfFire * self.decreasePerFrame, self.minRateOfFire);
		end
		if self.RoundInMagCount == 0 or self.spinTimer:IsPastSimMS(self.DeactivationDelay * 0.9) then
			self.ActivationDelay = self.origActivationDelay;
			self.DeactivationDelay = self.origDeactivationDelay;
		end
	end
end