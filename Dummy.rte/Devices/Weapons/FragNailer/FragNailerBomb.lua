function Create(self)
	self.toDetonate = false;
	self.detTimer = Timer();

	self.actionPhase = 0;
	self.stuck = false;
end

function Update(self)

	self.ToDelete = false;

	if self.actionPhase == 0 then
		local rayHitPos = Vector();
		local rayHit = false;
		local dots = math.sqrt(self.Vel.Magnitude);
		local trace = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(self.Vel.Magnitude * rte.PxTravelledPerFrame + 1);
		for i = 1, dots do
			local checkPos = self.Pos + trace * (i/dots);
			local checkPix = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
			if checkPix ~= rte.NoMOID and (self.ID == rte.NoMOID or (self.ID ~= rte.NoMOID and checkPix ~= self.ID)) and MovableMan:GetMOFromID(checkPix).Team ~= self.Team then
				checkPos = checkPos + SceneMan:ShortestDistance(checkPos, self.Pos, SceneMan.SceneWrapsX):SetMagnitude(3);
				
				self.target = MovableMan:GetMOFromID(checkPix);
				self.stickposition = SceneMan:ShortestDistance(self.target.Pos, checkPos, SceneMan.SceneWrapsX);
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
			if SceneMan:CastStrengthRay(self.Pos, trace, 0, rayHitPos, 1, rte.airID, SceneMan.SceneWrapsX) then
				self.Pos = rayHitPos + SceneMan:ShortestDistance(rayHitPos, self.Pos, SceneMan.SceneWrapsX):SetMagnitude(3);
				self.PinStrength = 1000;
				self.AngularVel = 0;
				self.stuck = true;
				self.actionPhase = 2;
				self.HitsMOs = false;
			end
		end
	elseif self.actionPhase == 1 then
		if self.target and self.target.ID ~= rte.NoMOID then
			self.Pos = self.target.Pos + Vector(self.stickposition.X, self.stickposition.Y):RadRotate(self.target.RotAngle - self.stickrotation);
			self.RotAngle = self.stickdirection + (self.target.RotAngle - self.stickrotation);
			self.PinStrength = 1000;
			self.Vel = Vector();
			self.HitsMOs = false;
		else
			self.toDetonate = true;
		end
	end
	if self.detTimer:IsPastSimMS(2000) or self.toDetonate then
		local explosion = CreateMOSRotating("Particle Dummy Frag Nailer Explosion");
		explosion.Pos = self.Pos;
		explosion:GibThis();
		MovableMan:AddParticle(explosion);
		self.ToDelete = true;
	end
end