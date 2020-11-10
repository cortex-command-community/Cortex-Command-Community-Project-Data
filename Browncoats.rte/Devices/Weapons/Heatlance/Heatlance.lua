function Update(self)
	if self:IsActivated() and self.RoundInMagCount > 0 then
		if not self.triggerPulled then
			AudioMan:PlaySound("Browncoats.rte/Devices/Weapons/Heatlance/Sounds/Start.wav", self.MuzzlePos);
		end
		self.triggerPulled = true;
	else
		if self.triggerPulled then
			AudioMan:PlaySound("Browncoats.rte/Devices/Weapons/Heatlance/Sounds/End.wav", self.MuzzlePos);
		end
		self.triggerPulled = false;
	end
end