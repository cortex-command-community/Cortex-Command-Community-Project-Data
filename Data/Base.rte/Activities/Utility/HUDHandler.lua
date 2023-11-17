--------------------------------------- Instructions ---------------------------------------

--

--------------------------------------- Misc. Information ---------------------------------------

--




local HUDHandler = {};

function HUDHandler:Create()
	local Members = {};

	setmetatable(Members, self);
	self.__index = self;

	return Members;
end

function HUDHandler:Initialize(activity, newGame)
	
	print("HUDHandlerinited")
	
	self.Activity = activity;
	
	self.objListStartXOffset = 50;
	self.objListStartYOffset = 50;
	self.objListSpacing = 15;
	
	self.descriptionSpacing = 15;
	
	if newGame then
		
		self.mainTable = {};
		
		self.mainTable.playersInTeamTables = {};
		self.mainTable.teamTables = {};

		for team = 0, self.Activity.TeamCount do
			self.mainTable.playersInTeamTables[team] = {};
			self.mainTable.teamTables[team] = {};
			self.mainTable.teamTables[team].Objectives = {};
		end
		
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self.Activity:PlayerActive(player) and self.Activity:PlayerHuman(player) then
				table.insert(self.mainTable.playersInTeamTables[self.Activity:GetTeamOfPlayer(player)], player);
			end
		end
		
	end
	
	-- DEBUG TEST OBJECTIVES
	
	self:AddObjective(0, "TestObj1", "TestOne", "Attack", "Test the objective One", "This is a test One objective! Testing.", nil, true);
	self:AddObjective(0, "TestObj2", "TestTwo", "Attack", "Test the objective Two", "This is a test Two objective! Testing.", nil, true);
	
end

function HUDHandler:OnLoad(saveLoadHandler)
	
	print("loading HUDHandler...");
	self.mainTable = saveLoadHandler:ReadSavedStringAsTable("HUDHandlerMainTable");
	print("loaded HUDHandler!");
	
end

function HUDHandler:OnSave(saveLoadHandler)
	
	print("saving HUD handler")
	saveLoadHandler:SaveTableAsString("HUDHandlerMainTable", self.mainTable);	
	print("saved HUDHandler!");
	
end

function HUDHandler:MakeRelativeToScreenPos(player, vector)

	local vector = Vector(
		CameraMan:GetOffset(player).X + vector.X,
		CameraMan:GetOffset(player).Y + vector.Y
	)
	return vector;
	
end

function HUDHandler:AddObjective(objTeam, objInternalNameOrFullTable, objShortName, objType, objLongName, objDescription, objPos, showArrowOnlyOnSpectatorView)

	local objTable;
	
	if type(objInternalNameOrFullTable) == "table" then
		objTable = objInternalNameOrFullTable;
	elseif objTeam and objInternalNameOrFullTable then
		
		objTable = {};
		
		objTable.internalName = objInternalNameOrFullTable;
		objTable.shortName = objShortName or objInternalNameOrFullTable;
		objTable.Type = objType or "Generic";
		objTable.longName = objLongName or objShortName;
		objTable.Description = objDescription or ""
		objTable.Position = objPos;
		objTable.showArrowOnlyOnSpectatorView = showArrowOnlyOnSpectatorView or false;
		
	else
		print("HUD Handler tried to add an objective with no team or no internal name!");
		return false;
	end
	
	for i, objTable in ipairs(self.mainTable.teamTables[objTeam].Objectives) do
		if objTable.internalName == objInternalName then
			print("HUD Handler tried to add an objective with an internal name already in use!");
			return false;
		end
	end
	
	table.insert(self.mainTable.teamTables[objTeam].Objectives, objTable);
	
	return self.mainTable.teamTables[objTeam].Objectives[#self.mainTable.teamTables[objTeam].Objectives];
	
end

function HUDHandler:RemoveObjective(objTeam, objInternalName)

	for i, objTable in ipairs(self.mainTable.teamTables[objTeam].Objectives) do
		if objTable.internalName == objInternalName then
			table.remove(self.mainTable.teamTables[objTeam].Objectives, objTable);
			break;
		end
	end
	
end

function HUDHandler:MakeObjectivePrimary(objTeam, objInternalName)

	for i, objTable in ipairs(self.mainTable.teamTables[objTeam].Objectives) do
		if objTable.internalName == objInternalName then
			table.insert(objTable, 1, table.remove(objTable, i));
			break;
		end
	end
	
end

function HUDHandler:UpdateHUDHandler()

	for team = 0, #self.mainTable.teamTables do
		for i, objTable in pairs(self.mainTable.teamTables[team].Objectives) do
			for k, player in pairs(self.mainTable.playersInTeamTables[team]) do
				if i == 1 then
					-- First objective special treatment
					local vec = Vector(self.objListStartXOffset, self.objListStartYOffset);
					local pos = self:MakeRelativeToScreenPos(player, vec)
					PrimitiveMan:DrawTextPrimitive(pos, objTable.longName, false, 0, 0);
					-- Description
					PrimitiveMan:DrawTextPrimitive(pos + Vector(10, self.descriptionSpacing), objTable.Description, true, 0, 0);
				else
					local spacing = (self.objListSpacing*i);
					local vec = Vector(self.objListStartXOffset, self.objListStartYOffset + spacing);
					local pos = self:MakeRelativeToScreenPos(player, vec)
					PrimitiveMan:DrawTextPrimitive(pos, objTable.shortName, false, 0, 0);		
				end
			end
		end
	end

end


return HUDHandler:Create();