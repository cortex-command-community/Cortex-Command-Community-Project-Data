function Create(self)
	self.shellsToEject = self.RoundInMagCount;
end
function Update(self)
	if self.Magazine ~= nil then
		self.shellsToEject = self.Magazine.Capacity - self.Magazine.RoundCount;
	elseif self.shellsToEject > 0 then
		for i = 1, self.shellsToEject do
			local shell = CreateMOSParticle("Casing", "Base.rte");
			shell.Pos = self.Pos;
			shell.Vel = Vector(math.random() * (-3) * self.FlipFactor, 0):RadRotate(self.RotAngle):DegRotate((math.random() * 32) - 16);
			MovableMan:AddParticle(shell);
		end
		self.shellsToEject = 0;
	end
end