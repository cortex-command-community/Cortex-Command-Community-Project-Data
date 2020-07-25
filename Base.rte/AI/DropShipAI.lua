
dofile("Base.rte/Constants.lua")
require("AI/NativeDropShipAI")
--dofile("Base.rte/Actors/AI/NativeDropShipAI.lua")

function Create(self)
	self.AI = NativeDropShipAI:Create(self)
end

function UpdateAI(self)
	self.AI:Update(self)
end

function Update(self)
	--Re-orient the craft at 180 degrees to help rotational AI
	if self.RotAngle > math.pi then
		self.RotAngle = self.RotAngle - (math.pi * 2);
	end
	if self.RotAngle < -math.pi then
		self.RotAngle = self.RotAngle + (math.pi * 2);
	end
end