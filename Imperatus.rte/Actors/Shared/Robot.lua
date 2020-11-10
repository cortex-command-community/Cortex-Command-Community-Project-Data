function Create(self)
	self.inputLagMS = self:NumberValueExists("InputLagMS") and self:GetNumberValue("InputLagMS") or 100;
end
function Update(self)
	if self.controller:IsState(Controller.MOVE_RIGHT) then
		if self.moveTimer then
			if self.moveTimer:IsPastSimMS(self.inputLagMS) then
				self.moveTo = 1;
				self.moveTimer:Reset();
			else
				self.controller:SetState(Controller.MOVE_RIGHT, false);
			end
		else
			self.moveTimer = Timer();
			self.controller:SetState(Controller.MOVE_RIGHT, self.HFlipped);
		end
	end
	if self.controller:IsState(Controller.MOVE_LEFT) then
		if self.moveTimer then
			if self.moveTimer:IsPastSimMS(self.inputLagMS) then
				self.moveTo = -1;
				self.moveTimer:Reset();
			else
				self.controller:SetState(Controller.MOVE_LEFT, false);
			end
		else
			self.moveTimer = Timer();
			self.controller:SetState(Controller.MOVE_LEFT, not self.HFlipped);
		end
	end
	if self.moveTo then
		self.controller:SetState((self.moveTo == 1 and Controller.MOVE_RIGHT or Controller.MOVE_LEFT), true);
		if self.moveTimer then
			if self.moveTimer:IsPastSimMS(self.inputLagMS) then
				self.moveTimer = nil;
				self.moveTo = nil;
			end
		else
			self.moveTimer = Timer();
		end
	end
	if self.Head then
		local inheritAngleRatio = 4;
		self.Head.RotAngle = (self.Head.RotAngle * inheritAngleRatio + self.RotAngle)/(1 + inheritAngleRatio);
	end
end