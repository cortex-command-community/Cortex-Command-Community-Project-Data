function FriendlyFireScript:StartScript()
	-- Amount of frames the particles still ignore teammates for
	self.frames = 6;
	self.minAge = 17 * self.frames;
	-- Default settings are approximately according to squad sizes
	self.updateTimer = Timer();
end
function FriendlyFireScript:UpdateScript()
	if self.updateTimer:IsPastSimMS(50) then
		self.updateTimer:Reset();
		for part in MovableMan.Particles do
			if part.HitsMOs == true and part.Team ~= -1 then
				if part.Age > self.minAge / (1 + part.Vel.Magnitude / 100) then
					part.Team = -1;		-- Hit everyone
					part.IgnoresTeamHits = false;
				end
			end
		end
	end
end