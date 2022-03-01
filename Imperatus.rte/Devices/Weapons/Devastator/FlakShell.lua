function Create(self)

	self.delayTimer = Timer();

	self.delayTime = 100;

	self.pointCount = 40;
	self.spiralScale = 10;
	self.skipPoints = 10;
end

function Update(self)

	if self.delayTimer:IsPastSimMS(self.delayTime) then
		for i = self.skipPoints, self.pointCount - 1 do
			local radius = self.spiralScale * math.sqrt(i);
			local angle = i * 137.508;
			local checkPos = self.Pos + Vector(radius, 0):DegRotate(angle);
			if SceneMan.SceneWrapsX == true then
				if checkPos.X > SceneMan.SceneWidth then
					checkPos = Vector(checkPos.X - SceneMan.SceneWidth, checkPos.Y);
				elseif checkPos.X < 0 then
					checkPos = Vector(SceneMan.SceneWidth + checkPos.X, checkPos.Y);
				end
			end
			local moCheck = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
			if moCheck ~= rte.NoMOID then
				local actor = MovableMan:GetMOFromID(MovableMan:GetMOFromID(moCheck).RootID);
				if MovableMan:IsActor(actor) and actor.Team ~= self.Team and actor.Radius > radius then
					self:GibThis();
					break;
				end
			end
		end
	end
end