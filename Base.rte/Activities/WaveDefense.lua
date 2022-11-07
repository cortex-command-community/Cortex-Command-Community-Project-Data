function WaveDefense:CheckBrains()
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			-- Check if we already have a brain assigned
			if not self:GetPlayerBrain(player) then
				local foundBrain = MovableMan:GetUnassignedBrain(self:GetTeamOfPlayer(player));
				-- If we can't find an unassigned brain in the scene to give each player, then force to go into editing mode to place one
				if not foundBrain then
					self.ActivityState = Activity.EDITING;
					-- Open all doors so we can do pathfinding through them with the brain placement
					MovableMan:OpenAllDoors(true, Activity.NOTEAM);
					AudioMan:ClearMusicQueue();
					AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/ccambient4.ogg", -1, -1);
					self:SetLandingZone(Vector(player*SceneMan.SceneWidth/4, 0), player);
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
end

function WaveDefense:StartActivity()
	collectgarbage("collect");

	-- Get player team
	self.playerTeam = Activity.TEAM_1;
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			self.playerTeam = self:GetTeamOfPlayer(player);
			break; -- All players are on the same team
		end
	end

	self:SetTeamFunds(self:GetStartingGold(), self.playerTeam);
	self:CheckBrains();
	self.triggerWaveInit = true;

	-- Set all actors defined in the ini-file to sentry mode
	for actor in MovableMan.AddedActors do
		if actor.ClassName == "AHuman" or actor.ClassName == "ACrab" then
			actor.AIMode = Actor.AIMODE_SENTRY;
		end
	end

	-- Initialize the AI
	if self.CPUTeam ~= Activity.NOTEAM then
		self.wave = 1;
		self.wavesDefeated = 0;

		self.AI = {};
		self.AI.SpawnTimer = Timer();
		self.AI.BombTimer = Timer();
		self.AI.HuntTimer = Timer();
		self.AI.EngineerTimer = Timer();

		-- Store data about terrain and enemy actors in the LZ map, use it to pick safe landing zones
		self.AI.LZmap = require("Activities/LandingZoneMap"); --self.AI.LZmap = dofile("Base.rte/Activities/LandingZoneMap.lua")
		self.AI.LZmap:Initialize({self.CPUTeam});

		-- Store data about player teams: self.AI.OnPlayerTeam[Act.Team] is true if "Act" is an enemy to the AI
		self.AI.OnPlayerTeam = {};
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				self.AI.OnPlayerTeam[self:GetTeamOfPlayer(player)] = true;
			end
		end
	end

	self.StartTimer = Timer();
	self.NextWaveTimer = Timer();
	self.PrepareForNextWaveTimer = Timer();
	self.PrepareForNextWaveTimer:SetRealTimeLimitMS(30000);

	-- Take scene ownership
	for actor in MovableMan.AddedActors do
		actor.Team = self.playerTeam;
	end

	self.Fog = self:GetFogOfWarEnabled();
end

function WaveDefense:InitWave()
	self.AI.bombChance = math.min(math.max(self.Difficulty/100+math.random(-0.1, 0.1), 0), 1);
	self.AI.timeToSpawn = 8000 - 50 * self.Difficulty; -- Time before the first AI spawn: from 8s to 3s
	self.AI.timeToBomb = (42000 - 300 * self.Difficulty) * math.random(0.7, 1.1); -- From 42s to 12s
	self.AI.timeToEngineer = (60000 - 300 * self.Difficulty) * math.random(0.55, 1.15); -- From 60s to 30s
	self.AI.baseSpawnTime = 9000 - 40 * self.Difficulty; -- From 9s to 5s
	self.AI.randomSpawnTime = 6000 - 30 * self.Difficulty; -- From 6s to 3s

	self.AI.SpawnTimer:Reset();
	self.AI.BombTimer:Reset();
	self.AI.HuntTimer:Reset();
	self.AI.EngineerTimer:Reset();

	self.AI.Tech = self:GetTeamTech(self.CPUTeam);	-- Select a tech for the CPU player
	gPrevAITech = self.AI.Tech; -- Store the AI tech in a global so we don't pick the same tech again next round
	self.AI.TechID = PresetMan:GetModuleID(self.AI.Tech);

	local lastWavePlayerValue = self.AI.playerValue;
	self.AI.playerValue = self:GetTeamFunds(self.playerTeam); -- The gold value of the players

	for Act in MovableMan.AddedActors do
		if Act.Team == self.playerTeam then
			self.AI.playerValue = self.AI.playerValue + Act:GetTotalValue(0, 1);
			if Act.AIMode == Actor.AIMODE_PATROL or Act.AIMode == Actor.AIMODE_BRAINHUNT then
				Act.AIMode = Actor.AIMODE_SENTRY;
			end
		end
	end

	for Act in MovableMan.Actors do
		if Act.Team == self.playerTeam then
			self.AI.playerValue = self.AI.playerValue + Act:GetTotalValue(0, 1);
			if Act.AIMode == Actor.AIMODE_PATROL or Act.AIMode == Actor.AIMODE_BRAINHUNT then
				Act.AIMode = Actor.AIMODE_SENTRY;
			end
		end
	end

	if self.AI.lastWaveValue then
		-- TODO: figure out how much gold we need to defeat the player based on previous waves

		local handicap = 0;
		if self.AI.playerValue > lastWavePlayerValue then
			handicap = handicap + (self.AI.playerValue - lastWavePlayerValue) * 0.5;
		end

		if self.AI.playerValue > self.AI.lastWaveValue * 0.7 then
			handicap = handicap + 100 + 6 * self.Difficulty;
		end

		self.AI.lastWaveValue = 37 * self.Difficulty + self.wave * (4*self.Difficulty+1000) + handicap;
	else
		self.AI.lastWaveValue = 37 * self.Difficulty + 900; -- AI team gold: from 1k to 5k
	end

	self:SetTeamFunds(self.AI.lastWaveValue, self.CPUTeam);
