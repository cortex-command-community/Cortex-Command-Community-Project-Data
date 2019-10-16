dofile("Base.rte/Constants.lua")
require("AI/NativeHumanAI")

function Create(self)
	self.AI = NativeHumanAI:Create(self)
	self.Frame = math.random(0, self.FrameCount - 1);
end

function UpdateAI(self)
	self.AI:Update(self)
end

function Destroy(self)
	self.AI:Destroy(self)
end
