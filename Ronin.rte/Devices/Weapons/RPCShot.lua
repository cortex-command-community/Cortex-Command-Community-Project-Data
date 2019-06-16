function Create(self)

	self.lifeTimer = Timer();

end

function Update(self)

	self.AngularVel = self.AngularVel * 0.2;

	if self.lifeTimer:IsPastSimMS(5000) then
		local explosion = CreateMOSRotating("Ronin RPC Explosion");
		explosion.Pos = self.Pos;
		explosion:GibThis();
		MovableMan:AddParticle(explosion);
		self.ToDelete = true;
	else
		self.ToDelete = false;
	end

end