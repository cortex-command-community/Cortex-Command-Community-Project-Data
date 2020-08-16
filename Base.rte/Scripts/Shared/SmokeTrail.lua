function Create(self)
	self.smokeTrailLifeTime = self:NumberValueExists("SmokeTrailLifeTime") and self:GetNumberValue("SmokeTrailLifeTime") or 150;
	self.spread = self.Radius/3;
end
function Update(self)
	local effect;
	local offset = self.Vel * rte.PxTravelledPerFrame;	--The effect will be created the next frame so move it one frame backwards towards the barrel
	
	local trailLength = math.floor(offset.Magnitude + 0.5);
	for i = 1, trailLength, 6 do
		effect = CreateMOSParticle("Tiny Smoke Trail 1", "Base.rte");
		if effect then
			effect.Pos = self.Pos - offset * (i/trailLength) + Vector(RangeRand(-1, 1), RangeRand(-1, 1)) * self.spread;
			effect.Vel = self.Vel * RangeRand(0.75, 1.0);
			effect.Lifetime = self.smokeTrailLifeTime * RangeRand(1.0, 1.5);
			MovableMan:AddParticle(effect);
		end
	end
end