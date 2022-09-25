dofile("Base.rte/Constants.lua")

function OneManArmy:StartActivity()

	self.BuyMenuEnabled = false;
	
	local primaryGroup = "Weapons - Primary";
	local secondaryGroup = "Weapons - Secondary";
	-- Tertiary weapon is always a grenade
	local actorGroup = "Actors - Light";
	-- Default actors if no tech is chosen
	local defaultActor = ("Soldier Light");
	local defaultPrimary = ("Ronin/SPAS 12");
	local defaultSecondary = ("Ronin/.357 Magnum");
	local defaultTertiary = ("Ronin/Molotov Cocktail");

	if self.Difficulty <= GameActivity.CAKEDIFFICULTY then
		self.TimeLimit = 5 * 60000 + 5000;
		self.timeDisplay = "five minutes";
		self.BaseSpawnTime = 6000;
		
		primaryGroup = "Weapons - Heavy";
		secondaryGroup = "Weapons - Explosive";
		actorGroup = "Actors - Heavy";
	elseif self.Difficulty <= GameActivity.EASYDIFFICULTY then
		self.TimeLimit = 5 * 60000 + 5000;
		self.timeDisplay = "five minutes";
		self.BaseSpawnTime = 5500;
		
		primaryGroup = "Weapons - Primary";
		secondaryGroup = "Weapons - Light";
		actorGroup = "Actors - Heavy";
	elseif self.Difficulty <= GameActivity.MEDIUMDIFFICULTY then
		self.TimeLimit = 5 * 60000 + 5000;
		self.timeDisplay = "five minutes";
		self.BaseSpawnTime = 5000;
		
	elseif self.Difficulty <= GameActivity.HARDDIFFICULTY then
		self.TimeLimit = 6 * 60000 + 5000;
		self.timeDisplay = "six minutes";
		self.BaseSpawnTime = 4500;
		
		primaryGroup = "Weapons - Light";
		secondaryGroup = "Weapons - Secondary";
	elseif self.Difficulty <= GameActivity.NUTSDIFFICULTY then
		self.TimeLimit = 8 * 60000 + 5000;
		self.timeDisplay = "eight minutes";
		self.BaseSpawnTime = 4000;
		
		primaryGroup = "Weapons - Secondary";
		secondaryGroup = "Weapons - Secondary";
	elseif self.Difficulty <= GameActivity.MAXDIFFICULTY then
		self.TimeLimit = 10 * 60000 + 5000;
		self.timeDisplay = "ten minutes";
		self.BaseSpawnTime = 3500;
		
		primaryGroup = "Weapons - Secondary";
		secondaryGroup = "Tools";
	end
	-- Destroy all doors for this Activity
	MovableMan:OpenAllDoors(true, -1);
	for actor in MovableMan.AddedActors do
		if actor.ClassName == "ADoor" then
			actor.ToSettle = true;
			actor:GibThis();
		end
	end
	-- Check if we already have a brain assigned
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			if not self:GetPlayerBrain(player) then
				local team = self:GetTeamOfPlayer(player);
				local foundBrain = MovableMan:GetUnassignedBrain(team);
				-- If we can't find an unassigned brain in the scene to give the player, create one
				if not foundBrain then
					local tech = PresetMan:GetModuleID(self:GetTeamTech(team));
					foundBrain = CreateAHuman(defaultActor);
					-- If a faction was chosen, pick the first item from faction listing
					if tech ~= -1 then
						local module = PresetMan:GetDataModule(tech);
						local primaryWeapon, secondaryWeapon, throwable, actor;
						for entity in module.Presets do
							local picked;	-- Prevent duplicates
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
							if weapons[i] then
								foundBrain:AddInventoryItem(weapons[i]);
							end
						end
					else	-- If no tech selected, use default items
						local weapons = {defaultPrimary, defaultSecondary};
						for i = 1, #weapons do
							foundBrain:AddInventoryItem(CreateHDFirearm(weapons[i]));
						end
						local item = CreateTDExplosive(defaultTertiary);
						if item then
							foundBrain:AddInventoryItem(item);
						end
					end
					foundBrain.Pos = SceneMan:MovePointToGround(Vector(math.random(0, SceneMan.SceneWidth), 0), 0, 0) + Vector(0, -foundBrain.Radius);
					foundBrain.Team = self:GetTeamOfPlayer(player);
					MovableMan:AddActor(foundBrain);
					-- Set the found brain to be the selected actor at start
					self:SetPlayerBrain(foundBrain, player);
					self:SwitchToActor(foundBrain, player, self:GetTeamOfPlayer(player));
					self:SetLandingZone(self:GetPlayerBrain(player).Pos, player);
					-- Set the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
					self:SetObservationTarget(self:GetPlayerBrain(player).Pos, player);
				else
					-- Set the found brain to be the selected actor at start
					self:SetPlayerBrain(foundBrain, player);
					self:SwitchToActor(foundBrain, player, self:GetTeamOfPlayer(player));
					self:SetLandingZone(self:GetPlayerBrain(player).Pos, player);
					-- Set the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
					self:SetObservationTarget(self:GetPlayerBrain(player).Pos, player);
				end
			end
		end
	end
	
	-- Select a tech for the CPU player
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
	
	-- CPU Funds are unlimited
	self:SetTeamFunds(1000000, self.CPUTeam);
	
	self.TimeLeft = 500;
