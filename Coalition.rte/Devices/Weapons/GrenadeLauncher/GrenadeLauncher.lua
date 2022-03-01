function OnPieMenu(item)
	if item and IsHDFirearm(item) and item.PresetName == "Grenade Launcher" then
		item = ToHDFirearm(item);
		local mode = item:GetStringValue("GrenadeMode");
		--Remove corresponding pie slices if mode is already active
		if mode == "Impact" then
			ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Impact Mode", "GrenadeLauncherImpact");
		elseif mode == "Bounce" then
			ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Bounce Mode", "GrenadeLauncherBounce");
		elseif mode == "Remote" then
			ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Remote Mode", "GrenadeLauncherRemote");
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
	if self.FiredFrame then
		if self.Magazine then
			self.Magazine.Frame = (self.Magazine.Frame + 1) % self.Magazine.FrameCount;	--To-do: add animation frames for the Magazine
		end
		local mode = self:GetStringValue("GrenadeMode");
		local bullet = CreateActor("Coalition Grenade Launcher Shot", "Coalition.rte");
		bullet.Pos = self.MuzzlePos;
		bullet.Vel = self.Vel + Vector(35 * self.FlipFactor, 0):RadRotate(self.RotAngle):DegRotate(self.ShakeRange * 0.5 - (self.ShakeRange * math.random()));
		
		local actor = self:GetRootParent();
		if MovableMan:IsActor(actor) then
			actor = ToActor(actor);
			if actor:GetController():IsState(Controller.AIM_SHARP) then
				bullet.Vel = self.Vel + Vector(35 * self.FlipFactor, 0):RadRotate(self.RotAngle):DegRotate(self.SharpShakeRange * 0.5 - (self.SharpShakeRange * math.random()));
			end
			if mode == "Remote" then
				if actor:IsPlayerControlled() then
					if self.grenadeTableA[self.maxActiveGrenades] then
						self.grenadeTableA[self.maxActiveGrenades]:SetStringValue("GrenadeMode", "Delete");
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
					self:SetNumberValue("CoalitionRemoteGrenades", #self.grenadeTableA);
				else
					mode = "Timed";
				end
			end
		end
		bullet.Team = actor.Team;
		bullet.IgnoresTeamHits = true;
		bullet:SetStringValue("GrenadeMode", mode);
		MovableMan:AddParticle(bullet);
	end
	if self:StringValueExists("GrenadeTrigger") then
		local trigger = self:GetStringValue("GrenadeTrigger");
		for i = 1, #self.grenadeTableA do
			if MovableMan:IsParticle(self.grenadeTableA[i]) then
				self.grenadeTableA[i]:SetStringValue("GrenadeMode", trigger);
			end
		end
		self.grenadeTableA = {};
		self:RemoveNumberValue("CoalitionRemoteGrenades");
		self:RemoveStringValue("GrenadeTrigger");
	end
end

function Destroy(self)
	for i = 1, #self.grenadeTableA do
		if MovableMan:IsParticle(self.grenadeTableA[i]) then
			self.grenadeTableA[i]:SetStringValue("GrenadeMode", "Delete");
		end
	end
end