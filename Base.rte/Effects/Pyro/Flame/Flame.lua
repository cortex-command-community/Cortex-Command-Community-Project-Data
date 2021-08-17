function Create(self)
	--Add flames to a global table that handles their stickyness
	if self.ClassName == "PEmitter" and not string.find(self.PresetName, "Ground") then
		Flames = Flames or {};
		local id = #Flames + 1;
		Flames[id] = {particle = self, id = self.UniqueID};
		if string.find(self.PresetName, "Short") then
			Flames[id].deleteDelay = self.Lifetime * RangeRand(0.1, 0.2);
			Flames[id].isShort = true;
		end
		if GlobalFlameHandler == nil then
			GlobalFlameHandler = CreateMOPixel("Global Flame Handler", "Base.rte");
			MovableMan:AddParticle(GlobalFlameHandler);
		end
	end
end