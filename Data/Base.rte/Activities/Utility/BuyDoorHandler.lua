--------------------------------------- Instructions ---------------------------------------

--

--------------------------------------- Misc. Information ---------------------------------------

--




local BuyDoorHandler = {};

function BuyDoorHandler:Create()
	local Members = {};

	setmetatable(Members, self);
	self.__index = self;

	return Members;
end

function BuyDoorHandler:Initialize(activity, newGame)
	
	print("buydoorhandlerinited")
	
	self.Activity = activity;
	
	if newGame then
	
		-- find and save buy doors
		
		self.buyDoorTable = {};
		
		for mo in MovableMan.AddedActors do
			if mo.PresetName == "Reinforcement Door" then
				table.insert(self.buyDoorTable, ToMOSRotating(mo));
			end
		end
		
	end
	
end

function BuyDoorHandler:OnLoad(saveLoadHandler)
	
	print("loading buydoorhandler...");
	self.buyDoorTable = saveLoadHandler:ReadSavedStringAsTable("buyDoorHandlerBuyDoorTable");
	print("loaded buydoorhandler!");
	
end

function BuyDoorHandler:OnSave(saveLoadHandler)
	
	print("saving buy door")
	saveLoadHandler:SaveTableAsString("buyDoorHandlerBuyDoorTable", self.buyDoorTable);
	
end

function BuyDoorHandler:ReplaceBuyDoorTable(newTable)

	if newTable then
		self.buyDoorTable = newTable;
		return true;
	end
	
	return false;

end

function BuyDoorHandler:IsBusyDoorBusy(specificIndex)

	return self.buyDoorTable[specificIndex]:NumberValueExists("BuyDoor_Unusable");
	
end

function BuyDoorHandler:GetAvailableBuyDoorsInArea(area, team)

	local usableIndexesTable = {};
	for i = 1, #self.buyDoorTable do
		if not self.buyDoorTable[i]:NumberValueExists("BuyDoor_Unusable") and (team and self.buyDoorTable[i].Team == team) or (not team) then
			if area:IsInside(self.buyDoorTable[i].Pos) then
				table.insert(usableIndexesTable, i);
			end
		end
	end
	
	if #usableIndexesTable > 0 then
		return usableIndexesTable;
	else
		return false;
	end
	
end

function BuyDoorHandler:SendCustomOrder(order, team, specificIndex)
	
	if specificIndex then
		--print("specificattempted")
		if not self.buyDoorTable[specificIndex]:NumberValueExists("BuyDoor_Unusable") then
			self.buyDoorTable[specificIndex]:SendMessage("BuyDoor_CustomTableOrder", order);
		else
			--print("Buy Door Handler was asked to send a custom order to a busy specific index!");
			return false;
		end
	else
		-- we trust the buy door to tell us if it can be used or not
		-- it's either busy or has enemies nearby if it can't
		local usableIndexesTable = {};
		for i = 1, #self.buyDoorTable do
			if not self.buyDoorTable[i]:NumberValueExists("BuyDoor_Unusable") and (team and self.buyDoorTable[i].Team == team) or (not team) then
				table.insert(usableIndexesTable, i);
			end
		end
		if #usableIndexesTable > 0 then
			self.buyDoorTable[usableIndexesTable[math.random(1, #usableIndexesTable)]]:SendMessage("BuyDoor_CustomTableOrder", order);
		else
			--print("Buy Door Handler could not find any non-busy Buy Doors to send a custom order to!");
			return false;
		end
	end

	return true;

end


return BuyDoorHandler:Create();