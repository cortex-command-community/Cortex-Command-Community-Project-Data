function Create(self)

	self.actionPhase = 0;
	self.stuck = false;
	self.lifeTimer = Timer();

end

function Update(self)

	if self.Sharpness == 0 then
		self.ToDelete = false;
		self.ToSettle = false;
	elseif self.Sharpness == 1 then
		self.ToDelete = true;
	elseif self.Sharpness == 2 then
		local explosion = CreateMOSRotating("Coalition Remote Grenade Shot Explosion");
		explosion.Pos = self.Pos;
		explosion:GibThis();
		MovableMan:AddParticle(explosion);
		self.ToDelete = true;
	elseif self.Sharpness == 3 then
		if self.lifeTimer:IsPastSimMS(3000) then
			local explosion = CreateMOSRotating("Coalition Remote Grenade Shot Explosion");
			explosion.Pos = self.Pos;
			explosion:GibThis();
			MovableMan:AddParticle(explosion);
			self.ToDelete = true;
		else
			self.ToDelete = false;
			self.ToSettle = false;
		end
	end

	if self.actionPhase == 0 then
		local rayHitPos = Vector(0,0);
		local rayHit = false;
		for i = 1, 15 do
			local checkPos = self.Pos + Vector(self.Vel.X,self.Vel.Y):SetMagnitude(i);
			local checkPix = SceneMan:GetMOIDPixel(checkPos.X,checkPos.Y);
			if checkPix ~= rte.NoMOID and (self.ID == rte.NoMOID or (self.ID ~= rte.NoMOID and checkPix ~= self.ID)) and MovableMan:GetMOFromID(checkPix).Team ~= self.Team then
				checkPos = checkPos + SceneMan:ShortestDistance(checkPos,self.Pos,SceneMan.SceneWrapsX):SetMagnitude(3);
				self.target = MovableMan:GetMOFromID(checkPix);
				self.stickpositionX = checkPos.X-self.target.Pos.X;
				self.stickpositionY = checkPos.Y-self.target.Pos.Y;
				self.stickrotation = self.target.RotAngle;
				self.stickdirection = self.RotAngle;
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
				self.HitsMOs = false;
			end
		end
	elseif self.actionPhase == 1 then
		if self.target ~= nil and self.target.ID ~= 255 then
			self.Pos = self.target.Pos + Vector(self.stickpositionX,self.stickpositionY):RadRotate(self.target.RotAngle-self.stickrotation);
			self.RotAngle = self.stickdirection+(self.target.RotAngle-self.stickrotation);
			self.PinStrength = 1000;
			self.Vel = Vector(0,0);
			self.HitsMOs = false;
		else
			self.PinStrength = 0;
			self.actionPhase = 0;
			self.HitsMOs = true;
		end
	end

end