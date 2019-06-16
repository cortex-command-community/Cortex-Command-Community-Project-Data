function Create(self)

	if self.Sharpness > -1 then
		for i = 1, MovableMan:GetMOIDCount()-1 do
			local mo = MovableMan:GetMOFromID(i);
			if mo.UniqueID == self.Sharpness then
				self.target = mo;
				self.Sharpness = 0;
				self.PinStrength = 0;
				break;
			end
		end
	else
		self.ToDelete = true;
	end

end

function Update(self)

	if self.target ~= nil and self.target.ID ~= 255 then
		local dist = SceneMan:ShortestDistance(self.Pos, self.target.Pos, SceneMan.SceneWrapsX);
		if dist.Magnitude > 10 then
			self.Vel = Vector(dist.X,dist.Y):SetMagnitude(10);
		else
			self.ToDelete = true;
		end
	end

end