function Create(self)
	self.AirResistance = self.AirResistance * RangeRand(1.0, 1.5);

	self.trailPar = CreateMOPixel("Dummy Blaster Trail Glow");
	self.trailPar.Pos = self.Pos;
	self.trailPar.Vel = self.Vel * 0.1;
	self.trailPar.Lifetime = 60;
	MovableMan:AddParticle(self.trailPar);

	self.endPar = CreateMOSParticle("Tiny Smoke Ball 1 Glow Yellow");

	self.lastVel = Vector(self.Vel.X, self.Vel.Y);
end
function Update(self)
	if not self.ToDelete and self.trailPar and MovableMan:IsParticle(self.trailPar) then
		self.trailPar.Pos = self.Pos - Vector(self.lastVel.X, self.lastVel.Y):SetMagnitude(math.min(self.lastVel.Magnitude * rte.PxTravelledPerFrame, self.TrailLength) * 0.5);
		self.trailPar.Vel = self.lastVel * 0.5;
		self.trailPar.Lifetime = self.Age + TimerMan.DeltaTimeMS;
	end
	if self.Vel.Magnitude < 4 then
		self.ToDelete = true;
	end
	self.lastVel = Vector(self.Vel.X, self.Vel.Y);
end
function Destroy(self)
	self.endPar.Pos = Vector(self.Pos.X, self.Pos.Y) + Vector(self.Vel.X, self.Vel.Y) * 0.16;
	self.endPar.Vel = Vector(self.Vel.X + math.random(-5, 5), self.Vel.Y + math.random(-5, 5)) * 0.5;
	self.endPar.HitsMOs = true;
	self.endPar.Mass = self.Mass;
	self.endPar.Lifetime = self.endPar.Lifetime/(1 + self.Age/self.Lifetime);
	MovableMan:AddParticle(self.endPar);
end