function Create(self)

	self.mapwrapx = SceneMan.SceneWrapsX;
	self.CTimer = Timer();
	self.MouseCTimer = Timer();
	self.actionmode = 0;
	self.climb = 0;
	self.canrelease = false;

	self.taptimer = Timer();
	self.tapcounter = 0;
	self.didtap = false;
	self.cantap = false;

	self.maxlinelength = 400;
	self.setlinelength = 0;
	self.linelength = 0;
	self.linevec = Vector(0,0);

	self.pieselection = 0; -- 0 is nothing, 1 is full retract, 2 is partial retract, 3 is partial detract, 4 is full detract

	self.climbdelay = 10; -- MS time delay between "climbs" to keep the speed consistant
	self.taptime = 200; -- maximum amount of time between tapping for claw to return
	self.tapamount = 3; -- how many times to tap to bring back rope
	self.mouseclimblength = 250; -- how long to climb per mouse wheel for mouse users
	self.climbinterval = 2; -- how many pixels the rope retracts/extends at a time
	self.autoclimbintervalA = 2; -- how many pixels the rope retracts/extends at a time when auto-climbing (fast)
	self.autoclimbintervalB = 2; -- how many pixels the rope retracts/extends at a time when auto-climbing (slow)

	for i = 1, MovableMan:GetMOIDCount()-1 do
		local gun = MovableMan:GetMOFromID(i);
		if gun and gun.ClassName == "HDFirearm" and gun.PresetName == "Grapple Gun" and SceneMan:ShortestDistance(self.Pos,ToHDFirearm(gun).MuzzlePos,self.mapwrapx).Magnitude < 5 then
			self.parentgun = ToHDFirearm(gun);
			self.parent = MovableMan:GetMOFromID(gun.RootID);
			if MovableMan:IsActor(self.parent) then
				self.parent = ToActor(self.parent);
				self.Vel = Vector(40,0):RadRotate(self.parent:GetAimAngle(true));
				self.parentgun.Sharpness = 0;
				for i = 1, MovableMan:GetMOIDCount()-1 do
					local part = MovableMan:GetMOFromID(i);
					if part and part.RootID == self.parent.ID and part.ClassName ~= "HDFirearm" and part.ClassName ~= "TDExplosive" and part.ClassName ~= "HeldDevice" then
						local radcheck = SceneMan:ShortestDistance(self.parent.Pos,part.Pos,self.mapwrapx).Magnitude + part.Radius;
						if self.parentRadius == nil or (self.parentRadius ~= nil and radcheck > self.parentRadius) then
							self.parentRadius = radcheck;
						end
					end
				end
				self.actionmode = 1;
			else
				self.parent = nil;
			end
			break;
		end
	end

	if self.parentgun ~= nil then
		if self.parentgun.Magazine ~= nil then
			self.parentgun.Magazine.Scale = 0;
		end
	else
		self.ToDelete = true;
	end

end

