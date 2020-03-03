function Create(self)

	self.mapWrapsX = SceneMan.SceneWrapsX;
	self.climbTimer = Timer();
	self.mouseClimbTimer = Timer();
	self.actionMode = 0; -- 0 = start, 1 = flying, 2 = grab terrain, 3 = grab MO
	self.climb = 0;
	self.canRelease = false;

	self.tapTimer = Timer();
	self.tapCounter = 0;
	self.didTap = false;
	self.canTap = false;

	self.fireVel = 40;
	self.maxLineLength = 500;
	self.setLineLength = 0;
	self.lineLength = 0;
	self.lineVec = Vector(0,0);
	
	self.limitReached = false;
	self.stretchMode = false; -- Alternative elastic pull mode à la Liero
	self.pieSelection = 0; -- 0 is nothing, 1 is full retract, 2 is partial retract, 3 is partial extend, 4 is full extend

	self.climbDelay = 10; -- MS time delay between "climbs" to keep the speed consistant
	self.tapTime = 200; -- Maximum amount of time between tapping for claw to return
	self.tapAmount = 2; -- How many times to tap to bring back rope
	self.mouseClimbLength = 250; -- How long to climb per mouse wheel for mouse users
	self.climbInterval = 3.5; -- How many pixels the rope retracts / extends at a time
	self.autoClimbIntervalA = 4.0; -- How many pixels the rope retracts / extends at a time when auto-climbing (fast)
	self.autoClimbIntervalB = 2.0; -- How many pixels the rope retracts / extends at a time when auto-climbing (slow)
	
	for i = 1, MovableMan:GetMOIDCount()-1 do
		local gun = MovableMan:GetMOFromID(i);
		if gun and gun.ClassName == "HDFirearm" and gun.PresetName == "Grapple Gun" and SceneMan:ShortestDistance(self.Pos, ToHDFirearm(gun).MuzzlePos, self.mapWrapsX).Magnitude < 5 then
			self.parentGun = ToHDFirearm(gun);
			self.parent = MovableMan:GetMOFromID(gun.RootID);
			if MovableMan:IsActor(self.parent) then
				self.parent = ToActor(self.parent);
				if IsAHuman(self.parent) then
					self.parent = ToAHuman(self.parent);
				elseif IsACrab(self.parent) then
					self.parent = ToACrab(self.parent);
				end
				self.Vel = (self.parent.Vel / 2) + Vector(self.fireVel, 0):RadRotate(self.parent:GetAimAngle(true));
				self.parentGun.Sharpness = 0;
				for i = 1, MovableMan:GetMOIDCount() - 1 do
					local part = MovableMan:GetMOFromID(i);
					if part and part.RootID == self.parent.ID and part.ClassName ~= "HDFirearm" and part.ClassName ~= "TDExplosive" and part.ClassName ~= "HeldDevice" then
						local radcheck = SceneMan:ShortestDistance(self.parent.Pos, part.Pos, self.mapWrapsX).Magnitude + part.Radius;
						if self.parentRadius == nil or (self.parentRadius ~= nil and radcheck > self.parentRadius) then
							self.parentRadius = radcheck;
						end
					end
				end
				self.actionMode = 1;
			else
				self.parent = nil;
			end
			break;
		end
	end
	
	if self.parentGun ~= nil then
		if self.parentGun.Magazine ~= nil then
			self.parentGun.Magazine.Scale = 0;
		end
	else
		self.ToDelete = true;
	end
end

