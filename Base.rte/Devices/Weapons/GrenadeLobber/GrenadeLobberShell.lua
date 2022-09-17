function Create(self)
	self.setAngle = 0;
	self.tilt = 0.2;
	self.loadTimer = Timer();
	self.shellsToEject = 0;
end
function Update(self)
	if self.setAngle > 0 then
		self.setAngle = self.setAngle - 0.0001 * self.RateOfFire;
		if self.setAngle < 0 then
			self.setAngle = 0;
		end
	end
	if self.FiredFrame then
		self.setAngle = self.setAngle + self.tilt;
	end
	self.RotAngle = self.RotAngle + self.setAngle * self.FlipFactor;
	local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
	self.Pos = self.Pos - jointOffset + Vector(jointOffset.X, jointOffset.Y):RadRotate(-self.setAngle * self.FlipFactor);

    if self.FiredFrame then
        self.shellsToEject = 1
    end
    if self.Magazine then
        self.loadTimer:Reset();
        self.Frame = 0;
    elseif self:IsReloading() then
		if self.loadTimer:IsPastSimMS(self.ReloadTime * 0.3) then
			if self.Frame ~= 1 then
				AudioMan:PlaySound("Ronin.rte/Devices/Weapons/DoubleBarreledShotgun/Sounds/Eject.flac", self.Pos);
				self.Frame = 1;
			end
			if self.shellsToEject > 0 then
				local shell = CreateAEmitter("Smoking Cannon Casing");
				shell.Pos = self.Pos;
				shell.Vel = self.Vel + Vector(-6 * self.FlipFactor, -3):RadRotate(self.RotAngle):DegRotate(math.random(-7, 7)) * RangeRand(0.7, 1.0);
				MovableMan:AddParticle(shell);
				self.shellsToEject = self.shellsToEject - 1;
			end
		end
	end
end