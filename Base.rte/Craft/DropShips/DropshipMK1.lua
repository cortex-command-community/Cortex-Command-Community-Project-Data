dofile("Base.rte/Constants.lua")
require("AI/NativeDropShipAI")

function Create(self)
	self.AI = NativeDropShipAI:Create(self)
	self.Frame = math.random(0, self.FrameCount - 1);
end

function UpdateAI(self)
	self.AI:Update(self)
end
