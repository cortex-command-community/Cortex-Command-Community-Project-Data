function Create(self)

	self.laserTimer = Timer();
	self.laserTimer:SetSimTimeLimitMS(25);
	self.guideTable = {};

	self.projectileVel = 30;
	if self.Magazine and self.Magazine.RoundCount ~= 0 then
		self.projectileVel = self.Magazine.NextRound.FireVel;
		self.projectileGravity = self.Magazine.NextRound.NextParticle.GlobalAccScalar;
	end

	self.maxTrajectoryPars = 60;

	self.guideColor = 120;
end

function Update(self)

	local actor = MovableMan:GetMOFromID(self.RootID);
	if MovableMan:IsActor(actor) and ToActor(actor):IsPlayerControlled() and ToActor(actor):GetController():IsState(Controller.AIM_SHARP) then
		if self.laserTimer:IsPastSimTimeLimit() then
			self.laserTimer:Reset();

			self.guideTable = {};
			self.guideTable[1] = Vector(self.MuzzlePos.X, self.MuzzlePos.Y);

			local actor = ToActor(actor);
			local guideParPos = self.MuzzlePos;
			local guideParVel = Vector(self.projectileVel, 0):RadRotate(actor:GetAimAngle(true));
			for i = 1, self.maxTrajectoryPars do
				guideParVel = guideParVel + Vector((SceneMan.GlobalAcc.X/GetPPM()), (SceneMan.GlobalAcc.Y/GetPPM())) * self.projectileGravity;
				guideParPos = guideParPos + guideParVel;
				if SceneMan:GetTerrMatter(guideParPos.X,guideParPos.Y) == 0 then
					self.guideTable[#self.guideTable + 1] = guideParPos;
				else
					local hitPos = Vector(self.guideTable[#self.guideTable].X,self.guideTable[#self.guideTable].Y);
					SceneMan:CastStrengthRay(self.guideTable[#self.guideTable], SceneMan:ShortestDistance(self.guideTable[#self.guideTable], guideParPos,false), 0, hitPos, 3, 0, false);
					self.guideTable[#self.guideTable + 1] = hitPos;
					break;
				end
			end
		end
	else
		self.guideTable = {};
	end

	if #self.guideTable > 1 then
		for i = 1, #self.guideTable-1 do
			PrimitiveMan:DrawLinePrimitive(self.guideTable[i],self.guideTable[i+1], self.guideColor);
		end
		PrimitiveMan:DrawCirclePrimitive(self.guideTable[#self.guideTable], 12, self.guideColor);
	end

	if self:DoneReloading() and self.Magazine and self.Magazine.RoundCount ~= 0 then
		self.projectileVel = self.Magazine.NextRound.FireVel;
		self.projectileGravity = self.Magazine.NextRound.NextParticle.GlobalAccScalar;
	end
end