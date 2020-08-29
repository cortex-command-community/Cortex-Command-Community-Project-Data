function Create(self)
	self.origMass = self.Mass;
	self.lastVel = self.Vel.Magnitude;
end
function Update(self)
	if self.ID == self.RootID then
		if self.thrown == false then
			self.AngularVel = self.AngularVel - self.Vel.Magnitude * self.FlipFactor * math.random();
			self.thrown = true;
		end
		self.Mass = self.origMass + (math.sqrt(self.lastVel) * self.origMass);
	else
		self.thrown = false;
		self.Mass = self.origMass;
	end
	self.lastVel = (self.Vel.Magnitude + self.lastVel) * 0.5;
end