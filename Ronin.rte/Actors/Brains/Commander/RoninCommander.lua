function Create(self)
	self.updateTimer = Timer();

	self.lungeTapDelay = 200;
	self.lungePower = 6;
	self.tapTimer = Timer();

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
	self.analogSpin = 0;
	self.lastAnalogAngle = self:GetController().AnalogMove.AbsRadAngle;
end
function Update(self)
	self.analogSpin = self.analogSpin * 0.9;
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
			local motion = (self.Vel.Magnitude * 0.5 + math.abs(self.AngularVel));
			local stillness = 1/(1 + motion);
			if crouching then
				self.AngularVel = self.AngularVel * (1 - stillness) - (self.RotAngle - (self:GetAimAngle(false) - math.pi * 0.5) * self.FlipFactor) * 2 * stillness;
			end
		elseif crouching then
			if not self.crouchHeld then
				if not self.tapTimer:IsPastSimMS(self.lungeTapDelay) and SceneMan.Scene.GlobalAcc.Magnitude > 10 then
					Lunge(self, 3);
				else
					self.tapTimer:Reset();
				end	
				self.controller:SetState(Controller.BODY_CROUCH, false);
			end
		else
			self.analogSpin = self.analogSpin + math.sin(self.controller.AnalogMove.AbsRadAngle - self.lastAnalogAngle);
			if math.abs(self.analogSpin) > 2 then
				Lunge(self, 12);
				self.analogSpin = 0;
			end
		end
		self.crouchHeld = crouching;
	end
	self.lastAnalogAngle = self.controller.AnalogMove.AbsRadAngle;
end

function Lunge(self, spin)
	local flip = self.FlipFactor;
	if self.controller:IsState(Controller.MOVE_RIGHT) then
		flip = 1;
	elseif self.controller:IsState(Controller.MOVE_LEFT) then
		flip = -1;
	end
	--Different factors that affect the lunge
	local angVel = math.abs(self.AngularVel * 0.1) + 1;
	local vel = (self.Vel.Magnitude + angVel)^2 * 0.0005 + 1;
	local mass = math.abs(self.Mass * 0.005) + 1;
	local aimAng = self:GetAimAngle(false);
	local vertical = math.abs(math.cos(aimAng))/vel;
	local strength = (self.lungePower/self.MaxHealth) * math.min(self.Health, self.MaxHealth);
	
	local jumpVec =	Vector((self.lungePower + strength/vel) * flip, -(self.lungePower * 0.5 + (strength * 0.3)) * vertical):RadRotate(aimAng * self.FlipFactor);
	
	self.Vel = self.Vel + jumpVec/mass;
	self.AngularVel = self.AngularVel - (spin/angVel * vertical) * flip * math.cos(self.RotAngle);
	self.Status = Actor.UNSTABLE;
	self.tapTimer:Reset();
end