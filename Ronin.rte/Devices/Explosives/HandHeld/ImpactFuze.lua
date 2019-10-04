function Update(self)
	if self.armed and self.ID == self.RootID then	-- grenade released
		local Payload = CreateMOSRotating("Impact Grenade Payload", "Ronin.rte")
		if Payload then
			Payload.Pos = self.Pos
			Payload.Vel = self.Vel
			Payload.RotAngle = self.RotAngle
			Payload.AngularVel = self.AngularVel
			MovableMan:AddParticle(Payload)
			
			self.ToDelete = true
		end
	elseif self:IsActivated() then	-- player pressed the button
		self.armed = true
	end
end