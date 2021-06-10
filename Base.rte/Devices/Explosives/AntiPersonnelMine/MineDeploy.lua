function Create(self)

	self.alliedTeam = -1;
end

function Update(self)

	local parent = self:GetRootParent();
	if IsActor(parent) then
		self.alliedTeam = ToActor(parent).Team;
	end

	if self:IsActivated() and self.ID == self.RootID then

		local mine = CreateMOSRotating("Anti Personnel Mine Active");
		mine.Pos = self.Pos;
		mine.Vel = self.Vel;
		mine.Sharpness = self.alliedTeam;
		mine.RotAngle = self.RotAngle;
		mine.HFlipped = self.HFlipped;
		MovableMan:AddParticle(mine);

		self.ToDelete = true;
	end
end