function Update(self)

	if self.parentgun ~= nil and self.parent ~= nil and MovableMan:IsActor(self.parent) and self.parentgun.ID ~= 255 and self.parent:HasObject("Grapple Gun") then

		self.ToDelete = false;
		self.ToSettle = false;

		self.pieselection = self.parentgun.Sharpness;

		self.linevec = SceneMan:ShortestDistance(self.parent.Pos,self.Pos,self.mapwrapx);
		self.linelength = self.linevec.Magnitude;

		FrameMan:DrawLinePrimitive(self.parent.Pos,self.Pos,250)

		if MovableMan:IsParticle(self.cranksound) then
			self.cranksound.PinStrength = 1000;
			self.cranksound.ToDelete = false;
			self.cranksound.ToSettle = false;
			self.cranksound.Pos = self.parent.Pos;
			if self.lastsetlinelength ~= self.setlinelength then
				self.cranksound:EnableEmission(true);
			else
				self.cranksound:EnableEmission(false);
			end
		else
			self.cranksound = CreateAEmitter("Grapple Gun Sound Crank");
			self.cranksound.Pos = self.parent.Pos;
			MovableMan:AddParticle(self.cranksound);
		end

			self.lastsetlinelength = self.setlinelength;

		if not(self.parent:GetController():IsState(Controller.WEAPON_FIRE)) then
			if self.actionmode == 1 then
				self.ToDelete = true;
			else
				self.canrelease = true;
			end
		elseif self.parent:GetController():IsState(Controller.WEAPON_FIRE) then
			if self.canrelease == true and (Vector(self.parentgun.Vel.X,self.parentgun.Vel.Y) ~= Vector(0,-1) or self.parentgun:IsActivated() == true) then
				self.ToDelete = true;
			end
		end

		self.parentgun.Vel = Vector(0,-1);

		if self.actionmode == 1 then
			self.rayvec = Vector(0,0);
			if self.parent:GetController():IsState(Controller.WEAPON_FIRE) then
				self.canfire = false;
				--self.objectdetect = SceneMan:CastMORay(self.Pos,Vector(10,0):RadRotate(self.Vel.AbsRadAngle),self.parent.RootID,0,false,0);
				if SceneMan:CastStrengthRay(self.Pos,Vector(10,0):RadRotate(self.Vel.AbsRadAngle),0,self.rayvec,0,0,self.mapwrapx) == true then
					self.PinStrength = 1000;
					self.Frame = 1;
					self.setlinelength = math.floor(self.linelength);
					local hitsound = CreateAEmitter("Grapple Gun Sound Stick");
					hitsound.Pos = self.Pos;
					MovableMan:AddParticle(hitsound);
					self.actionmode = 2;
				end
			else
				self.ToDelete = true;
			end
			if self.linelength > self.maxlinelength then
				self.ToDelete = true;
			end
		elseif self.actionmode == 2 then

			if self.parentRadius ~= nil then
				vectorthing = Vector(0,0);
				self.terrcheck = SceneMan:CastStrengthRay(self.parent.Pos,self.linevec:SetMagnitude(self.parentRadius),0,vectorthing,2,0,self.mapwrapx);
			else
				self.terrcheck = false;
			end

			if self.pieselection ~= 0 then

				if self.CTimer:IsPastSimMS(self.climbdelay) then
					self.CTimer:Reset();

					if self.pieselection == 1 then
						if self.setlinelength > self.autoclimbintervalA and self.terrcheck == false then
								self.setlinelength = self.setlinelength - self.autoclimbintervalA;
						else
							self.parentgun.Sharpness = 0;
							self.pieselection = 0;
						end
					elseif self.pieselection == 2 then
						if self.setlinelength < (self.maxlinelength-self.autoclimbintervalB) then
							self.setlinelength = self.setlinelength + self.autoclimbintervalB;
						else
							self.parentgun.Sharpness = 0;
							self.pieselection = 0;
						end
					end

				end
			end

			if self.parent:GetController():IsState(Controller.BODY_CROUCH) then

				if self.cantap == true then
					self.climb = 0;
					self.parentgun.Sharpness = 0;
					self.pieselection = 0;
					self.taptimer:Reset();
					self.didtap = true;
					self.cantap = false;
					self.tapcounter = self.tapcounter + 1;
				end

				if self.climb == 1 or self.climb == 2 then
					if self.CTimer:IsPastSimMS(self.climbdelay) then
						self.CTimer:Reset();
						if self.pieselection == 0 then
							if self.climb == 1 then
								self.setlinelength = self.setlinelength - self.climbinterval;
							elseif self.climb == 2 then
								self.setlinelength = self.setlinelength + self.climbinterval;
							end
						end
						self.climb = 0;
					end
				elseif self.climb == 3 or self.climb == 4 then
					if self.CTimer:IsPastSimMS(self.mouseclimblength) then
						self.CTimer:Reset();
						self.MouseCTimer:Reset();
						self.climb = 0;
					else
						if self.MouseCTimer:IsPastSimMS(self.climbdelay) then
							self.MouseCTimer:Reset();
							if self.climb == 3 then
								if (self.setlinelength-self.climbinterval) >= 0 and self.terrcheck == false then
									self.setlinelength = self.setlinelength - self.climbinterval;
								end
							elseif self.climb == 4 then
								if (self.setlinelength+self.climbinterval) <= self.maxlinelength then
									self.setlinelength = self.setlinelength + self.climbinterval;
								end
							end
						end
					end
				end

				if self.parent:GetController():IsMouseControlled() == true then
					self.parent:GetController():SetState(Controller.WEAPON_CHANGE_NEXT,false);
					self.parent:GetController():SetState(Controller.WEAPON_CHANGE_PREV,false);
					if self.parent:GetController():IsState(Controller.SCROLL_UP) then
						self.CTimer:Reset();
						self.climb = 3;
					end
					if self.parent:GetController():IsState(Controller.SCROLL_DOWN) then
						self.CTimer:Reset();
						self.climb = 4;
					end
				elseif self.parent:GetController():IsMouseControlled() == false then
					if self.parent:GetController():IsState(Controller.HOLD_UP) and self.setlinelength > self.climbinterval and self.terrcheck == false then
						self.climb = 1;
					end
					if self.parent:GetController():IsState(Controller.HOLD_DOWN) and self.setlinelength < (self.maxlinelength-self.climbinterval) then
						self.climb = 2;
					end
				end



			elseif not(self.parent:GetController():IsState(Controller.BODY_CROUCH)) then
				self.cantap = true;
			end

			if self.taptimer:IsPastSimMS(self.taptime) then
				self.tapcounter = 0;
			elseif not(self.taptimer:IsPastSimMS(self.taptime)) then
				if self.tapcounter >= self.tapamount then
					self.ToDelete = true;
				end
			end

			if self.linelength > self.setlinelength then

				local movetopos = self.Pos + (self.linevec*-1):SetMagnitude(self.setlinelength);
				if self.mapwrapx == true then
					if movetopos.X > SceneMan.SceneWidth then
						movetopos = Vector(movetopos.X - SceneMan.SceneWidth,movetopos.Y);
					elseif movetopos.X < 0 then
						movetopos = Vector(SceneMan.SceneWidth + movetopos.X,movetopos.Y);
					end
				end
				self.parent.Pos = movetopos;

				local pullamountnumber = math.abs(self.linevec.AbsRadAngle-self.parent.Vel.AbsRadAngle)/(math.pi*2);
				self.parent.Vel = self.parent.Vel + self.linevec:SetMagnitude(self.parent.Vel.Magnitude*pullamountnumber);

			end
		end
	else
		self.ToDelete = true;
	end

end

function Destroy(self)

	if MovableMan:IsParticle(self.cranksound) then
		self.cranksound.ToDelete = true;
	end

	if self.parentgun ~= nil and self.parentgun.ID ~= 255 then
		self.parentgun.Sharpness = 0;
		if self.parentgun.Magazine ~= nil then
			self.parentgun.Magazine.Scale = 1;
		end
	end

end