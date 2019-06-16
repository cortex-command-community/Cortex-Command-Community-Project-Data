
dofile("Base.rte/Constants.lua")
require("Actors/AI/NativeTurretAI")

function Create(self)
	self.AI = NativeTurretAI:Create(self)
end

function UpdateAI(self)
	self.AI:Update(self)
end
