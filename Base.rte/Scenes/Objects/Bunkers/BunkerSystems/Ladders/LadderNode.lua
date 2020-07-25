function Create(self)
	self.checkTimer = Timer();
	self.checkTimer:SetSimTimeLimitMS(51);
	self.width = (ToMOSprite(self):GetSpriteWidth()/2) - 1;
	self.height = (ToMOSprite(self):GetSpriteHeight()/2) - 1;
end
function Update(self)
	if self.PinStrength > 0 and self.checkTimer:IsPastSimTimeLimit() then
		self.checkTimer:Reset();
		self.checkTimer:SetSimTimeLimitMS(51 + self.WoundCount * 34);
		self.Vel, self.AngularVel = Vector(), 0;
		local checkPos = self.Pos + Vector(self.width * self.FlipFactor, math.random(-self.height, self.height)):RadRotate(self.RotAngle);
		local moCheck = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
		if moCheck ~= rte.NoMOID then
			local mo = MovableMan:GetMOFromID(moCheck);
			if IsAttachable(mo) and ToAttachable(mo):GetParent() and IsAHuman(ToAttachable(mo):GetParent()) then
				local actor = ToAHuman(MovableMan:GetMOFromID(mo.RootID));
				local controller, velFactor = actor:GetController(), 1 + actor.Vel.Magnitude * 0.3;
				if actor.Status == Actor.STABLE and actor.FlipFactor ~= self.FlipFactor and not controller:IsState(Controller.BODY_JUMP) then
					actor.Vel = actor.Vel * (1 - 1 / velFactor);
					if controller:IsState(Controller.MOVE_LEFT) or controller:IsState(Controller.MOVE_RIGHT) then
						local speed = actor:GetLimbPathSpeed(1)/velFactor;
						actor.Vel = actor.Vel + Vector(speed/2, 0):RadRotate(actor:GetAimAngle(true)) - Vector(0, speed);
					elseif controller:IsState(Controller.BODY_CROUCH) then
						actor.Vel = actor.Vel/2;
					end	
				end	
			end	
		end	
	end	
end