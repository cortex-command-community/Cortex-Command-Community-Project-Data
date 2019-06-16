
dofile("Base.rte/Constants.lua")
require("Actors/AI/NativeDropShipAI")
--dofile("Base.rte/Actors/AI/NativeDropShipAI.lua")

function Create(self)
	self.AI = NativeDropShipAI:Create(self)
end

function UpdateAI(self)
	self.AI:Update(self)
end
