dofile("Base.rte/Constants.lua")
require("AI/NativeHumanAI")
require("AI/HumanFunctions")

function Create(self)
	self.AI = NativeHumanAI:Create(self);
	--You can turn features on and off here
	self.armSway = true;
	self.automaticEquip = false;
	self.alternativeGib = true;
	self.visibleInventory = true;
end
function Update(self)
	self.controller = self:GetController();
	
	if self.alternativeGib then
		HumanFunctions.DoAlternativeGib(self);
	end
	if self.automaticEquip then
		HumanFunctions.DoAutomaticEquip(self);
	end
	if self.armSway then
		HumanFunctions.DoArmSway(self, (self.Health/self.MaxHealth));	--Argument: shove strength
	end
	if self.visibleInventory then
		HumanFunctions.DoVisibleInventory(self, false);	--Argument: whether to show all items
	end
end
function UpdateAI(self)
	self.AI:Update(self);
end
function Destroy(self)
	self.AI:Destroy(self);
end