end

function WaveDefense:UpdateActivity()
	if self.ActivityState == Activity.OVER then
		return;
	end

	if self.ActivityState == Activity.EDITING then
		-- Game is in editing or other modes, so open all doors
		MovableMan:OpenAllDoors(true, Activity.NOTEAM);

		-- Remove fog
		if self.Fog then
			SceneMan:RevealUnseenBox(0, 0, SceneMan.SceneWidth-1, SceneMan.SceneHeight-1, self.playerTeam);
		end

		-- Make sure all actors are in sentry mode
		for Act in MovableMan.AddedActors do
			if Act.Team == self.playerTeam and (Act.AIMode == Actor.AIMODE_PATROL or Act.AIMode == Actor.AIMODE_BRAINHUNT) then
				Act.AIMode = Actor.AIMODE_SENTRY;
			end
		end
	elseif self.prepareForNextWave then
		if self.PrepareForNextWaveTimer:IsPastRealTimeLimit() then
			self.prepareForNextWave = false;
		else
			local time = math.floor(self.PrepareForNextWaveTimer:LeftTillRealTimeLimitMS() / 1000);
			for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
				if self:PlayerActive(player) and self:PlayerHuman(player) then
					FrameMan:SetScreenText("The next wave arrive in "..time.." seconds. Press [Space] to enter edit mode.", player, 0, 100, false);
				end
			end

			if UInputMan:KeyPressed(75) then	-- spacebar
				self.prepareForNextWave = false;
				self.ActivityState = Activity.EDITING;

				-- Remove control of the actors during edit mode
				for Act in MovableMan.Actors do
					if Act.Team == self.playerTeam then
						Act:GetController().InputMode = Controller.CIM_DISABLED;
					end
				end

				-- Remove and refund the player's brains (otherwise edit mode does not work)
				for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
					if self:PlayerActive(player) and self:PlayerHuman(player) then
						local Brain = self:GetPlayerBrain(player);
						if MovableMan:IsActor(Brain) then
							self:ChangeTeamFunds(Brain:GetTotalValue(0, 1), self.playerTeam);
							MovableMan:RemoveActor(Brain);
						end
					end

					-- Award some gold for defeateing the wave
					self:ChangeTeamFunds((500-5.5*self.Difficulty)*rte.StartingFundsScale, self.playerTeam);
				end
			end
		end
	else
		if self.triggerWaveInit then
			self.triggerWaveInit = false;
			self.StartTimer:Reset();
			self:CheckBrains();
			self:InitWave();
			self:EnforceMOIDLimit();

			-- Give back control of the actors
			for Act in MovableMan.Actors do
				if Act.Team == self.playerTeam then
					Act:GetController().InputMode = Controller.CIM_AI;
				end
			end

			MovableMan:OpenAllDoors(false, Activity.NOTEAM); -- Close all doors after placing brains so our fortresses are secure

			-- Add fog
			if self.Fog then
				for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
					if self:PlayerActive(player) and self:PlayerHuman(player) then
						SceneMan:MakeAllUnseen(Vector(25, 25), self:GetTeamOfPlayer(player));
					end
				end

				for team = 0, Activity.MAXTEAMCOUNT - 1 do
					if self:TeamActive(team) and self:TeamIsCPU(team) then
						SceneMan:MakeAllUnseen(Vector(65, 65), team);
					end
				end

				for Act in MovableMan.AddedActors do
					if Act.ClassName ~= "ADoor" then
						for ang = 0, math.pi*2, 0.15 do
							SceneMan:CastSeeRay(Act.Team, Act.EyePos, Vector(30+FrameMan.PlayerScreenWidth*0.5, 0):RadRotate(ang), Vector(), 1, 5);
						end
					end
				end

				for Act in MovableMan.Actors do
					if Act.ClassName ~= "ADoor" then
						for ang = 0, math.pi*2, 0.15 do
							SceneMan:CastSeeRay(Act.Team, Act.EyePos, Vector(30+FrameMan.PlayerScreenWidth*0.5, 0):RadRotate(ang), Vector(), 1, 5);
						end
					end
				end
			end
		end

		-- Clear all objective markers, they get re-added each frame
		self:ClearObjectivePoints()
		-- Keep track of which teams we have set objective points for already, since multiple players can be on the same team
		local setTeam = { [Activity.TEAM_1] = false, [Activity.TEAM_2] = false, [Activity.TEAM_3] = false, [Activity.TEAM_4] = false };
		local teamtally = 0;
		local playertally = 0;
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				if not self.StartTimer:IsPastRealMS(3000) then
					FrameMan:SetScreenText("Survive wave "..self.wave, player, 333, 5000, true);
				end
				-- The current player's team
				local team = self:GetTeamOfPlayer(player);

				-- If player brain is dead then try to find another, maybe he just entered craft
				if not MovableMan:IsActor(self:GetPlayerBrain(player)) then
					local newBrain = MovableMan:GetUnassignedBrain(self:GetTeamOfPlayer(player));
					if newBrain then
						self:SetPlayerBrain(newBrain, player);
						self:SwitchToActor(newBrain, player, self:GetTeamOfPlayer(player));
						self:SetObservationTarget(self:GetPlayerBrain(player).Pos, player);
					end
				end

				-- Check if any player's brain is dead and we could not find another
				if not MovableMan:IsActor(self:GetPlayerBrain(player)) then
					self:SetPlayerBrain(nil, player);
					self:ResetMessageTimer(player);
					FrameMan:ClearScreenText(player);
					local str = "Your brain has been destroyed by wave "..self.wave.." at "..self.Difficulty.."% difficulty";
					FrameMan:SetScreenText(str, player, 333, -1, false);
					ConsoleMan:PrintString(str);
				else
					playertally = playertally + 1;
					if not setTeam[team] then
						-- Add objective points
						self:AddObjectivePoint("Protect!", self:GetPlayerBrain(player).AboveHUDPos, team, GameActivity.ARROWDOWN);
						for otherPlayer = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
							if otherPlayer ~= player and self:PlayerActive(otherPlayer) and self:PlayerHuman(otherPlayer) and MovableMan:IsActor(self:GetPlayerBrain(otherPlayer)) then
								local otherTeam = self:GetTeamOfPlayer(otherPlayer);
								if otherTeam ~= team then
									self:AddObjectivePoint("Destroy!", self:GetPlayerBrain(otherPlayer).AboveHUDPos, team, GameActivity.ARROWDOWN);
								else
									self:AddObjectivePoint("Protect!", self:GetPlayerBrain(otherPlayer).AboveHUDPos, team, GameActivity.ARROWDOWN);
								end
							end
						end

						setTeam[team] = true;
						teamtally = teamtally + 1;
					end
				end
			end
		end

		-- Win/Lose Conditions player vs player
		if self.wavesDefeated >= self.wave then
			if self.NextWaveTimer:IsPastRealMS(3000) then
				self.wave = self.wave + 1;
				self.triggerWaveInit = true;
				self.prepareForNextWave = true;
				self.PrepareForNextWaveTimer:Reset();
			else
				for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
					if self:PlayerActive(player) and self:PlayerHuman(player) then
						FrameMan:SetScreenText("Wave "..self.wave.." defeated!", player, 250, 500, true);
					end
				end
			end
		else
			-- Win/Lose Conditions player vs AI
			if playertally < 1 then
				self.WinnerTeam = self.CPUTeam;
				ActivityMan:EndActivity();

				-- Temp fix so music doesn't start playing if ending the Activity when changing resolution through the ingame settings.
				if not self:IsPaused() then
					AudioMan:ClearMusicQueue();
					AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/udiedfinal.ogg", 2, -1.0);
					AudioMan:QueueSilence(10);
					AudioMan:QueueMusicStream("Base.rte/Music/dBSoundworks/ccambient4.ogg");
				end
				return;
			end

			self.AI.LZmap:Update(); -- Update info about landing zones and player actors

			-- Check if any AI actors have reached their destination
			if self.AI.HuntTimer:IsPastSimMS(8000) then
				self.AI.HuntTimer:Reset();

				for Act in MovableMan.Actors do
					if Act.Team == self.CPUTeam and Act.AIMode ~= Actor.AIMODE_GOLDDIG and (Act.ClassName == "AHuman" or Act.ClassName == "ACrab") then
						if (Act.AIMode == Actor.AIMODE_GOTO and SceneMan:ShortestDistance(Act:GetLastAIWaypoint(), Act.Pos, false).Largest < 100) or Act.AIMode == Actor.AIMODE_SENTRY or Act.Age > 60000 then
							-- Destination reached: hunt for the brain
							Act.AIMode = Actor.AIMODE_BRAINHUNT;
						end
					end
				end
			end

			-- The AI have money to buy units
			if self:GetTeamFunds(self.CPUTeam) > 0 then
				if MovableMan:GetTeamMOIDCount(self.CPUTeam) <= rte.AIMOIDMax * 3 / self:GetActiveCPUTeamCount() then
					if self.AI.SpawnTimer:IsPastSimMS(self.AI.timeToSpawn) then
						if self.AI.AttackPos then	-- Search for a LZ from where to attack the target
							local easyPathLZx, easyPathLZobst, closeLZx, closeLZobst = self.AI.LZmap:FindLZ(self.CPUTeam, self.AI.AttackPos);
							if easyPathLZx then	-- Search done
								self.AI.SpawnTimer:Reset();

								local xPosLZ, obstacleHeight;
								if closeLZobst < 25 and easyPathLZobst < 25 then
									if math.random() < 0.5 then
										xPosLZ = closeLZx;
										obstacleHeight = closeLZobst;
									else
										xPosLZ = easyPathLZx;
										obstacleHeight = easyPathLZobst;
									end
								elseif closeLZobst > 100 then
									xPosLZ = easyPathLZx;
									obstacleHeight = easyPathLZobst;
								else
									if math.random() < 0.4 then
										xPosLZ = closeLZx;
										obstacleHeight = closeLZobst;
									else
										xPosLZ = easyPathLZx;
										obstacleHeight = easyPathLZobst;
									end
								end

								if obstacleHeight > 200 and math.random() < 0.4 then
									-- This target is very difficult to reach: cancel this attack and search for another target again soon
									self.AI.timeToSpawn = 500;
									self.AI.AttackTarget = nil;
									self.AI.AttackPos = nil;
								else
									self.AI.timeToSpawn = (self.AI.baseSpawnTime + math.random(self.AI.randomSpawnTime)) * rte.SpawnIntervalScale;

									if obstacleHeight < 30 then
										self:CreateHeavyDrop(xPosLZ, self.AI.AttackPos);
									elseif obstacleHeight < 100 then
										self:CreateMediumDrop(xPosLZ, self.AI.AttackPos);
									elseif obstacleHeight < 250 then
										self:CreateLightDrop(xPosLZ, self.AI.AttackPos);
									else
										self:CreateScoutDrop(xPosLZ, self.AI.AttackPos);

										-- This target is very difficult to reach: change target for the next attack
										self.AI.AttackTarget = nil;
										self.AI.AttackPos = nil;
									end

									if not MovableMan:IsActor(self.AI.AttackTarget) or math.random() < 0.4 then
										-- Change target for the next attack
										self.AI.AttackTarget = nil;
										self.AI.AttackPos = nil;
									else
										self.AI.AttackPos = Vector(self.AI.AttackTarget.Pos.X, self.AI.AttackTarget.Pos.Y);
									end
								end
							end
						else	-- Select a player actor as a target for the next attack
							local safePosX = self.AI.LZmap:FindSafeLZ(self.CPUTeam) or math.random(SceneMan.SceneWidth-1);
							local TargetActors = {};

							for Act in MovableMan.Actors do
								if self.AI.OnPlayerTeam[Act.Team] and (Act.ClassName == "AHuman" or Act.ClassName == "ACrab" or Act.ClassName == "Actor") then
									local distance = 20 * (SceneMan:ShortestDistance(Vector(safePosX, Act.Pos.Y), Act.Pos, false).Largest / SceneMan.SceneWidth);
									distance = distance + self.AI.LZmap:SurfaceProximity(Act.Pos);
									if Act:HasObjectInGroup("Brains") then
										distance = distance * 0.8; -- Increase the likelihood of targeting the brain
									end

									table.insert(TargetActors, {Act=Act, score=distance});
								end
							end

							self.AI.AttackTarget = self:SelectTarget(TargetActors);
							if self.AI.AttackTarget then
								self.AI.AttackPos = Vector(self.AI.AttackTarget.Pos.X, self.AI.AttackTarget.Pos.Y);
							else
								-- No target found
								self.AI.SpawnTimer:Reset();
								self.AI.timeToSpawn = 5000;
							end
						end
					elseif self.AI.EngineerTimer:IsPastSimMS(self.AI.timeToEngineer) then
						self.AI.EngineerTimer:Reset();

						if not self.AI.Engineer or not MovableMan:IsActor(self.AI.Engineer) then
							local digPosX = self.AI.LZmap:FindSafeLZ(self.CPUTeam);
							if digPosX then
								local Craft = RandomACDropShip("Craft", self.AI.Tech); -- Pick a drop-ship to deliver with
								if Craft then
									Craft.Team = self.CPUTeam;
									Craft.Pos = Vector(digPosX, -30); -- Set the spawn point of the craft

									self.AI.Engineer = self:CreateEngineer();
									if self.AI.Engineer then
										Craft:AddInventoryItem(self.AI.Engineer);

										-- Subtract the total value of the craft+cargo from the CPU team's funds
										self:ChangeTeamFunds(-Craft:GetTotalValue(self.AI.TechID, 3), self.CPUTeam);

										-- Spawn the Craft onto the scene
										MovableMan:AddActor(Craft);

										-- Wait a bit longer until the next check
										self.AI.timeToEngineer = self.AI.timeToEngineer * 1.1;
									end
								end
							end
						end
					end

					if self.AI.BombTimer:IsPastSimMS(self.AI.timeToBomb) then
						self.AI.BombTimer:Reset();
						self.AI.timeToBomb = math.random(20, 30) * 1000;

						if math.random() < self.AI.bombChance then
							local bombPosX = self.AI.LZmap:FindBombTarget(self.CPUTeam);
							if bombPosX then
								if self.Difficulty > 45 and math.random() < (0.7-(1-self.Difficulty*0.004)^2) then	-- 3% to 34% chance
									self.AI.bombChance = math.max(self.AI.bombChance*0.96, 0.01);
									self.AI.timeToBomb = self.AI.timeToBomb * 0.75;
									self:CreateTrollDrop(bombPosX);
								else
									self.AI.bombChance = math.max(self.AI.bombChance*0.87, 0.01);
									self:CreateBombDrop(bombPosX);
								end
							end
						end
					end
				end
			else	-- The AI is out of gold
				local enemyPresent = false;
				local objectives = 0;
				for Act in MovableMan.Actors do
					if Act.Team == self.CPUTeam and not Act:IsDead() then
						if Act.ClassName ~= "ADoor" then
							enemyPresent = true;

							-- Add objective points
							if Act.ClassName == "AHuman" or Act.ClassName == "ACrab" then
								objectives = objectives + 1;
								if objectives > 3 then
									break;
								end

								for team = self.playerTeam, Activity.TEAM_4 do
									self:AddObjectivePoint("Destroy!", Act.AboveHUDPos, team, GameActivity.ARROWDOWN);
								end
							end
						end
					end
				end

				-- No AI actors left, remove the CPU-Team
				if not enemyPresent then
					self.wavesDefeated = self.wavesDefeated + 1;
					self.NextWaveTimer:Reset();
				end
			end
		end
	end
