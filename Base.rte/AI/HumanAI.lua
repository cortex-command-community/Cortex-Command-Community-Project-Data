
dofile("Base.rte/Constants.lua")
require("Actors/AI/NativeHumanAI")  --dofile("Base.rte/Actors/AI/NativeHumanAI.lua")

function Create(self)
	self.AI = NativeHumanAI:Create(self)
end

function UpdateAI(self)
	self.AI:Update(self)
end

function Destroy(self)
	self.AI:Destroy(self)
end
