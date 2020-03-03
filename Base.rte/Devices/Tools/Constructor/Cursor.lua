function Create(self)
	self.DelayTimer = Timer();
	self.movespeed = 10;
	self.futurevel = Vector(0,0);
end

function Update(self)
	self.ToDelete = false;
	self.ToSettle = false;
	self.AngularVel = 0;
	self.RotAngle = 0;
	
	self.ctrl = self:GetController();
	
	local screen = ActivityMan:GetActivity():ScreenOfPlayer(self.ctrl.Player);
	FrameMan:DrawLinePrimitive(screen, self.Pos + Vector(0, 4), self.Pos + Vector(0, -4), 120);
	FrameMan:DrawLinePrimitive(screen, self.Pos + Vector(4, 0), self.Pos + Vector(-4, 0), 120);

	if self.ctrl:IsMouseControlled() == false then
		if self.ctrl:IsState(Controller.HOLD_UP) or self.ctrl:IsState(Controller.BODY_JUMP) then
			self.futurevel = self.futurevel + Vector(0,-1);
		end

		if self.ctrl:IsState(Controller.HOLD_DOWN) or self.ctrl:IsState(Controller.BODY_CROUCH) then
			self.futurevel = self.futurevel + Vector(0,1);
		end

		if self.ctrl:IsState(Controller.HOLD_LEFT) then
			self.futurevel = self.futurevel + Vector(-1,0);
		end

		if self.ctrl:IsState(Controller.HOLD_RIGHT) then
			self.futurevel = self.futurevel + Vector(1,0);
		end
	elseif self.ctrl:IsMouseControlled() == true then
		self.futurevel = self.futurevel + self.ctrl.MouseMovement;
	end

	if self.futurevel == Vector(0,0) then
		self.Vel = ((SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs)*-1);
	elseif not(self.futurevel == Vector(0,0)) then
		if self.ctrl:IsMouseControlled() == false then
			self.Vel = (self.futurevel:SetMagnitude(self.movespeed)) + ((SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs)*-1);
		elseif self.ctrl:IsMouseControlled() == true then
			self.Vel = (self.futurevel) + ((SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs)*-1);
		end
	end

	self.futurevel = Vector(0,0);

	if self.Sharpness == -2 or self:IsPlayerControlled() == false then
		self.ToDelete = true;
	end
end

function Destroy(self)
	ActivityMan:GetActivity():ReportDeath(self.Team,-1);

	if MovableMan:IsParticle(self.drawlighta) then
		self.drawlighta.ToDelete = true;
		self.drawlighta.LifeTime = 1;
	end

end