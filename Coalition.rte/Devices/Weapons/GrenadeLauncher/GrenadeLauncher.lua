function OnPieMenu(item)
	if item and IsHDFirearm(item) and item.PresetName == "Grenade Launcher" then
		item = ToHDFirearm(item);
		if item.Magazine then
			--Remove corresponding pie slices if mode is already active
			if item.Magazine.PresetName == "Magazine Grenade Launcher Impact Grenade" then
				ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Impact Mode", "GrenadeLauncherImpact");
			elseif item.Magazine.PresetName == "Magazine Grenade Launcher Bounce Grenade" then
				ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Bounce Mode", "GrenadeLauncherBounce");
			elseif item.Magazine.PresetName == "Magazine Grenade Launcher Remote Grenade" then
				ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Remote Mode", "GrenadeLauncherRemote");
			end
		end
		if item:GetNumberValue("CoalitionRemoteGrenades") == 0 then
			ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Detonate Grenades", "GrenadeLauncherRemoteDetonate");
			ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Remove Grenades", "GrenadeLauncherRemoteDelete");
		end
	end
end

function Create(self)
	self.grenadeTableA = {};
	self.grenadeTableB = {};
	self.maxActiveGrenades = 12;
end

function Update(self)
	if self.FiredFrame and self.Magazine then
		self.Magazine.Frame = (self.Magazine.Frame + 1) % self.Magazine.FrameCount;	--To-do: add animation frames for the Magazine
		if self.Magazine.PresetName == "Magazine Grenade Launcher Remote Grenade" then				
			local bullet = CreateActor("Grenade Launcher Shot Remote");
			bullet.Pos = self.MuzzlePos;
			bullet.Vel = self.Vel + Vector(35 * self.FlipFactor, 0):RadRotate(self.RotAngle):DegRotate(self.ShakeRange * 0.5 - (self.ShakeRange * math.random()));
			local actor = MovableMan:GetMOFromID(self.RootID);
			if MovableMan:IsActor(actor) then
				if ToActor(actor):GetController():IsState(Controller.AIM_SHARP) then
					bullet.Vel = self.Vel + Vector(35 * self.FlipFactor, 0):RadRotate(self.RotAngle):DegRotate(self.SharpShakeRange * 0.5 - (self.SharpShakeRange * math.random()));
				end
				if ToActor(actor):IsPlayerControlled() then
					if self.grenadeTableA[self.maxActiveGrenades] then
						self.grenadeTableA[self.maxActiveGrenades].Sharpness = 2;
					end
					for i = 1, self.maxActiveGrenades do
						self.grenadeTableB[i + 1] = self.grenadeTableA[i];
					end
					self.grenadeTableA = {};
					for i = 1, self.maxActiveGrenades do
						self.grenadeTableA[i] = self.grenadeTableB[i];
					end
					self.grenadeTableB = {};
					self.grenadeTableA[1] = bullet;
					bullet.Sharpness = 0;
					self:SetNumberValue("CoalitionRemoteGrenades", #self.grenadeTableA);
				else
					bullet.Sharpness = 3;
				end
				bullet.Team = ToActor(actor).Team;
				bullet.IgnoresTeamHits = true;
			end
			MovableMan:AddParticle(bullet);
		end
	end
	if self.Sharpness == 1 then
		self.Sharpness = 0;
		for i = 1, #self.grenadeTableA do
			if MovableMan:IsParticle(self.grenadeTableA[i]) then
				self.grenadeTableA[i].Sharpness = 2;
			end
		end
		self.grenadeTableA = {};
		self:RemoveNumberValue("CoalitionRemoteGrenades");
	elseif self.Sharpness == 2 then
		self.Sharpness = 0;
		for i = 1, #self.grenadeTableA do
			if MovableMan:IsParticle(self.grenadeTableA[i]) then
				self.grenadeTableA[i].Sharpness = 1;
			end
		end
		self.grenadeTableA = {};
		self:RemoveNumberValue("CoalitionRemoteGrenades");
	end
end

function Destroy(self)
	for i = 1, #self.grenadeTableA do
		if MovableMan:IsParticle(self.grenadeTableA[i]) then
			self.grenadeTableA[i].Sharpness = 1;
		end
	end
end