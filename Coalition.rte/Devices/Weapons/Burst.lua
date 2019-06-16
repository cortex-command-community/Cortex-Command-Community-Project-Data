function Create(self)
	self.burstTimer = Timer();
	self.burst = false;
	self.canBurst = true;
end

function Update(self)

	if self.canBurst == true and self:IsActivated() and self.Magazine ~= nil and self.Magazine.RoundCount > 0 then
		self.burstTimer:Reset();
		self.canBurst = false;
		self.burst = true;
	end

	if self.burst == true then
		if self.burstTimer:IsPastSimMS(150) then
			self.burstTimer:Reset();
			self:Deactivate();
			self.burst = false;
		else
			self:Activate();
		end
	else
		if self.canBurst == false then
			self:Deactivate();
			if self.burstTimer:IsPastSimMS(200) then
				self.canBurst = true;
			end
		end
	end

end