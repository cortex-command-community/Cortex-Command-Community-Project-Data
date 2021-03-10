function Create(self)
	self.origMass = self.Mass;
	self.lastVel = 0;
end
function Update(self)
	if self.ID == self.RootID then
		if self.thrown == false then
			self.AngularVel = self.AngularVel - self.Vel.Magnitude * self.FlipFactor * math.random();
			self.thrown = true;
		end
		self.Mass = self.origMass + math.sqrt(self.lastVel);
	else
		self.thrown = false;
		self.Mass = self.origMass;
	end
	if self.WoundCount > 1 then
		self:Activate();
	end
	if not self.explosion and self:IsActivated() then
		self.explosion = CreateMOSRotating("Molotov Cocktail Explosion");
	end
	self.lastVel = self.Vel.Magnitude;
end
function Destroy(self)
	-- Explode into flames only if lit
	if self.explosion then
		self.explosion.Pos = Vector(self.Pos.X, self.Pos.Y);
		self.explosion.Vel = Vector(self.Vel.X, self.Vel.Y);
		MovableMan:AddParticle(self.explosion);
		self.explosion:GibThis();
	end
end