function AutosaveScript:StartScript()
	self.AutosaveTimer = Timer();
	self.AutosaveTimer:SetRealTimeLimitS(60*3);
end

function AutosaveScript:UpdateScript()
	if self.AutosaveTimer:IsPastRealTimeLimit() then
		LuaMan:SaveGame("Autosave");
		self.AutosaveTimer:Reset();
	end
end