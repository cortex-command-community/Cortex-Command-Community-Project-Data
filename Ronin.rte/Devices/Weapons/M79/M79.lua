function OnAttach(self, newParent)
	local rootParent = self:GetRootParent();
	if IsActor(rootParent) and MovableMan:IsActor(rootParent) then
		local magazinePresetName = self.Magazine and self.Magazine.PresetName or self:GetNextMagazineName();
		local pieSliceToAddPresetName = magazinePresetName == "Magazine Ronin M79 Grenade Launcher Bounce" and "M79 Turn Off Failsafe" or "M79 Turn On Failsafe";
		ToActor(rootParent).PieMenu:AddPieSliceIfPresetNameIsUnique(CreatePieSlice(pieSliceToAddPresetName, self.ModuleName), self);
	end
end