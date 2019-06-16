dofile("Base.rte/Constants.lua")

function KeepieUppie:StartActivity()
	print("START! -- KeepieUppie:StartActivity()!");

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			self:AddOverridePurchase(CreateACRocket("Rocklet"), player);
			self:SetViewState(Activity.LZSELECT, player);
		end
	end

	-- Select a tech for the CPU player
	self.CPUTechName = self:GetTeamTech(self.CPUTeam);
	self.ESpawnTimer = Timer();
	self.LZ = SceneMan.Scene:GetArea("LZ Team 1");
	self.EnemyLZ = SceneMan.Scene:GetArea("LZ All");

	self.SurvivalTimer = Timer();
	
	if self.Difficulty <= GameActivity.CAKEDIFFICULTY then
		self.TimeLimit = 25000;
		self.timeDisplay = "twenty seconds";
		self.BaseSpawnTime = 6000;
		self.RandomSpawnTime = 8000;
	elseif self.Difficulty <= GameActivity.EASYDIFFICULTY then
		self.TimeLimit = 45000;
		self.timeDisplay = "forty seconds";
		self.BaseSpawnTime = 5500;
		self.RandomSpawnTime = 7000;
	elseif self.Difficulty <= GameActivity.MEDIUMDIFFICULTY then
		self.TimeLimit = 65000;
		self.timeDisplay = "one minute";
		self.BaseSpawnTime = 5000;
		self.RandomSpawnTime = 6000;
	elseif self.Difficulty <= GameActivity.HARDDIFFICULTY then
		self.TimeLimit = 95000;
		self.timeDisplay = "one minute and thirty seconds";
		self.BaseSpawnTime = 4500;
		self.RandomSpawnTime = 5000;
	elseif self.Difficulty <= GameActivity.NUTSDIFFICULTY then
		self.TimeLimit = 125000;
		self.timeDisplay = "two minutes and thirty seconds";
		self.BaseSpawnTime = 4000;
		self.RandomSpawnTime = 4500;
	elseif self.Difficulty <= GameActivity.MAXDIFFICULTY then
		self.TimeLimit = 305000;
		self.timeDisplay = "five minutes";
		self.BaseSpawnTime = 3500;
		self.RandomSpawnTime = 4000;
	end
	
	self:SetTeamFunds(0, Activity.TEAM_1);
	-- CPU Funds are unlimited
	self:SetTeamFunds(1000000, self.CPUTeam);

	self.StartTimer = Timer();
	self.started = false;
	
	self.TimeLeft = 2000
end


function KeepieUppie:EndActivity()
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


function KeepieUppie:UpdateActivity()
	self:ClearObjectivePoints();

	if self.started then
		if self.ActivityState ~= Activity.OVER and self.ActivityState ~= Activity.EDITING then
			for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
				if self:PlayerActive(player) and self:PlayerHuman(player) then
					--Display messages.
					self:ResetMessageTimer(player);
					FrameMan:ClearScreenText(player);
					if self.StartTimer:IsPastSimMS(3000) then
						FrameMan:SetScreenText(math.floor(self.SurvivalTimer:LeftTillSimMS(self.TimeLimit) / 1000) .. " seconds left", player, 0, 1000, false);
					else
						FrameMan:SetScreenText("Keep the rocket alive for " .. self.timeDisplay .. "!", player, 333, 5000, true);
					end
				
					-- The current player's team
					local team = self:GetTeamOfPlayer(player);
					-- Check if any player's brain is dead
					if not MovableMan:IsActor(self:GetPlayerBrain(player)) then
						self:SetPlayerBrain(nil, player);
						self:ResetMessageTimer(player);
						FrameMan:ClearScreenText(player);
						FrameMan:SetScreenText("Your rocket has been destroyed!", player, 333, -1, false);
						-- Now see if all brains of self player's team are dead, and if so, end the game
						if not MovableMan:GetFirstBrainActor(team) then
							self.WinnerTeam = self:OtherTeam(team);
							ActivityMan:EndActivity();
						end
					else
						self.HuntPlayer = player;
					end
					
					--Check if the player has won.
					if self.SurvivalTimer:IsPastSimMS(self.TimeLimit) then
						self:ResetMessageTimer(player);
						FrameMan:ClearScreenText(player);
						FrameMan:SetScreenText("You survived!", player, 333, -1, false);
						
						self.WinnerTeam = player;
						
						--Kill all enemies.
						for actor in MovableMan.Actors do
							if actor.Team ~= self.WinnerTeam then
								actor.Health = 0;
							end
						end

						ActivityMan:EndActivity();
					end
				end
			end

			--Spawn the AI.
			if self.CPUTeam ~= Activity.NOTEAM and self.ESpawnTimer:LeftTillSimMS(self.TimeLeft) <= 0 and MovableMan:GetTeamMOIDCount(self.CPUTeam) <= rte.AIMOIDMax * 3 / self:GetActiveCPUTeamCount() then
				local ship, actorsInCargo
				
				if PosRand() < 0.5 then
					-- Set up the ship to deliver this stuff
					ship = RandomACDropShip("Any", self.CPUTechName);
					actorsInCargo = ship.MaxPassengers
				else
					ship = RandomACRocket("Any", self.CPUTechName);
					actorsInCargo = math.min(ship.MaxPassengers, 2)
				end
				
				ship.Team = self.CPUTeam;
				
				-- Set the ship up with a cargo of a few armed and equipped actors
				for i = 1, actorsInCargo do
					-- Get any Actor from the CPU's native tech
					local passenger = nil;
					if math.random() >= self:GetCrabToHumanSpawnRatio(PresetMan:GetModuleID(self.CPUTechName)) then
						passenger = RandomAHuman("Any", self.CPUTechName);
					else
						passenger = RandomACrab("Any", self.CPUTechName);
					end
					-- Equip it with tools and guns if it's a humanoid
					if IsAHuman(passenger) then
						passenger:AddInventoryItem(RandomHDFirearm("Primary Weapons", self.CPUTechName));
						passenger:AddInventoryItem(RandomHDFirearm("Secondary Weapons", self.CPUTechName));
						if PosRand() < 0.5 then
							passenger:AddInventoryItem(RandomHDFirearm("Diggers", self.CPUTechName));
						end
					end
					-- Set AI mode and team so it knows who and what to fight for!
					passenger.AIMode = Actor.AIMODE_BRAINHUNT;
					passenger.Team = self.CPUTeam;
					ship:AddInventoryItem(passenger)
				end
				
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

				-- Spawn the ship onto the scene
				MovableMan:AddActor(ship);

				self.ESpawnTimer:Reset();
				self.TimeLeft = (self.BaseSpawnTime + math.random(self.RandomSpawnTime) * rte.SpawnIntervalScale)
			end
		end
	else
		self.StartTimer:Reset();
		self.SurvivalTimer:Reset();
		
		FrameMan:SetScreenText("Order your rocket...", Activity.PLAYER_1, 0, 5000, false);
		
		--See if the rocket has spawned yet.
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				for actor in MovableMan.Actors do
					if actor.ClassName == "ACRocket" and actor.Team == Activity.TEAM_1 then
						self:SetPlayerBrain(actor, player);
						self:SetObservationTarget(actor.Pos, player);
						self:SwitchToActor(actor, player, player);
				
						self.started = true;
					end
				end
			end
		end
	end
	
	self:SetTeamFunds(0, Activity.TEAM_1);
	
	self:YSortObjectivePoints();
end
