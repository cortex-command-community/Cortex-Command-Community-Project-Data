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
		if self.dingSound == false then
			if MovableMan:IsParticle(self.lastMag) then
				if self.HFlipped == false then
					self.negativeNum = 1;
				else
					self.negativeNum = -1;
				end
				self.lastMag.Sharpness = 1;
				self.lastMag.Vel = self.lastMag.Vel + Vector(-12*self.negativeNum,0):RadRotate(self.RotAngle);
				local soundfx = CreateAEmitter("Techion Giga Pulsar Sound Magazine Eject");
				soundfx.Pos = self.lastMag.Pos;
				soundfx.RotAngle = Vector(-1*self.negativeNum,0):RadRotate(self.RotAngle).AbsRadAngle;
				MovableMan:AddParticle(soundfx);
			end
		end
		self.dingSound = true;
	end

end