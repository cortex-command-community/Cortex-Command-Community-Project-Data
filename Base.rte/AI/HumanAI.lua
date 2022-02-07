dofile("Base.rte/Constants.lua")
require("AI/NativeHumanAI")
require("AI/HumanFunctions")

function Create(self)
	self.AI = NativeHumanAI:Create(self);
end
function UpdateAI(self)
	self.AI:Update(self);
end
function Destroy(self)
	self.AI:Destroy(self);
end