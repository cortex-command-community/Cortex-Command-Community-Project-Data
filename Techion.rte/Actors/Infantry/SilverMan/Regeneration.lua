function Create(self)
	self.healAmount = 1;
	self.regenDelay = 750;
	self.regenTimer = Timer();

	self.lastWoundCount = self.TotalWoundCount;
	self.lastHealth = self.Health;
end
function Update(self)
	if self.regenTimer:IsPastSimMS(self.regenDelay) then
		self.regenTimer:Reset();
		if self.Health > 0 then
			local damageRatio = (self.TotalWoundCount - self.lastWoundCount)/self.TotalWoundLimit + (self.lastHealth - self.Health)/self.MaxHealth;
			if damageRatio > 0 then
				self.regenDelay = self.regenDelay * (1 + damageRatio);
			else
				local healed = self:RemoveAnyRandomWounds(1);
				if healed ~= 0 and self.Health < self.MaxHealth then
					self:AddHealth(self.healAmount);
					if self.Health > self.MaxHealth	then
						self.Health = self.MaxHealth;
					end
				end
			end
		end
		self.lastWoundCount = self.TotalWoundCount;
		self.lastHealth = self.Health;
	end
end