function Create(self)

	self.lifeTimer = Timer();
	self.smokeTimer = Timer();
	self.smokeDelay = 25;

	self.triggered = false;

end

function Update(self)

	if self.Sharpness == 1 then
		if self.triggered == false then
			self.triggered = true;
			self.lifeTimer:Reset();
		end
		if self.smokeTimer:IsPastSimMS(self.smokeDelay) and not(self.lifeTimer:IsPastSimMS(750)) then
			self.smokeTimer:Reset();
			local smoke = CreateMOSParticle("Tiny Smoke Ball 1");
			smoke.Pos = self.Pos;
			smoke.Vel = self.Vel + Vector((math.random()*5)-2.5,(math.random()*5)-2.5);
			MovableMan:AddParticle(smoke);
		end

	end
end