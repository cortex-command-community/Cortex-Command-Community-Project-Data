function Create(self)
	local Effect
	local Offset = self.Vel*(20*TimerMan.DeltaTimeSecs)	-- the effect will be created the next frame so move it one frame backwards towards the barrel
	
	-- bullets
	for i = 1, 5 do
		Effect = CreateMOPixel("Imperatus Heavy Sniper Particle", "Imperatus.rte")
		if Effect then
			Effect.Vel = self.Vel
			Effect.Pos = self.Pos + Offset * 0.25	-- place the MOPixels in front of the MOSRotating
			Effect.Team = self.Team
			Effect.IgnoresTeamHits = true
			MovableMan:AddParticle(Effect)
		end
	end
	
	-- smoke forward
	for i = 1, 4 do
		Effect = CreateMOSParticle("Side Thruster Blast Ball 1", "Base.rte")
		if Effect then
			Effect.Vel = self:RotateOffset(Vector(RangeRand(6,9),RangeRand(-3,3)))
			Effect.Pos = self.Pos - Offset
			MovableMan:AddParticle(Effect)
		end
	end
	
	-- smoke up
	for i = 1, 5 do
		Effect = CreateMOSParticle("Tiny Smoke Ball 1", "Base.rte")
		if Effect then
			Effect.Vel = self:RotateOffset(Vector(RangeRand(-2,2), -RangeRand(7,11)))
			Effect.Pos = self.Pos - Offset
			MovableMan:AddParticle(Effect)
		end
	end
	
	-- smoke down
	for i = 1, 5 do
		Effect = CreateMOSParticle("Tiny Smoke Ball 1", "Base.rte")
		if Effect then
			Effect.Vel = self:RotateOffset(Vector(RangeRand(-2,2), RangeRand(7,11)))
			Effect.Pos = self.Pos - Offset
			MovableMan:AddParticle(Effect)
		end
	end
end

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
