function Create(self)

	self.reloaded = false;
	self.ammoCounter = 0;

end

function Update(self)

	if self.Magazine ~= nil then
		if self.reloaded == false then
			self.reloaded = true;
			self.ammoCounter = self.Magazine.RoundCount;
		else
			if self.ammoCounter ~= self.Magazine.RoundCount then

				if self.HFlipped == false then
					self.negativeNum = 1;
				else
					self.negativeNum = -1;
				end

				local bullet = CreateMOSRotating("Particle Nucleo");
				bullet.Pos = self.MuzzlePos;
				bullet.Vel = self.Vel + Vector(30*self.negativeNum,0):RadRotate(self.RotAngle);
				bullet.Sharpness = self.UniqueID;
				bullet.Team = self.Team;

				MovableMan:AddParticle(bullet);

			end
			self.ammoCounter = self.Magazine.RoundCount;
		end
	else
		self.reloaded = false;
	end

end