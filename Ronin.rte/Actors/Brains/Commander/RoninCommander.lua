function Create(self)
	self.updateTimer = Timer();

	self.lungeTapDelay = 200;
	self.lungePower = 6;
	self.tapTimer = Timer();
	self.dir = 0;

	if not self:NumberValueExists("Identity") then
		self.face = math.random(0, self.FrameCount - 2);
		self.Frame = self.face;
		self.Head.Frame = self.face;
		self:SetNumberValue("Identity", self.face);
		--Add a ponytail if we are Lara
		if self.face == 2 then
			self.DeathSound.Pitch = 1.2;
			self.PainSound.Pitch = 1.2;
			self.Head:AddAttachable(CreateAttachable("Ronin Brunette Ponytail"));
		end
	else
		self.face = self:GetNumberValue("Identity");
		if self.Head then
			self.Head.Frame = self.face;
		end
	end
end
function Update(self)
	if self.updateTimer:IsPastSimMS(1000) then
		self.updateTimer:Reset();
		self.aggressive = self.Health < self.MaxHealth * 0.5;
	end
	if self.Head then
		self.Head.Frame = self.face;
		if self.controller:IsState(Controller.WEAPON_FIRE) or self.aggressive then
			self.Head.Frame = self.face + (self.Head.FrameCount * 0.5);
		end
	end
	self.Frame = (self.face == 2 and self.Vel.Y > (SceneMan.GlobalAcc.Y * 0.15)) and 3 or self.face;
	
	if self:IsPlayerControlled() and self.Status < Actor.INACTIVE and self.FGLeg and self.BGLeg then
		local crouching = self.controller:IsState(Controller.BODY_CROUCH);
		if self.Status == Actor.UNSTABLE then
			if self.dir == self.FlipFactor then
				local motion = (self.Vel.Magnitude * 0.5 + math.abs(self.AngularVel));
				local stillness = 1/(1 + motion);
				if crouching then
					self.AngularVel = self.AngularVel * (1 - stillness) - (self.RotAngle - (self:GetAimAngle(false) - math.pi * 0.5) * self.FlipFactor) * 2 * stillness;
				end
			else
				self.dir = 0;
			end
		elseif crouching then
			if not self.crouchHeld then
				if not self.tapTimer:IsPastSimMS(self.lungeTapDelay) and SceneMan.Scene.GlobalAcc.Magnitude > 10 then
					self.dir = HumanFunctions.Lunge(self, self.lungePower);
				end
				self.tapTimer:Reset();
				self.controller:SetState(Controller.BODY_CROUCH, false);
			end
		end
		self.crouchHeld = crouching;
	end
end