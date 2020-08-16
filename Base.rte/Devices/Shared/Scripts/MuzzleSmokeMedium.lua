function Create(self)
	self.minSmokeCount = 3;
	self.maxSmokeCount = 6;
	self.spread = 0.6;
end
function Update(self)
	if self.FiredFrame then
		local smokeCount = math.random(self.minSmokeCount, self.maxSmokeCount);

		for i = 1, smokeCount do
			local smokefx = CreateMOSParticle("Tiny Smoke Ball 1");
			smokefx.Pos = self.MuzzlePos;
			smokefx.Vel = Vector(i * self.FlipFactor, 0):RadRotate(self.RotAngle + (math.random() * self.spread) - (self.spread/2));
			MovableMan:AddParticle(smokefx);
		end
	end
end