function Create(self)
	self.rotNum = 0;
	self.stance = Vector(6, 8);
	self.sharpStance = Vector(11, 2);
	self.length = self.Radius/rte.PxTravelledPerFrame;
	self.momentum = 0;
	self.charge = 0;
	self.swingSound = CreateSoundContainer("Uzira.rte/Swing");
	
	self.particle = CreateMOPixel("Smack Particle Light");
	self.particle.IgnoresTeamHits = true;
	self.particle.Sharpness = (self.Sharpness/self.length/self.particle.Mass);
end
function Update(self)
	local sinAngle = math.sin(self.rotNum);
	local cosAngle = math.cos(self.rotNum);
	local parent = self:GetRootParent();
	local aimNum = 0;
	if IsAHuman(parent) then
		parent = ToAHuman(parent);
		aimNum = parent.SharpAimProgress * 2;
		local activated = self:IsActivated();
		local speed = 0.8 + (0.3 - cosAngle) * self.charge;
		if not self.Supported then
			speed = speed * 0.7;
		end
		if aimNum > 1 and activated then
			self.justFired = true;
		end
		if (self.rotNum > 0 or activated) and aimNum < 1 and not self.justFired then
			parent:GetController():SetState(Controller.AIM_SHARP, false);
			self.SharpLength = 0;
			if not activated then
				self.canFire = true;
				self.swingSound.Pitch = math.sqrt(speed);
			elseif cosAngle > 0 and sinAngle < 0 then
				self.canFire = false;
			end
			if not parent:IsPlayerControlled() and sinAngle > 0.3 then
				parent:GetController():SetState(Controller.WEAPON_FIRE, false);
			end
			parent.AngularVel = parent.AngularVel + math.cos(self.rotNum) * 0.5 * speed * self.FlipFactor;
			if cosAngle < 0 then	--Swing
				self.particle.Pos = self.Pos;
				self.particle.Team = self.Team;
				for i = 1, math.floor(speed^3 - cosAngle + math.sqrt(self.momentum)) do
					local part = self.particle:Clone();
					part.Mass = part.Mass * (-cosAngle);
					part.Vel = parent.Vel + Vector(self.length * self.FlipFactor, 0):RadRotate(self.RotAngle - math.sqrt(i) * 0.5 * self.FlipFactor) * math.sqrt(-cosAngle);
					MovableMan:AddParticle(part);
				end
				if sinAngle < 0 and not self.swingSound:IsBeingPlayed() then
					self.swingSound.Pos = self.Pos;
					self.swingSound:Play();
				end
			elseif activated and not self.canFire then
				speed = speed * cosAngle * 0.6;
				self.charge = math.abs(sinAngle);
			end
			if not self.canFire then
				self:Deactivate();
			end
			
			local twoPI = math.pi * 2;
			if self.rotNum < twoPI then
				self.rotNum = math.min(self.rotNum + speed * 0.2, twoPI);
			else
				self.rotNum = 0;
			end
		else
			self.SharpLength = 25;
			self.canFire = false;
		end
		if self:DoneReloading() or not parent:GetController():IsState(Controller.AIM_SHARP) then
			self.justFired = false;
		end
	
		local stance = Vector(self.stance.X * (3 - cosAngle - math.abs(sinAngle)), self.stance.Y):RadRotate(sinAngle * 1.5);
		self.StanceOffset = stance;
		self.SharpStanceOffset = self.sharpStance * math.max(aimNum, 0.7);
		self.InheritedRotAngleOffset = (math.sin(self.rotNum - 0.3) * (1.4 - cosAngle * 0.6) + 1.2) * math.max(1 - aimNum, 0);
		if self.Magazine then
			self.Magazine.Scale = 1;
			self.Magazine.Frame = self.Frame;
			self.Scale = 0;
		else
			self.Scale = 1;
		end
	else
		if self.Magazine then
			self.Magazine.Scale = 0;
		end
		self.Scale = 1;
		self.rotNum = 0;
	end
	self.momentum = (self.momentum + self.Vel.Magnitude) * 0.5;
end