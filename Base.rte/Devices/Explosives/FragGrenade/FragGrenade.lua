function Update(self)
	if self:IsActivated() then
		if not self.pin then
			self.pin = CreateMOSParticle("Frag Grenade Pin");
			self.pin.Pos = self.Pos;
			self.pin.Vel = self.Vel * 0.5 + Vector(self.Vel.Magnitude * 0.25, 0):RadRotate(6.28 * math.random());
			MovableMan:AddParticle(self.pin);
		end
		self.Frame = 1;
	end
end