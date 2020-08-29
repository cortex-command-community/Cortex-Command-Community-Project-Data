function Create(self)
	self.setRecoilAngle = 0;
	self.recoilAngleSize = self:NumberValueExists("RecoilAngleSize") and math.rad(self:GetNumberValue("RecoilAngleSize")) or 0.5/math.sqrt(self.Radius);
	self.recoilAngleVariation = self:NumberValueExists("RecoilAngleVariation") and 1 - self:GetNumberValue("RecoilAngleVariation") or 0.2;
	self.recoilRevertSpeed = self:NumberValueExists("RecoilRevertSpeed") and self:GetNumberValue("RecoilRevertSpeed") * 0.01 or 0.01;
end
function Update(self)
	if self.setRecoilAngle > 0 then
		self.setRecoilAngle = math.max(self.setRecoilAngle - (self.recoilRevertSpeed * (1 + math.sqrt(self.RateOfFire * 0.1) * self.setRecoilAngle)), 0);
	end
	if self.FiredFrame then
		self.setRecoilAngle = self.setRecoilAngle + (self.recoilAngleSize * RangeRand(self.recoilAngleVariation, 1))/(1 + self.setRecoilAngle)^2;
	end
	self.RotAngle = self.RotAngle + (self.setRecoilAngle * self.FlipFactor);
	local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
	self.Pos = self.Pos - jointOffset + Vector(jointOffset.X, jointOffset.Y):RadRotate(-self.setRecoilAngle * self.FlipFactor);
end