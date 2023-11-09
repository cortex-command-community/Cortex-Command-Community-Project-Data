function OnMessage(self, message, squadInfo)

	if message == "TacticsHandler_InitSquadInfo" then
		-- a table of three values: team, squad index, and our index within that squad
		self.tacticsHandlerSquadInfo = squadInfo;
	end
end

function Destroy(self)

	local activity = ActivityMan:GetActivity();
	if activity then
		activity:SendMessage("TacticsHandler_InvalidateActor", self.tacticsHandlerSquadInfo);
	end
end