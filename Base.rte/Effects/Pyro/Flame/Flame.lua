function Create(self)
	self.strength = 1;
	self.checkTimer = Timer();
	self.checkDelay = math.random(25);
	if string.find(self.PresetName, "Ground") then
		self.notSticky = true;
	elseif string.find(self.PresetName, "Short") then
		self.isShort = true;
		self.deleteDelay = self.Lifetime * RangeRand(0.05, 0.15);
	end
end
function Update(self)
	self.ToSettle = false;
	if not self.notSticky then
		if self.target and self.target.ID ~= rte.NoMOID and not self.target.ToDelete then
			self.Vel = self.target.Vel;
			self.Pos = self.target.Pos + Vector(self.stickPos.X, self.stickPos.Y):RadRotate(self.target.RotAngle - self.targetStickAngle);
			local actor = self.target:GetRootParent();
			if MovableMan:IsActor(actor) then
				actor = ToActor(actor);
				if math.random() < (self.strength * self.target.DamageMultiplier)/(actor.Mass * 0.5 + self.target.Material.StructuralIntegrity * 0.75) then
					actor.Health = actor.Health - 1;
				end
				--Stop, drop and roll!
				self.Lifetime = self.Lifetime - math.abs(actor.AngularVel);
			end
		else
			self.target = nil;
			if self.checkTimer:IsPastSimMS(self.checkDelay) then
				self.checkTimer:Reset();
				self.checkDelay = math.floor(self.checkDelay * 1.05 + 3);	--Gradually extend the delay for optimization reasons
				local checkPos = Vector(self.Pos.X, self.Pos.Y - 1) + self.Vel * rte.PxTravelledPerFrame * math.random();
				local moCheck = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
				if moCheck ~= rte.NoMOID then
					local mo = MovableMan:GetMOFromID(moCheck);
					if mo and (self.Team == Activity.NOTEAM or mo.Team ~= self.Team) then
						self.target = ToMOSRotating(mo);

						self.isShort = true;
						self.deleteDelay = math.random(self.Lifetime);
						self.GlobalAccScalar = 0.9;
						
						self.targetStickAngle = mo.RotAngle;	
						self.stickPos = SceneMan:ShortestDistance(mo.Pos, self.Pos, SceneMan.SceneWrapsX) * 0.8;
						self.Pos = mo.Pos + Vector(self.stickPos.X, self.stickPos.Y);
					end
				elseif not self.isShort and math.random() < 0.1 then
					--Spawn another, shorter flame particle occasionally
					local particle = CreatePEmitter("Flame Hurt Short Float");
					particle.Lifetime = particle.Lifetime * RangeRand(0.6, 0.9);
					particle.Vel = self.Vel + Vector(0, -3) + Vector(math.random(), 0):RadRotate(math.random() * math.pi * 2);
					particle.Pos = Vector(self.Pos.X, self.Pos.Y - 1);
					MovableMan:AddParticle(particle);
				end
				if self.deleteDelay and self.Age > self.deleteDelay then
					self.ToDelete = true;
				end
			end
		end
	end
end