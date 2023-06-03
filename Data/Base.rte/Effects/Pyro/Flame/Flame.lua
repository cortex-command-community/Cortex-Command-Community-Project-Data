function Create(self)
	if self.PresetName:find("Short") then
		self.isShort = true;
	end
	if self.Throttle == nil then
		self.Throttle = 0;
	end
end

function Update(self)
	local ageRatio = self.Age/self.Lifetime;
	self.ToSettle = false;
	self.Throttle = self.Throttle - TimerMan.DeltaTimeMS/self.Lifetime;

	if self.target and MovableMan:ValidMO(self.target) and self.target.ID ~= rte.NoMOID and not self.target.ToDelete then
		self.Vel = self.target.Vel;
		self.Pos = self.target.Pos + Vector(self.stickOffset.X, self.stickOffset.Y):RadRotate(self.target.RotAngle - self.targetStickAngle);
		local actor = self.target:GetRootParent();
		if MovableMan:IsActor(actor) then
			actor = ToActor(actor);
			actor.Health = actor.Health - math.max(self.target.DamageMultiplier * (self.Throttle + 1), 0.1)/(actor.Mass * 0.7 + self.target.Material.StructuralIntegrity);
			--Stop, drop and roll!
			self.Lifetime = self.Lifetime - math.abs(actor.AngularVel);
		end
	else
		self.target = nil;
		if math.random() > ageRatio then
			if self.Vel:MagnitudeIsGreaterThan(1) then
				local checkPos = Vector(self.Pos.X, self.Pos.Y - 1) + self.Vel * rte.PxTravelledPerFrame * math.random();
				local moCheck = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y, self.Team);
				if moCheck ~= rte.NoMOID then
					local mo = MovableMan:GetMOFromID(moCheck);
					self.target = ToMOSRotating(mo);

					self.isShort = true;
					self.deleteDelay = math.random(self.Lifetime);

					self.targetStickAngle = mo.RotAngle;
					self.stickOffset = SceneMan:ShortestDistance(mo.Pos, self.Pos, SceneMan.SceneWrapsX) * 0.8;

					self.GlobalAccScalar = 0.9;
				elseif self.GlobalAccScalar < 0.5 and self.isShort and math.random() < 0.2 and SceneMan:GetTerrMatter(checkPos.X, checkPos.Y) ~= rte.airID then
					self.deleteDelay = math.random(self.Lifetime);
					self.GlobalAccScalar = 0.9;
				end
			end
			
			--Spawn another, shorter self particle occasionally
			if not self.isShort and math.random() < self.Throttle * 0.1 then
				local particle = CreatePEmitter("Flame Hurt Short Float", "Base.rte");
				particle.Lifetime = self.Lifetime * RangeRand(0.6, 0.9);
				particle.Vel = self.Vel + Vector(0, -3) + Vector(math.random(), 0):RadRotate(math.random() * math.pi * 2);
				particle.Pos = Vector(self.Pos.X, self.Pos.Y - 1);
				MovableMan:AddParticle(particle);
			end
		end
		if self.deleteDelay and self.Age > self.deleteDelay then
			self.ToDelete = true;
		end
	end
end