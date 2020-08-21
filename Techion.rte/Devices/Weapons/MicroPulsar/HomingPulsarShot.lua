function Create(self)

	self.disintegrationStrength = 50;
	self.adjustmentAmount = 2;

	self.delayTimer = Timer();

	self.target = null;
	local longDist = 800;
	local shortDist = 98;
	
	for i = 1, MovableMan:GetMOIDCount() - 1 do
		local mo = MovableMan:GetMOFromID(i);
		if mo and (mo.Team ~= self.Team or mo.ClassName == "TDExplosive" or mo.ClassName == "MOSRotating" or (mo.ClassName == "AEmitter" and mo.RootID == moCheck)) then

		local distCheck = SceneMan:ShortestDistance(self.Pos, mo.Pos, SceneMan.SceneWrapsX);
			if distCheck.Magnitude - mo.Radius < longDist then

				local toCheckPos = Vector(distCheck.Magnitude, 0):RadRotate(self.Vel.AbsRadAngle);
				local checkPos = self.Pos + toCheckPos;
				if SceneMan.SceneWrapsX == true then
					if checkPos.X > SceneMan.SceneWidth then
						checkPos = Vector(checkPos.X - SceneMan.SceneWidth, checkPos.Y);
					elseif checkPos.X < 0 then
						checkPos = Vector(SceneMan.SceneWidth + checkPos.X, checkPos.Y);
					end
				end

				local distCheck2 = SceneMan:ShortestDistance(checkPos, mo.Pos, SceneMan.SceneWrapsX);

				if distCheck2.Magnitude - mo.Radius < shortDist then

					if SceneMan:CastStrengthRay(self.Pos, toCheckPos, 0, Vector(), 3, rte.airID, SceneMan.SceneWrapsX) == false and SceneMan:CastStrengthRay(checkPos, distCheck2:SetMagnitude(distCheck2.Magnitude - mo.Radius), 0, Vector(), 3, 0, SceneMan.SceneWrapsX) == false then
						self.target = mo;
						longDist = distCheck.Magnitude - mo.Radius;
						shortDist = distCheck2.Magnitude - mo.Radius;
					end
				end
			end
		end
	end
	PulsarDissipate(self, true);
	
	self.trailPar = CreateMOPixel("Techion Pulse Shot Trail Glow Small");
	self.trailPar.Pos = self.Pos - (self.Vel * rte.PxTravelledPerFrame);
	self.trailPar.Vel = self.Vel/10;
	self.trailPar.Lifetime = 60;
	MovableMan:AddParticle(self.trailPar);
end
function Update(self)
	if self.delayTimer:IsPastSimMS(25) and self.target ~= null and self.target.ID ~= rte.NoMOID then
		local checkVel = SceneMan:ShortestDistance(self.Pos, self.target.Pos, SceneMan.SceneWrapsX);
		checkVel = checkVel:SetMagnitude(checkVel.Magnitude - self.target.Radius);
		if SceneMan:CastStrengthRay(self.Pos, checkVel, 0, Vector(), 3, rte.airID, SceneMan.SceneWrapsX) == false then
			local aimVel = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(1) + SceneMan:ShortestDistance(self.Pos, self.target.Pos, SceneMan.SceneWrapsX):SetMagnitude(self.adjustmentAmount);
			self.Vel = Vector(self.Vel.Magnitude, 0):RadRotate(aimVel.AbsRadAngle);
		end
	end
	self.ToSettle = false;
	if self.explosion then
		self.ToDelete = true;
	else
		PulsarDissipate(self, false);
		if self.trailPar and MovableMan:IsParticle(self.trailPar) then
			self.trailPar.Pos = self.Pos - Vector(self.Vel.X, self.Vel.Y):SetMagnitude(3);
			self.trailPar.Vel = self.Vel/2;
			self.trailPar.Lifetime = self.Age + TimerMan.DeltaTimeMS;
		end
	end
	self.EffectRotAngle = self.Vel.AbsRadAngle;
end