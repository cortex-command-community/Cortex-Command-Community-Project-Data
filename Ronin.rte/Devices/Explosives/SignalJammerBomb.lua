function Update(self)

	if self.ID ~= self.RootID then
		self.Sharpness = MovableMan:GetMOFromID(self.RootID).Team;
	else
		if self:IsActivated() then
			local bomb = CreateMOSRotating("Ronin Signal Jammer Object");
			bomb.Pos = self.Pos;
			bomb.Vel = self.Vel;
			bomb.AngularVel = self.AngularVel;
			bomb.Sharpness = self.Sharpness;
			MovableMan:AddParticle(bomb);
			self.ToDelete = true;
		end
	end

end