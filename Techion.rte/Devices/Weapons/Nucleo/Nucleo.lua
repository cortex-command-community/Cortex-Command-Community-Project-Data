function Update(self)
	if self.FiredFrame then
		local bullet = CreateMOSRotating("Particle Nucleo");
		bullet.Pos = self.MuzzlePos;
		bullet.Vel = self.Vel + Vector(30 * self.FlipFactor, 0):RadRotate(self.RotAngle);
		bullet.Sharpness = self.UniqueID;
		bullet.Team = self.Team;
		MovableMan:AddParticle(bullet);
	end
end