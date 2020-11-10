function Create(self)
	self.trailLength = 50;
	local trail = CreateMOPixel("Incendiary Bullet Trail Glow 0");
	trail.Pos = self.Pos - Vector(self.Vel.X, self.Vel.Y) * rte.PxTravelledPerFrame * 0.5;
	trail.EffectRotAngle = self.Vel.AbsRadAngle;
	MovableMan:AddParticle(trail);
	
	self.fire = CreatePEmitter("Flame Hurt Short");
end
function Update(self)
	local velFactor = math.floor(1 + math.sqrt(self.Vel.Magnitude)/(1 + self.Age * 0.01));
	for i = 1, velFactor do
		local particle = i == 1 and CreateMOPixel("Ground Fire Burn Particle") or CreateMOSParticle("Flame Smoke 1 Micro");
		particle.Pos = Vector(self.Pos.X, self.Pos.Y) - Vector(self.Vel.X, self.Vel.Y) * rte.PxTravelledPerFrame * (i/velFactor);
		particle.Vel = self.Vel * 0.5 + Vector(math.random(5, 10)/velFactor, 0):RadRotate(math.random() * 6.28);
		particle.Lifetime = particle.Lifetime * RangeRand(0.7, math.sqrt(velFactor));
		particle.Sharpness = particle.Sharpness/i;
		particle.GlobalAccScalar = -math.random();
		particle.Team = self.Team;
		particle.IgnoresTeamHits = true;
		MovableMan:AddParticle(particle);
	end
	local glowNumber = self.Vel.Magnitude > 60 and 1 or (self.Vel.Magnitude > 40 and 2 or (self.Vel.Magnitude > 20 and 3 or 4));
	local trail = CreateMOPixel("Incendiary Bullet Trail Glow ".. glowNumber);
	trail.Pos = self.Pos - Vector(self.Vel.X, self.Vel.Y):SetMagnitude(math.min(self.Vel.Magnitude * rte.PxTravelledPerFrame, self.trailLength) * 0.5);
	trail.EffectRotAngle = self.Vel.AbsRadAngle;
	MovableMan:AddParticle(trail);

	if self.ToDelete then
		if self.Age < self.Lifetime then
			local hitPos = Vector(self.Pos.X, self.Pos.Y);
			local trace = Vector(self.Vel.X, self.Vel.Y) * rte.PxTravelledPerFrame;
			local skipPx = 2;
			local obstacleRay = SceneMan:CastObstacleRay(Vector(self.Pos.X, self.Pos.Y), trace, Vector(), hitPos, rte.NoMOID, self.Team, rte.airID, skipPx);
			if obstacleRay >= 0 then
				self.fire.Pos = hitPos;
				self.fire.Vel = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(skipPx);
				MovableMan:AddParticle(self.fire);
			end
		else
			local smoke = CreateMOSParticle("Flame Smoke 1");
			smoke.Pos = Vector(self.Pos.X, self.Pos.Y);
			smoke.Vel = Vector(self.Vel.X, self.Vel.Y) * 0.5;
			smoke.Lifetime = math.random(250, 500);
			MovableMan:AddParticle(smoke);
		end
	end
end