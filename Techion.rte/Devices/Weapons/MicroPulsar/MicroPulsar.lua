function Create(self)
	self.delayTimer = Timer();
	self.guidePos = null;
	self.guideSize = 0;
	self.guideLine = null;
	self.guideLine2 = null;
end

function Update(self)
	local actor = MovableMan:GetMOFromID(self.RootID);
	if MovableMan:IsActor(actor) and ToActor(actor):GetController():IsState(Controller.AIM_SHARP) then

		if self.delayTimer:IsPastSimMS(50) then
			self.delayTimer:Reset();
			self.guidePos = null;
			local longDist = 800;
			local shortDist = 98;
			for i = 1, MovableMan:GetMOIDCount() - 1 do
				local mo = MovableMan:GetMOFromID(i);
				if mo and mo.ClassName ~= "ADoor" and (mo.Team ~= self.Team or mo.ClassName == "TDExplosive" or mo.ClassName == "MOSRotating" or (mo.ClassName == "AEmitter" and mo.RootID == moCheck)) then

					local distCheck = SceneMan:ShortestDistance(self.MuzzlePos, mo.Pos, SceneMan.SceneWrapsX);
					if distCheck.Magnitude - mo.Radius < longDist then

						local toCheckPos = Vector(distCheck.Magnitude * self.FlipFactor, 0):RadRotate(self.RotAngle);
						local checkPos = self.MuzzlePos + toCheckPos;
						if SceneMan.SceneWrapsX == true then
							if checkPos.X > SceneMan.SceneWidth then
								checkPos = Vector(checkPos.X - SceneMan.SceneWidth, checkPos.Y);
							elseif checkPos.X < 0 then
								checkPos = Vector(SceneMan.SceneWidth + checkPos.X, checkPos.Y);
							end
						end

						local distCheck2 = SceneMan:ShortestDistance(checkPos, mo.Pos, SceneMan.SceneWrapsX);

						if distCheck2.Magnitude - mo.Radius < shortDist then

							if SceneMan:CastStrengthRay(self.MuzzlePos, toCheckPos, 0, Vector(), 3, rte.airID, SceneMan.SceneWrapsX) == false and SceneMan:CastStrengthRay(checkPos, distCheck2:SetMagnitude(distCheck2.Magnitude - mo.Radius), 0, Vector(), 3, rte.airID, SceneMan.SceneWrapsX) == false then
								self.guidePos = Vector(mo.Pos.X, mo.Pos.Y);
								self.guideSize = mo.Radius;
								self.guideLine = toCheckPos;
								self.guideLine2 = distCheck2;
								longDist = distCheck.Magnitude - mo.Radius;
								shortDist = distCheck2.Magnitude - mo.Radius;
							end
						end
					end
				end
			end
		end
		if self.guidePos ~= null then

			local cornerPos = Vector(self.guidePos.X - self.guideSize, self.guidePos.Y - self.guideSize);
			PrimitiveMan:DrawLinePrimitive(cornerPos, cornerPos + Vector(5, 0), 13);
			PrimitiveMan:DrawLinePrimitive(cornerPos, cornerPos + Vector(0, 5), 13);

			cornerPos = Vector(self.guidePos.X - self.guideSize, self.guidePos.Y + self.guideSize);
			PrimitiveMan:DrawLinePrimitive(cornerPos, cornerPos + Vector(5, 0), 13);
			PrimitiveMan:DrawLinePrimitive(cornerPos, cornerPos + Vector(0, -5), 13);

			cornerPos = Vector(self.guidePos.X + self.guideSize, self.guidePos.Y + self.guideSize);
			PrimitiveMan:DrawLinePrimitive(cornerPos, cornerPos + Vector(-5, 0), 13);
			PrimitiveMan:DrawLinePrimitive(cornerPos, cornerPos + Vector(0, -5), 13);

			cornerPos = Vector(self.guidePos.X + self.guideSize, self.guidePos.Y - self.guideSize);
			PrimitiveMan:DrawLinePrimitive(cornerPos, cornerPos + Vector(-5, 0), 13);
			PrimitiveMan:DrawLinePrimitive(cornerPos, cornerPos + Vector(0, 5), 13);

			cornerPos = Vector(self.guidePos.X, self.guidePos.Y - self.guideSize);
			PrimitiveMan:DrawLinePrimitive(cornerPos, cornerPos + Vector(0, -5), 13);

			cornerPos = Vector(self.guidePos.X - self.guideSize, self.guidePos.Y);
			PrimitiveMan:DrawLinePrimitive(cornerPos, cornerPos + Vector(-5, 0), 13);

			cornerPos = Vector(self.guidePos.X, self.guidePos.Y + self.guideSize);
			PrimitiveMan:DrawLinePrimitive(cornerPos, cornerPos + Vector(0, 5), 13);

			cornerPos = Vector(self.guidePos.X + self.guideSize, self.guidePos.Y);
			PrimitiveMan:DrawLinePrimitive(cornerPos, cornerPos + Vector(5, 0), 13);
		end
	else
		self.guidePos = null;
	end
end