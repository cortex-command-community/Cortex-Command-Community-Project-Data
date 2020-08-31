function Create(self)
	self.setRecoilAngle = 0;
	--Suffer from fire rate loss when firing rapidly
	self.fireRatePenaltyPerShot = 75;
	self.fireRateRevertIncrement = 1;
	self.fireRateRevertTimer = Timer();

	self.origStanceOffset = Vector(12, 0);
	self.origSharpStanceOffset = Vector(13, -2);
end
function Update(self)
	if not self.origRateOfFire then	--Check original stats on Update() to include global script changes
		self.origRateOfFire = self.RateOfFire;
	end
	if self.FiredFrame then
		local parent = self:GetParent() and self:GetParent() or self;

		self.setRecoilAngle = self.setRecoilAngle + RangeRand(1.0, 1.3)/math.sqrt(1 + parent.Mass + parent.Material.StructuralIntegrity * 0.1);
		self.RateOfFire = math.max(self.RateOfFire - self.fireRatePenaltyPerShot, 1);

		self.fireRateRevertTimer:Reset();
	elseif self.RateOfFire < self.origRateOfFire then

		self.RateOfFire = math.min(self.RateOfFire * (1 + self.fireRateRevertIncrement * 0.01) + self.fireRateRevertIncrement, self.origRateOfFire);
		self.fireRateRevertTimer:Reset();
	end

	self.RotAngle = self.RotAngle + (self.setRecoilAngle * self.FlipFactor);
	local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
	self.Pos = self.Pos - jointOffset + Vector(jointOffset.X, jointOffset.Y):RadRotate(-self.setRecoilAngle * self.FlipFactor);

	self.StanceOffset = Vector(self.origStanceOffset.X, self.origStanceOffset.Y):RadRotate(self.setRecoilAngle);
	self.SharpStanceOffset = Vector(self.origSharpStanceOffset.X, self.origSharpStanceOffset.Y):RadRotate(self.setRecoilAngle);

	if self.setRecoilAngle > 0 then
		self.setRecoilAngle = self.setRecoilAngle - 0.0001 * (self.RateOfFire/(1 + self.setRecoilAngle));

		if self.setRecoilAngle < 0 then
			self.setRecoilAngle = 0;
		end
	end
end