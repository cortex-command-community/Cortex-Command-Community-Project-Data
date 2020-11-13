function Create(self)
	self.updateTimer = Timer();

	self.lungeTapDelay = 200;
	self.frontFlip = {input = {Controller.BODY_JUMP, Controller.BODY_CROUCH}, inputCounter  = 0};
	self.lungePower = 6;
	self.tapTimer = Timer();

	if not self:NumberValueExists("Identity") then
		self.face = math.random(0, self.FrameCount - 2);
		self.Frame = self.face;
		self.Head.Frame = self.face;
		self:SetNumberValue("Identity", self.face);
		--Add a ponytail if we are Lara
		if self.face == 2 then
			self.Head:AddAttachable(CreateAttachable("Ronin Brunette Ponytail"));
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
	local crouching = self.controller:IsState(Controller.BODY_CROUCH);
	
	if self:IsPlayerControlled() and self.Status < Actor.DYING and self.FGLeg and self.BGLeg then
		if self.Status == Actor.UNSTABLE then
			if not crouching then
				local motion = self.Vel.Magnitude * 0.5 + math.abs(self.AngularVel);
				if self.AngularVel ~= 0 then
					self.AngularVel = self.AngularVel * (1 - 0.1/motion);
				end
				if self.tapTimer:IsPastSimMS(500) and math.cos(self.RotAngle) > 0.9 and motion < 20  then
					self.tapTimer:Reset();
					self.Status = Actor.STABLE;
					self.AngularVel = self.AngularVel * 0.5;
				end
			end
		else
			--Track the key combo input (jump -> crouch) to trigger frontflip
			if self.controller:IsState(self.frontFlip.input[self.frontFlip.inputCounter + 1]) then
				if (self.frontFlip.inputCounter == 0 or not self.tapTimer:IsPastSimMS(self.lungeTapDelay)) then
					self.frontFlip.inputCounter = self.frontFlip.inputCounter + 1;
					if self.frontFlip.inputCounter == #self.frontFlip.input then
						Lunge(self, 8);
						self.frontFlip.inputCounter = 0;
						--AudioMan:PlaySound("Ronin.rte/Actors/Brains/Commander/Sounds/Jump.flac", self.Pos);
					end
					self.tapTimer:Reset();
				else
					self.frontFlip.inputCounter = 0;
				end
			elseif crouching then
				if not self.keyHeld then
					if not self.tapTimer:IsPastSimMS(self.lungeTapDelay) and SceneMan.Scene.GlobalAcc.Magnitude > 10 then
						Lunge(self, 0);
					else
						self.tapTimer:Reset();
					end	
				end
				self.keyHeld = true;
			else
				self.keyHeld = false;
			end
		end
	end
end

function Lunge(self, spin)
	local flip = self.FlipFactor;
	if self.controller:IsState(Controller.MOVE_RIGHT) then
		flip = 1;
	elseif self.controller:IsState(Controller.MOVE_LEFT) then
		flip = -1;
	end
	--Different factors that affect the lunge
	local vel = (self.Vel.Magnitude^2) * 0.0005 + 1;
	local ang = math.abs(self.AngularVel * 0.05) + 1;
	local mass = math.abs(self.Mass * 0.005) + 1;
	local aimAng = self:GetAimAngle(false);
	local vertical = math.abs(math.cos(aimAng))/vel;
	local strength = (self.lungePower/self.MaxHealth) * math.min(self.Health, self.MaxHealth);
	
	local jumpVec =	Vector((self.lungePower + strength/vel) * flip, -(self.lungePower * 0.5 + (strength * 0.3)) * vertical):RadRotate(aimAng * self.FlipFactor);
	
	self.Vel = self.Vel + jumpVec/mass;
	self.AngularVel = self.AngularVel - (2/ang * vertical + spin) * flip;
	self.Status = Actor.UNSTABLE;
	self.tapTimer:Reset();
end