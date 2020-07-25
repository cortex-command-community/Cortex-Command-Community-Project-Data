function Create(self)
	self.Team = Activity.NOTEAM;
	self.IgnoresTeamHits = false;

	self.updateTimer = Timer();
	self.updateTimer:SetSimTimeLimitMS(math.random(900, 1000));
	
	self.materialID = SceneMan:GetTerrMatter(self.Pos.X, self.Pos.Y);
end
function Update(self)
	--Check if the terrain piece still exists and delete the emitter if it does not
	if self.updateTimer:IsPastSimTimeLimit() then
		self.updateTimer:Reset();
		local terrainFound = false;
		local checkPosY = {-2, 0, 2};
		for i = 1, #checkPosY do
			local checkPos = self.Pos + Vector(0, checkPosY[i]):RadRotate(self.RotAngle);
			if SceneMan:GetTerrMatter(checkPos.X, checkPos.Y) == self.materialID then
				terrainFound = true;
				break;
			end
		end
		if not terrainFound then
			self:GibThis();
		end
	end
end