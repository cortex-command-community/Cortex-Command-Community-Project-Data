function Create(self)
	self.origActivationDelay = self.ActivationDelay;
	self.origDeactivationDelay = self.DeactivationDelay;
	self.spinTimer = Timer();
end
function Update(self)
	if self.FiredFrame then
		self.ActivationDelay = 0;
		self.DeactivationDelay = self.origDeactivationDelay * 9;
		self.spinTimer:Reset();
	elseif self.RoundInMagCount == 0 or self.spinTimer:IsPastSimMS(self.DeactivationDelay * 0.9) then
		self.ActivationDelay = self.origActivationDelay;
		self.DeactivationDelay = self.origDeactivationDelay;
	end
end