function Update(self)

	if self.parent ~= nil and MovableMan:IsActor(self.parent) and self.parent:HasObject("Grapple Gun") then
	
		local cont = self.parent:GetController();
		local startPos = self.parent.Pos;

		local item = self.parent.EquippedItem;
		if item and item.ID == self.parentGun.ID then
			self.parent:GetController():SetState(Controller.AIM_SHARP, false);
		end

		local negNum = self.parent.HFlipped and -1 or 1;

		self.ToDelete = false;
		self.ToSettle = false;

		self.pieSelection = 0;
		if self.parentGun ~= nil and self.parentGun.ID ~= 255 then
			startPos = self.parentGun.Pos;
			
			self.pieSelection = self.parentGun.Sharpness;
			self.parentGun.Vel = Vector(0, -1);
			if self.parentGun.FiredFrame then
				if self.actionMode == 1 then
					self.ToDelete = true;
				else
					self.canRelease = true;
				end
			end
			
			self.parentGun.StanceOffset = Vector(12, 1);
			self.parentGun.SharpStanceOffset = Vector(12, 1);
			
			if self.parentGun.FiredFrame and self.canRelease == true and (Vector(self.parentGun.Vel.X, self.parentGun.Vel.Y) ~= Vector(0, -1) or self.parentGun:IsActivated()) then
				self.ToDelete = true;
			end
		end
		
		self.lineVec = SceneMan:ShortestDistance(self.parent.Pos, self.Pos, self.mapWrapsX);
		self.lineLength = self.lineVec.Magnitude;

		if MovableMan:IsParticle(self.crankSound) then
			self.crankSound.PinStrength = 1000;
			self.crankSound.ToDelete = false;
			self.crankSound.ToSettle = false;
			self.crankSound.Pos = startPos;
			if self.lastSetLineLength ~= self.setLineLength then
				self.crankSound:EnableEmission(true);
			else
				self.crankSound:EnableEmission(false);
			end
		else
			self.crankSound = CreateAEmitter("Grapple Gun Sound Crank");
			self.crankSound.Pos = startPos;
			MovableMan:AddParticle(self.crankSound);
		end

		self.lastSetLineLength = self.setLineLength;

		if self.actionMode == 1 then
			self.parent:GetController():SetState(Controller.BODY_JUMP, false);
			self.rayVec = Vector(0,0);
			-- Gradually retract the hook for a return hit
			if self.stretchMode == true then
				self.Vel = self.Vel - self.lineVec / self.maxLineLength;
			end
			local length = math.sqrt(self.Diameter + self.Vel.Magnitude);
			if SceneMan:CastStrengthRay(self.Pos, Vector(length, 0):RadRotate(self.Vel.AbsRadAngle), 0, self.rayVec, 0, 0, self.mapWrapsX) == true then
				self.actionMode = 2;
			else
				local moRay = SceneMan:CastMORay(self.Pos, Vector(length, 0):RadRotate(self.Vel.AbsRadAngle), self.parent.RootID, -2, 0, false, 0);
				if moRay ~= 255 then
					self.target = MovableMan:GetMOFromID(moRay);
					-- Treat pinned MOs as terrain
					if self.target.PinStrength > 0 then
						self.actionMode = 2;
					else
						self.stickPositionX = self.Pos.X - self.target.Pos.X;
						self.stickPositionY = self.Pos.Y - self.target.Pos.Y;
						self.stickrotation = self.target.RotAngle;
						self.stickdirection = self.RotAngle;
						self.actionMode = 3;
					end
					-- Inflict damage
					local part = CreateMOPixel("Grapple Gun Damage Particle");
					local vec = SceneMan:ShortestDistance(self.Pos, self.target.Pos, SceneMan.SceneWrapsX):SetMagnitude(self.Vel.Magnitude);
					part.Pos = self.Pos;
					part.Vel = vec;
					MovableMan:AddParticle(part);
				end
			end
			if self.actionMode > 1 then
				AudioMan:PlaySound("Base.rte/Devices/Tools/GrappleGun/Sounds/ClawStick.wav", SceneMan:TargetDistanceScalar(self.Pos), false, true, -1);
				self.setLineLength = math.floor(self.lineLength);
				self.Vel = Vector(0, 0);
				self.PinStrength = 1000;
				self.Frame = 1;
				self.lastVel = Vector(self.Pos.X, self.Pos.Y);
			end

			if self.lineLength > self.maxLineLength then
				if self.limitReached == false then
					self.limitReached = true;
					AudioMan:PlaySound("Base.rte/Devices/Tools/GrappleGun/Sounds/Click.wav", SceneMan:TargetDistanceScalar(startPos), false, true, -1);
				end
				local movetopos = self.parent.Pos + (self.lineVec):SetMagnitude(self.maxLineLength);
				if self.mapWrapsX == true then
					if movetopos.X > SceneMan.SceneWidth then
						movetopos = Vector(movetopos.X - SceneMan.SceneWidth, movetopos.Y);
					elseif movetopos.X < 0 then
						movetopos = Vector(SceneMan.SceneWidth + movetopos.X, movetopos.Y);
					end
				end
				self.Pos = movetopos;

				local pullamountnumber = math.abs(-self.lineVec.AbsRadAngle + self.Vel.AbsRadAngle) / 6.28;
				self.Vel = self.Vel - self.lineVec:SetMagnitude(self.Vel.Magnitude * pullamountnumber);
			end
		elseif self.actionMode > 1 then
			-- Actor mass and velocity affect pull strength negatively, rope length affects positively (diminishes the former)
			local actorForces = 1 + (self.parent.Vel.Magnitude * 10 + self.parent.Mass) / (1 + self.lineLength);

			local terrVector = Vector(0,0);

			if self.parentRadius ~= nil then
				self.terrcheck = SceneMan:CastStrengthRay(self.parent.Pos, self.lineVec:SetMagnitude(self.parentRadius), 0, terrVector, 2, 0, self.mapWrapsX);
			else
				self.terrcheck = false;
			end

			if self.parentGun ~= nil and self.parentGun.ID ~= 255 then

				local negNum = self.parent.HFlipped and -1 or 1;
				local flipAng = self.parent.HFlipped and 3.14 or 0;
			
				self.parentGun.RotAngle = self.lineVec.AbsRadAngle + flipAng;
				local offset = Vector(ToMOSprite(self.parentGun:GetParent()):GetSpriteWidth(), 0):RadRotate(negNum * (self.lineVec.AbsRadAngle - self.parent:GetAimAngle(true)))
				self.parentGun.StanceOffset = offset;
				self.parentGun.SharpStanceOffset = offset;
			
				local nudge = math.sqrt(self.lineVec.Magnitude + self.parent.Radius) / (10 + self.parent.Vel.Magnitude);
				
				cont:SetState(Controller.WEAPON_DROP, false);
			
				if (self.pieSelection ~= 0 or self.parentGun:IsActivated()) then

					if self.climbTimer:IsPastSimMS(self.climbDelay) then
						self.climbTimer:Reset();

						if self.pieSelection == 1 or (self.pieSelection == 0 and self.parentGun:IsActivated()) then
							self.parent:GetController():SetState(Controller.BODY_JUMP, false);
						
							if self.setLineLength > self.autoClimbIntervalA and self.terrcheck == false then
								self.setLineLength = self.setLineLength - (self.autoClimbIntervalA / actorForces);
							else
								self.parentGun.Sharpness = 0;
								self.pieSelection = 0;
								if self.terrcheck ~= false then
									-- Try to nudge past terrain
									local aimvec = Vector(self.lineVec.Magnitude, 0):SetMagnitude(nudge):RadRotate((self.lineVec.AbsRadAngle + self.parent:GetAimAngle(true)) / 2 + negNum * 0.7);
									self.parent.Vel = self.parent.Vel + aimvec;
								end
							end
						elseif self.pieSelection == 2 then
							if self.setLineLength < (self.maxLineLength-self.autoClimbIntervalB) then
								self.setLineLength = self.setLineLength + self.autoClimbIntervalB;
							else
								self.parentGun.Sharpness = 0;
								self.pieSelection = 0;
							end
						end
					end
				end
				if cont:IsState(Controller.BODY_CROUCH) then
					if self.climb == 1 or self.climb == 2 then
						if self.climbTimer:IsPastSimMS(self.climbDelay) then
							self.climbTimer:Reset();
							if self.pieSelection == 0 then
								if self.climb == 1 then
									self.setLineLength = self.setLineLength - (self.climbInterval / actorForces);
								elseif self.climb == 2 then
									self.setLineLength = self.setLineLength + self.climbInterval;
								end
							end
							self.climb = 0;
						end
					elseif self.climb == 3 or self.climb == 4 then
						if self.climbTimer:IsPastSimMS(self.mouseClimbLength) then
							self.climbTimer:Reset();
							self.mouseClimbTimer:Reset();
							self.climb = 0;
						else
							if self.mouseClimbTimer:IsPastSimMS(self.climbDelay) then
								self.mouseClimbTimer:Reset();
								if self.climb == 3 then
									if (self.setLineLength-self.climbInterval) >= 0 and self.terrcheck == false then
										self.setLineLength = self.setLineLength - (self.climbInterval / actorForces);
										
									elseif self.terrcheck ~= false then
										-- Try to nudge past terrain
										local aimvec = Vector(self.lineVec.Magnitude, 0):SetMagnitude(nudge):RadRotate((self.lineVec.AbsRadAngle + self.parent:GetAimAngle(true)) / 2 + negNum * 0.7);
										self.parent.Vel = self.parent.Vel + aimvec;	
									end
								elseif self.climb == 4 then
									if (self.setLineLength+self.climbInterval) <= self.maxLineLength then
										self.setLineLength = self.setLineLength + self.climbInterval;
									end
								end
							end
						end
					end

					if cont:IsMouseControlled() then
						cont:SetState(Controller.WEAPON_CHANGE_NEXT,false);
						cont:SetState(Controller.WEAPON_CHANGE_PREV,false);
						if cont:IsState(Controller.SCROLL_UP) then
							self.climbTimer:Reset();
							self.climb = 3;
						end
						if cont:IsState(Controller.SCROLL_DOWN) then
							self.climbTimer:Reset();
							self.climb = 4;
						end
					elseif cont:IsMouseControlled() == false then
						if cont:IsState(Controller.HOLD_UP) then 
							if self.setLineLength > self.climbInterval and self.terrcheck == false then
								self.climb = 1;
							elseif self.terrcheck ~= false then
								-- Try to nudge past terrain
								local aimvec = Vector(self.lineVec.Magnitude, 0):SetMagnitude(nudge):RadRotate((self.lineVec.AbsRadAngle + self.parent:GetAimAngle(true)) / 2 + negNum * 0.7);
								self.parent.Vel = self.parent.Vel + aimvec;
							end
						end
						if cont:IsState(Controller.HOLD_DOWN) and self.setLineLength < (self.maxLineLength-self.climbInterval) then
							self.climb = 2;
						end
					end
					cont:SetState(Controller.AIM_UP, false);
					cont:SetState(Controller.AIM_DOWN, false);
				end
			end
			if self.actionMode == 2 then
				if self.stretchMode == true then
					
					local pullVec = self.lineVec:SetMagnitude(0.15 * math.sqrt(self.lineLength) / actorForces);
					self.parent.Vel = self.parent.Vel + pullVec;
					
				elseif self.lineLength > self.setLineLength then
				
					local hookVel = SceneMan:ShortestDistance(Vector(self.lastVel.X, self.lastVel.Y), Vector(self.Pos.X, self.Pos.Y), self.mapWrapsX);

					local pullAmountNumber = self.lineVec.AbsRadAngle - self.parent.Vel.AbsRadAngle;
					if pullAmountNumber < 0 then
						pullAmountNumber = pullAmountNumber * -1;
					end
					pullAmountNumber = pullAmountNumber / 6.28;
					self.parent:AddAbsForce(self.lineVec:SetMagnitude(((self.lineLength - self.setLineLength) ^3 ) * pullAmountNumber)	+	hookVel:SetMagnitude(math.pow(self.lineLength - self.setLineLength,2)*0.8), self.parent.Pos);

					local moveToPos = self.Pos + (self.lineVec*-1):SetMagnitude(self.setLineLength);
					if self.mapWrapsX == true then
						if moveToPos.X > SceneMan.SceneWidth then
							moveToPos = Vector(moveToPos.X - SceneMan.SceneWidth, moveToPos.Y);
						elseif moveToPos.X < 0 then
							moveToPos = Vector(SceneMan.SceneWidth + moveToPos.X, moveToPos.Y);
						end
					end
					self.parent.Pos = moveToPos;
					
					local pullAmountNumber = math.abs(self.lineVec.AbsRadAngle - self.parent.Vel.AbsRadAngle) / 6.28;
					self.parent.Vel = self.parent.Vel + self.lineVec:SetMagnitude(self.parent.Vel.Magnitude * pullAmountNumber);
				end
				
			elseif self.actionMode == 3 then
				if self.target.ID ~= 255 then

					self.Pos = self.target.Pos + Vector(self.stickPositionX, self.stickPositionY):RadRotate(self.target.RotAngle - self.stickrotation);
					self.RotAngle = self.stickdirection + (self.target.RotAngle - self.stickrotation);
					if self.lineLength > self.setLineLength then
		
						local jointStiffness;
						local target = self.target;
						if target.ID ~= target.RootID then
							local mo = MovableMan:GetMOFromID(target.RootID);
							if mo.ID ~= 255 and IsAttachable(target) then
								-- It's best to apply all the forces to the parent instead
								target = mo;
							end
						end

						local hookVel = SceneMan:ShortestDistance(Vector(self.lastVel.X, self.lastVel.Y), Vector(self.Pos.X, self.Pos.Y), self.mapWrapsX);

						local pullAmountNumber = self.lineVec.AbsRadAngle - self.parent.Vel.AbsRadAngle;
						if pullAmountNumber < 0 then
							pullAmountNumber = pullAmountNumber * -1;
						end
						pullAmountNumber = pullAmountNumber / 6.28;
						self.parent:AddAbsForce(self.lineVec:SetMagnitude(((self.lineLength - self.setLineLength) ^3 ) * pullAmountNumber)	+	hookVel:SetMagnitude(math.pow(self.lineLength - self.setLineLength,2)*0.8), self.parent.Pos);

						pullAmountNumber = (self.lineVec*-1).AbsRadAngle-(SceneMan:ShortestDistance(Vector(self.lastVel.X,self.lastVel.Y),Vector(self.Pos.X,self.Pos.Y),self.mapWrapsX)).AbsRadAngle;
						if pullAmountNumber < 0 then
							pullAmountNumber = pullAmountNumber * -1;
						end
						pullAmountNumber = pullAmountNumber / 6.28;
						local targetforce = ((self.lineVec*-1):SetMagnitude(((self.lineLength - self.setLineLength) ^3 ) * pullAmountNumber)	+	(self.lineVec*-1):SetMagnitude(math.pow(self.lineLength - self.setLineLength,2)*0.8));

						target:AddAbsForce(targetforce, self.Pos);
						target.AngularVel = target.AngularVel * 0.99;
						
						self.lastVel = Vector(self.Pos.X, self.Pos.Y);
					end
				else
					self.ToDelete = true;
				end
			end
			-- Prevent actor from spinning frantically
			if self.parent.Status > 0 then
				self.parent.AngularVel = self.parent.AngularVel * 0.99;
			end
		end
		-- Double tapping crouch retrieves the hook
		if cont:IsState(Controller.BODY_CROUCH) then
			if self.canTap == true then
				self.climb = 0;
				if self.parentGun ~= nil and self.parentGun.ID ~= 255 then
					self.parentGun.Sharpness = 0;
				end
				self.pieSelection = 0;
				self.tapTimer:Reset();
				self.didTap = true;
				self.canTap = false;
				self.tapCounter = self.tapCounter + 1;
			end
		else
			self.canTap = true;
		end
		if self.tapTimer:IsPastSimMS(self.tapTime) then
			self.tapCounter = 0;
		else
			if self.tapCounter >= self.tapAmount then
				self.ToDelete = true;
			end
		end
		-- Fine tuning: take the seam into account when drawing the rope
		local drawPos = self.parent.Pos + self.lineVec:SetMagnitude(self.lineLength);
		if self.ToDelete == true then
			drawPos = self.parent.Pos + (self.lineVec / 2);
			AudioMan:PlaySound("Base.rte/Devices/Tools/GrappleGun/Sounds/Return.wav", SceneMan:TargetDistanceScalar(drawPos), false, true, -1);
		end
		FrameMan:DrawLinePrimitive(startPos, drawPos, 249);
	else
		self.ToDelete = true;
	end
end

function Destroy(self)
	if MovableMan:IsParticle(self.crankSound) then
		self.crankSound.ToDelete = true;
	end
	if self.parentGun ~= nil and self.parentGun.ID ~= 255 then
		self.parentGun.Sharpness = 0;
		self.parentGun.StanceOffset = Vector(12, 1);
		self.parentGun.SharpStanceOffset = Vector(12, 1);
		if self.parentGun.Magazine then
			self.parentGun.Magazine.Scale = 1;
		end
	end
end