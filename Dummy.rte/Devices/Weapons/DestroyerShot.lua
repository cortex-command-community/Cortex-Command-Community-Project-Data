function Create(self)

	self.lifeTimer = Timer();
	self.emitTimer = Timer();

end

function Update(self)

	if self.emitTimer:IsPastSimMS(6) then
		self.emitTimer:Reset();
		for i = 1, 2 do
			local damagePar = CreateMOPixel("Destroyer Emission Particle "..i);
			damagePar.Pos = self.Pos;
			damagePar.Vel = Vector((math.random()*10)+20,0):RadRotate(math.pi*2*math.random());
			damagePar.Team = self.Team;
			damagePar.IgnoresTeamHits = true;
			MovableMan:AddParticle(damagePar);
		end
	end

	if self.lifeTimer:IsPastSimMS(3800) then
		self:GibThis();
	end

end