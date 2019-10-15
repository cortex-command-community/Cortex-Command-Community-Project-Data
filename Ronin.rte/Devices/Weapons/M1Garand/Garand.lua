function Create(self)
	self.pingSound = false;
	self.lastAmmo = 0;
end

function Update(self)
	if self.Magazine ~= nil then
		self.lastMag = self.Magazine;
		self.lastAmmo = self.Magazine.RoundCount;
		self.pingSound = false;
		if self.Magazine.RoundCount <= 0 then
			self:Reload();
		end
	else
		if self.pingSound == false and self.lastAmmo <= 0 then
			local soundEffect = CreateAEmitter("Ronin M1 Garand Sound Ping","Ronin.rte");
			soundEffect.Pos = self.Pos;
			MovableMan:AddParticle(soundEffect);
			if MovableMan:IsParticle(self.lastMag) then
				self.lastMag.Vel = self.lastMag.Vel + Vector(-4 * self.FlipFactor, -7):RadRotate(self.RotAngle);
			end
		end
		self.pingSound = true;
	end
end