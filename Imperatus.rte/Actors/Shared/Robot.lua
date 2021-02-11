function Create(self)
	self.walkSpeed = self:GetLimbPathSpeed(1);
	self.moveTimer = Timer();
	self.stopTimer = Timer();
end
function Update(self)
	local walkSpeedScalar = 2.3;
	local legs = {self.FGLeg, self.BGLeg};
	for _, leg in pairs(legs) do
		walkSpeedScalar = walkSpeedScalar - (leg and leg.Frame/leg.FrameCount or 1.1);
	end
	self:SetLimbPathSpeed(1, self.walkSpeed * walkSpeedScalar);
	if self.Jetpack then
		self.Jetpack.Throttle = self.JetTimeLeft/self.JetTimeTotal - 0.5;
		self.Jetpack.FlashScale = 1 + self.Jetpack.Throttle;
	end
end