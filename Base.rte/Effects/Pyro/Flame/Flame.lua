function Create(self)
	--Add flames to a global table that handles their stickyness
	if self.ClassName == "PEmitter" and not string.find(self.PresetName, "Ground") then
		if GlobalFlameManagement.FlameHandler == nil then
			local handler = CreateMOPixel("Global Flame Handler", "Base.rte");
			MovableMan:AddParticle(handler);
			GlobalFlameManagement.FlameHandler = handler;
		end
		local id = #GlobalFlameManagement.Flames + 1;
		GlobalFlameManagement.Flames[id] = {particle = self, id = self.UniqueID};
		if string.find(self.PresetName, "Short") then
			GlobalFlameManagement.Flames[id].deleteDelay = self.Lifetime * RangeRand(0.1, 0.2);
			GlobalFlameManagement.Flames[id].isShort = true;
		end
	end
end