end

-- Pick an actor semi-randomly, with a larger probablility for actors with a lower score
function WaveDefense:SelectTarget(TargetActors)
	if #TargetActors > 1 then
		table.sort(TargetActors, function(A, B) return A.score < B.score end); -- Actors closer to the surface first

		local temperature = 5; -- a higher temperature means less random selection
		local sum = 0;
		local worstScore = TargetActors[#TargetActors].score;

		-- normalize the score
		for i, Data in pairs(TargetActors) do
			TargetActors[i].chance = 1 - Data.score / worstScore;
			sum = sum + math.exp(temperature*TargetActors[i].chance);
		end

		-- use Softmax to pick one of the n best LZs
		if sum > 0 then
			local pick = math.random() * sum;
			sum = 0;
			for _, Data in pairs(TargetActors) do
				sum = sum + math.exp(temperature*Data.chance);
				if sum >= pick then
					return Data.Act;
				end
			end
		end

		return TargetActors[1].Act;
	elseif #TargetActors == 1 then
		return TargetActors[1].Act;
	end
end

function WaveDefense:CreateHeavyDrop(xPosLZ, Destination)
	local Craft = RandomACDropShip("Craft", self.AI.Tech); -- Pick a craft to deliver with
	if Craft then
		-- The max allowed weight of this craft's cargo
		local craftMaxMass = Craft.MaxInventoryMass;
		if craftMaxMass < 0 then
			craftMaxMass = math.huge;
		elseif craftMaxMass < 1 then
			Craft = RandomACDropShip("Craft", 0); -- MaxMass not defined
			craftMaxMass = Craft.MaxInventoryMass;
		end

		Craft.Team = self.CPUTeam;
		Craft.Pos = Vector(xPosLZ, -30); -- Set the spawn point of the craft

		local passengers;
		if Craft.MaxPassengers < 2 then
			passengers = 1;
		elseif Craft.MaxPassengers > 2 then
			passengers = math.random(2, Craft.MaxPassengers);
		else
			passengers = 2;
		end

		local crabRatio = self:GetCrabToHumanSpawnRatio(PresetMan:GetModuleID(self.AI.Tech));
		for _ = 1, passengers do
			local Passenger;
			if crabRatio > 0 and math.random() < crabRatio + self.Difficulty / 800 then
				Passenger = self:CreateCrab();
			elseif RangeRand(0, 105) < self.Difficulty then
				Passenger = self:CreateHeavyInfantry();
			else
				Passenger = self:CreateRandomInfantry();
			end

			if Passenger then
				if Destination then
					Passenger.AIMode = Actor.AIMODE_GOTO;
					Passenger:AddAISceneWaypoint(Destination);
				end

				Craft:AddInventoryItem(Passenger);

				if Craft.InventoryMass > craftMaxMass or Craft:GetTotalValue(self.AI.TechID, 3) > self:GetTeamFunds(self.CPUTeam) then
					break;
				end
			end
		end

		-- Subtract the total value of the craft+cargo from the CPU team's funds
		self:ChangeTeamFunds(-Craft:GetTotalValue(self.AI.TechID, 3), self.CPUTeam);

		-- Spawn the Craft onto the scene
		MovableMan:AddActor(Craft);
	end
end

function WaveDefense:CreateMediumDrop(xPosLZ, Destination)
	-- Pick a craft to deliver with
	local Craft, actorsInCargo;
	if math.random() < 0.6 then
		Craft = RandomACDropShip("Craft", self.AI.Tech);
		if Craft.MaxPassengers < 2 then
			actorsInCargo = 1;
		elseif Craft.MaxPassengers > 2 then
			actorsInCargo = math.random(2, Craft.MaxPassengers);
		else
			actorsInCargo = 2;
		end
	else
		Craft = RandomACRocket("Craft", self.AI.Tech);
		actorsInCargo = Craft.MaxPassengers;
	end

	if Craft then
		-- The max allowed weight of this craft's cargo
		local craftMaxMass = Craft.MaxInventoryMass;
		if craftMaxMass < 0 then
			craftMaxMass = math.huge;
		elseif craftMaxMass < 1 then
			if Craft.ClassName == "ACDropship" then
				Craft = RandomACDropShip("Craft", 0); -- MaxMass not defined
			else
				Craft = RandomACRocket("Craft", 0); -- MaxMass not defined
			end
			craftMaxMass = Craft.MaxInventoryMass;
		end

		Craft.Team = self.CPUTeam;
		Craft.Pos = Vector(xPosLZ, -30); -- Set the spawn point of the craft

		for _ = 1, actorsInCargo do
			local Passenger;
			if RangeRand(-5, 125) < self.Difficulty then
				Passenger = self:CreateMediumInfantry();
			elseif math.random() < 0.65 then
				Passenger = self:CreateRandomInfantry();
			else
				Passenger = self:CreateLightInfantry();
			end

			if Passenger then
				if Destination then
					Passenger.AIMode = Actor.AIMODE_GOTO;
					Passenger:AddAISceneWaypoint(Destination);
				end

				Craft:AddInventoryItem(Passenger);

				if Craft.InventoryMass > craftMaxMass or Craft:GetTotalValue(self.AI.TechID, 3) > self:GetTeamFunds(self.CPUTeam) then
					break;
				end
			end
		end

		-- Subtract the total value of the craft+cargo from the CPU team's funds
		self:ChangeTeamFunds(-Craft:GetTotalValue(self.AI.TechID, 3), self.CPUTeam);

		-- Spawn the Craft onto the scene
		MovableMan:AddActor(Craft);
	end
end

function WaveDefense:CreateLightDrop(xPosLZ, Destination)
	-- Pick a craft to deliver with
	local Craft;
	if math.random() < 0.6 then
		Craft = RandomACDropShip("Craft", self.AI.Tech);
	else
		Craft = RandomACRocket("Craft", self.AI.Tech);
	end

	if Craft then
		-- The max allowed weight of this craft plus cargo
		local craftMaxMass = Craft.MaxInventoryMass;
		if craftMaxMass < 0 then
			craftMaxMass = math.huge;
		elseif craftMaxMass < 1 then
			if Craft.ClassName == "ACDropship" then
				Craft = RandomACDropShip("Craft", 0); -- MaxMass not defined
			else
				Craft = RandomACRocket("Craft", 0); -- MaxMass not defined
			end
			craftMaxMass = Craft.MaxInventoryMass;
		end

		Craft.Team = self.CPUTeam;
		Craft.Pos = Vector(xPosLZ, -30); -- Set the spawn point of the craft

		for _ = 1, Craft.MaxPassengers do
			local Passenger;
			if RangeRand(10, 200) < self.Difficulty then
				Passenger = self:CreateMediumInfantry();
			else
				Passenger = self:CreateLightInfantry();
			end

			if Passenger then
				if Destination then
					Passenger.AIMode = Actor.AIMODE_GOTO;
					Passenger:AddAISceneWaypoint(Destination);
				end

				Craft:AddInventoryItem(Passenger);

				if Craft.InventoryMass > craftMaxMass or Craft:GetTotalValue(self.AI.TechID, 3) > self:GetTeamFunds(self.CPUTeam) then
					break;
				end
			end
		end

		-- Subtract the total value of the craft+cargo from the CPU team's funds
		self:ChangeTeamFunds(-Craft:GetTotalValue(self.AI.TechID, 3), self.CPUTeam);

		-- Spawn the Craft onto the scene
		MovableMan:AddActor(Craft);
	end
end

function WaveDefense:CreateScoutDrop(xPosLZ, Destination)
	-- Pick a craft to deliver with
	local Craft;
	if math.random() < 0.6 then
		Craft = RandomACDropShip("Craft", self.AI.Tech);
	else
		Craft = RandomACRocket("Craft", self.AI.Tech);
	end

	if Craft then
		-- The max allowed weight of this craft plus cargo
		local craftMaxMass = Craft.MaxInventoryMass;
		if craftMaxMass < 0 then
			craftMaxMass = math.huge;
		elseif craftMaxMass < 1 then
			if Craft.ClassName == "ACDropship" then
				Craft = RandomACDropShip("Craft", 0); -- MaxMass not defined
			else
				Craft = RandomACRocket("Craft", 0); -- MaxMass not defined
			end
			craftMaxMass = Craft.MaxInventoryMass;
		end

		Craft.Team = self.CPUTeam;
		Craft.Pos = Vector(xPosLZ, -30); -- Set the spawn point of the craft

		for _ = 1, Craft.MaxPassengers do
			local Passenger;
			if math.random() < 0.35 then
				Passenger = self:CreateLightInfantry();
			else
				Passenger = self:CreateScoutInfantry();
			end

			if Passenger then
				if Destination then
					Passenger.AIMode = Actor.AIMODE_GOTO;
					Passenger:AddAISceneWaypoint(Destination);
				end

				Craft:AddInventoryItem(Passenger);

				if Craft.InventoryMass > craftMaxMass or Craft:GetTotalValue(self.AI.TechID, 3) > self:GetTeamFunds(self.CPUTeam) then
					break;
				end
			end
		end

		-- Subtract the total value of the craft+cargo from the CPU team's funds
		self:ChangeTeamFunds(-Craft:GetTotalValue(self.AI.TechID, 3), self.CPUTeam);

		-- Spawn the Craft onto the scene
		MovableMan:AddActor(Craft);
	end
end

function WaveDefense:CreateBombDrop(bombPosX)
	local Craft = RandomACDropShip("Craft", self.AI.Tech); -- Pick a craft to deliver with
	if Craft then
		-- The max allowed weight of this craft plus cargo
		local craftMaxMass = Craft.MaxInventoryMass;
		if craftMaxMass < 0 then
			craftMaxMass = math.huge;
		elseif craftMaxMass < 1 then
			Craft = RandomACDropShip("Craft", 0); -- MaxMass not defined
			craftMaxMass = Craft.MaxInventoryMass;
		end

		Craft.AIMode = Actor.AIMODE_BOMB; -- DropShips open doors at a high altitude in bomb mode
		Craft.Team = self.CPUTeam;
		Craft.Pos = Vector(bombPosX, -30); -- Set the spawn point of the craft

		for _ = 3, 5 do
			Craft:AddInventoryItem(RandomTDExplosive("Bombs - Payloads", self.AI.Tech));

			if Craft.InventoryMass > craftMaxMass or Craft:GetTotalValue(self.AI.TechID, 3) > self:GetTeamFunds(self.CPUTeam) then
				break;
			end
		end

		-- Subtract the total value of the craft+cargo from the CPU team's funds
		self:ChangeTeamFunds(-Craft:GetTotalValue(self.AI.TechID, 3), self.CPUTeam);

		-- Spawn the Craft onto the scene
		MovableMan:AddActor(Craft);
	end
end

function WaveDefense:CreateTrollDrop(bombPosX)
	local Craft = RandomACRocket("Craft - Crates", self.AI.Tech); -- Pick a crate to deliver with
	if Craft then
		Craft.Team = self.CPUTeam;
		Craft.Pos = Vector(bombPosX, -30); -- Set the spawn point of the craft

		local Passenger = CreateAHuman("Culled Clone", "Base.rte");
		if Passenger then
			Passenger:AddInventoryItem(RandomTDExplosive("Bombs - Payloads", self.AI.Tech));
			Craft:AddInventoryItem(Passenger);
		end

		-- Subtract the total value of the craft+cargo from the CPU team's funds
		self:ChangeTeamFunds(-Craft:GetTotalValue(self.AI.TechID, 3), self.CPUTeam);

		-- Spawn the Craft onto the scene
		MovableMan:AddActor(Craft);
	end
end


function WaveDefense:CreateCrab()
	local Passenger = RandomACrab("Actors - Mecha", self.AI.Tech);
	if Passenger then
		Passenger.AIMode = Actor.AIMODE_BRAINHUNT;
		Passenger.Team = self.CPUTeam;
		return Passenger;
	end
end

-- Get any Actor from the CPU's native tech
function WaveDefense:CreateRandomInfantry()
	local Passenger = RandomAHuman("Any", self.AI.Tech);
	if Passenger then
		Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Primary", self.AI.Tech));
		Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.AI.Tech));

		local rand = math.random();
		if rand < 0.25 then
			Passenger:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", self.AI.Tech));
		elseif rand < 0.50 then
			Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.AI.Tech));
		elseif rand < 0.75 then
			Passenger:AddInventoryItem(RandomHeldDevice("Shields", self.AI.Tech));
		else
			Passenger:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
		end
		if math.random() < 0.05 then
			Passenger:AddInventoryItem(RandomHDFirearm("Tools - Breaching", self.AI.Tech));
		end

		Passenger.AIMode = Actor.AIMODE_BRAINHUNT;
		Passenger.Team = self.CPUTeam;
		return Passenger;
	end
