function Create(self)
	self.updateTimer = Timer();
	if not self:NumberValueExists("Identity") then
		self.face = math.random(0, (self.Head.FrameCount * 0.5) - 1);
		if self.Head then
			self.Head.Frame = self.face;
		end
		self:SetNumberValue("Identity", self.face);
		self:SetGoldValue(self:GetGoldValue(0, 1, 1) * 0.4);
	else
		self.face = self:GetNumberValue("Identity");
		if self.Head then
			self.Head.Frame = self.face;
		end
	end
	--Equip loadout actors with random weapons
	if not self:NumberValueExists("Equipped") then
		if string.find(self.PresetName, "Ronin") then
			local loadoutName = string.gsub(self.PresetName, "Ronin ", "");
			if RoninLoadouts[loadoutName] then
				local unit = RoninLoadouts[loadoutName];
				--Pick a random item out of each set of items
				local firearms = {unit["Primary"], unit["Secondary"], unit["Tertiary"]};
				for class = 1, #firearms do
					if firearms[class] then
						local firearm = CreateHDFirearm(firearms[class][math.random(#firearms[class])], "Ronin.rte");
						firearm:SetGoldValue(firearm:GetGoldValue(0, 1, 1) * 0.6);
						self:AddInventoryItem(firearm);
					end
				end
				if unit["Throwable"] then
					self:AddInventoryItem(CreateTDExplosive(unit["Throwable"][math.random(#unit["Throwable"])], "Ronin.rte"));
				end
				if unit["Headgear"] and self.Head then
					self.Head:AddAttachable(CreateAttachable("Ronin ".. unit["Headgear"][math.random(#unit["Headgear"])]));
				end
			end
		elseif math.random() < 0.01 then
			local headgear = CreateAttachable("Ronin Crab Helmet", "Ronin.rte");
			if headgear and self.Head then
				self.Head:AddAttachable(headgear);
			end
		elseif self.PresetName == "Raider" then
			local headgear = CreateAttachable("Ronin ".. RoninLoadouts["Machinegunner"]["Headgear"][math.random(#RoninLoadouts["Machinegunner"]["Headgear"])]);
			if headgear and self.Head then
				self.Head:AddAttachable(headgear);
			end
		elseif self.Head then
			if self.face == 1 then	--"Mia"
				self.DeathSound.Pitch = 1.2;
				self.PainSound.Pitch = 1.2;
				self.Head:AddAttachable(CreateAttachable("Ronin Black Hair"));
			elseif self.face == 4 then	--"Sandra"
				self.DeathSound.Pitch = 1.2;
				self.PainSound.Pitch = 1.2;
				self.Head:AddAttachable(CreateAttachable("Ronin Blonde Hair"));
			end
		end
		self:SetNumberValue("Equipped", 1);
	end
end
function Update(self)
	local damaged = self.Health < self.PrevHealth - 1;
	if self.updateTimer:IsPastSimMS(1000) or damaged then
		self.updateTimer:Reset();
		self.aggressive = self.Health < (self.MaxHealth * 0.5);
		if self.Head then
			if self.aggressive or damaged or (self.controller and self.controller:IsState(Controller.WEAPON_FIRE)) then
				self.Head.Frame = self.face + (self.Head.FrameCount * 0.5);
			else
				self.Head.Frame = self.face;
			end
		end
	end
end