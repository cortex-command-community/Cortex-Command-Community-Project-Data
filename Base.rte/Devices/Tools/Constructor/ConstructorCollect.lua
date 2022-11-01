function Create(self)

	self.speed = self.Vel.Magnitude;

	self.ToSettle = false;
	if self.Sharpness ~= rte.NoMOID then
		local mo = MovableMan:GetMOFromID(self.Sharpness);
		if mo then
			self.target = mo;
			self.Sharpness = 0;
		end
	else
		self.ToDelete = true;
	end
end

function Update(self)

	if self.target and self.target.ID ~= rte.NoMOID then
		local dist = SceneMan:ShortestDistance(self.Pos, self.target.Pos, SceneMan.SceneWrapsX);
		if dist:MagnitudeIsGreaterThan(self.speed) then
			self.Vel = Vector(dist.X, dist.Y):SetMagnitude(self.speed) - (SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs) * self.GlobalAccScalar;
		else
			self.ToDelete = true;
		end
	end
	if self.PinStrength > 0 then
		self.Pos = self.Pos + self.Vel * rte.PxTravelledPerFrame;
	end
end