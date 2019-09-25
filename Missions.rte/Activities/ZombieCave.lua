package.loaded.Constants = nil; require("Constants");

-----------------------------------------------------------------------------------------
-- Start Activity
-----------------------------------------------------------------------------------------

function ZombieCaveMission:StartActivity()
	print("START! -- ZombieCaveMission:StartActivity()!");

	self.FightStage = { BEGINFIGHT = 0, OUTERCAVE = 1, INNERCAVE = 2, AMBUSH = 3, FIGHTSTAGECOUNT = 4 };

	self.AreaTimer = Timer();
	self.StepTimer = Timer();
	self.SpawnTimer = Timer();
	self.BombSpawnTimer = Timer();
	self.BombSpawnTimer2 = Timer();
	self.ScreenChange = false;
	self.bombPickupArea = SceneMan.Scene:GetArea("Bomb Pickup");
	self.bombPickupArea2 = SceneMan.Scene:GetArea("Bomb Pickup 2");
	self.caveArea = SceneMan.Scene:GetArea("Cave");
	self.innerCaveArea = SceneMan.Scene:GetArea("Inner Cave");
	self.artifactArea = SceneMan.Scene:GetArea("Artifact Pickup");
	self.CurrentFightStage = self.FightStage.BEGINFIGHT;
	self.BrainHasLanded = false;
	self.CPUBrain = nil;
	self.CPUTechName = "Ronin.rte"
	self.braindead = {};

	--------------------------
	-- Set up teams

	-- Team 2 is always zombie
	self.ZombieTeam = Activity.TEAM_2;

	-- Create the zombie generators and place them in the scene
	self.Generator1 = CreateAEmitter("Zombie Generator");
	self.Generator1.Pos = SceneMan.Scene:GetArea("Zombie Generator 1"):GetCenterPoint() --Vector(339, 219);
	self.Generator1.Team = self.ZombieTeam;
	self.Generator1:EnableEmission(false);
	MovableMan:AddParticle(self.Generator1);

	self.Generator2 = CreateAEmitter("Zombie Generator");
	self.Generator2.Pos = SceneMan.Scene:GetArea("Zombie Generator 2"):GetCenterPoint(); --Vector(1078, 214);
	self.Generator2.Team = self.ZombieTeam;
	self.Generator2:EnableEmission(false);
	MovableMan:AddParticle(self.Generator2);

	-- Create the bomb makers and place them in the scene
	self.BombMaker1 = CreateAEmitter("Bomb Maker");
	self.BombMaker1.Pos = Vector(468, 276);
	self.BombMaker1.RotAngle = 5.1;
	self.BombMaker1.Team = self.ZombieTeam;
	self.BombMaker1:EnableEmission(false);
	MovableMan:AddParticle(self.BombMaker1);

	self.BombMaker2 = CreateAEmitter("Bomb Maker");
	self.BombMaker2.Pos = Vector(1128, 276);
	self.BombMaker2.RotAngle = 5.9;
	self.BombMaker2.Team = self.ZombieTeam;
	self.BombMaker2:EnableEmission(false);
	MovableMan:AddParticle(self.BombMaker2);

	self.ControlCase = CreateMOSRotating("Control Chip Case");
	self.ControlCase.Pos = Vector(203, 494);
	self.ControlCase.Team = self.ZombieTeam;
	MovableMan:AddParticle(self.ControlCase);

	--------------------------
	-- Set up players

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			-- Check if we already have a brain assigned - but don't worry if this is a human-controlled zombie team!
			if not self:GetPlayerBrain(player) and self:GetTeamOfPlayer(player) ~= self.ZombieTeam then
				self.braindead[player] = false;
				--local foundBrain = MovableMan:GetUnassignedBrain(self:GetTeamOfPlayer(player));
				-- Create a rocket with a brain bot inside instead
				local rocket = CreateACRocket("Rocket MK1");
				local brainBot = CreateAHuman("Brain Robot");
				local gun = CreateHDFirearm("Pistol");
				brainBot:AddInventoryItem(gun);
				brainBot.AIMode = Actor.AIMODE_SENTRY;
				rocket:AddInventoryItem(brainBot);

				rocket.Pos = Vector(3100 - 50 * (player + 1), -50);
				rocket.Team = self:GetTeamOfPlayer(player);
				rocket:SetControllerMode(Controller.CIM_AI, -1);
				-- Let the spawn into the world, passing ownership
				MovableMan:AddActor(rocket);
				foundBrain = rocket;

				-- If we can't find an unassigned brain in the scene to give each player, then force to go into editing mode to place one
				if not foundBrain then
					self.ActivityState = Activity.EDITING;
					AudioMan:ClearMusicQueue();
					AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/ccambient4.ogg", -1, -1);
				else
					-- Set the found brain to be the selected actor at start
					self:SetPlayerBrain(foundBrain, player);
					self:SetViewState(Activity.ACTORSELECT, player);
	--				self:SwitchToActor(foundBrain, player, self:GetTeamOfPlayer(player));
	--				SceneMan:SetScroll(self:GetPlayerBrain(player).Pos, player);
					self:SetActorSelectCursor(Vector(3024, 324), player);
					self:SetLandingZone(self:GetPlayerBrain(player).Pos, player);
					-- Set the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
					self:SetObservationTarget(self:GetPlayerBrain(player).Pos, player)
				end
			end
		end
	end

	-- Set up AI modes for the Actors that have been added to the scene by the scene definition
	for actor in MovableMan.AddedActors do
		if actor.Team == self.ZombieTeam then
			actor.AIMode = Actor.AIMODE_PATROL;
		end
	end

	-- Set up the landing zones
	self:SetLZArea(Activity.TEAM_1, SceneMan.Scene:GetArea("LZ Team 1"));
	self:SetLZArea(Activity.TEAM_2, SceneMan.Scene:GetArea("LZ Team 2"));
	self:SetBrainLZWidth(Activity.PLAYER_1, 0);
	self:SetBrainLZWidth(Activity.PLAYER_2, 0);
	self:SetBrainLZWidth(Activity.PLAYER_3, 0);
	self:SetBrainLZWidth(Activity.PLAYER_4, 0);
	
	--------------------------
	-- Set up tutorial

	self.AreaTimer:Reset();
	self.StepTimer:Reset();
	self.SpawnTimer:Reset();

