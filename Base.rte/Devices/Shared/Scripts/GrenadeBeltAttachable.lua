function Create(self)

	self.whatGrenade = self:GetStringValue("Grenade Name")		--Get grenade name
	self.whatTech = self:GetStringValue("Grenade Tech")			--Get grenade tech
	
	if self:NumberValueExists("Thrown Device") then
		self.explosive = CreateThrownDevice(self.whatGrenade, self.whatTech)
	else
		self.explosive = CreateTDExplosive(self.whatGrenade, self.whatTech)
	end

	self.whatBelt = self:GetStringValue("What Belt")			--Get grenade belt name

	self.addedGrenade = false;
	self.addGrenadeTimer = Timer();
	self.addGrenadeDelay = self:GetNumberValue("Replenish Rate")	--Get grenade replenish rate

	if IsAHuman(self:GetRootParent()) then
		self.parent = ToAHuman(self:GetRootParent())

	end

	if self.parent then
	
		self.parent:EquipNamedDevice(self.whatGrenade, true)	
	
		if self.parent:HasObject(self.whatBelt) then
			self.parent:RemoveInventoryItem(self.whatBelt)
		end

		self.grenadePerBelt = self:GetNumberValue("Grenade Count")		--Get grenade count per belt
		self.parent:SetNumberValue(self.whatBelt, self.grenadePerBelt-1);
		self.grenadeCount = self.parent:GetNumberValue(self.whatBelt);	--Get ammount of grenades in our belt

		self.beltMass = self:GetNumberValue("Belt Mass")				--Get belt mass

		self.explosiveGoldValue = self:GetNumberValue("Grenade Value")	--Todo: Increase actor oz price depending on ammount of grenades
		self.parent:SetGoldValue(self.parent:GetGoldValue(self.explosive.ModuleID, 1, 1) + (self.explosiveGoldValue*(self.grenadePerBelt-1)))

		self.IsPlayer = ActivityMan:GetActivity():IsHumanTeam(self.parent.Team)
		
	end
	
	-----------------------
	self.refreshGui = false
	self.refreshGuiTimer = Timer();
	self.refreshGuiDelay = 1200

end

function Update(self)

	if not self:IsAttached() then
		self.ToDelete = true
		self.parent = nil;
	end

	if self.parent and self.parent.Health > 0 then
		if self.parent:HasObject(self.whatBelt) then
			self.parent:RemoveInventoryItem(self.whatBelt)
			self.parent:SetNumberValue(self.whatBelt, self.grenadeCount+self.grenadePerBelt)
			self.parent:SetGoldValue(self.parent:GetGoldValue(self.parent.ModuleID, 1, 1) + self.explosiveGoldValue*self.grenadePerBelt)
		end	
		----------------------------------------------------------------------------------------
		self.grenadeCount = self.parent:GetNumberValue(self.whatBelt);

		self.Mass = self.beltMass + self:GetNumberValue("Grenade Mass")*self.grenadeCount;
		
		if self.grenadeCount <= 0 then
			if self.parent:HasObject(self.whatGrenade) then	--This way the next gui is still present at 0
				self.Mass = 0
			else
				self.ToDelete = true
			end
		end
		
		if self.parent.EquippedItem and self.parent.EquippedItem.PresetName == self.whatGrenade then	--This way the next gui is still present at 0
			if self.parent:IsPlayerControlled() == true and not (self.parent.Jetpack and self.parent.Jetpack:IsEmitting()) then	--I'm sorry if this looks weird. Ammo counter + extra pouch
				local ctrl = self.parent:GetController();
				local screen = ActivityMan:GetActivity():ScreenOfPlayer(ctrl.Player);
				local yPos = ctrl:IsState(Controller.PIE_MENU_ACTIVE) and 16 or 7;	-- align ammo counter properly
		
				local digits = 3;
				PrimitiveMan:DrawTextPrimitive(screen, self.parent.AboveHUDPos + Vector(digits, yPos), "/".. self.grenadeCount, true, 0);		
			end
		end
		
		if self.parent:HasObject(self.whatGrenade) or (self.parent.EquippedItem and self.parent.EquippedItem.PresetName == self.whatGrenade) then	
			self.addGrenadeTimer:Reset();	--Don't give more grenades if we already have them
		elseif self.addGrenadeTimer:IsPastSimMS(self.addGrenadeDelay) and self.grenadeCount > 0 then
		
			self.parent:AddInventoryItem(self.explosive:Clone());
			
			if self.addGrenadeDelay < 100 then
				self.parent:EquipNamedDevice(self.whatGrenade, true)
			else
				self.refreshGui = true;
				self.refreshGuiTimer:Reset();			
			end
			
			self.parent:SetNumberValue(self.whatBelt, self.grenadeCount-1)
			self.parent:SetGoldValue(self.parent:GetGoldValue(self.parent.ModuleID, 1, 1) - self.explosiveGoldValue)

	--		AudioMan:PlaySound("UniTec.rte/Sounds/Devices/Grenade One Up.ogg", self.Pos); --Add sound to match the GUI?

		end
		
		if self.refreshGui == true then
			if self.IsPlayer == true and self.HUDVisible == true then
				local ctrl = self.parent:GetController();
				local screen = ActivityMan:GetActivity():ScreenOfPlayer(ctrl.Player);	
							
				local grenadeRefreshIcon = CreateTDExplosive(self.whatGrenade, self.whatTech);
				local grenadeRefreshIconPos = self.parent.AboveHUDPos + Vector(25,24) --self.Pos + Vector(28, -43)
				
				local grenadeRefreshPlus = CreateMOSParticle("Particle Heal Effect", "Base.rte");	--TODO: Change + sprite color or smh
				local grenadeRefreshPlusPos = self.parent.AboveHUDPos + Vector(30,24) --self.Pos + Vector(28, -43)
								
				PrimitiveMan:DrawBitmapPrimitive(screen, grenadeRefreshIconPos, grenadeRefreshIcon, 3.14, 0, true, true);
				PrimitiveMan:DrawBitmapPrimitive(screen, grenadeRefreshPlusPos, grenadeRefreshPlus, 3.14, 0, true, true);
			end
			if self.refreshGuiTimer:IsPastSimMS(self.refreshGuiDelay) then
				self.refreshGui = false;
			end
		else
			self.refreshGuiTimer:Reset();
		end	
	end	
end