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
		print(mo)
		if mo.PresetName == "Reinforcement Door" then
			table.insert(self.buyDoorTable, ToMOSRotating(mo));
			print("yes")
		end
	end
	
end

function BuyDoorHandler:SendCustomOrder(order, specificIndex)
	
	if specificIndex then
		if not self.buyDoorTable[specificIndex]:NumberValueExists("BuyDoor_Busy") then
			self.buyDoorTable[specificIndex]:SendMessage("BuyDoor_CustomTableOrder", order);
		else
			print("Buy Door Handler was asked to send a custom order to a busy specific index!");
			return false;
		end
	else
		local nonBusyIndexesTable = {};
		for i = 1, #self.buyDoorTable do
			if not self.buyDoorTable[i]:NumberValueExists("BuyDoor_Busy") then
				table.insert(nonBusyIndexesTable, i);
			end
		end
		if #nonBusyIndexesTable > 0 then
			self.buyDoorTable[nonBusyIndexesTable[math.random(1, #nonBusyIndexesTable)]]:SendMessage("BuyDoor_CustomTableOrder", order);
		else
			print("Buy Door Handler could not find any non-busy Buy Doors to send a custom order to!");
			return false;
		end
	end

end


return BuyDoorHandler:Create();