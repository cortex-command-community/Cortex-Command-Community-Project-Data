function Create(self)
	self.detonationDelay = 3000;
end
function Update(self)
	if self.Age > self.detonationDelay then
		local explosion = CreateMOSRotating("Ronin M79 Grenade Explosion");
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

	ActivityMan:GetActivity():ReportDeath(self.Team, -1);
end