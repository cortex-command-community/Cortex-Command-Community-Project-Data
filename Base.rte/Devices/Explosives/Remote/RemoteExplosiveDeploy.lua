function Create(self)

	self.alliedTeam = -1;

end

function Update(self)

	if self.ID ~= self.RootID then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if MovableMan:IsActor(actor) then
			self.alliedTeam = ToActor(actor).Team;
		end
	end

	if self:IsActivated() and self.ID == self.RootID then

		local explosive = CreateMOSRotating("Particle Active Remote Explosive");
		explosive.Pos = self.Pos;
		explosive.Vel = self.Vel;
		explosive.RotAngle = self.RotAngle;
		explosive.Sharpness = self.alliedTeam;
		MovableMan:AddParticle(explosive);

		self.ToDelete = true;

	end

end