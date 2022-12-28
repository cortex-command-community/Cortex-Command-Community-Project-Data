function Create(self)
	self.parent = nil;
	self.addedBandolier = false;
	self.BandolierName = self.PresetName;
	self.grenadeName = self:StringValueExists("Grenade Name") and self:GetStringValue("Grenade Name") or "Frag Grenade";
	self.grenadeTech = self:StringValueExists("Grenade Tech") and self:GetStringValue("Grenade Tech") or "Base.rte";

	self.isThrownDevice = self:NumberValueExists("Thrown Device");
	if  self.isThrownDevice then
		self.grenadeObject = CreateThrownDevice(self.grenadeName, self.grenadeTech);
	else
		self.grenadeObject = CreateTDExplosive(self.grenadeName, self.grenadeTech);
	end

	self.grenadeCount = self:NumberValueExists("Grenade Count") and self:GetNumberValue("Grenade Count") or 3;
	self.replenishDelay = self:NumberValueExists("Replenish Delay") and self:GetNumberValue("Replenish Delay") or 0;
	self.BandolierMass = self:NumberValueExists("Bandolier Mass") and self:GetNumberValue("Bandolier Mass") or 1.5;
	self.grenadeMass = self:NumberValueExists("Grenade Mass") and self:GetNumberValue("Grenade Mass") or  self.grenadeObject.Mass;

	self.grenadeObjectGoldValue = self.grenadeObject:GetGoldValue(self.grenadeObject.ModuleID, 1, 1);

	self.attachable = CreateAttachable("Grenade Bandolier", "Base.rte");
	self.attachable:SetStringValue("Bandolier Name", self.PresetName);
	self.attachable:SetNumberValue("Replenish Delay", self.replenishDelay);
	self.attachable:SetStringValue("Grenade Name", self.grenadeName);
	self.attachable:SetStringValue("Grenade Tech", self.grenadeTech);
	self.attachable:SetNumberValue("Bandolier Mass", self.BandolierMass);
	self.attachable:SetNumberValue("Grenade Mass", self.grenadeMass);
	self.attachable:SetNumberValue("Grenade Count", self.grenadeCount);
	self.attachable:SetNumberValue("Grenade Value", self.grenadeObjectGoldValue);
	if self.isThrownDevice then
		self.attachable:SetNumberValue("Thrown Device", 1);
	end

end

function Update(self)		--For some reason onAttach causes issues
	local rootParent = self:GetRootParent();
	if MovableMan:IsActor(rootParent) then
		self.rootParent = ToActor(rootParent);
	end

	if self.rootParent and self:IsAttached() then
		if self.addedBandolier == false and (not self.rootParent:NumberValueExists(self.PresetName) or (self.rootParent:NumberValueExists(self.PresetName) and self.rootParent:GetNumberValue(self.PresetName) <= 0)) then
			self.rootParent:AddInventoryItem(self.grenadeObject);
			self.rootParent:AddAttachable(self.attachable, Vector(0,0));
			self.addedBandolier = true;
		end
	end
end