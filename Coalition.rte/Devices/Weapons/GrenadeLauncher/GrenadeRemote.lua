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
		local explosion = CreateMOSRotating("Grenade Launcher Grenade Explosion");
		explosion.Pos = self.Pos;
		explosion:GibThis();
		MovableMan:AddParticle(explosion);
		self.ToDelete = true;
	elseif self.Sharpness == 3 then
		if self.lifeTimer:IsPastSimMS(3000) then
			local explosion = CreateMOSRotating("Grenade Launcher Grenade Explosion");
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
		local rayHitPos = Vector();
		local rayHit = false;
		local trace = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(self.Vel.Magnitude * rte.PxTravelledPerFrame + self.Radius);
		local dots = trace.Magnitude/2;
		for i = 1, dots do
			local checkPos = self.Pos + Vector(trace.X, trace.Y) * (i/dots);
			local checkPix = SceneMan:GetMOIDPixel(checkPos.X,checkPos.Y);
			if checkPix ~= rte.NoMOID and (self.ID == rte.NoMOID or (self.ID ~= rte.NoMOID and checkPix ~= self.ID)) and MovableMan:GetMOFromID(checkPix).Team ~= self.Team then
				checkPos = checkPos + SceneMan:ShortestDistance(checkPos, self.Pos, SceneMan.SceneWrapsX):SetMagnitude(3);
				self.target = MovableMan:GetMOFromID(checkPix);
				self.stickPosition = SceneMan:ShortestDistance(self.target.Pos, checkPos, SceneMan.SceneWrapsX);
				self.stickRotation = self.target.RotAngle;
				self.stickDirection = self.RotAngle;
				self.stuck = true;
				rayHit = true;
				break;
			end
		end
		if rayHit == true then
			self.actionPhase = 1;
		else
			if SceneMan:CastStrengthRay(self.Pos, trace, 0, rayHitPos, 0, rte.airID, SceneMan.SceneWrapsX) == true then
				self.Pos = rayHitPos + SceneMan:ShortestDistance(rayHitPos, self.Pos, SceneMan.SceneWrapsX):SetMagnitude(3);
				self.PinStrength = 1000;
				self.Vel = Vector();
				self.AngularVel = 0;
				self.stuck = true;
				self.actionPhase = 2;
				self.HitsMOs = false;
			end
		end
	elseif self.actionPhase == 1 then
		if self.target ~= nil and self.target.ID ~= rte.NoMOID then
			self.Pos = self.target.Pos + Vector(self.stickPosition.X, self.stickPosition.Y):RadRotate(self.target.RotAngle - self.stickRotation);
			self.RotAngle = self.stickDirection + (self.target.RotAngle - self.stickRotation);
			self.PinStrength = 1000;
			self.Vel = Vector();
			self.AngularVel = 0;
			self.HitsMOs = false;
		else
			self.PinStrength = 0;
			self.actionPhase = 0;
			self.HitsMOs = true;
		end
	end
end