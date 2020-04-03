function Create(self)
	self.shotsPerBurst = 3;
	self.coolDownDelay = (60000 / self.RateOfFire);
end
function Update(self)
	if self.Magazine then
		if self.coolDownTimer then
			local parent = self:GetRootParent();
			if self.coolDownTimer:IsPastSimMS(self.coolDownDelay) and (parent and IsActor(parent)) and (not self:IsActivated() or not ToActor(parent):IsPlayerControlled()) then
				self.coolDownTimer, self.shotCounter = nil;
			else
				self:Deactivate();
			end
		elseif self.shotCounter then
			self:Activate();
			if self.FiredFrame then
				self.shotCounter = self.shotCounter + 1;
				if self.shotCounter >= self.shotsPerBurst then
					self.coolDownTimer = Timer();
				end
			end
		elseif self.FiredFrame then
			self.shotCounter = 1;
		end
	else
		self.coolDownTimer, self.shotCounter = nil;
	end
end