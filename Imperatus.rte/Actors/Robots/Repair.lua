require("Actors/AI/NativeHumanAI")

function Create(self)
	self.AI = NativeHumanAI:Create(self)
	self.repairTimer = Timer();
end

function Update(self)
	if self.repairTimer:IsPastSimMS(250) then
		self.repairTimer:Reset();
		if self.Health < 100 then
			self.Health = self.Health + 1;
			--print("Heal!");
		end
	end
end

function UpdateAI(self)
	self.AI:Update(self)
end