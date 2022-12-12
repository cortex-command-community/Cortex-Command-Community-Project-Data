function AutosaveScript:StartScript()
	self.autosaveTimer = Timer();
	self.autosaveTimer:SetRealTimeLimitS(60 * 3);
end

function AutosaveScript:UpdateScript()
	if self.autosaveTimer:IsPastRealTimeLimit() then
		LuaMan:SaveGame("Autosave");
		self.autosaveTimer:Reset();
	end
end