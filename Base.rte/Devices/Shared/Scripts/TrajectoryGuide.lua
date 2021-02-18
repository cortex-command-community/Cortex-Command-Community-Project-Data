function Create(self)

	self.laserTimer = Timer();
	self.laserTimer:SetSimTimeLimitMS(10);
	self.guideTable = {};

	self.projectileVel = 30;

	if IsThrownDevice(self) then
		self.isThrownDevice = true;
		self.projectileVel = self.MaxThrowVel;
		self.projectileVelMin = self.MinThrowVel;
		self.projectileGravity = self.GlobalAccScalar;
		self.projectileAirResistance = self.AirResistance;
		self.projectileAirThreshold = self.AirThreshold;

	elseif self.Magazine and self.Magazine.RoundCount ~= 0 then
		self.projectileVel = self.Magazine.NextRound.FireVel;
		self.projectileGravity = self.Magazine.NextRound.NextParticle.GlobalAccScalar;
		self.projectileAirResistance = self.Magazine.NextRound.NextParticle.AirResistance;
		self.projectileAirThreshold = self.Magazine.NextRound.NextParticle.AirThreshold;
	end

	self.guideRadius = self:NumberValueExists("TrajectoryGuideBlastRadius") and self:GetNumberValue("TrajectoryGuideBlastRadius") or 12;
	self.maxTrajectoryPars = self:NumberValueExists("TrajectoryGuideLength") and self:GetNumberValue("TrajectoryGuideLength") or 60;
	self.guideColor = self:NumberValueExists("TrajectoryGuideColorIndex") and self:GetNumberValue("TrajectoryGuideColorIndex") or 120;
	self.skipLines = self:NumberValueExists("TrajectoryGuideSkipLines") and self:GetNumberValue("TrajectoryGuideSkipLines") or 1;
	self.drawHitsOnly = self:GetNumberValue("TrajectoryGuideDrawHitsOnly") == 1;
end

function Update(self)

	local actor = self:GetRootParent();
	if MovableMan:IsActor(actor) and ToActor(actor):IsPlayerControlled() then
		local actor = ToActor(actor);
		local controller = actor:GetController();
		if self.isThrownDevice then 
			if not self.throwTimer and controller:IsState(Controller.WEAPON_FIRE) then
				self.throwTimer = Timer();
			end
		elseif (self:DoneReloading() or self.FiredFrame) and self.Magazine and self.Magazine.RoundCount ~= 0 then
			self.projectileVel = self.Magazine.NextRound.FireVel;
			self.projectileGravity = self.Magazine.NextRound.NextParticle.GlobalAccScalar;
		end
		local hitPos;
		if controller:IsState(Controller.AIM_SHARP) or self.isThrownDevice and controller:IsState(Controller.WEAPON_FIRE) then
			if self.laserTimer:IsPastSimTimeLimit() then

				local guideParPos, gudeParVel;

				if self.isThrownDevice and IsAHuman(actor) then
					--Display detonation point if a scripted fuze is active
					if self.fuze and self.fuzeDelay then
						self.maxTrajectoryPars = (self.fuzeDelay - self.fuze.ElapsedSimTimeMS - self.laserTimer.ElapsedSimTimeMS)/TimerMan.DeltaTimeMS * rte.PxTravelledPerFrame;
					end
					actor = ToAHuman(actor);
					--The following offset is as found in the source code (To-do: expose and utilize EndThrowOffset properly instead)
					guideParPos = actor.Pos + Vector((actor.FGArm.ParentOffset.X + 15) * actor.FlipFactor, actor.FGArm.ParentOffset.Y - 8);
					local projectileVel = self.throwTimer and self.projectileVelMin + (self.projectileVel - self.projectileVelMin) * math.min(self.throwTimer.ElapsedSimTimeMS, actor.ThrowPrepTime)/actor.ThrowPrepTime or self.projectileVel;
					guideParVel = Vector(projectileVel, 0):RadRotate(actor.RotAngle + actor:GetAimAngle(true));
				else
					guideParPos = self.MuzzlePos;
					guideParVel = Vector(self.projectileVel, 0):RadRotate(actor:GetAimAngle(true));
				end

				self.guideTable = {};
				self.guideTable[1] = Vector(guideParPos.X, guideParPos.Y);

				for i = 1, self.maxTrajectoryPars do
					guideParVel = guideParVel + Vector(SceneMan.GlobalAcc.X, SceneMan.GlobalAcc.Y)/GetPPM() * self.projectileGravity;
					if self.projectileAirResistance ~= 0 and guideParVel.Largest >= self.projectileAirThreshold then
						guideParVel:SetMagnitude(guideParVel.Magnitude * (1 - (self.projectileAirResistance * TimerMan.DeltaTimeSecs * 2.5)));	--To-do: replace "* 2.5" with something more intangible
					end
					guideParPos = guideParPos + guideParVel;
					if SceneMan:GetTerrMatter(guideParPos.X, guideParPos.Y) == rte.airID then
						self.guideTable[#self.guideTable + 1] = guideParPos;
					else
						hitPos = Vector(self.guideTable[#self.guideTable].X, self.guideTable[#self.guideTable].Y);
						SceneMan:CastStrengthRay(self.guideTable[#self.guideTable], SceneMan:ShortestDistance(self.guideTable[#self.guideTable], guideParPos, false), 0, hitPos, 3, rte.airID, false);
						self.guideTable[#self.guideTable + 1] = hitPos;
						break;
					end
				end
				self.laserTimer:Reset();
			end
		else
			self.guideTable = {};
		end
		if #self.guideTable > 1 and (not self.drawHitsOnly or hitPos) then
			if self.skipLines > 0 then
				for i = 1, #self.guideTable - 1 do
					if self.skipLines == 0 or i % (self.skipLines + 1) == 0 then
						PrimitiveMan:DrawLinePrimitive(controller.Player, self.guideTable[i], self.guideTable[i + 1], self.guideColor);
					end
				end
			end
			PrimitiveMan:DrawCirclePrimitive(controller.Player, self.guideTable[#self.guideTable], self.guideRadius, self.guideColor);
			--Optional: move view point closer to guide point?
			--local viewLength = SceneMan:ShortestDistance(actor.EyePos, actor.ViewPoint, SceneMan.SceneWrapsX).Magnitude;
			--local viewPoint = actor.ViewPoint + SceneMan:ShortestDistance(actor.ViewPoint, self.guideTable[#self.guideTable], SceneMan.SceneWrapsX):SetMagnitude(viewLength);
			--SceneMan:SetScrollTarget(viewPoint, 0.1, false, ActivityMan:GetActivity():ScreenOfPlayer(controller.Player));
		end
	else
		self.throwTimer = nil;
	end
end