end

function WaveDefense:CreateLightInfantry()
	local Passenger = RandomAHuman("Actors - Light", self.AI.Tech);
	if Passenger.ModuleID ~= self.AI.TechID then
		Passenger = RandomAHuman("Actors", self.AI.TechID);
	end

	if Passenger then
		Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Light", self.AI.Tech));
		Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.AI.Tech));

		local rand = math.random();
		if rand < 0.5 then
			Passenger:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", self.AI.Tech));
		elseif rand < 0.8 then
			Passenger:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
		else
			Passenger:AddInventoryItem(RandomHDFirearm("Tools - Breaching", self.AI.Tech));
		end

		Passenger.AIMode = Actor.AIMODE_BRAINHUNT;
		Passenger.Team = self.CPUTeam;
		return Passenger;
	end
end

function WaveDefense:CreateHeavyInfantry()
	local Passenger = RandomAHuman("Actors - Heavy", self.AI.Tech);
	if Passenger.ModuleID ~= self.AI.TechID then
		Passenger = RandomAHuman("Actors", self.AI.TechID);
	end

	if Passenger then
		Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Heavy", self.AI.Tech));

		if math.random() < 0.3 then
			Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Light", self.AI.Tech));
			if math.random() < 0.25 then
				Passenger:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", self.AI.Tech));
			elseif math.random() < 0.35 then
				Passenger:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
			end
		else
			Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.AI.Tech));
			if math.random() < 0.3 then
				Passenger:AddInventoryItem(RandomHeldDevice("Shields", self.AI.Tech));
				Passenger:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
			else
				Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.AI.Tech));
			end
		end

		Passenger.AIMode = Actor.AIMODE_BRAINHUNT;
		Passenger.Team = self.CPUTeam;
		return Passenger;
	end
