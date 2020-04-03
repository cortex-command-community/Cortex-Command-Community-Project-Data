function Create(self)
	self.strength = 80;	-- Damage frequency factor
	self.checkTimer = Timer();
	self.checkDelay = math.random(20);
end

function Update(self)
	self.ToSettle = false;
	if self.target and IsMOSRotating(self.target) then
		self.Vel = self.target.Vel;
		self.Pos = self.target.Pos - Vector(self.stickPos.X, self.stickPos.Y):RadRotate(self.target.RotAngle - self.tsAngle);
		local actor = MovableMan:GetMOFromID(self.target.RootID);	-- Inflict damage on the root actor
		if MovableMan:IsActor(actor) then
			actor = ToActor(actor);
			if math.random() < (self.strength * self.target.DamageMultiplier) / actor.Mass / (self.target.Material.StructuralIntegrity) then
				actor.Health = actor.Health - 1;
			end
		end
	else
		self.target = nil;
		if self.checkTimer:IsPastSimMS(self.checkDelay) then
			self.checkTimer:Reset();
			self.checkDelay = self.checkDelay + 1;	-- Gradually extend the delay for optimization reasons
			local checkPos = self.Pos + Vector(self.Vel.X, self.Vel.Y):SetMagnitude(math.sqrt(self.Vel.Magnitude));
			local mocheck = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
			if mocheck ~= 255 then
				local mo = MovableMan:GetMOFromID(mocheck);
				if mo then
					self.target = ToMOSRotating(mo);
					self.tsAngle = mo.RotAngle;	-- Target angle when sticking	
					self.stickPos = SceneMan:ShortestDistance(mo.Pos, self.Pos, SceneMan.SceneWrapsX) * 0.8;
					self.Pos = mo.Pos - Vector(self.stickPos.X, self.stickPos.Y);
				end
			end
		end
	end
	local age = self.Age * 0.0001 + 1;
	local chance = math.random();
	local particle;
	if chance < (0.1 / age) then
		particle = CreateMOPixel("Ground Fire Burn Particle");
		particle.Vel = self.Vel + Vector(RangeRand(-10, 10), -math.random(5, 20));
	elseif chance < (1 / age) then
		particle = CreateMOSParticle("Flame Smoke 1");
		particle.Vel = self.Vel + Vector(0, -3) + Vector(math.random(0, 3), 0):RadRotate(math.random() * 6.28);
		particle.Lifetime = 100 + math.random(math.ceil(700 / age));
	end
	if particle then
		particle.Pos = Vector(self.Pos.X + math.random(-1, 1), self.Pos.Y - math.random(0, 2));
		MovableMan:AddParticle(particle);
	end
end