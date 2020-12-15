function Create(self)
	self.smokeTrailLifeTime = self:NumberValueExists("SmokeTrailLifeTime") and self:GetNumberValue("SmokeTrailLifeTime") or 150;
	self.smokeTrailRadius = self:NumberValueExists("SmokeTrailRadius") and self:GetNumberValue("SmokeTrailRadius") or ToMOSprite(self):GetSpriteHeight() * 0.5;
	self.smokeTrailTwirl = self:NumberValueExists("SmokeTrailTwirl") and self:GetNumberValue("SmokeTrailTwirl") or 0;
	self.smokeTwirlCounter = math.random() < 0.5 and math.pi or 0;
end
function Update(self)
	local effect;
	local offset = self.Vel * rte.PxTravelledPerFrame;	--The effect will be created the next frame so move it one frame backwards towards the barrel
	
	local trailLength = math.floor(offset.Magnitude * 0.5 - 1);
	for i = 1, trailLength do
		local effect = CreateMOSParticle("Tiny Smoke Trail 1", "Base.rte");
		if effect then
			effect.Pos = self.Pos - offset * (i/trailLength) + Vector(RangeRand(-1, 1), RangeRand(-1, 1)) * self.smokeTrailRadius;
			effect.Vel = self.Vel * RangeRand(0.75, 1);
			effect.Lifetime = self.smokeTrailLifeTime * RangeRand(0.5, 1);
		
			if self.smokeTrailTwirl > 0 then
				effect.AirResistance = effect.AirResistance * RangeRand(0.9, 1);
				effect.GlobalAccScalar = effect.GlobalAccScalar * math.random();

				effect.Pos = self.Pos - offset + offset * i/trailLength;
				effect.Vel = self.Vel + Vector(0, math.sin(self.smokeTwirlCounter) * self.smokeTrailTwirl + RangeRand(-0.1, 0.1)):RadRotate(self.Vel.AbsRadAngle);
				
				self.smokeTwirlCounter = self.smokeTwirlCounter + RangeRand(-0.2, 0.4);
			end
			MovableMan:AddParticle(effect);
		end
	end
end