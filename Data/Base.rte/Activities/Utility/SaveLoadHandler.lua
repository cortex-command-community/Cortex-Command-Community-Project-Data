local SaveLoadHandler = {}

-- From Bebomonky's Last Cortex mod, from MyNameIsTrez

function SaveLoadHandler:Create()
	local Members = {};

	setmetatable(Members, self);
	self.__index = self;

	return Members;
end

function SaveLoadHandler:Initialize()
	
	print("SaveLoadHandlerinited")
	
	-- congrats, we did nothing
	
end

function SaveLoadHandler:SerializeTable(val, name, skipnewlines, depth)
	skipnewlines = skipnewlines or false
	depth = depth or 0

	local tmp = string.rep(" ", depth)

	if name then
		tmp = tmp .. name .. " = "
	end

	if type(val) == "table" then
		tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

		for k, v in pairs(val) do
			tmp = tmp
				.. SaveLoadHandler:SerializeTable(v, k, skipnewlines, depth + 1)
				.. ","
				.. (not skipnewlines and "\n" or "")
		end

		tmp = tmp .. string.rep(" ", depth) .. "}"
	elseif type(val) == "number" then
		tmp = tmp .. tostring(val)
	elseif type(val) == "string" then
		tmp = tmp .. string.format("%q", val)
	elseif type(val) == "boolean" then
		tmp = tmp .. (val and "true" or "false")
	elseif IsMOSRotating(val) then
		val:SetNumberValue("saveLoadHandlerUniqueID", val.UniqueID);
		tmp = tmp .. ("SAVELOADHANDLERUNIQUEID_" .. tostring(val.UniqueID))
	else
		tmp = tmp .. '"[inserializeable datatype:' .. type(val) .. ']"'
	end

	return tmp
end

function SaveLoadHandler:ReadSavedStringAsTable(name)
	local savedString = ActivityMan:GetActivity():LoadString(name)
	local tab = loadstring("return " .. savedString)()
	-- Parse for saved MOSRotatings
	-- Very mildly inefficient in terms of looping even after resolving a value, but it happens once on startup
	local didNotFindAnMO = false;
	for k, v in pairs(tab) do
		if string.find(v, "SAVELOADHANDLERUNIQUEID_") then
			local id = string.sub(v, 26, -1);
			for particle in MovableMan.AddedParticles do
				if particle:GetNumberValue("saveLoadHandlerUniqueID") == id then
					particle:RemoveNumberValue("saveLoadHandlerUniqueID");
					v = particle;
					break;
				end
			end
			for act in MovableMan.AddedActors do
				if act:GetNumberValue("saveLoadHandlerUniqueID") == id then
					act:RemoveNumberValue("saveLoadHandlerUniqueID");
					v = act;
					break;
				end
				for item in act.Inventory do
					if item:GetNumberValue("saveLoadHandlerUniqueID") == id then
						item:RemoveNumberValue("saveLoadHandlerUniqueID");
						v = item;
						break;
					end
				end
			end
			for item in MovableMan.AddedItems do
				if item:GetNumberValue("saveLoadHandlerUniqueID") == id then
					item:RemoveNumberValue("saveLoadHandlerUniqueID");
					v = item;
					break;
				end
			end
			-- if we got here, we couldn't resolve it.
			didNotFindAnMO = true;
		end
	end
	
	if didNotFindAnMO then
		print("WARNING: SaveLoadHandler could not resolve a saved MO UniqueID! A loaded table is likely broken.");
	end
	
	return tab;

end

function SaveLoadHandler:SaveTableAsString(name, tab)
	local tabStr = SaveLoadHandler:SerializeTable(tab)
	ActivityMan:GetActivity():SaveString(name, tabStr)
end

function SaveLoadHandler:SaveMOLocally(self, name, mo)
	mo:SetNumberValue("saveLoadHandlerUniqueID", val.UniqueID);
	self:SetStringValue(name, "SAVELOADHANDLERUNIQUEID_" .. tostring(val.UniqueID));
end

function SaveLoadHandler:LoadLocallySavedMO(self, name)
	local v = self:GetStringValue(name);
	local didNotFindAnMO = false;
	
	local notFound = true;
	
	local id = string.sub(v, 26, -1);
	for particle in MovableMan.AddedParticles do
		if particle:GetNumberValue("saveLoadHandlerUniqueID") == id then
			particle:RemoveNumberValue("saveLoadHandlerUniqueID");
			v = particle;
			notFound = false;
			break;
		end
	end
	for act in MovableMan.AddedActors do
		if act:GetNumberValue("saveLoadHandlerUniqueID") == id then
			act:RemoveNumberValue("saveLoadHandlerUniqueID");
			v = act;
			notFound = false;
			break;
		end
		for item in act.Inventory do
			if item:GetNumberValue("saveLoadHandlerUniqueID") == id then
				item:RemoveNumberValue("saveLoadHandlerUniqueID");
				v = item;
				notFound = false;
				break;
			end
		end
	end
	for item in MovableMan.AddedItems do
		if item:GetNumberValue("saveLoadHandlerUniqueID") == id then
			item:RemoveNumberValue("saveLoadHandlerUniqueID");
			v = item;
			notFound = false;
			break;
		end
	end
	
	if notFound then
		print("WARNING: SaveLoadHandler could not resolve a locally saved MO!");
		return false;
	end
	
	return v;

end

return SaveLoadHandler:Create();