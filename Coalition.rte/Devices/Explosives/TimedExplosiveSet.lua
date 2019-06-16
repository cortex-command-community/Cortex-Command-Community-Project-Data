function Create(self)

	self.lifeTimer = Timer();
	self.blinkTimer = Timer();
	self.blipTimer = Timer();

	self.actionPhase = 0;
	self.blink = true;
	self.changeCounter = 0;
	self.stuck = false;
	self.blipdelay = 1000;

	self.minBlipDelay = 100;
	self.medBlipDelay = 250;
	self.maxBlipDelay = 500;

end

function Update(self)

	if self.actionPhase == 0 then
		local rayHitPos = Vector(0,0);
		local rayHit = false;
		for i = 1, 15 do
			local checkPos = self.Pos + Vector(self.Vel.X,self.Vel.Y):SetMagnitude(i);
			local checkPix = SceneMan:GetMOIDPixel(checkPos.X,checkPos.Y);
			if checkPix ~= rte.NoMOID then
				checkPos = checkPos + SceneMan:ShortestDistance(checkPos,self.Pos,SceneMan.SceneWrapsX):SetMagnitude(3);
				self.target = MovableMan:GetMOFromID(checkPix);
				self.stickpositionX = checkPos.X-self.target.Pos.X;
				self.stickpositionY = checkPos.Y-self.target.Pos.Y;
				self.stickrotation = self.target.RotAngle;
				self.stickdirection = self.RotAngle;
				local soundfx = CreateAEmitter("Remote Explosive Sound Activate");
				soundfx.Pos = self.Pos;
				MovableMan:AddParticle(soundfx);
				self.stuck = true;
				rayHit = true;
				break;
			end
		end
		if rayHit == true then
			self.actionPhase = 1;
		else
			if SceneMan:CastStrengthRay(self.Pos,Vector(self.Vel.X,self.Vel.Y):SetMagnitude(15),0,rayHitPos,0,0,SceneMan.SceneWrapsX) == true then
				self.Pos = rayHitPos + SceneMan:ShortestDistance(rayHitPos,self.Pos,SceneMan.SceneWrapsX):SetMagnitude(3);
				self.PinStrength = 1000;
				self.AngularVel = 0;
				self.stuck = true;
				self.actionPhase = 2;
				local soundfx = CreateAEmitter("Remote Explosive Sound Activate");
				soundfx.Pos = self.Pos;
				MovableMan:AddParticle(soundfx);
			end
		end
	elseif self.actionPhase == 1 then
		if self.target ~= nil and self.target.ID ~= 255 then
			self.Pos = self.target.Pos + Vector(self.stickpositionX,self.stickpositionY):RadRotate(self.target.RotAngle-self.stickrotation);
			self.RotAngle = self.stickdirection+(self.target.RotAngle-self.stickrotation);
			self.PinStrength = 1000;
			self.Vel = Vector(0,0);
		else
			self.PinStrength = 0;
			self.actionPhase = 0;
		end
	end


	if self.stuck == true then

		if self.changeCounter == 0 and self.lifeTimer.ElapsedSimTimeMS > 5000 then
			self.changeCounter = 1;
			self.blipdelay = self.maxBlipDelay;
		end

		if self.changeCounter == 1 and self.lifeTimer.ElapsedSimTimeMS > 7000 then
			self.changeCounter = 2;
			self.blipdelay = self.medBlipDelay;
		end

		if self.changeCounter == 2 and self.lifeTimer.ElapsedSimTimeMS > 9000 then
			self.changeCounter = 3;
			self.blipdelay = self.minBlipDelay;
		end

		if self.lifeTimer:IsPastSimMS(10000) then
			self:GibThis();
		else
			self.ToDelete = false;
			self.ToSettle = false;
		end

		if self.blinkTimer:IsPastSimMS(self.blipdelay/2) then
			self.blinkTimer:Reset();
			if self.blink == false then
				self.blink = true;
				self.Frame = 0;
			else
				self.blink = false;
				self.Frame = 1;
			end
		end

		if self.blipTimer:IsPastSimMS(self.blipdelay) then
			self.blipTimer:Reset();
			local soundfx = CreateAEmitter("Coalition Timed Explosive Sound Blip");
			soundfx.Pos = self.Pos;
			MovableMan:AddParticle(soundfx);
		end

	end

end