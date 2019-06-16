
function Update(self)
	local Effect
	local Offset = self.Vel*(20*TimerMan.DeltaTimeSecs)	-- the effect will be created the next frame so move it one frame backwards towards the barrel
	
	-- smoke trail
	local trailLength = math.floor(Offset.Magnitude+0.5)
	for i = 1, trailLength, 6 do
		Effect = CreateMOSParticle("Sniper Smoke Trail " .. math.random(3), "Imperatus.rte")
		if Effect then
			Effect.Pos = self.Pos - Offset * (i/trailLength) + Vector(RangeRand(-2, 2), RangeRand(-2, 2))
			Effect.Vel = self.Vel * RangeRand(0.9, 1.0)
			MovableMan:AddParticle(Effect)
		end
	end
end
