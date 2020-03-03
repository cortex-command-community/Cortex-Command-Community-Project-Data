function Create(self)
	self.tapTimerAim = Timer();
	self.tapTimerJump = Timer();
	self.tapCounter = 0;
	self.didTap = false;
	self.canTap = false;
	
	self.tapTime = 200;
	self.tapAmount = 2;
	self.guide = false;
end

function Update(self)
	local actor = MovableMan:GetMOFromID(self.RootID);
	if actor and IsActor(actor) then
		self.parent = ToActor(actor);
		local ctrl = self.parent:GetController();
		if self.parent:IsPlayerControlled() and self.parent.Status < 2 then
			local mouse = ctrl:IsMouseControlled();
			-- Deactivate when equipped in BG arm to allow FG arm shooting
			if IsAHuman(self.parent) and ToAHuman(self.parent).EquippedBGItem then
				local itemBG = ToAHuman(self.parent).EquippedBGItem;
				if itemBG.ID == self.ID then
					self:Deactivate();
				end
			end
			-- Alternatively you can tap Jump twice to grapple
			if ctrl:IsState(Controller.BODY_JUMPSTART) then
				if self.tapTimerJump:IsPastSimMS(self.tapTime) then
					self.tapTimerJump:Reset();
				else
					self:Activate();
				end
			end
			-- Tap sharp aim twice to toggle aim guide
			if ctrl:IsState(Controller.AIM_SHARP) then
				if mouse then
					self.guide = true;
				elseif self.canTap == true then
					self.tapTimerAim:Reset();
					self.didTap = true;
					self.canTap = false;
					self.tapCounter = self.tapCounter + 1;
				end
			else
				self.canTap = true;
				if mouse then
					self.guide = false;
				end
			end
			if self.tapTimerAim:IsPastSimMS(self.tapTime) then
				self.tapCounter = 0;
			else
				if self.tapCounter >= self.tapAmount then
					if self.guide == false then
						self.guide = true;
					else
						self.guide = false;
					end
				end
			end
			if self.guide == true then
				local frame = 0;
				if self.parent.Vel.Magnitude > 10 then
					frame = 1;
				end
				local startPos = (self.parent.Pos + self.parent.EyePos + self.Pos) / 3;
				local arrow = CreateMOSRotating("Grapple Gun Guide Arrow");
				local guidePos = startPos + Vector(self.parent.AimDistance + (self.parent.Vel.Magnitude), 0):RadRotate(self.parent:GetAimAngle(true));
				FrameMan:DrawBitmapPrimitive(self.parent.Team, guidePos, arrow, self.parent:GetAimAngle(true), frame);
			end
		else
			self:Deactivate();
			ctrl:SetState(Controller.AIM_SHARP, false);
		end
	end
end