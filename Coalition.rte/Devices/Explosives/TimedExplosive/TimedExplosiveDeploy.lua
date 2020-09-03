function Update(self)
	if self:IsActivated() and self.ID == self.RootID then

		local explosive = CreateMOSRotating("Timed Explosive Active");
		explosive.Pos = self.Pos;
		explosive.Vel = self.Vel;
		explosive.RotAngle = self.Vel.AbsRadAngle;
		MovableMan:AddParticle(explosive);

		self.ToDelete = true;
	end
end