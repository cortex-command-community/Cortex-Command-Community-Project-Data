function Create(self)

	self.laserTimer = Timer();
	self.particleTable = {};

	self.projectileVel = 30;
	self.maxTrajectoryPars = 60;

end

function Update(self)

	if self.laserTimer:IsPastSimMS(25) then
		self.laserTimer:Reset();

		for i = 1, #self.particleTable do
			if MovableMan:IsParticle(self.particleTable[i]) then
				self.particleTable[i].ToDelete = true;
			end
		end
		self.particleTable = {};

		local actor = MovableMan:GetMOFromID(self.RootID);
		if MovableMan:IsActor(actor) and ToActor(actor):IsPlayerControlled() and ToActor(actor):GetController():IsState(Controller.AIM_SHARP) then
			local actor = ToActor(actor);
			self.guideParPos = self.MuzzlePos;
			self.guideParVel = Vector(self.projectileVel,0):RadRotate(actor:GetAimAngle(true));
			for i = 1, self.maxTrajectoryPars do
				if SceneMan:GetTerrMatter(self.guideParPos.X,self.guideParPos.Y) == 0 then
					self.guideParVel = self.guideParVel + Vector((SceneMan.GlobalAcc.X/FrameMan.PPM),(SceneMan.GlobalAcc.Y/FrameMan.PPM));
					self.guideParPos = self.guideParPos + self.guideParVel;
					if SceneMan.SceneWrapsX == true then
						if self.guideParPos.X > SceneMan.SceneWidth then
							self.guideParPos = Vector(self.guideParPos.X - SceneMan.SceneWidth,self.guideParPos.Y);
						elseif self.guideParPos.X < 0 then
							self.guideParPos = Vector(SceneMan.SceneWidth + self.guideParPos.X,self.guideParPos.Y);
						end
					end
					local laserParticle = CreateMOSParticle("Coalition Breaker Grenade Launcher Guide Particle");
					laserParticle.Pos = self.guideParPos;
					MovableMan:AddParticle(laserParticle);
					self.particleTable[#self.particleTable+1] = laserParticle;
				else
					break;
				end
			end
		end
	end

end