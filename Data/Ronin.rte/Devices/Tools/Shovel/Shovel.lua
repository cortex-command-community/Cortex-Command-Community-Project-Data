function Create(self)
	self.origStanceOffset = Vector(0, 8);
	self.origSharpStanceOffset = Vector(4, 6);
	self.minimumRoF = self.RateOfFire * 0.5;
	self.angleOffset = 0;

	self.suitableMaterials = {"Sand", "Topsoil", "Earth", "Dense Earth", "Dense Red Earth", "Red Earth", "Lunar Earth", "Dense Lunar Earth", "Earth Rubble", "Sandbag", "Scrap Metal", "Flesh Scraps"};
	self.collectSound = CreateSoundContainer("Device Switch", "Base.rte");
	self.hitSound = CreateSoundContainer("Ronin Shovel Hit", "Ronin.rte");
	--How much the shovel tilts when firing
	self.angleSize = 1.0;

	self.lastVel = Vector(50 * self.FlipFactor, 0):RadRotate(self.RotAngle);
	self.lastMuzzlePos = Vector(self.MuzzlePos.X, self.MuzzlePos.Y);
end
function Update(self)
	self.StanceOffset = Vector(self.origStanceOffset.X + self.InheritedRotAngleOffset * 5, self.origStanceOffset.Y):RadRotate(self.angleSize * 0.5 * self.InheritedRotAngleOffset * 0.8);
	self.SharpStanceOffset = Vector(self.origSharpStanceOffset.X + self.InheritedRotAngleOffset * 5, self.origSharpStanceOffset.Y):RadRotate(self.angleSize * 0.5 * self.InheritedRotAngleOffset * 0.8);
	
	local parent = self:GetRootParent();
	if parent and IsActor(parent) then
		parent = ToActor(parent);
		local controller = parent:GetController();
		local resource = parent:GetNumberValue("RoninShovelResource");
		if parent:IsPlayerControlled() and controller:IsState(Controller.AIM_SHARP) and (not controller:IsMouseControlled() or controller.AnalogAim.Magnitude > 0.9) then
			self.InheritedRotAngleOffset = math.min(self.InheritedRotAngleOffset + (0.0003 * self.RateOfFire), self.angleSize * 2);
		else
			self.InheritedRotAngleOffset = math.max(self.InheritedRotAngleOffset - (0.0003 * self.RateOfFire), 0);
		end
		self.SupportOffset = Vector(-self.InheritedRotAngleOffset * 5, 2);
		if self.FiredFrame then
			local offsetMultiplier = math.max(self.InheritedRotAngleOffset, 1);
			local particleCount = 5/offsetMultiplier;
			local overhead = self.InheritedRotAngleOffset > self.angleSize * 0.5;
			local fireVec = Vector((50 + 10 * offsetMultiplier) * self.FlipFactor, 0):RadRotate(self.RotAngle + 0.2 * self.FlipFactor);
			for i = 1, particleCount do
				--Lua-generated particles that can chip stone
				local dig = CreateMOPixel("Particle Ronin Shovel 2", "Ronin.rte");
				dig.Pos = self.Pos;
				dig.Vel = Vector(math.random(50, 60) * self.FlipFactor, 0):RadRotate(self.RotAngle + (-0.4 + i * 0.2) * self.FlipFactor);
				MovableMan:AddParticle(dig);
			end
			local trace = (fireVec * rte.PxTravelledPerFrame):RadRotate(-self.InheritedRotAngleOffset * 1.4 * self.FlipFactor);
			--Play a radical sound if a MO is met
			local moCheck = SceneMan:CastMORay(self.Pos, trace, self.ID, self.Team, 0, false, 1);
			if moCheck ~= rte.NoMOID then
				self.hitSound:Play(self.MuzzlePos);
				local spread = 0.4/offsetMultiplier;
				particleCount = 3 * offsetMultiplier;
				for i = 1, particleCount do
					local damagePar = CreateMOPixel("Smack Particle Light", "Base.rte");
					damagePar.Pos = self.Pos;
					damagePar.Vel = Vector(fireVec.X, fireVec.Y):RadRotate((-spread * 2 + i * spread - self.InheritedRotAngleOffset * 1.4) * self.FlipFactor);
					damagePar.Team = self.Team;
					damagePar.IgnoresTeamHits = true;
					
					damagePar.Mass = math.sqrt(self:GetParent().Mass + self.Mass);
					damagePar.Sharpness = self.Sharpness * RangeRand(0.5, 1.0);
					
					MovableMan:AddParticle(damagePar);
				end
			elseif not overhead and resource < 10 then
				--Gather materials and turn them into sandbags
				local rayCount = 3;
				local hits = 0;
				for i = 1, rayCount do
					local hitPos = self.MuzzlePos;
					local terrRay = SceneMan:CastStrengthRay(self.MuzzlePos, Vector(trace.X, trace.Y):DegRotate(self.ParticleSpreadRange * 0.5 - self.ParticleSpreadRange * (i/rayCount)), 30, hitPos, 3, rte.grassID, SceneMan.SceneWrapsX);
					if terrRay then
						local material = SceneMan:GetMaterialFromID(SceneMan:GetTerrMatter(hitPos.X, hitPos.Y)).PresetName;
						for _, terrainMaterial in pairs(self.suitableMaterials) do
							if material == terrainMaterial then
								hits = hits + 1;
								if hits > rayCount * 0.5 then
									parent:SetNumberValue("RoninShovelResource", resource + 1);
									self.collectSound:Play(self.Pos);
									break;
								end
								break;
							end
						end
					end
				end
			end
			self.InheritedRotAngleOffset = overhead and -0.1 or self.angleSize;
		end
		--This trick disables the collision for the weapon while the Magazine has no collision but looks exactly the same
		self.Scale = 0;
		if self.Magazine then
			self.Magazine.Scale = 1;

			self.Magazine.RoundCount = resource > 0 and resource or -1;
		end
		self.RateOfFire = self.minimumRoF + (self.minimumRoF) * (parent.Health/parent.MaxHealth);
	else
		self.Scale = 1;
		if self.Magazine then
			self.Magazine.Scale = 0;
		end
		if self.lastVel.Magnitude > 25 then
			if self.HitWhatMOID ~= rte.NoMOID then
				local mo = MovableMan:GetMOFromID(self.HitWhatMOID);
				if mo then
					local particleCount = 3;
					local spread = self.AngularVel * TimerMan.DeltaTimeSecs * 0.5;
					for i = 0, particleCount - 1 do
						local damagePar = CreateMOPixel("Smack Particle", "Base.rte");
						damagePar.Mass = self.Mass--/particleCount;
						damagePar.Sharpness = self.Sharpness-- * particleCount;

						damagePar.Pos = self.lastMuzzlePos;
						damagePar.Vel = Vector(self.lastVel.X, self.lastVel.Y):RadRotate(spread * 0.5 - spread * i/(particleCount - 1)) * 1.5;
	
						damagePar:SetWhichMOToNotHit(self, -1);
						MovableMan:AddParticle(damagePar);
					end
					self.hitSound:Play(self.MuzzlePos);
				end
			end
		end
	end
	self.lastVel = Vector(self.Vel.X, self.Vel.Y);
	self.lastMuzzlePos = Vector(self.MuzzlePos.X, self.MuzzlePos.Y);
end
function OnPieMenu(item)
	if item and IsHDFirearm(item) and item.PresetName == "Shovel" then
		item = ToHDFirearm(item);
		local parent = item:GetRootParent();
		if parent and IsActor(parent) then
			local resource = ToActor(parent):GetNumberValue("RoninShovelResource");
			ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Fill Sandbag", "RoninCreateSandbag");
			ToGameActivity(ActivityMan:GetActivity()):AddPieMenuSlice("Fill Sandbag", "RoninCreateSandbag", Slice.RIGHT, resource >= 10);
		end
	end
end