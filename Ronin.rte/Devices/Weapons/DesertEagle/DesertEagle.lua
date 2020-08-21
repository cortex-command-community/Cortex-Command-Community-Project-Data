function Create(self)
	self.setAngle = 0;
	--Suffer from fire rate loss when firing rapidly
	self.fireRatePenaltyPerShot = 75;
	self.fireRateRevertIncrement = 1;
	self.fireRateRevertTimer = Timer();
end
function Update(self)
	if not self.origRateOfFire then	--Check original stats on Update() to include global script changes
		self.origRateOfFire = self.RateOfFire;
	end
	if self.FiredFrame then
		local parent = self:GetParent() and self:GetParent() or self;

		self.setAngle = self.setAngle + RangeRand(1.0, 1.3)/math.sqrt(1 + parent.Mass + parent.Material.StructuralIntegrity/10);
		self.RateOfFire = math.max(self.RateOfFire - self.fireRatePenaltyPerShot, 1);

		self.fireRateRevertTimer:Reset();
	elseif self.RateOfFire < self.origRateOfFire then

		self.RateOfFire = math.min(self.RateOfFire * (1 + self.fireRateRevertIncrement/100) + self.fireRateRevertIncrement, self.origRateOfFire);
		self.fireRateRevertTimer:Reset();
	end

	self.RotAngle = self.RotAngle + (self.setAngle * self.FlipFactor);
	local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
	self.Pos = self.Pos - jointOffset + Vector(jointOffset.X, jointOffset.Y):RadRotate(-self.setAngle * self.FlipFactor);

	if self.setAngle > 0 then
		self.setAngle = self.setAngle - 0.0001 * (self.RateOfFire/(1 + self.setAngle));

		if self.setAngle < 0 then
			self.setAngle = 0;
		end
	end
end