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
		self.buyDoorTable[specificIndex]:SendMessage("BuyDoor_CustomTableOrder", order);
	else
		self.buyDoorTable[math.random(1, #self.buyDoorTable)]:SendMessage("BuyDoor_CustomTableOrder", order);
	end

end


return BuyDoorHandler:Create();