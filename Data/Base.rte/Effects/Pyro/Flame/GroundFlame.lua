function Create(self)
	self.shortFlame = CreatePEmitter("Flame Hurt Short Float", "Base.rte");
	
	self.flameTimer = Timer();
	self.flameTimer:SetSimTimeLimitMS(math.random(self.Lifetime));
	--Define Throttle for non-emitter particles
	if self.Throttle == nil then
		self.Throttle = 0;
	end
end

function Update(self)
	self:NotResting();
	--TODO: Use Throttle to combine multiple flames into one
	self.Throttle = self.Throttle - TimerMan.DeltaTimeMS/self.Lifetime;
	--Spawn another, shorter flame occasionally
	if self.flameTimer:IsPastSimTimeLimit() then
		self.flameTimer:Reset();
		self.flameTimer:SetSimTimeLimitMS(1000 + self.Age);
		
		local particle = self.shortFlame:Clone();
		particle.Lifetime = math.max(particle.Lifetime - self.Age, 100);
		particle.Vel = self.Vel + Vector(0, -3) + Vector(math.random(), 0):RadRotate(RangeRand(-math.pi, math.pi));
		particle.Pos = self.Pos - Vector(0, 1);
		MovableMan:AddParticle(particle);
	end
end