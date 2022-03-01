dofile("Base.rte/Constants.lua")

function OneManArmy:StartActivity()

	self.BuyMenuEnabled = false;
	--Brain strength multiplier
	self.multiplier = math.ceil(11 - (self.Difficulty * 0.1));	--Med = 6, Max = 11, Min = 1

	local primaryGroup = "Weapons - Heavy";
	local secondaryGroup = "Weapons - Light";
	--Tertiary weapon is always a grenade
	local actorGroup = "Actors - Heavy";
	--Default actors if no tech is chosen
	local defaultActor = ("Soldier Heavy");
	local defaultPrimary = ("Coalition/Assault Rifle");
	local defaultSecondary = ("Coalition/Auto Pistol");
	local defaultTertiary = ("Coalition/Frag Grenade");

	if self.Difficulty <= GameActivity.CAKEDIFFICULTY then
		self.TimeLimit = 3 * 60000 + 5000;
		self.timeDisplay = "three minutes";
		self.BaseSpawnTime = 6000;
		
		primaryGroup = "Weapons - Heavy";
		secondaryGroup = "Weapons - Explosive";
	elseif self.Difficulty <= GameActivity.EASYDIFFICULTY then
		self.TimeLimit = 4 * 60000 + 5000;
		self.timeDisplay = "four minutes";
		self.BaseSpawnTime = 5500;

	elseif self.Difficulty <= GameActivity.MEDIUMDIFFICULTY then
		self.TimeLimit = 5 * 60000 + 5000;
		self.timeDisplay = "five minutes";
		self.BaseSpawnTime = 5000;
		
	elseif self.Difficulty <= GameActivity.HARDDIFFICULTY then
		self.TimeLimit = 6 * 60000 + 5000;
		self.timeDisplay = "six minutes";
		self.BaseSpawnTime = 4500;

	elseif self.Difficulty <= GameActivity.NUTSDIFFICULTY then
		self.TimeLimit = 7 * 60000 + 5000;
		self.timeDisplay = "seven minutes";
		self.BaseSpawnTime = 4000;
		
		primaryGroup = "Weapons - Primary";
		secondaryGroup = "Weapons - Secondary";
		actorGroup = "Actors - Light";
	elseif self.Difficulty <= GameActivity.MAXDIFFICULTY then
		self.TimeLimit = 9 * 60000 + 5000;
		self.timeDisplay = "nine minutes";
		self.BaseSpawnTime = 3500;
		
		primaryGroup = "Weapons - Secondary";
		secondaryGroup = "Weapons - Secondary";
		actorGroup = "Actors - Light";
	end
	--Destroy all doors for this Activity - the enemy is not equipped to deal with them
	MovableMan:OpenAllDoors(true, -1);
	for actor in MovableMan.AddedActors do
		if actor.ClassName == "ADoor" then
			actor.ToSettle = true;
			actor:GibThis();
		end
	end
	--Check if we already have a brain assigned
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			if not self:GetPlayerBrain(player) then
				local team = self:GetTeamOfPlayer(player);
				local foundBrain = MovableMan:GetUnassignedBrain(team);
				--If we can't find an unassigned brain in the scene to give the player, create one
				if not foundBrain then
					local tech = PresetMan:GetModuleID(self:GetTeamTech(team));
					foundBrain = CreateAHuman(defaultActor);
					--If a faction was chosen, pick the first item from faction listing
					if tech ~= -1 then
						local module = PresetMan:GetDataModule(tech);
						local primaryWeapon, secondaryWeapon, throwable, actor;
						for entity in module.Presets do
							local picked;	--Prevent duplicates
							if not primaryWeapon and entity.ClassName == "HDFirearm" and ToMOSRotating(entity):HasObjectInGroup(primaryGroup) and ToMOSRotating(entity).IsBuyable then
								primaryWeapon = CreateHDFirearm(entity:GetModuleAndPresetName());
								picked = true;
							end
							if not picked and not secondaryWeapon and entity.ClassName == "HDFirearm" and ToMOSRotating(entity):HasObjectInGroup(secondaryGroup) and ToMOSRotating(entity).IsBuyable then
								secondaryWeapon = CreateHDFirearm(entity:GetModuleAndPresetName());
								picked = true;
							end
							if not picked and not throwable and entity.ClassName == "TDExplosive" and ToMOSRotating(entity):HasObjectInGroup("Bombs - Grenades") and ToMOSRotating(entity).IsBuyable then
								throwable = CreateTDExplosive(entity:GetModuleAndPresetName());
								picked = true;
							end
							if not picked and not actor and entity.ClassName == "AHuman" and ToMOSRotating(entity):HasObjectInGroup(actorGroup) and ToMOSRotating(entity).IsBuyable then
								actor = CreateAHuman(entity:GetModuleAndPresetName());
							end
						end
						if actor then
							foundBrain = actor;
						end
						local weapons = {primaryWeapon, secondaryWeapon, throwable};
						for i = 1, #weapons do
							local item = weapons[i];
							if item then
								item.GibWoundLimit = item.GibWoundLimit * self.multiplier;
								item.JointStrength = item.JointStrength * self.multiplier;
								foundBrain:AddInventoryItem(weapons[i]);
							end
						end
					else	--If no tech selected, use default items
						local weapons = {defaultPrimary, defaultSecondary};
						for i = 1, #weapons do
							local item = CreateHDFirearm(weapons[i]);
							if item then
								item.GibWoundLimit = item.GibWoundLimit and item.GibWoundLimit * self.multiplier or item.GibWoundLimit;
								item.JointStrength = item.JointStrength * self.multiplier;
								foundBrain:AddInventoryItem(CreateHDFirearm(weapons[i]));
							end
						end
						local item = CreateTDExplosive(defaultTertiary);
						if item then
							foundBrain:AddInventoryItem(item);
						end
					end
					--Reinforce the brain actor
					local parts = {foundBrain, foundBrain.Head, foundBrain.FGArm, foundBrain.BGArm, foundBrain.FGLeg, foundBrain.BGLeg};
					for i = 1, #parts do
						local part = parts[i];
						if part then
							part.GibWoundLimit = math.ceil(part.GibWoundLimit * self.multiplier);
							part.DamageMultiplier = part.DamageMultiplier/self.multiplier;
							if IsAttachable(part) then
								ToAttachable(part).JointStrength = ToAttachable(part).JointStrength * self.multiplier;
							else
								part.GibImpulseLimit = foundBrain.GibImpulseLimit * self.multiplier;
								part.ImpulseDamageThreshold = foundBrain.GibImpulseLimit * self.multiplier;
							end
							for att in part.Attachables do
								att.GibWoundLimit = math.ceil(att.GibWoundLimit * self.multiplier);
								att.JointStrength = att.JointStrength * self.multiplier;
							end
						end
					end
					local medikit = CreateHDFirearm("Base/Medikit");
					if medikit then
						foundBrain:AddInventoryItem(medikit);
					end
					--Reinforce FGArm so that we don't lose it
					--No FGArm = no weapons = no gameplay
					foundBrain.FGArm.GibWoundLimit = 999999;
					foundBrain.FGArm.JointStrength = 999999;

					foundBrain.Pos = SceneMan:MovePointToGround(Vector(math.random(0, SceneMan.SceneWidth), 0), 0, 0) + Vector(0, -foundBrain.Radius);
					foundBrain.Team = self:GetTeamOfPlayer(player);
					MovableMan:AddActor(foundBrain);
					--Set the found brain to be the selected actor at start
					self:SetPlayerBrain(foundBrain, player);
					self:SwitchToActor(foundBrain, player, self:GetTeamOfPlayer(player));
					self:SetLandingZone(self:GetPlayerBrain(player).Pos, player);
					--Set the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
					self:SetObservationTarget(self:GetPlayerBrain(player).Pos, player);
				else
					--Set the found brain to be the selected actor at start
					self:SetPlayerBrain(foundBrain, player);
					self:SwitchToActor(foundBrain, player, self:GetTeamOfPlayer(player));
					self:SetLandingZone(self:GetPlayerBrain(player).Pos, player);
					--Set the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
					self:SetObservationTarget(self:GetPlayerBrain(player).Pos, player);
				end
			end
		end
	end
	
	--Select a tech for the CPU player
	self.CPUTechName = self:GetTeamTech(self.CPUTeam);
	self.ESpawnTimer = Timer();
	self.LZ = SceneMan.Scene:GetArea("LZ Team 1");
	self.EnemyLZ = SceneMan.Scene:GetArea("LZ All");
	self.SurvivalTimer = Timer();

	self.StartTimer = Timer();
	ActivityMan:GetActivity():SetTeamFunds(0, Activity.TEAM_1);
	ActivityMan:GetActivity():SetTeamFunds(0, Activity.TEAM_2);
	ActivityMan:GetActivity():SetTeamFunds(0, Activity.TEAM_3);
	ActivityMan:GetActivity():SetTeamFunds(0, Activity.TEAM_4);
	
	--CPU Funds are "unlimited"
	self:SetTeamFunds(1000000, self.CPUTeam);
	
	self.TimeLeft = 500;
