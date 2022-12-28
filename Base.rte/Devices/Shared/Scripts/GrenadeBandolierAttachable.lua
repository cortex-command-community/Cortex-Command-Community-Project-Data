function Create(self)

	self.grenadeName = self:GetStringValue("Grenade Name");
	self.grenadeTech = self:GetStringValue("Grenade Tech");

	if self:NumberValueExists("Thrown Device") then
		self.grenadeObject = CreateThrownDevice(self.grenadeName, self.grenadeTech);
	else
		self.grenadeObject = CreateTDExplosive(self.grenadeName, self.grenadeTech);
	end

	self.grenadeBandolierName = self:GetStringValue("Bandolier Name");

	self.addedGrenade = false;
	self.addGrenadeTimer = Timer();
	self.grenadeReplenishDelay = self:GetNumberValue("Replenish Delay");

	if IsAHuman(self:GetRootParent()) then
		self.rootParent = ToAHuman(self:GetRootParent());
	end

	if self.rootParent then
		self.rootParent:EquipNamedDevice(self.grenadeName, true);

		if self.rootParent:HasObject(self.grenadeBandolierName) then
			self.rootParent:RemoveInventoryItem(self.grenadeBandolierName);
		end

		self.grenadePerBandolier = self:GetNumberValue("Grenade Count");
		self.rootParent:SetNumberValue(self.grenadeBandolierName, self.grenadePerBandolier - 1);
		self.grenadeCount = self.rootParent:GetNumberValue(self.grenadeBandolierName);	--Get ammount of grenades in our Bandolier

		self.BandolierMass = self:GetNumberValue("Bandolier Mass");

		self.explosiveGoldValue = self:GetNumberValue("Grenade Value");
		self.rootParent:SetGoldValue(self.rootParent:GetGoldValue(self.grenadeObject.ModuleID, 1, 1) + (self.explosiveGoldValue * (self.grenadePerBandolier - 1)));

		self.IsPlayer = ActivityMan:GetActivity():IsHumanTeam(self.rootParent.Team)

	end

	-- Icons go here, loaded in Create for efficiency
	self.grenadeAmmoIcon = CreateMOSParticle("Ammo Icon", "Base.rte");
	self.grenadeRefreshIcon = CreateTDExplosive(self.grenadeName, self.grenadeTech);
	-- TODO maybe change sprite or at least sprite colour for refresh plus
	self.grenadeRefreshPlus = CreateMOSParticle("Particle Heal Effect", "Base.rte");

	self.refreshGui = false;
	self.refreshGuiTimer = Timer();
	self.refreshGuiDelay = 1200;
end

function Update(self)
	if not self:IsAttached() then
		self.ToDelete = true;
		return;
	end

	if self.rootParent and self.rootParent.Health > 0 then
		if self.rootParent:HasObject(self.grenadeBandolierName) then
			self.rootParent:RemoveInventoryItem(self.grenadeBandolierName);
			self.rootParent:SetNumberValue(self.grenadeBandolierName, self.grenadeCount+self.grenadePerBandolier);
			self.rootParent:SetGoldValue(self.rootParent:GetGoldValue(self.rootParent.ModuleID, 1, 1) + self.explosiveGoldValue*self.grenadePerBandolier);
		end

		self.grenadeCount = self.rootParent:GetNumberValue(self.grenadeBandolierName);

		self.Mass = self.BandolierMass + self:GetNumberValue("Grenade Mass") * self.grenadeCount;

		if self.grenadeCount <= 0 then
			if self.rootParent:HasObject(self.grenadeName) then
				self.Mass = 0;
			else
				self.ToDelete = true;
			end
		end

		if self.rootParent.HUDVisible and self.rootParent.EquippedItem and self.rootParent.EquippedItem.PresetName == self.grenadeName and self.rootParent:IsPlayerControlled() and not (self.rootParent.Jetpack and self.rootParent.Jetpack:IsEmitting()) then
			local rootParentController = self.rootParent:GetController();
			local distanceBetweenIconAndText = 2 + math.floor(self.grenadeAmmoIcon:GetSpriteWidth() * 0.5);
			local drawPosition = self.rootParent.AboveHUDPos + Vector(-distanceBetweenIconAndText, rootParentController:IsState(Controller.PIE_MENU_ACTIVE) and 16 or 2);

			PrimitiveMan:DrawBitmapPrimitive(rootParentController.Player, drawPosition, self.grenadeAmmoIcon, 3.14, 0, true, true);
			drawPosition = drawPosition + Vector(distanceBetweenIconAndText, -self.grenadeAmmoIcon:GetSpriteHeight() * 0.5);
			PrimitiveMan:DrawTextPrimitive(rootParentController.Player, drawPosition, tostring(self.grenadeCount + 1), true, 0);
		end

		if self.rootParent:HasObject(self.grenadeName) or (self.rootParent.EquippedItem and self.rootParent.EquippedItem.PresetName == self.grenadeName) then
			self.addGrenadeTimer:Reset();
		elseif self.addGrenadeTimer:IsPastSimMS(self.grenadeReplenishDelay) and self.grenadeCount > 0 then
			self.rootParent:AddInventoryItem(self.grenadeObject:Clone());

			if self.grenadeReplenishDelay < 100 then
				self.rootParent:EquipNamedDevice(self.grenadeName, true);
			else
				self.refreshGui = true;
				self.refreshGuiTimer:Reset();
			end

			self.rootParent:SetNumberValue(self.grenadeBandolierName, self.grenadeCount - 1);
			self.rootParent:SetGoldValue(self.rootParent:GetGoldValue(self.rootParent.ModuleID, 1, 1) - self.explosiveGoldValue);

		end

		if self.refreshGui == true then
			if self.IsPlayer == true and self.HUDVisible == true then
				local rootParentController = self.rootParent:GetController();

				local grenadeRefreshIconPos = self.rootParent.AboveHUDPos + Vector(25, 24);
				local grenadeRefreshPlusPos = self.rootParent.AboveHUDPos + Vector(30, 24);

				PrimitiveMan:DrawBitmapPrimitive(rootParentController.Player, grenadeRefreshIconPos, self.grenadeRefreshIcon, 3.14, 0, true, true);
				PrimitiveMan:DrawBitmapPrimitive(rootParentController.Player, grenadeRefreshPlusPos, self.grenadeRefreshPlus, 3.14, 0, true, true);
			end
			if self.refreshGuiTimer:IsPastSimMS(self.refreshGuiDelay) then
				self.refreshGui = false;
			end
		else
			self.refreshGuiTimer:Reset();
		end
	end
end