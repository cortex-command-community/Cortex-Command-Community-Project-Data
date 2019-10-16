function Create(self)

	self.lifeTimer = Timer();
	self.lifeTimer:SetSimTimeLimitMS(4900);

	self.raylength = 20;
	self.rayPixSpace = 2;

	self.dots = math.floor(self.raylength/self.rayPixSpace);

end

function Update(self)

	self.raylength = self.Vel.Magnitude;
	self.dots = math.floor(self.raylength/self.rayPixSpace);

	for i = 1, self.dots do
		local checkPos = self.Pos + Vector(self.Vel.X,self.Vel.Y):SetMagnitude((i/self.dots)*self.raylength);
		if SceneMan.SceneWrapsX == true then
			if checkPos.X > SceneMan.SceneWidth then
				checkPos = Vector(checkPos.X - SceneMan.SceneWidth,checkPos.Y);
			elseif checkPos.X < 0 then
				checkPos = Vector(SceneMan.SceneWidth + checkPos.X,checkPos.Y);
			end
		end
		local terrCheck = SceneMan:GetTerrMatter(checkPos.X,checkPos.Y);
		if terrCheck == 0 then
			local moCheck = SceneMan:GetMOIDPixel(checkPos.X,checkPos.Y);
			if moCheck ~= 255 then
				local actor = MovableMan:GetMOFromID( MovableMan:GetMOFromID(moCheck).RootID );
				if actor.Team ~= self.Team then
					self:GibThis();
				end
			end
		else
			self:GibThis();
		end
	end
	
	if self.lifeTimer:IsPastSimTimeLimit() then
		self:GibThis();
	end
	
end