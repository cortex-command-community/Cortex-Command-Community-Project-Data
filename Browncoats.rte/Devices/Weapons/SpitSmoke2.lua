function Create(self)
	if self.Magazine then
		self.ammo = self.Magazine.RoundCount
	else
		self.ammo = 0
	end
end

function Update(self)
	if self.Magazine then
		if self.ammo > self.Magazine.RoundCount then

			local checkFlip = 1;
			if self.HFlipped then
				checkFlip = -1;
			end

			local randomSmoke = math.floor(math.random()*3)+3;

			for i = 1, randomSmoke do
				local smokefx = CreateMOSParticle("Tiny Smoke Ball 1");
				smokefx.Pos = self.MuzzlePos;
				smokefx.Vel = Vector(((math.random()*4)+1)*checkFlip,0):RadRotate(self.RotAngle+(math.random()*0.6)-0.3);
				MovableMan:AddParticle(smokefx);
				smokefx = nil;
			end

		end
		self.ammo = self.Magazine.RoundCount
	end
end
