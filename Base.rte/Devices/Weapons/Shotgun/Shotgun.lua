function Create(self)
	self.pullTimer = Timer();
	self.loaded = false;
	self.rotFactor = math.pi;
end
function Update(self)
	local parent;
	local actor = self:GetRootParent();
	if actor and IsAHuman(actor) then
		parent = ToAHuman(actor);
	end
	if self.FiredFrame then
		self.shell = CreateMOSParticle("Shell");
		self.loaded = false;
		self.playedSound = false;
		self.rotFactor = math.pi;
	end
	if parent and not self.loaded and self.RoundInMagCount > 0 and not self.reloadCycle then
		self:Deactivate();
		if self.pullTimer:IsPastSimMS(15000/self.RateOfFire) then
			if not self.playedSound then
				AudioMan:PlaySound("Base.rte/Sounds/Devices/ChamberRound.wav", self.Pos);
				self.playedSound = true;
			end
			if self.shell then
				self.shell.Pos = self.Pos;
				self.shell.Vel = self.Vel + Vector(-6 * self.FlipFactor, -4):RadRotate(self.RotAngle);
				self.shell.Team = self.Team;
				MovableMan:AddParticle(self.shell);
				self.shell = nil;
			end
			self.Frame = 1;
			self.SupportOffset = Vector(1, 3);
			local rotTotal = math.sin(self.rotFactor)/5;
			self.RotAngle = self.RotAngle + self.FlipFactor * rotTotal;
			local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
			self.Pos = self.Pos - jointOffset + Vector(jointOffset.X, jointOffset.Y):RadRotate(-rotTotal * self.FlipFactor);
			self.rotFactor = self.rotFactor - math.pi * 0.0005 * self.RateOfFire;
		end
		if self.rotFactor <= 0 then
			self.loaded = true;
			self.Frame = 0;
			self.SupportOffset = Vector(4, 2);
			self.rotFactor = 0;
		end
	else
		self.pullTimer:Reset();
	end
end