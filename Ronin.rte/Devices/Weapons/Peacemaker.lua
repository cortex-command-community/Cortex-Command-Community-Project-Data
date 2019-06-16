function Create(self)

	self.ejectedShell = false;

end

function Update(self)

	if self.Magazine ~= nil then
		self.ejectedShell = false;
	else
		if self.ejectedShell == false then
			self.ejectedShell = true;
			if self.HFlipped == false then
				self.negativeNum = 1;
			else
				self.negativeNum = -1;
			end
			for i = 1, 6 do
				local shell = CreateMOSParticle("Casing");
				shell.Pos = self.Pos;
				shell.Vel = Vector(math.random()*(-3)*self.negativeNum,0):RadRotate(self.RotAngle):DegRotate((math.random()*32)-16);
				MovableMan:AddParticle(shell);
			end
		end
	end

end