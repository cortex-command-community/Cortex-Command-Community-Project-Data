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

function BuyDoorHandler:Initialize(activity)
	
	print("buydoorhandlerinited")
	
	self.Activity = activity;
	
	-- find and save buy doors
	
	self.buyDoorTable = {};
	
	for mo in MovableMan.AddedParticles do
		if mo.PresetName == "Reinforcement Door" then
			table.insert(self.buyDoorTable, ToMOSRotating(mo));
		end
	end
	
end

function BuyDoorHandler:ReplaceBuyDoorTable(newTable)

	if newTable then
		self.buyDoorTable = newTable;
		return true;
	end
	
	return false;

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