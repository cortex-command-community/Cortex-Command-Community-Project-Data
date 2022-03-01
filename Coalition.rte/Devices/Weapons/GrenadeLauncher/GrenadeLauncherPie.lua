function GrenadeLauncherImpact(actor)
	ToHDFirearm(ToAHuman(actor).EquippedItem):SetStringValue("GrenadeMode", "Impact");
end

function GrenadeLauncherBounce(actor)
	ToHDFirearm(ToAHuman(actor).EquippedItem):SetStringValue("GrenadeMode", "Bounce");
end

function GrenadeLauncherRemote(actor)
	ToHDFirearm(ToAHuman(actor).EquippedItem):SetStringValue("GrenadeMode", "Remote");
end

function GrenadeLauncherRemoteDetonate(actor)
	ToHDFirearm(ToAHuman(actor).EquippedItem):SetStringValue("GrenadeTrigger", "Detonate");
end

function GrenadeLauncherRemoteDelete(actor)
	ToHDFirearm(ToAHuman(actor).EquippedItem):SetStringValue("GrenadeTrigger", "Delete");
end