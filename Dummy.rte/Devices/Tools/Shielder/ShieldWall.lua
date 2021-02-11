function Update(self)
	if self.AngularVel < 1 then
		self.AngularVel = 0;
	else
		self.AngularVel = self.AngularVel * 0.99;
		self.EffectRotAngle = self.RotAngle;
	end
	if self.PinStrength == 0 and self.Vel.Magnitude < 1 then
		self.PinStrength = self.Mass;
	end
	if self.Age > self.Lifetime - 17 * (1 + self.WoundCount) then
		self:GibThis();
	end
end