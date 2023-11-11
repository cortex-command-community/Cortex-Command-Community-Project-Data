function Create(self)

	if self.saveLoadHandler and self:StringValueExists("tacticsActorInvalidatorSquadInfo") then
		self.tacticsHandlerSquadInfo = loadstring("return " .. self:GetStringValue("tacticsActorInvalidatorSquadInfo"))()
	end
	
end

function OnMessage(self, message, squadInfo)

	if message == "TacticsHandler_InitSquadInfo" then
		-- a table of three values: team, squad index, and our index within that squad
		self.tacticsHandlerSquadInfo = {};
		for k, v in pairs(squadInfo) do
			self.tacticsHandlerSquadInfo[k] = v;
		end
		
		self.saveLoadHandler = require("Activities/Utility/SaveLoadHandler");
		self.saveLoadHandler:Initialize(self);
		
		self:SetStringValue("tacticsActorInvalidatorSquadInfo", self.saveLoadHandler:SerializeTable(self.tacticsHandlerSquadInfo))		
		
	end
	
end

function Destroy(self)

	local activity = ActivityMan:GetActivity();
	if activity then
		activity:SendMessage("TacticsHandler_InvalidateActor", self.tacticsHandlerSquadInfo);
	end
end