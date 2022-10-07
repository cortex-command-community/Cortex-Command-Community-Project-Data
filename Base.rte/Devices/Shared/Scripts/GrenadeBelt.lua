function Create(self)

	self.parent = nil;
	self.addedBelt = false
	self.beltName = self.PresetName
	self.whatGrenade = self:StringValueExists("Grenade Name") and self:GetStringValue("Grenade Name") or "Frag Grenade"
	self.whatTech = self:StringValueExists("Grenade Tech") and self:GetStringValue("Grenade Tech") or "Base.rte"
	
	self.isThrownDevice = self:NumberValueExists("Thrown Device");
	if  self.isThrownDevice then
		self.explosive = CreateThrownDevice(self.whatGrenade, self.whatTech)
	else
		self.explosive = CreateTDExplosive(self.whatGrenade, self.whatTech)
	end
	
	self.grenadeCount = self:NumberValueExists("Grenade Count") and self:GetNumberValue("Grenade Count") or 3
	self.replenishRate = self:NumberValueExists("Replenish Rate") and self:GetNumberValue("Replenish Rate") or 0
	self.beltMass = self:NumberValueExists("Belt Mass") and self:GetNumberValue("Belt Mass") or 1.5
	self.grenadeMass = self:NumberValueExists("Grenade Mass") and self:GetNumberValue("Grenade Mass") or  self.explosive.Mass

	self.explosiveGoldValue = self.explosive:GetGoldValue(self.explosive.ModuleID,1,1)
		
	self.attachable = CreateAttachable("Grenade Belt", "Base.rte")
	self.attachable:SetStringValue("What Belt", self.PresetName)					--New, initial belt gets the name of grenade belts to search for and merge
	self.attachable:SetNumberValue("Replenish Rate", self.replenishRate)			--Delay between each grenade
	self.attachable:SetStringValue("Grenade Name", self.whatGrenade)				--Name of the grenade to spawn
	self.attachable:SetStringValue("Grenade Tech", self.whatTech)				--From what tech to spawn, to avoid name dupe mistmatch
	self.attachable:SetNumberValue("Belt Mass", self.beltMass)				--Mass of the belt as is
	self.attachable:SetNumberValue("Grenade Mass", self.grenadeMass)			--Mass of each grenade
	self.attachable:SetNumberValue("Grenade Count", self.grenadeCount)			--Ammount of grenades per belt
	self.attachable:SetNumberValue("Grenade Value", self.explosiveGoldValue)
	if self.isThrownDevice then
		self.attachable:SetNumberValue("Thrown Device", 1)
	end
	
end

function Update(self)		--For some reason onAttach causes issues

	local actor = self:GetRootParent()
	
	if MovableMan:IsActor(actor) then
		self.parent = ToActor(actor);
	end
	
	if self.parent and self:IsAttached() then
		if self.addedBelt == false and (not self.parent:NumberValueExists(self.PresetName) or (self.parent:NumberValueExists(self.PresetName) and self.parent:GetNumberValue(self.PresetName) <= 0)) then

			--Add the first grenade--
			
			self.parent:AddInventoryItem(self.explosive);			

			--Add the belt (after the grenade so the belt script can switch to it)
			self.parent:AddAttachable(self.attachable, Vector(0,0));

			self.addedBelt = true;	
		end
	end
end