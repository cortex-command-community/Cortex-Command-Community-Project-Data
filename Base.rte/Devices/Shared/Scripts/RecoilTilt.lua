function Create(self)
	self.setAngle = 0;
	self.tilt = 0.2;
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
end