end

-----------------------------------------------------------------------------------------
-- Update Activity
-----------------------------------------------------------------------------------------

function ZombieCaveMission:MakeEnemy(whichMode)
	local passenger = RandomAHuman("Any", self.CPUTechName)
	if passenger then
		passenger:AddInventoryItem(RandomHDFirearm("Primary Weapons", self.CPUTechName));
		passenger:AddInventoryItem(RandomHDFirearm("Secondary Weapons", self.CPUTechName));
		if PosRand() < 0.25 then
			passenger:AddInventoryItem(RandomHDFirearm("Diggers", self.CPUTechName));
		end
	end
	
	passenger.AIMode = whichMode or 0;
	return passenger;
end


function ZombieCaveMission:EndActivity()
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


function ZombieCaveMission:UpdateActivity()
	-- Avoid game logic when we're editing
	if (self.ActivityState == Activity.EDITING) then
-- Don't update the editing, it's being done already by GameActivity
--		self:UpdateEditing();
		return;
	end

	--------------------------
	-- Iterate through all human players

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			-- The current player's team
			local team = self:GetTeamOfPlayer(player);

			-- Make sure the game is not already ending
			if not (self.ActivityState == Activity.OVER) then
				-- Defending Zombie team
				if team == self.ZombieTeam then
					
				-- Player team
				else
					-- Check if any of the attacking player's brain is dead
					local brain = self:GetPlayerBrain(player);
					if not brain or not MovableMan:IsActor(brain) or not brain:HasObjectInGroup("Brains") then
						self:SetPlayerBrain(nil, player);
						-- Try to find a new unasigned brain this player can use instead, or if his old brain entered a craft
						local newBrain = MovableMan:GetUnassignedBrain(team);
						-- Found new brain actor, assign it and keep on truckin'
						if newBrain and self.braindead[player] == false then
							self:SetPlayerBrain(newBrain, player);
							if MovableMan:IsActor(newBrain) then
								self:SwitchToActor(newBrain, player, team);
							end
						else				
							FrameMan:SetScreenText("Your brain has been lost!", player, 333, -1, false);
							self.braindead[player] = true;
							-- Now see if all brains of self player's team are dead, and if so, end the game
							if not MovableMan:GetFirstBrainActor(team) then
								self.WinnerTeam = self:OtherTeam(team);
								ActivityMan:EndActivity();
							end
							self:ResetMessageTimer(player);
						end
					else
						-- Update the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
						self:SetObservationTarget(brain.Pos, player)
					end
				end
			-- Game over, show the appropriate messages until a certain time
			elseif not self.GameOverTimer:IsPastSimMS(self.GameOverPeriod) then
	-- TODO: make more appropriate messages here for run out of funds endings
				if team == self.WinnerTeam then
					FrameMan:SetScreenText("Well done, you retrieved the item!", player, 0, -1, false);
				else
					FrameMan:SetScreenText("Your brain has been lost!", player, 0, -1, false);
				end
			end
		end
	end

	------------------------------------------------
	-- Iterate through all teams

	for team = Activity.TEAM_1, Activity.MAXTEAMCOUNT - 1 do
		if self:TeamActive(team) then
			-------------------------------------------
			-- Check for victory conditions
		   
			-- Make sure the game isn't already ending
			if (not (self.ActivityState == Activity.OVER)) and (not (team == self.ZombieTeam)) then
		   
			end
		end
	end
	
	--------------------------------------------
	-- Battle logic

	-- See if the player has any guys in the cave
	local playerInCave = false;
	for actor in MovableMan.Actors do
		if actor.Team == Activity.TEAM_1 and self.caveArea:IsInside(actor.Pos) then
			playerInCave = true;
			break;
		end
	end

	-- See if the player has any guys in the inner cave
	local playerInInnerCave = false;
	for actor in MovableMan.Actors do
		if actor.Team == Activity.TEAM_1 and self.innerCaveArea:IsInside(actor.Pos) then
			playerInInnerCave = true;
			break;
		end
	end

	-- See if the player has any guys in the artifact area.
	local playerInArtifactArea = false;
	for actor in MovableMan.Actors do
		if actor.Team == Activity.TEAM_1 and self.artifactArea:IsInside(actor.Pos) then
			playerInArtifactArea = true;
			break;
		end
	end

	if self.CurrentFightStage < self.FightStage.OUTERCAVE and playerInCave then
		self.CurrentFightStage = self.FightStage.OUTERCAVE;
	end
		
	if self.CurrentFightStage < self.FightStage.INNERCAVE and playerInInnerCave then
		self.CurrentFightStage = self.FightStage.INNERCAVE;
	end

	local genOuterEnabled = self.CurrentFightStage >= self.FightStage.OUTERCAVE;
	local genInnerEnabled = playerInCave or self.Generator2 ==  nil;
	
	-- OUTER CAVE BATTLE
	-- See if the outer generator is still alive
	if MovableMan:IsParticle(self.Generator2) then
		-- OUTER BOMB SPAWN
		-- See if we need a new bomb
		local bombCount = 0;
		for item in MovableMan.Items do
			-- See if there's a bomb in the pickup zone already, so we don't need to plop oiut a new one
			if self.bombPickupArea2:IsInside(item.Pos) and item.PresetName == "Blue Bomb" then
				bombCount = bombCount + 1;
			end
		end
		-- Plop out new bombs if there aren't enough
		self.BombMaker2:EnableEmission(bombCount < 1);
	
		-- Enable/disable the zombie generator as ordered
		self.Generator2:EnableEmission(genOuterEnabled);
	else
		self.Generator2 = nil;
		self.BombMaker2:EnableEmission(false);
	end
	
	-- INNER CAVE BATTLE
	-- Check if the generators are still alive, and if so, have the active only when the player is in the cave
	if MovableMan:IsParticle(self.Generator1) then
		-- INNER BOMB SPAWN
		-- Determine if we need a new bomb
		local bombCount = 0;
		for item in MovableMan.Items do
			-- See if there's a bomb in the pickup zone already, so we don't need to plop oiut a new one
			if self.bombPickupArea:IsInside(item.Pos) and item.PresetName == "Blue Bomb" then
				bombCount = bombCount + 1;
			end
		end
		-- Plop out the new bomb if there aren't enough
		self.BombMaker1:EnableEmission(bombCount < 2);

		-- Enable/disable the zombie generator as ordered
		self.Generator1:EnableEmission(genInnerEnabled);
	else
		self.Generator1 = nil;
		self.BombMaker1:EnableEmission(false);
	end

	-- MARK THE OBJECTIVES
	-- Clear all objective markers, they get re-added each frame
	self:ClearObjectivePoints();

	if not (self.ActivityState == Activity.OVER) then
		-- Control box
		if MovableMan:IsParticle(self.ControlCase) then
			self:AddObjectivePoint("Destroy!", self.ControlCase.AboveHUDPos, Activity.TEAM_1, GameActivity.ARROWDOWN);
			self:AddObjectivePoint("Protect!", self.ControlCase.AboveHUDPos, self.ZombieTeam, GameActivity.ARROWDOWN);
		else
			self.ControlCase = nil;
		end
		
		-- Chip on the ground
		for item in MovableMan.Items do
			if item:HasObject("Control Chip") then
				self:AddObjectivePoint("Pick up!", item.AboveHUDPos, Activity.TEAM_1, GameActivity.ARROWDOWN);
				self:AddObjectivePoint("Protect!", item.AboveHUDPos, self.ZombieTeam, GameActivity.ARROWDOWN);
			end
		end
		
		-- Actor markers
		local team1Count = 0;
		for actor in MovableMan.Actors do
			if actor.Team == Activity.TEAM_1 and actor:IsInGroup("Brains") then
				team1Count = team1Count + 1;
			end
			
			if actor:HasObject("Control Chip") then
				if actor:IsInGroup("Craft") then
					self:AddObjectivePoint("Launch into orbit!", actor.AboveHUDPos + Vector(0, -32), Activity.TEAM_1, GameActivity.ARROWUP);
					self:AddObjectivePoint("Destroy!", actor.AboveHUDPos + Vector(0, -32), self.ZombieTeam, GameActivity.ARROWUP);
				elseif self.caveArea:IsInside(actor.Pos) then
					self:AddObjectivePoint("Carry chip outside!", actor.AboveHUDPos + Vector(80, 0), Activity.TEAM_1, GameActivity.ARROWRIGHT);
					self:AddObjectivePoint("KILL!", actor.AboveHUDPos + Vector(80, 0), self.ZombieTeam, GameActivity.ARROWUP);
				else
					self:AddObjectivePoint("Load into a ship!", actor.AboveHUDPos, Activity.TEAM_1, GameActivity.ARROWDOWN);
					self:AddObjectivePoint("KILL!", actor.AboveHUDPos, self.ZombieTeam, GameActivity.ARROWDOWN);
				end
			end
			if actor:HasObjectInGroup("Brains") then
				self:AddObjectivePoint("Protect!", actor.AboveHUDPos, Activity.TEAM_1, GameActivity.ARROWDOWN);
				self:AddObjectivePoint("Destroy!", actor.AboveHUDPos, self.ZombieTeam, GameActivity.ARROWDOWN);
			end
		end
		
		if self.BrainHasLanded and team1Count < 1 then
			self:AddObjectivePoint("Buy more bodies to help you!", Vector(3060, 340), Activity.TEAM_1, GameActivity.ARROWDOWN);
		end
		
		-- Sort the objective points
		self:YSortObjectivePoints();
	end

	-- AMBUSH STAGE
	-- Triggered ambush stage
	if self.CurrentFightStage ~= self.FightStage.AMBUSH and playerInArtifactArea == true then
		 -- See if there is a designated LZ Area for attackers, and only land over it
		local attackLZ = SceneMan.Scene:GetArea("LZ Team 2");
		if attackLZ then
			-- Take over control of screen messages
			self:ResetMessageTimer(Activity.PLAYER_1);
			-- Display the text of the current step
			for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
				if self:PlayerActive(player) and self:PlayerHuman(player) then
					FrameMan:ClearScreenText(player);
					FrameMan:SetScreenText("UNKNOWN HOSTILES ARE LANDING AT THE CAVE ENTRANCE!", player, 500, 8000, true);
				end
			end
			-- Ship1 crew goes to investigate cave, ship2 goes to kill the player brain
			local ship1 = CreateACDropShip("Drop Ship MK1");
			local ronin = self:MakeEnemy(Actor.AIMODE_GOTO);
			ronin:ClearAIWaypoints();
			ronin:AddAISceneWaypoint(Vector(200, 500));
			ship1:AddInventoryItem(ronin);
			ronin = self:MakeEnemy(Actor.AIMODE_GOTO);
			ronin:ClearAIWaypoints();
			ronin:AddAISceneWaypoint(Vector(200, 500));
			ship1:AddInventoryItem(ronin);
			local ship2 = CreateACDropShip("Drop Ship MK1");
			ship2:AddInventoryItem(self:MakeEnemy(Actor.AIMODE_BRAINHUNT));
			ship2:AddInventoryItem(self:MakeEnemy(Actor.AIMODE_BRAINHUNT));

			-- Only land over the proper LZ
			ship1.Pos.X = attackLZ:GetRandomPoint().X;
			ship2.Pos.X = 2300;
			ship1.Pos.Y = 0;
			ship2.Pos.Y = -50;
			ship1.Team = self.ZombieTeam;
			ship2.Team = self.ZombieTeam;
			
			-- Let the spawn into the world, passing ownership
			MovableMan:AddActor(ship1);
			MovableMan:AddActor(ship2);

			-- Advance the stage
			self.CurrentFightStage = self.FightStage.AMBUSH;
		end
	end

	-- Any ronin guys who reach the innermost cave, should go brain hunt afterward
	if self.CurrentFightStage == self.FightStage.AMBUSH then
		for actor in MovableMan.Actors do
			if actor.Team == self.ZombieTeam and self.artifactArea:IsInside(actor.Pos) then
				actor.AIMode = Actor.AIMODE_BRAINHUNT;
			end
		end
	end
end

-----------------------------------------------------------------------------------------
-- Craft Entered Orbit
-----------------------------------------------------------------------------------------

function ZombieCaveMission:CraftEnteredOrbit()
	-- The intiial rocket has delivered the brain
	self.BrainHasLanded = true;
	-- This is set to the ACraft that just entered orbit
	if self.OrbitedCraft:HasObject("Control Chip") then
		-- WINRAR!
		self.WinnerTeam = Activity.TEAM_1;
		ActivityMan:EndActivity();
	end
end
