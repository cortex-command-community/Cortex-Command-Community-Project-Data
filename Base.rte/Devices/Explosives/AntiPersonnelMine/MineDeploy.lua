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

		local mine = CreateMOSRotating("Particle Mine");
		mine.Pos = self.Pos;
		mine.Vel = self.Vel;
		mine.Sharpness = self.alliedTeam;
		MovableMan:AddParticle(mine);

		self.ToDelete = true;

	end

end