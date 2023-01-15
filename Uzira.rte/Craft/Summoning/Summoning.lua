function Create(self)
	local largestRadius = 0;
	for actor in self.Inventory do
		if IsActor(actor) then
			actor = ToActor(actor);
			if actor.ModuleName == "Uzira.rte" then
				actor:AddScript("Uzira.rte/Actors/Shared/Undead.lua");
				actor.PinStrength = actor.Mass;
				if largestRadius == 0 or actor.Radius > largestRadius then
					largestRadius = actor.Radius;
				end
			else
				actor.HUDVisible = false;
				actor.Health = 0;
			end
		end
	end
	self.Pos = SceneMan:MovePointToGround(self.Pos, 0, 5) + Vector(0, largestRadius);
	if self.Pos.Y > SceneMan.SceneHeight or SceneMan:GetTerrMatter(self.Pos.X, self.Pos.Y) == rte.airID then
		self.Pos.Y = -(self.Height + 10);	--Return the craft if no ground was found
	else
		local partCount = largestRadius;
		for i = 1, partCount do
			local part = CreateMOPixel("Uzira.rte/Particle Grave Digger");
			local offset = Vector(largestRadius * RangeRand(-0.5, 0.5), 1 + largestRadius * RangeRand(1, 3));
			part.Pos = self.Pos - offset;
			part.Vel = Vector(offset.X * 0.5, (largestRadius + largestRadius * (i/partCount)) * 0.5);
			part.Sharpness = part.Sharpness/math.sqrt(part.Vel.Magnitude) * (i/partCount);
			MovableMan:AddParticle(part);
		end
		self:GibThis();
		ActivityMan:GetActivity():ReportDeath(self.Team, -1);
	end
end