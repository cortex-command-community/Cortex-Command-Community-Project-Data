function Create(self)
	self.fuzeDelay = 3000;
end
function Update(self)
	if self.fuze then
		if self.fuze:IsPastSimMS(self.fuzeDelay) then
			local payload = CreateMOSRotating("Ronin Scrambler Payload");
			if payload then
				payload.Pos = self.Pos;
				MovableMan:AddParticle(payload);
				payload:GibThis();
			end
			self:GibThis();
		end
	elseif self:IsActivated() then
		self.fuze = Timer();
	end
end