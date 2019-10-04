function Create(self)

	self.dinSound = false;
	self.lastAmmo = 0;

end

function Update(self)

	if self.Magazine ~= nil then
		self.lastMag = self.Magazine;
		self.lastAmmo = self.Magazine.RoundCount;
		self.dingSound = false;
		if self.Magazine.RoundCount <= 0 then
			self:Reload();
		end
	else
		if self.dingSound == false and self.lastAmmo <= 0 then
			local soundfx = CreateAEmitter("Ronin M1 Garand Sound Ding");
			soundfx.Pos = self.Pos;
			MovableMan:AddParticle(soundfx);
			if MovableMan:IsParticle(self.lastMag) then
				if self.HFlipped == false then
					self.negativeNum = 1;
				else
					self.negativeNum = -1;
				end
				self.lastMag.Vel = self.lastMag.Vel + Vector(-4*self.negativeNum,-7):RadRotate(self.RotAngle);
			end
		end
		self.dingSound = true;
	end

end