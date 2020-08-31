function Create(self)
	self.origMass = self.Mass;
	self.thrownMassMultiplier = self:NumberValueExists("ThrownMassMultiplier") and self:GetNumberValue("ThrownMassMultiplier") or 5;
end
function Update(self)
	if self.ID == self.RootID then
		if not self.thrown then
			self.AngularVel = self.AngularVel - self.Vel.Magnitude * self.FlipFactor * math.random();
			self.Mass = self.origMass * self.thrownMassMultiplier;
			self.GibImpulseLimit = self.GibImpulseLimit * self.thrownMassMultiplier;
			self.thrown = true;
		end
	else
		self.thrown = false;
		self.Mass = self.origMass;
	end
end