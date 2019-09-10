function Create(self)
	local Effect
	local Offset = self.Vel*(20*TimerMan.DeltaTimeSecs)	-- the effect will be created the next frame so move it one frame backwards towards the barrel
	
	-- bullets
	for i = 1, 4 do
		Effect = CreateMOPixel("Particle Coalition Sniper Heavy", "Coalition.rte")
		if Effect then
			Effect.Vel = self.Vel
			Effect.Pos = self.Pos
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
	for i = 1, math.floor(self.Vel.Magnitude*0.045) do
		Effect = CreateMOSParticle("Tiny Smoke Trail " .. math.random(3), "Coalition.rte")
		if Effect then
			Effect.Pos = self.Pos - Offset * i/8 + Vector(RangeRand(-2,2),RangeRand(-2,2))
			Effect.Vel = (self.Vel + Vector(RangeRand(-10,30),RangeRand(-10,10))) / 20
			MovableMan:AddParticle(Effect)
		end
	end
end
