require("AI/NativeHumanAI");

function Create(self)

	-- AI Overrides
	
	self:SetNumberValue("AIDisableProne", 1);
	
	self:SetNumberValue("AIAimSpeed", 0.04);
	self:SetNumberValue("AIAimSkill", 0.04);
	self:SetNumberValue("AISkill", 100);

	self.AI = NativeHumanAI:Create(self);
	
	local mainWeapon = CreateHDFirearm("MG-85 Manbreaker", "Browncoats.rte");
	mainWeapon:SetNumberValue("Boss Mode", 1);
	self:AddInventoryItem(mainWeapon);
	
	self.quickThrowTimer = Timer();
	self.quickThrowDelay = 15000;
	self.quickThrowExplosive = CreateTDExplosive("Fuel Bomb", "Browncoats.rte");	
	
end

function Update(self)

	if not self:HasObjectInGroup("Bombs") then 
	
		local explosive = self.quickThrowExplosive:Clone();
		explosive.MinThrowVel = 30;
		explosive.MaxThrowVel = 30;
		self:AddInventoryItem(explosive);
				
	end

	if not self:IsPlayerControlled() then -- just in case

		if self.quickThrowTimer:IsPastSimMS(self.quickThrowDelay) then
		
			self.quickThrowTimer:Reset();
			
			if not (self.EquippedItem and self.EquippedItem:IsReloading() or self.EquippedItem:NumberValueExists("Busy")) then

				self.AI:CreateQuickthrowBehavior(self);
				
			end
		end
	end

end

function UpdateAI(self)
	self.AI:Update(self);
end
function Destroy(self)
	self.AI:Destroy(self);
end