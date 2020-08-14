function Create(self)

	self.speed = 4;
	
	self.lifeTimer = Timer();

	self.ToSettle = false;
	if self.Sharpness ~= rte.NoMOID then
		local mo = MovableMan:GetMOFromID(self.Sharpness);
		if mo then
			self.target = mo;
			self.Sharpness = 0;
			self.PinStrength = 0;
		end
	else
		self.ToDelete = true;
	end
end

function Update(self)

	self.ToSettle = false;
	if self.target and self.target.ID ~= rte.NoMOID then
		local dist = SceneMan:ShortestDistance(self.Pos, self.target.Pos, SceneMan.SceneWrapsX);
		self.Vel = Vector(dist.X,dist.Y):SetMagnitude(self.speed);
	end

	if self.lifeTimer:IsPastSimMS(5000) then
		self.ToSettle = true;
	end
end