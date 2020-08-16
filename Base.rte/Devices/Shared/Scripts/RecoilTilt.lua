function Create(self)
	self.setRecoilAngle = 0;
	self.recoilTilt = 1/math.sqrt(self.Radius);
end
function Update(self)
	if self.setRecoilAngle > 0 then
		self.setRecoilAngle = self.setRecoilAngle - (0.003 * (10 + math.sqrt(self.RateOfFire) * self.setRecoilAngle));
		if self.setRecoilAngle < 0 then
			self.setRecoilAngle = 0;
		end
	end
	if self.FiredFrame then
		self.setRecoilAngle = self.setRecoilAngle + (self.recoilTilt * RangeRand(0.1, 1))/(1 + self.setRecoilAngle);
	end
	self.RotAngle = self.RotAngle + (self.setRecoilAngle * self.FlipFactor);
	local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
	self.Pos = self.Pos - jointOffset + Vector(jointOffset.X, jointOffset.Y):RadRotate(-self.setRecoilAngle * self.FlipFactor);
end