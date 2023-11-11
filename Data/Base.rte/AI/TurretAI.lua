--[[MULTITHREAD]]--

require("AI/NativeTurretAI");

function Create(self)
	self.AI = NativeTurretAI:Create(self);
end

function UpdateAI(self)
	self.AI:Update(self);
end

function Destroy(self)
	self.AI:Destroy(self);
end
