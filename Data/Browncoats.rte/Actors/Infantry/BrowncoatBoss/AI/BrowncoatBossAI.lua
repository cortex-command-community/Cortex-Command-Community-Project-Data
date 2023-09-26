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
	
	self.abilityShockwaveWhooshSound = CreateSoundContainer("Browncoat Boss Ability Shockwave Whoosh", "Browncoats.rte");	
	self.abilityShockwaveLandSound = CreateSoundContainer("Browncoat Boss Ability Shockwave Land", "Browncoats.rte");	
	
	self.abilityShockwaveTimer = Timer();
	self.abilityShockwaveJumpPackDelay = 300;
	
	self.abilityShockwaveScreenShakeAmount = 30;
	self.abilityShockwaveRange = 1500;
	self.abilityShockwaveStrength = 700;
	
	self.quickThrowTimer = Timer();
	self.quickThrowDelay = 15000;
	self.quickThrowExplosive = CreateTDExplosive("Fuel Bomb", "Browncoats.rte");	
	
end

function Update(self)

	self.abilityShockwaveWhooshSound.Pos = self.Pos;

	if not self:IsDead() then

		if not self:HasObjectInGroup("Bombs") then 
		
			local explosive = self.quickThrowExplosive:Clone();
			explosive.MinThrowVel = 30;
			explosive.MaxThrowVel = 30;
			self:AddInventoryItem(explosive);
					
		end
		
	end

	if not self:IsPlayerControlled() then -- just in case

		if self.quickThrowTimer:IsPastSimMS(self.quickThrowDelay) then
		
			self.quickThrowTimer:Reset();
			
			if not (self.EquippedItem and self.EquippedItem:IsReloading() or self.EquippedItem:NumberValueExists("Busy")) then

				self.AI:CreateQuickthrowBehavior(self);
				
			end
		end
	end
	
	-- DEBUG SHOCKWAVE ABILITY
	
	local debugTrigger = UInputMan:KeyPressed(Key.O);
	
	if debugTrigger then
		self.abilityShockwaveTrigger = true;
	end
	
	if self.abilityShockwaveOngoing then
		if self.abilityShockwaveTimer:IsPastSimMS(self.abilityShockwaveJumpPackDelay) then
		
			self.Jetpack.NegativeThrottleMultiplier = self.jumpPackDefaultNegativeMult * 1.3;
			self.Jetpack.PositiveThrottleMultiplier = self.jumpPackDefaultPositiveMult * 1.3;
			
			self.controller:SetState(Controller.BODY_JUMPSTART, true)
			self.controller:SetState(Controller.BODY_JUMP, true)
			if not self.abilityShockwaveWhooshSound:IsBeingPlayed() then
				self.abilityShockwaveWhooshSound:Play(self.Pos);
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