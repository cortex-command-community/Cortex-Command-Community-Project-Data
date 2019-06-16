function Create(self)

	self.lifeTimer = Timer();

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
		self.Vel = Vector(dist.X,dist.Y):SetMagnitude(10);
	end

	if self.lifeTimer:IsPastSimMS(5000) then
		self.ToSettle = true;
	end

end