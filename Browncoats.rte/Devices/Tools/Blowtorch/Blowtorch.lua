function Create(self)
	self.startSound = CreateSoundContainer("Heatlance Fire Sound Start", "Browncoats.rte");
	self.endSound = CreateSoundContainer("Heatlance Fire Sound End", "Browncoats.rte");
end
function Update(self)
	if self:IsActivated() and self.RoundInMagCount ~= 0 then
		if not self.triggerPulled then
			self.startSound:Play(self.MuzzlePos);
		end
		self.triggerPulled = true;
	else
		if self.triggerPulled then
			self.endSound:Play(self.MuzzlePos);
		end
		self.triggerPulled = false;
	end
end