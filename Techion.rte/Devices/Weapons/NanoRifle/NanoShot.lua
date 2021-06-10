function Create(self)
	--Collide with objects and deploy the destroy effect.
	self.CheckCollision = function(vel)
		local Trace = vel * rte.PxTravelledPerFrame;
		local moid = SceneMan:CastMORay(self.Pos, Trace, rte.NoMOID, self.Team, rte.airID, true, 1);
		if moid > 0 and moid < rte.NoMOID then
			local hitPos = Vector();
			SceneMan:CastFindMORay(self.Pos, Trace, moid, hitPos, rte.airID, true, 1);
			self.deleteNextFrame = true;
			self.Vel = (SceneMan:ShortestDistance(self.Pos, hitPos, true)/TimerMan.DeltaTimeSecs)/GetPPM();

			local target = MovableMan:GetMOFromID(moid);
			if target then
				local destroy = CreateAEmitter("Nanobot Destroy Effect", "Techion.rte");
				destroy.Sharpness = target.UniqueID;
				destroy.Pos = hitPos + SceneMan:ShortestDistance(hitPos, target.Pos, true):SetMagnitude(3);
				destroy.Vel = target.Vel;
				MovableMan:AddParticle(destroy);
			end
		end
	end
	--Speed at which this can actually activate.
	self.speedThreshold = 100;

	self.deleteNextFrame = false;
	--Check backward.
	self.CheckCollision(Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi));

	self.trailLength = 50;

	self.trailPar = CreateMOPixel("Nano Rifle Trail Glow");
	self.trailPar.Pos = self.Pos;
	self.trailPar.Vel = self.Vel * 0.1;
	self.trailPar.Lifetime = 60;
	MovableMan:AddParticle(self.trailPar);

	self.lastVel = Vector(self.Vel.X, self.Vel.Y);
end

function Update(self)
	if not self.ToDelete and self.trailPar and MovableMan:IsParticle(self.trailPar) then
		self.trailPar.Pos = self.Pos - Vector(self.lastVel.X, self.lastVel.Y):SetMagnitude(math.min(self.lastVel.Magnitude * rte.PxTravelledPerFrame, self.trailLength) * 0.5);
		self.trailPar.Vel = self.lastVel * 0.5;
		self.trailPar.Lifetime = self.Age + TimerMan.DeltaTimeMS;
	end
	if self.deleteNextFrame then
		self.ToDelete = true;
	elseif self.Vel.Magnitude >= self.speedThreshold then
		--Check forward.
		self.CheckCollision(self.Vel);
	end
	self.lastVel = Vector(self.Vel.X, self.Vel.Y);
end

function OnCollideWithTerrain(self, terrainID)
	if SceneMan:GetMaterialFromID(terrainID).StructuralIntegrity > (self.Vel.Magnitude * self.Mass * self.Sharpness) * 0.5 then
		self.ToDelete = true;
	end
end