end

function WaveDefense:CreateMediumInfantry()
	local Passenger = RandomAHuman("Actors - Heavy", self.AI.Tech);
	if Passenger.ModuleID ~= self.AI.TechID then
		Passenger = RandomAHuman("Actors", self.AI.TechID);
	end

	if Passenger then
		Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Light", self.AI.Tech));
		Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.AI.Tech));

		if math.random() < 0.3 then
			Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.AI.Tech));
		else
			Passenger:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", self.AI.Tech));
		end
		if math.random() < 0.5 then
			Passenger:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
		end

		Passenger.AIMode = Actor.AIMODE_BRAINHUNT;
		Passenger.Team = self.CPUTeam;
		return Passenger;
	end
end

function WaveDefense:CreateEngineer()
	local Passenger = RandomAHuman("Actors - Light", self.AI.Tech);
	if Passenger.ModuleID ~= self.AI.TechID then
		Passenger = RandomAHuman("Actors", self.AI.TechID);
	end

	if Passenger then
		if math.random() < 0.7 then
			Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Light", self.AI.Tech));
		else
			Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.AI.Tech));
			local rand = math.random();
			if rand < 0.2 then
				Passenger:AddInventoryItem(RandomHeldDevice("Shields", self.AI.Tech));
			elseif rand < 0.4 then
				Passenger:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
			else
				Passenger:AddInventoryItem(RandomTDExplosive("Tools - Breaching", self.AI.Tech));
			end
		end
		Passenger:AddInventoryItem(RandomHDFirearm("Tools - Diggers", self.AI.Tech));

		Passenger.AIMode = Actor.AIMODE_GOLDDIG;
		Passenger.Team = self.CPUTeam;
		return Passenger;
	end
