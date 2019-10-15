function GrenadeLauncherImpact(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		local gun = ToHDFirearm(gun);
		local magSwitchName = "Magazine Grenade Launcher Impact Grenade";
		if gun.Magazine == nil or (gun.Magazine ~= nil and gun.Magazine.PresetName ~= magSwitchName) then
			gun:SetNextMagazineName(magSwitchName);
			gun:Reload();
		end
	end
end

function GrenadeLauncherBounce(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		local gun = ToHDFirearm(gun);
		local magSwitchName = "Magazine Grenade Launcher Bounce Grenade";
		if gun.Magazine == nil or (gun.Magazine ~= nil and gun.Magazine.PresetName ~= magSwitchName) then
			gun:SetNextMagazineName(magSwitchName);
			gun:Reload();
		end
	end
end

function GrenadeLauncherRemote(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		local gun = ToHDFirearm(gun);
		local magSwitchName = "Magazine Grenade Launcher Remote Grenade";
		if gun.Magazine == nil or (gun.Magazine ~= nil and gun.Magazine.PresetName ~= magSwitchName) then
			gun:SetNextMagazineName(magSwitchName);
			gun:Reload();
		end
	end
end

function GrenadeLauncherRemoteDetonate(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		ToHDFirearm(gun).Sharpness = 1;
	end
end

function GrenadeLauncherRemoteDelete(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		ToHDFirearm(gun).Sharpness = 2;
	end
end