function ConstantGoldIncomeScript:StartScript()
	self.UpdateTimer = Timer()
	self.UpdateInterval = 50
	self.GoldPerSecond = 10
end

function ConstantGoldIncomeScript:UpdateScript()
	if self.UpdateTimer:IsPastSimMS(self.UpdateInterval) then
		for team = Activity.TEAM_1, Activity.MAXTEAMCOUNT - 1 do
			local activity = ActivityMan:GetActivity()
			if activity then
				if activity:IsPlayerTeam(team) then
					activity:SetTeamFunds(activity:GetTeamFunds(team) + (self.UpdateInterval / 1000 * self.GoldPerSecond), team)
				end
			end
		end
		self.UpdateTimer:Reset()
	end
end

function ConstantGoldIncomeScript:EndScript()
end

function ConstantGoldIncomeScript:PauseScript()
end

function ConstantGoldIncomeScript:CraftEnteredOrbit()
end
