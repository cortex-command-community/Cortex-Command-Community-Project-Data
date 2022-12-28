function Create(self)
	self.parent = nil;
	self.addedBandolier = false;
	self.BandolierName = self.PresetName;
	self.grenadeName = self:StringValueExists("GrenadeName") and self:GetStringValue("GrenadeName") or "Frag Grenade";
	self.grenadeTech = self:StringValueExists("GrenadeTech") and self:GetStringValue("GrenadeTech") or "Base.rte";

	self.isThrownDevice = self:NumberValueExists("ThrownDevice");
	if  self.isThrownDevice then
		self.grenadeObject = CreateThrownDevice(self.grenadeName, self.grenadeTech);
	else
		self.grenadeObject = CreateTDExplosive(self.grenadeName, self.grenadeTech);
	end

	self.grenadeCount = self:NumberValueExists("GrenadeCount") and self:GetNumberValue("GrenadeCount") or 3;
	self.replenishDelay = self:NumberValueExists("ReplenishDelay") and self:GetNumberValue("ReplenishDelay") or 0;
	self.BandolierMass = self:NumberValueExists("BandolierMass") and self:GetNumberValue("BandolierMass") or 1.5;
	self.grenadeMass = self:NumberValueExists("GrenadeMass") and self:GetNumberValue("GrenadeMass") or  self.grenadeObject.Mass;

	self.grenadeObjectGoldValue = self.grenadeObject:GetGoldValue(self.grenadeObject.ModuleID, 1, 1);

	self.attachable = CreateAttachable("Grenade Bandolier", "Base.rte");
	self.attachable:SetStringValue("BandolierName", self.PresetName);
	self.attachable:SetNumberValue("ReplenishDelay", self.replenishDelay);
	self.attachable:SetStringValue("GrenadeName", self.grenadeName);
	self.attachable:SetStringValue("GrenadeTech", self.grenadeTech);
	self.attachable:SetNumberValue("BandolierMass", self.BandolierMass);
	self.attachable:SetNumberValue("GrenadeMass", self.grenadeMass);
	self.attachable:SetNumberValue("GrenadeCount", self.grenadeCount);
	self.attachable:SetNumberValue("GrenadeValue", self.grenadeObjectGoldValue);
	if self.isThrownDevice then
		self.attachable:SetNumberValue("ThrownDevice", 1);
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