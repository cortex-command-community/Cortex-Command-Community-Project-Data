function Create(self)
	local Effect
	local Offset = self.Vel*(20*TimerMan.DeltaTimeSecs)/1.3	-- the effect will be created the next frame so move it one frame backwards towards the barrel
	
	for i = 1, 2 do
		Effect = CreateMOSParticle("Tiny Smoke Ball 1", "Base.rte")
		if Effect then
			Effect.Pos = self.Pos - Offset
			Effect.Vel = (self.Vel + Vector(RangeRand(-20,20), RangeRand(-20,20))) / 30
			MovableMan:AddParticle(Effect)
		end
	end
	
	if PosRand() < 0.5 then
		Effect = CreateMOSParticle("Side Thruster Blast Ball 1", "Base.rte")
		if Effect then
			Effect.Pos = self.Pos - Offset
			Effect.Vel = self.Vel / 10
			MovableMan:AddParticle(Effect)
		end
	end

	self.Vel = self.Vel+Vector(5*math.random(),0):RadRotate(math.random()*(math.pi*2));
	self.time = math.random(20,60);
	self.timer = Timer();

end

function Update(self)

	if self.timer:IsPastSimMS(self.time) then
		self.timer:Reset();

		self.Mass = self.Mass*0.95;
		self.Sharpness = self.Sharpness*0.95;
	end
end