function ConstructorModeCancel(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		gun.Sharpness = 1;
	end
end

function ConstructorModeBuild(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		gun.Sharpness = 2;
	end
end

function ConstructorDigMode(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		gun = ToMOSRotating(gun);
		gun:SetNumberValue("Constructor Mode", 0);
	end
end

function ConstructorSprayMode(actor)
	local gun = ToAHuman(actor).EquippedItem;
	if gun ~= nil then
		gun = ToMOSRotating(gun);
		gun:SetNumberValue("Constructor Mode", 1);
	end
end