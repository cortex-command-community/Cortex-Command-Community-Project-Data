
dofile("Base.rte/Constants.lua")
require("Actors/AI/NativeCrabAI")

function Create(self)
	self.AI = NativeCrabAI:Create(self)
end

function UpdateAI(self)
	self.AI:Update(self)
end
