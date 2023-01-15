function OnAttach(self, parent)
	if parent then
		if IsLeg(parent) and ToLeg(parent).Foot then
			ToLeg(parent).Foot = CreateAttachable(string.sub(ToLeg(parent).Foot.PresetName, 1, -2) .. "B");
		elseif IsArm(parent) then
			self.origWoundName = ToArm(parent):GetEntryWoundPresetName();
			ToArm(parent):SetEntryWound("Dent Metal Light", "Base.rte");
		end
	end
end
function OnDetach(self, parent)
	if parent then
		if IsLeg(parent) and ToLeg(parent).Foot then
			ToLeg(parent).Foot = CreateAttachable(string.sub(ToLeg(parent).Foot.PresetName, 1, -2) .. "A");
		elseif IsArm(parent) then
			ToArm(parent):SetEntryWound(self.origWoundName, "Base.rte");
		end
	end
end