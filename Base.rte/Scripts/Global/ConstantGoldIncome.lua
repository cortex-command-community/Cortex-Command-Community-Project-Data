function ConstantGoldIncomeScript:StartScript()
	self.updateTimer = Timer();
	self.updateInterval = 50;
	self.goldPerSecond = 10;
end
function ConstantGoldIncomeScript:UpdateScript()
	if self.updateTimer:IsPastSimMS(self.updateInterval) then
		for team = Activity.TEAM_1, Activity.MAXTEAMCOUNT - 1 do
			local activity = ActivityMan:GetActivity();
			if activity then
				if activity:IsPlayerTeam(team) then
					activity:SetTeamFunds(activity:GetTeamFunds(team) + (self.updateInterval / 1000 * self.goldPerSecond), team);
				end
			end
		end
		self.updateTimer:Reset();
	end
end