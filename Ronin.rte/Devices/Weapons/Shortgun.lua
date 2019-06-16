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
			for i = 1, 2 do
				local shell = CreateMOSParticle("Shell");
				shell.Pos = self.Pos;
				shell.Vel = Vector(-5*self.negativeNum,-3):RadRotate(self.RotAngle):DegRotate((math.random()*16)-8);
				MovableMan:AddParticle(shell);
			end
		end
	end

end