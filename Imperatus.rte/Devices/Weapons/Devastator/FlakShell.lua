function Create(self)

	self.delayTimer = Timer();

	self.delayTime = 100; -- Delay time in MS before prox sensor starts

	self.pointCount = 120; -- number of points in the spiral
	self.spiralScale = 12; -- spiral scale
	self.skipPoints = 20; -- skips the first X points

	self.minRecordDist = -1;
	self.detect = false;

	-- radius = spiralScale * squareroot( pountCount )

end

function Update(self)

	if self.delayTimer:IsPastSimMS(self.delayTime) then
		for i = self.skipPoints, self.pointCount - 1 do
			local radius = self.spiralScale*math.sqrt(i);
			local angle = i * 137.508;
			local checkPos = self.Pos + Vector(radius,0):DegRotate(angle);
			if SceneMan.SceneWrapsX == true then
				if checkPos.X > SceneMan.SceneWidth then
					checkPos = Vector(checkPos.X - SceneMan.SceneWidth,checkPos.Y);
				elseif checkPos.X < 0 then
					checkPos = Vector(SceneMan.SceneWidth + checkPos.X,checkPos.Y);
				end
			end
			local moCheck = SceneMan:GetMOIDPixel(checkPos.X,checkPos.Y);
			if moCheck ~= rte.NoMOID then
				local actor = MovableMan:GetMOFromID( MovableMan:GetMOFromID(moCheck).RootID );
				if MovableMan:IsActor(actor) and actor.Team ~= self.Team then
					local checkdist = radius;
					if self.minRecordDist == -1 or (self.minRecordDist ~= -1 and self.minRecordDist > checkdist) then
						self.minRecordDist = radius;
						self.detect = true;
						break;
					else
						self:GibThis();
					end
				end
			end
		end
	end

	if self.mindRecordDist == -1 and not self.detect then
		self:GibThis();
	else
		self.detect = false;
	end

end