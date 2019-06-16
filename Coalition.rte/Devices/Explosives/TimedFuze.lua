function Update(self)
	if self.Fuze then
		if self.Fuze:IsPastSimMS(4000) then
			local Payload = CreateMOSRotating("Timed Grenade Payload", "Coalition.rte")
			if Payload then
				Payload.Pos = self.Pos
				MovableMan:AddParticle(Payload)
				Payload:GibThis()
			end
			
			self:GibThis()
		end
	elseif self:IsActivated() then
		self.Fuze = Timer()
	end
end