function Create(self)
	self.disintegrationStrength = 50;
	self.EffectRotAngle = self.Vel.AbsRadAngle;
	--Check backward (second argument) on the first frame as the projectile might be bouncing off something immediately
	PulsarDissipate(self, true);
	
	self.trailPar = CreateMOPixel(self.PresetName .. " Trail Glow", "Techion.rte");
	self.trailPar.Pos = self.Pos - (self.Vel * rte.PxTravelledPerFrame);
	self.trailPar.Vel = self.Vel * 0.1;
	self.trailPar.Lifetime = 60;
	MovableMan:AddParticle(self.trailPar);
end
function Update(self)
	self.ToSettle = false;
	if self.explosion then
		self.ToDelete = true;
	else
		if PulsarDissipate(self, false) == false then
			self.EffectRotAngle = self.Vel.AbsRadAngle;
		end
		if self.trailPar and MovableMan:IsParticle(self.trailPar) then
			self.trailPar.Pos = self.Pos - Vector(self.Vel.X, self.Vel.Y):SetMagnitude(self.TrailLength - 1);
			self.trailPar.Vel = self.Vel * 0.5;
			self.trailPar.Lifetime = self.Age + TimerMan.DeltaTimeMS;
		else
			self.trailPar = nil;
		end
	end
end
function PulsarDissipate(self, inverted)
	self.lastVel = self.lastVel or Vector(self.Vel.X, self.Vel.Y);

	local trace = inverted and Vector(-self.Vel.X, -self.Vel.Y):SetMagnitude(GetPPM()) or Vector(self.Vel.X, self.Vel.Y):SetMagnitude(self.Vel.Magnitude * rte.PxTravelledPerFrame + 1);
	local hit = false;
	local hitPos = Vector(self.Pos.X, self.Pos.Y);
	local skipPx = math.sqrt(self.Vel.Magnitude) * 0.5;

	local moid = SceneMan:CastObstacleRay(self.Pos, trace, hitPos, Vector(), self.ID, self.Team, rte.airID, skipPx) >= 0 and SceneMan:GetMOIDPixel(hitPos.X, hitPos.Y) or self.HitWhatMOID;
	
	if moid ~= rte.NoMOID then
		local mo = MovableMan:GetMOFromID(moid);
		if mo then
			hit = true;

			local melt = CreateMOPixel("Disintegrator");
			melt.Pos = self.Pos;
			melt.Team = self.Team;
			melt.Sharpness = mo.RootID;
			melt.PinStrength = self.disintegrationStrength or 1;
			MovableMan:AddMO(melt);
		end
	else
		local penetration = self.Mass * self.Sharpness * self.Vel.Magnitude;
		if SceneMan:GetMaterialFromID(SceneMan:GetTerrMatter(hitPos.X, hitPos.Y)).StructuralIntegrity > penetration then
			hit = true;
		elseif self.Vel.Magnitude < self.lastVel.Magnitude * 0.5 then
			hit = true;
		end
	end
	if hit then
		local offset = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(skipPx);
		self.explosion = CreateAEmitter("Techion.rte/Laser Dissipate Effect");
		self.explosion.Pos = hitPos - offset;
		self.explosion.RotAngle = offset.AbsRadAngle;
		self.explosion.Team = self.Team;
		self.explosion.Vel = offset;
		MovableMan:AddParticle(self.explosion);
	end
	self.lastVel = Vector(self.Vel.X, self.Vel.Y);
	
	return hit;
end
--[[ To-do: Use this system instead
function OnCollideWithMO(self, mo, parentMO)
	self.explosion = CreateAEmitter("Techion.rte/Laser Dissipate Effect");
	self.explosion.Pos = self.Pos;
	self.explosion.RotAngle = self.Vel.AbsRadAngle;
	self.explosion.Team = self.Team;
	self.explosion.Vel = self.Vel;
	MovableMan:AddParticle(self.explosion);
end
function OnCollideWithTerrain(self, terrainID)
	self.explosion = CreateAEmitter("Techion.rte/Laser Dissipate Effect");
	self.explosion.Pos = self.Pos;
	self.explosion.RotAngle = self.Vel.AbsRadAngle;
	self.explosion.Team = self.Team;
	self.explosion.Vel = self.Vel;
	MovableMan:AddParticle(self.explosion);
end]]--