end


function OneManArmy:EndActivity()
	-- Temp fix so music doesn't start playing if ending the Activity when changing resolution through the ingame settings.
	if not self:IsPaused() then
		--Play sad music if no humans are left
		if self:HumanBrainCount() == 0 then
			AudioMan:ClearMusicQueue();
			AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/udiedfinal.ogg", 2, -1.0);
			AudioMan:QueueSilence(10);
			AudioMan:QueueMusicStream("Base.rte/Music/dBSoundworks/ccambient4.ogg");
		else
			--But if humans are left, play happy music!
			AudioMan:ClearMusicQueue();
			AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/uwinfinal.ogg", 2, -1.0);
			AudioMan:QueueSilence(10);
			AudioMan:QueueMusicStream("Base.rte/Music/dBSoundworks/ccambient4.ogg");
		end
	end
end


function OneManArmy:UpdateActivity()
	if self.ActivityState ~= Activity.OVER then
		ActivityMan:GetActivity():SetTeamFunds(0, 0)
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				--Display messages
				if self.StartTimer:IsPastSimMS(3000) then
					FrameMan:SetScreenText(math.floor(self.SurvivalTimer:LeftTillSimMS(self.TimeLimit) * 0.001) .. " seconds left", player, 0, 1000, false)
				else
					FrameMan:SetScreenText("Survive for " .. self.timeDisplay .. "!", player, 333, 5000, true)
				end

				local team = self:GetTeamOfPlayer(player);
				--Check if any player's brain is dead
				if not MovableMan:IsActor(self:GetPlayerBrain(player)) then
					self:SetPlayerBrain(nil, player);
					self:ResetMessageTimer(player);
					FrameMan:ClearScreenText(player);
					FrameMan:SetScreenText("Your brain has been destroyed!", player, 333, -1, false);
					--Now see if all brains of self player's team are dead, and if so, end the game
					if not MovableMan:GetFirstBrainActor(team) then
						self.WinnerTeam = self:OtherTeam(team);
						ActivityMan:EndActivity();
					end
				end
				
				--Check if the player has won
				if self.SurvivalTimer:IsPastSimMS(self.TimeLimit) then
					self:ResetMessageTimer(player);
					FrameMan:ClearScreenText(player);
					FrameMan:SetScreenText("You survived!", player, 333, -1, false);
					
					self.WinnerTeam = player;
					
					--Kill all enemies
					for actor in MovableMan.Actors do
						if actor.Team ~= self.WinnerTeam then
							actor.Health = 0;
						end
					end

					ActivityMan:EndActivity();
				end
			end
		end
		local enemyMOIDCount = MovableMan:GetTeamMOIDCount(self.CPUTeam);
		--Spawn the AI
		if self.CPUTeam ~= Activity.NOTEAM and self.ESpawnTimer:LeftTillSimMS(self.TimeLeft) <= 0 and enemyMOIDCount < rte.AIMOIDMax then
			local ship, actorsInCargo;
			
			if math.random() < 0.5 then
				--Set up the ship to deliver this stuff
				ship = RandomACDropShip("Any", self.CPUTechName);
				--If we can't afford this dropship, then try a rocket instead
				if ship:GetTotalValue(0, 3) > self:GetTeamFunds(self.CPUTeam) then
					DeleteEntity(ship);
					ship = RandomACRocket("Any", self.CPUTechName);
				end
				actorsInCargo = math.min(ship.MaxPassengers, 3);
			else
				ship = RandomACRocket("Any", self.CPUTechName);
				actorsInCargo = math.min(ship.MaxPassengers, 2);
			end
			
			ship.Team = self.CPUTeam;
			
			--The max allowed weight of this craft plus cargo
			local craftMaxMass = ship.MaxInventoryMass;
			if craftMaxMass < 0 then
				craftMaxMass = math.huge;
			elseif craftMaxMass < 1 then
				ship = RandomACDropShip("Any", 0);
				craftMaxMass = ship.MaxInventoryMass;
			end
			local totalInventoryMass = 0

			--Set the ship up with a cargo of a few armed and equipped actors
			for i = 1, actorsInCargo do
				--Get any Actor from the CPU's native tech
				local passenger = nil;
				if math.random() >= self:GetCrabToHumanSpawnRatio(PresetMan:GetModuleID(self.CPUTechName)) then
					passenger = RandomAHuman("Actors - Light", self.CPUTechName);
				else
					passenger = RandomACrab("Actors - Mecha", self.CPUTechName);
				end
				--Equip it with tools and guns if it's a humanoid
				if IsAHuman(passenger) then
					passenger:AddInventoryItem(RandomHDFirearm("Weapons - Light", self.CPUTechName));
					passenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.CPUTechName));
					if math.random() < 0.5 then
						passenger:AddInventoryItem(RandomHDFirearm("Tools - Diggers", self.CPUTechName));
					end
				end
				--Set AI mode and team so it knows who and what to fight for!
				passenger.AIMode = Actor.AIMODE_BRAINHUNT;
				passenger.Team = self.CPUTeam;

				--Check that we can afford to buy and to carry the weight of this passenger
				if (ship:GetTotalValue(0, 3) + passenger:GetTotalValue(0, 3)) <= self:GetTeamFunds(self.CPUTeam) and (totalInventoryMass + passenger.Mass) <= craftMaxMass then
					--Yes we can; so add it to the cargo hold
					ship:AddInventoryItem(passenger);
					totalInventoryMass = totalInventoryMass + passenger.Mass
					passenger = nil;
				else
					--Nope; just delete the nixed passenger and stop adding new ones
					--This doesn't need to be explicitly deleted here, the garbage collection would do it eventually,
					--but since we're so sure we don't need it, might as well go ahead and do it right away
					DeleteEntity(passenger);
					passenger = nil;
					
					if i < 2 then	-- Don't deliver empty craft
						DeleteEntity(ship);
						ship = nil;
					end
					
					break;
				end
			end
			
			if ship then
				--Set the spawn point of the ship from orbit
				if self.playertally == 1 then
					for i = 1, #self.playerlist do
						if self.playerlist[i] == true then
							local sceneChunk = SceneMan.SceneWidth * 0.3;
							local checkPos = self:GetPlayerBrain(i - 1).Pos.X + (SceneMan.SceneWidth * 0.5) + ((sceneChunk * 0.5) - (math.random() * sceneChunk));
							if checkPos > SceneMan.SceneWidth then
								checkPos = checkPos - SceneMan.SceneWidth;
							elseif checkPos < 0 then
								checkPos = SceneMan.SceneWidth + checkPos;
							end
							ship.Pos = Vector(checkPos, -50);
							break;
						end
					end
				else
					if SceneMan.SceneWrapsX then
						ship.Pos = Vector(math.random() * SceneMan.SceneWidth, -50);
					else
						ship.Pos = Vector(RangeRand(100, SceneMan.SceneWidth - 100), -50);
					end
				end

				--Double-check if the computer can afford this ship and cargo, then subtract the total value from the team's funds
				local shipValue = ship:GetTotalValue(0, 3);
				if shipValue <= self:GetTeamFunds(self.CPUTeam) then
					--Subtract the total value of the ship+cargo from the CPU team's funds
					self:ChangeTeamFunds(-shipValue, self.CPUTeam);
					--Spawn the ship onto the scene
					MovableMan:AddActor(ship);
				else
					--The ship and its contents is deleted if it can't be afforded
					DeleteEntity(ship);
					ship = nil;
				end
			end

			self.ESpawnTimer:Reset();
			self.TimeLeft = (self.BaseSpawnTime * (1 + enemyMOIDCount * 0.1) + math.random(self.BaseSpawnTime)) * rte.SpawnIntervalScale;
		end
	end
end
