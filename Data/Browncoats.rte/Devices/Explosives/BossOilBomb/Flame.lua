function Create(self)
	self.ageRatio = 1;
	--A separate delay for lifetime control is used to preserve animation speed
	self.deleteDelay = self.PresetName:find("Short") and self.Lifetime * RangeRand(0.1, 0.2) or self.Lifetime;
	--Define Throttle for non-emitter particles
	if self.Throttle == nil then
		self.Throttle = 0;
	end
end

function Update(self)
	self.ageRatio = 1 - self.Age/self.deleteDelay;
	self:NotResting();
	--TODO: Use Throttle to combine multiple flames into one
	self.Throttle = self.Throttle - TimerMan.DeltaTimeMS/self.Lifetime;

	if self.target and IsMOSRotating(self.target) and self.target.ID ~= rte.NoMOID and self.target.Team ~= self.Team and not self.target.ToDelete then
		self.Vel = Vector();
		self.Pos = self.target.Pos + Vector(self.stickOffset.X, self.stickOffset.Y):RadRotate(self.target.RotAngle - self.targetStickAngle);
		local actor = self.target:GetRootParent();
		if MovableMan:IsActor(actor) then
			actor = ToActor(actor);
			actor.Health = actor.Health - math.max(self.target.DamageMultiplier * (self.Throttle + 1), 0.1)/((actor.Mass - actor.InventoryMass) * 0.5 + self.target.Material.StructuralIntegrity);
			--Stop, drop and roll!
			self.deleteDelay = self.deleteDelay - math.abs(actor.AngularVel);
		end
	else
		self.target = nil;
		if math.random() < math.max(self.Throttle + 0.5, 0.1) then
			local firePar = CreateMOPixel("Ground Fire Burn Particle");
			firePar.Pos = self.Pos;
			firePar.Team = self.Team;
			firePar.IgnoresTeamHits = true;
			firePar.Vel = self.Vel + Vector(RangeRand(-20, 20), -math.random(-10, 30));
			MovableMan:AddParticle(firePar);
		end
	end
	if self.Age > self.deleteDelay then
		self.ToDelete = true;
	end
end

function OnCollideWithMO(self, mo, rootMO)
	if self.target == nil and mo.Team ~= mo.Team then
		--Stick to objects on collision
		if not mo.ToDelete and IsMOSRotating(mo) and math.random() < self.ageRatio then
			self.target = ToMOSRotating(mo);
			self.targetStickAngle = mo.RotAngle;
			local velOffset = self.PrevVel * rte.PxTravelledPerFrame * 0.5;
			local dist = SceneMan:ShortestDistance(mo.Pos, self.Pos + velOffset, SceneMan.SceneWrapsX);
			dist:SetMagnitude(math.max(dist.Magnitude - velOffset.Magnitude, 0));
			self.stickOffset = Vector(dist.X, dist.Y);
			
			self.deleteDelay = self.Lifetime;
		else
			self.deleteDelay = math.random(self.Age, self.Lifetime);
		end
		self.GlobalAccScalar = 0.9;
		self.HitsMOs = false;
	end
end

function OnCollideWithTerrain(self, terrainID)

	if self.HitsMOs then
		--Let the flames linger almost always
		if math.random() < 0.9 then
			self.GlobalAccScalar = 0.9;
			self.deleteDelay = math.random(self.Age, self.Lifetime);
		end
		self.HitsMOs = false;
	end
end