function MoreGoldScript:StartScript()
	self.LastGold = {}
	self.Activity = ActivityMan:GetActivity()
	
	for t = Activity.TEAM_1, Activity.TEAM_4 do
		self.LastGold[t] = self.Activity:GetTeamFunds(t)
	end
end

function MoreGoldScript:UpdateScript()
	for t = Activity.TEAM_1, Activity.TEAM_4 do
		local diff = self.Activity:GetTeamFunds(t) - self.LastGold[t] 
	
		if diff > 0 and diff < 20 then
			diff = diff * 2
			self.Activity:SetTeamFunds(self.Activity:GetTeamFunds(t) + diff, t)
		end
	
		self.LastGold[t] = self.Activity:GetTeamFunds(t)
	end
end

function MoreGoldScript:EndScript()
end

function MoreGoldScript:PauseScript()
end

function MoreGoldScript:CraftEnteredOrbit()
end
