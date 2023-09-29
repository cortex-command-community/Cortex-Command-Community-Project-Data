function Create(self)
	self.ageRatio = 1;
	--A separate delay for lifetime control is used to preserve animation speed
	self.deleteDelay = self.PresetName:find("Short") and self.Lifetime * RangeRand(0.1, 0.2) or self.Lifetime;
	--Define Throttle for non-emitter particles
	if self.Throttle == nil then
		self.Throttle = 0;
	end
	
	-- for full functionality: have a FlameProperties.lua or similar that sets the following values to whatever you desire:
	
		-- extra hurty particle toggle when on ground/without target
	--self.extraParticles = false;
	
		-- team awareness toggle... friendly fire hahahahahahaah
	--self.teamAware = false;
	
	self.flameLingerChance = self.flameLingerChance or 0.5;
	
		-- i am not sure why this grass interaction occurs, but i'm not going to remove it, Chesterton's Fence and all
	--self.grassInteraction = true;
	
end

function Update(self)
	self.ageRatio = 1 - self.Age/self.deleteDelay;
	self:NotResting();
	--TODO: Use Throttle to combine multiple flames into one
	self.Throttle = self.Throttle - TimerMan.DeltaTimeMS/self.Lifetime;

	if self.target and IsMOSRotating(self.target) and self.target.ID ~= rte.NoMOID and not self.target.ToDelete and (self.teamAware ~= true or self.target.Team ~= self.Team) then
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
		if self.extraParticles then
			local extraPar = CreateMOPixel("Ground Fire Burn Particle");
			extraPar.Pos = self.Pos;
			extraPar.Team = self.Team;
			extraPar.IgnoresTeamHits = true;
			extraPar.Vel = self.Vel + Vector(RangeRand(-20, 20), -math.random(-10, 30));
			MovableMan:AddParticle(extraPar);
		end
	end
	if self.Age > self.deleteDelay then
		self.ToDelete = true;
	end
end

function OnCollideWithMO(self, mo, rootMO)
	if self.target == nil then
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
	if self.grassInteraction ~= false and terrainID == rte.grassID then
		local newFlame = CreatePEmitter("Ground Flame", "Base.rte");
		newFlame.Pos = self.Pos;
		newFlame.Vel = self.Vel;
		MovableMan:AddParticle(newFlame);
		self.ToDelete = true;
	elseif self.HitsMOs then
		--Let the flames linger occasionally
		if math.random() < self.flameLingerChance then
			self.GlobalAccScalar = 0.9;
			self.deleteDelay = math.random(self.Age, self.Lifetime);
		end
		self.HitsMOs = false;
	end
end