end


function OneManArmy:EndActivity()
	-- Temp fix so music doesn't start playing if ending the Activity when changing resolution through the ingame settings.
	if not self:IsPaused() then
		-- Play sad music if no humans are left
		if self:HumanBrainCount() == 0 then
			AudioMan:ClearMusicQueue();
			AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/udiedfinal.ogg", 2, -1.0);
			AudioMan:QueueSilence(10);
			AudioMan:QueueMusicStream("Base.rte/Music/dBSoundworks/ccambient4.ogg");
		else
			-- But if humans are left, then play happy music!
			AudioMan:ClearMusicQueue();
			AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/uwinfinal.ogg", 2, -1.0);
			AudioMan:QueueSilence(10);
			AudioMan:QueueMusicStream("Base.rte/Music/dBSoundworks/ccambient4.ogg");
		end
	end
end


function OneManArmy:UpdateActivity()
	if self.ActivityState ~= Activity.OVER then
		ActivityMan:GetActivity():SetTeamFunds(0,0)
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				--Display messages.
				if self.StartTimer:IsPastSimMS(3000) then
					FrameMan:SetScreenText(math.floor(self.SurvivalTimer:LeftTillSimMS(self.TimeLimit) / 1000) .. " seconds left", player, 0, 1000, false)
				else
					FrameMan:SetScreenText("Survive for " .. self.timeDisplay .. "!", player, 333, 5000, true)
				end
			
				-- The current player's team
				local team = self:GetTeamOfPlayer(player)
				-- Check if any player's brain is dead
				if not MovableMan:IsActor(self:GetPlayerBrain(player)) then
					self:SetPlayerBrain(nil, player)
					self:ResetMessageTimer(player)
					FrameMan:ClearScreenText(player)
					FrameMan:SetScreenText("Your brain has been destroyed!", player, 333, -1, false)
					-- Now see if all brains of self player's team are dead, and if so, end the game
					if not MovableMan:GetFirstBrainActor(team) then
						self.WinnerTeam = self:OtherTeam(team)
						ActivityMan:EndActivity()
					end
				else
					self.HuntPlayer = player
				end
				
				--Check if the player has won.
				if self.SurvivalTimer:IsPastSimMS(self.TimeLimit) then
					self:ResetMessageTimer(player)
					FrameMan:ClearScreenText(player)
					FrameMan:SetScreenText("You survived!", player, 333, -1, false)
					
					self.WinnerTeam = player
					
					--Kill all enemies.
					for actor in MovableMan.Actors do
						if actor.Team ~= self.WinnerTeam then
							actor.Health = 0
						end
					end

					ActivityMan:EndActivity()
				end
			end
		end

		--Spawn the AI.
		if self.CPUTeam ~= Activity.NOTEAM and self.ESpawnTimer:LeftTillSimMS(self.TimeLeft) <= 0 and MovableMan:GetTeamMOIDCount(self.CPUTeam) <= rte.AIMOIDMax * 3 / self:GetActiveCPUTeamCount() then

			-- Set up the ship to deliver this stuff
			local ship = RandomACRocket("Any", self.CPUTechName);
			local actorsInCargo = math.min(ship.MaxPassengers, 2)
			
			ship.Team = self.CPUTeam;
			
			-- The max allowed weight of this craft plus cargo
			local craftMaxMass = ship.MaxInventoryMass
			if craftMaxMass < 0 then
				craftMaxMass = math.huge
			elseif craftMaxMass < 1 then
				ship = RandomACRocket("Any", 0);
				craftMaxMass = ship.MaxInventoryMass
			end
			local totalInventoryMass = 0
			
			-- Set the ship up with a cargo of a few armed and equipped actors
			for i = 1, actorsInCargo do
				local passenger = RandomAHuman("Actors - " .. ((self.Difficulty > 75 and math.random() > 0.5) and "Heavy" or "Light"), self.CPUTechName);
				if passenger.ModuleID ~= PresetMan:GetModuleID(self.CPUTechName) then
					passenger = RandomAHuman("Actors", self.CPUTechName);
				end
				
				passenger:AddInventoryItem(CreateHDFirearm("Light Digger", "Base.rte"));
				
				-- Set AI mode and team so it knows who and what to fight for!
				passenger.AIMode = Actor.AIMODE_BRAINHUNT;
				passenger.Team = self.CPUTeam;

				-- Check that we can afford to buy and to carry the weight of this passenger
				if (ship:GetTotalValue(0,3) + passenger:GetTotalValue(0,3)) <= self:GetTeamFunds(self.CPUTeam) and (totalInventoryMass + passenger.Mass) <= craftMaxMass then
					-- Yes we can; so add it to the cargo hold
					ship:AddInventoryItem(passenger);
					totalInventoryMass = totalInventoryMass + passenger.Mass
					passenger = nil;
				else
					-- Nope; just delete the nixed passenger and stop adding new ones
					-- This doesn't need to be explicitly deleted here, teh garbage collection would do it eventually..
					-- but since we're so sure we don't need it, might as well go ahead and do it here right away
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
				-- Set the spawn point of the ship from orbit
				if self.playertally == 1 then
					for i = 1, #self.playerlist do
						if self.playerlist[i] == true then
							local sceneChunk = SceneMan.SceneWidth / 3;
							local checkPos = self:GetPlayerBrain(i - 1).Pos.X + (SceneMan.SceneWidth/2) + ( (sceneChunk/2) - (math.random()*sceneChunk) );
							if checkPos > SceneMan.SceneWidth then
								checkPos = checkPos - SceneMan.SceneWidth;
							elseif checkPos < 0 then
								checkPos = SceneMan.SceneWidth + checkPos;
							end
							ship.Pos = Vector(checkPos,-50);
							break;
						end
					end
				else
					if SceneMan.SceneWrapsX then
						ship.Pos = Vector(math.random() * SceneMan.SceneWidth, -50);
					else
						ship.Pos = Vector(RangeRand(100, SceneMan.SceneWidth-100), -50);
					end
				end

				-- Double-check if the computer can afford this ship and cargo, then subtract the total value from the team's funds
				local shipValue = ship:GetTotalValue(0,3)
				if shipValue <= self:GetTeamFunds(self.CPUTeam) then
					-- Subtract the total value of the ship+cargo from the CPU team's funds
					self:ChangeTeamFunds(-shipValue, self.CPUTeam);
					-- Spawn the ship onto the scene
					MovableMan:AddActor(ship);
				else
					-- The ship and its contents is deleted if it can't be afforded
					-- This doesn't need to be explicitly deleted here, teh garbage collection would do it eventually..
					-- but since we're so sure we don't need it, might as well go ahead and do it here right away
					DeleteEntity(ship);
					ship = nil;
				end
			end

			self.ESpawnTimer:Reset();
			self.TimeLeft = (self.BaseSpawnTime + math.random(self.BaseSpawnTime) * rte.SpawnIntervalScale);
		end
	end
end
