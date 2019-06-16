
dofile("Base.rte/Constants.lua")
require("Actors/AI/NativeHumanAI")

function Create(self)
	self.AI = NativeHumanAI:Create(self)
end

function UpdateAI(self)
	self.AI:Update(self)
end
