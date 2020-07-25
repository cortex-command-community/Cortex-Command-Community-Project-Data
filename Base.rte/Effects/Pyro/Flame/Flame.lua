function Create(self)
	self.strength = 1;
	self.checkTimer = Timer();
	self.checkDelay = math.random(30);
	if string.find(self.PresetName, "Short") then
		self.isShort = true;
		self.deleteDelay = self.Lifetime * RangeRand(0.05, 0.15);
	end
	if string.find(self.PresetName, "Ground") then
		self.notSticky = true;
	end
end
function Update(self)
	self.ToSettle = false;
	if not self.notSticky then
		if self.target and IsMOSRotating(self.target) then
			self.Vel = self.target.Vel;
			self.Pos = self.target.Pos + Vector(self.stickPos.X, self.stickPos.Y):RadRotate(self.target.RotAngle - self.targetStickAngle);
			local actor = MovableMan:GetMOFromID(self.target.RootID);
			if MovableMan:IsActor(actor) then
				actor = ToActor(actor);
				if math.random() < (self.strength * self.target.DamageMultiplier) / (actor.Mass + self.target.Material.StructuralIntegrity) then
					actor.Health = actor.Health - 1;
				end
				-- Stop, drop and roll!
				self.Lifetime = self.Lifetime - math.abs(actor.AngularVel);
			end
		else
			self.target = nil;
			if self.checkTimer:IsPastSimMS(self.checkDelay) then
				self.checkTimer:Reset();
				self.checkDelay = self.checkDelay + 3;	-- Gradually extend the delay for optimization reasons
				local checkPos = self.Pos + self.Vel * rte.PxTravelledPerFrame * math.random();
				local moCheck = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
				if moCheck ~= rte.NoMOID then
					local mo = MovableMan:GetMOFromID(moCheck);
					if mo then
						self.target = ToMOSRotating(mo);

						self.isShort = true;
						self.deleteDelay = math.random(self.Lifetime);
						self.GlobalAccScalar = 0.9;
						
						self.targetStickAngle = mo.RotAngle;	
						self.stickPos = SceneMan:ShortestDistance(mo.Pos, self.Pos, SceneMan.SceneWrapsX) * 0.8;
						self.Pos = mo.Pos + Vector(self.stickPos.X, self.stickPos.Y);
					end
				end
				if self.deleteDelay and self.Age > self.deleteDelay then
					self.ToDelete = true;
				end
			end
		end
	end
	local age = (self.Age * 0.0001) + 1;	-- Have age slightly affect particle settings relative to 10 seconds
	local chance = math.random();
	local particle;
	if chance < (0.1/age) then
		particle = CreateMOPixel("Ground Fire Burn Particle");
		particle.Vel = self.Vel + Vector(RangeRand(-15, 15), -math.random(-10, 20));
		particle.Sharpness = particle.Sharpness * RangeRand(0.5, 1.0);
	elseif chance < (0.5/age) then
		-- Spawn another, shorter flame particle occasionally
		if not self.isShort and math.random() < 0.05 then
			particle = CreateMOSParticle("Flame Hurt Short Float");
			particle.Lifetime = 4000/age;
			particle.Vel = self.Vel + Vector(0, -3);
		else
			particle = CreateMOSParticle("Flame Smoke 2");
			particle.Lifetime = math.random(250, 1000)/age;
			particle.Vel = self.Vel + Vector(0, -1);
		end
		particle.Vel = particle.Vel + Vector(math.random(), 0):RadRotate(math.random() * 6.28);
	end
	if particle then
		particle.Pos = Vector(self.Pos.X + math.random(-2, 2), self.Pos.Y - math.random(0, 4));
		MovableMan:AddParticle(particle);
	end
end