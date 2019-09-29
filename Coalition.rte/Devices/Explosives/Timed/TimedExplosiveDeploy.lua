function Update(self)

	if self:IsActivated() and self.ID == self.RootID then

		local explosive = CreateMOSRotating("Particle Coalition Active Timed Explosive");
		explosive.Pos = self.Pos;
		explosive.Vel = self.Vel;
		explosive.RotAngle = self.RotAngle;
		MovableMan:AddParticle(explosive);

		self.ToDelete = true;

	end

end