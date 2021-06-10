function Update(self)
	if self:DoneReloading() then
		self:SetNextMagazineName("Magazine Ronin RPG-7");
	end
end
function OnPieMenu(self)
	if not (self:GetRootParent():HasObject("Shovel") and (not self.Magazine or self.Magazine.PresetName ~= "Magazine Ronin Shovel Shot")) then
		ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Insert Ammo", "RoninRPGSwitchAmmo");
	end
end