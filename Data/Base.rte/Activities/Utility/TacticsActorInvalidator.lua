function Create(self)

	if self:StringValueExists("tacticsActorInvalidatorSquadInfo") ~= "" then
		--print("tried to create load serialized invalidator")
		--print(self:LoadString("tacticsActorInvalidatorSquadInfo"))
		self.tacticsHandlerSquadInfo = loadstring("return " .. self:GetStringValue("tacticsActorInvalidatorSquadInfo"))()
	end
	
end

function Update(self)

	if not self.pathUpdated then
	
		self.pathUpdated = true;
		self:UpdateMovePath(); -- if we travel a lot before getting out of a dropship, our task movepath can get all sortsa messed up.
	
	end
	
end

function OnMessage(self, message, squadInfo)

	if message == "TacticsHandler_InitSquadInfo" then
		-- a table of three values: team, squad index, and our index within that squad
		self.tacticsHandlerSquadInfo = {};
		for k, v in pairs(squadInfo) do
			self.tacticsHandlerSquadInfo[k] = v;
			--print("got squad info:" .. k .. v)
		end
		
		self.saveLoadHandler = require("Activities/Utility/SaveLoadHandler");
		self.saveLoadHandler:Initialize(self);
		
	elseif message == "TacticsHandler_UpdateSquadIndex" then
		self.tacticsHandlerSquadInfo.squadIndex = squadInfo;
	end
	
end

function OnSave(self)

	--print("tried to save...?")
	self:SetStringValue("tacticsActorInvalidatorSquadInfo", self.saveLoadHandler:SerializeTable(self.tacticsHandlerSquadInfo))		

end

function Destroy(self)

--	if self.PresetName then
--		print("On Destroy, we invalidated this actor of team " .. self.Team);
---		print(self.PresetName)
--	end
	local activity = ActivityMan:GetActivity();
	if activity then
		activity:SendMessage("TacticsHandler_InvalidateActor", self.tacticsHandlerSquadInfo);
	end
end