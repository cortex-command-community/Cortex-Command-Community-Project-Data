function Create(self)

	self.lifeTimer = Timer();

end

function Update(self)

	if self.lifeTimer:IsPastSimMS(3000) then
		local explosion = CreateMOSRotating("Coalition Breaker Grenade Explosion");
		explosion.Pos = self.Pos;
		explosion:GibThis();
		MovableMan:AddParticle(explosion);
		self.ToDelete = true;
	else
		self.ToDelete = false;
		self.ToSettle = false;
	end

end

function Destroy(self)

	ActivityMan:GetActivity():ReportDeath(self.Team,-1);

end