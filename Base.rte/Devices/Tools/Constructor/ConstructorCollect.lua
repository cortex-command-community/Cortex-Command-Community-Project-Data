function Create(self)

	self.speed = 8;

	self.ToSettle = false;
	if self.Sharpness ~= rte.NoMOID then
		local mo = MovableMan:GetMOFromID(i);
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
	if self.target ~= nil and self.target.ID ~= 255 then
		local dist = SceneMan:ShortestDistance(self.Pos, self.target.Pos, SceneMan.SceneWrapsX);
		if dist.Magnitude > self.speed then
			self.Vel = Vector(dist.X,dist.Y):SetMagnitude(self.speed);
		else
			self.ToDelete = true;
		end
	end
end