end

function WaveDefense:CreateScoutInfantry()
	local Passenger = RandomAHuman("Actors - Light", self.AI.Tech);
	if Passenger.ModuleID ~= self.AI.TechID then
		Passenger = RandomAHuman("Actors", self.AI.TechID);
	end

	if Passenger then
		if math.random() < 0.15 then
			Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Sniper", self.AI.Tech));
		end
		Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.AI.Tech));

		if math.random() < 0.3 then
			Passenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.AI.Tech));
		else
			Passenger:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", self.AI.Tech));
			Passenger:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
		end

		Passenger.AIMode = Actor.AIMODE_BRAINHUNT;
		Passenger.Team = self.CPUTeam;
		return Passenger;
	end
end

-- Get the total MOIDFootprint of the player's actors
function WaveDefense:GetPlayerMOIDCount()
	local playerMOID = 0;
	for Act in MovableMan.Actors do
		if Act.Team == self.playerTeam then
			playerMOID = playerMOID + Act.MOIDFootprint;
		end
	end

	return playerMOID;
end

-- Make sure there are enough MOIDs to land AI units
function WaveDefense:EnforceMOIDLimit()
	local ids = self:GetPlayerMOIDCount() - rte.MOIDCountMax * 0.8;
	if ids > 0 then
		local Prune = {};
		for Item in MovableMan.Items do
			table.insert(Prune, Item);
		end

		-- Sort the tables so we delete the oldest object first
		table.sort(Prune, function(A, B) return A.Age < B.Age end);

		while true do
			local Object = table.remove(Prune);
			if Object then
				Object.ToSettle = true;

				ids = ids - Object.MOIDFootprint;
				if ids < 1 then
					break;
				end
			else
				break;
			end
		end
	end
end
