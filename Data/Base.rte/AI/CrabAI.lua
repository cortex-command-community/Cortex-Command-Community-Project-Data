--[[MULTITHREAD]]--

require("AI/NativeCrabAI");

function Create(self)
	self.AI = NativeCrabAI:Create(self);
end

function UpdateAI(self)
	self.AI:Update(self);
end

function Destroy(self)
	self.AI:Destroy(self);
end
