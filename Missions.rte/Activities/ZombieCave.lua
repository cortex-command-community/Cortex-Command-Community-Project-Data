package.loaded.Constants = nil;
require("Constants");

function ZombieCaveMission:StartActivity(isNewGame)
	self.bombPickupArea = SceneMan.Scene:GetArea("Bomb Pickup");
	self.bombPickupArea2 = SceneMan.Scene:GetArea("Bomb Pickup 2");
	self.caveArea = SceneMan.Scene:GetArea("Cave");
	self.innerCaveArea = SceneMan.Scene:GetArea("Inner Cave");
	self.artifactArea = SceneMan.Scene:GetArea("Artifact Pickup");

	self.fightStage = { beginFight = 0, outerCave = 1, innerCave = 2, ambush = 3 };

	--TODO this stuff may be totally pointless, but I don't really wanna do the testing.
	self:SetLZArea(Activity.TEAM_1, SceneMan.Scene:GetArea("LZ Team 1"));
	self:SetLZArea(Activity.TEAM_2, SceneMan.Scene:GetArea("LZ Team 2"));
	self:SetBrainLZWidth(Activity.PLAYER_1, 0);
	self:SetBrainLZWidth(Activity.PLAYER_2, 0);
	self:SetBrainLZWidth(Activity.PLAYER_3, 0);
	self:SetBrainLZWidth(Activity.PLAYER_4, 0);

	self.zombieTeam = Activity.NOTEAM;
	self.humanTeam = Activity.TEAM_1;
	self.ambusherTeam = Activity.TEAM_2;
	self.ambusherTechName = "Ronin.rte";

	self.brainDead = {};

	if isNewGame then
		self:StartNewGame();
	else
		self:ResumeLoadedGame();
	end
end

function ZombieCaveMission:OnSave()
	self:SaveNumber("currentFightStage", self.currentFightStage);

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			self:SaveNumber("brainDead." .. tostring(player), self.brainDead[player] and 1 or 0);
		end
	end
end

function ZombieCaveMission:StartNewGame()
	self.currentFightStage = self.fightStage.beginFight;

	for actor in MovableMan.AddedActors do
		if actor.Team == self.zombieTeam then
			actor.AIMode = Actor.AIMODE_PATROL;
		end
	end

	self.generator1 = CreateAEmitter("Zombie Generator");
	self.generator1.Pos = SceneMan.Scene:GetArea("Zombie Generator 1"):GetCenterPoint();
	self.generator1.Team = self.zombieTeam;
	self.generator1:EnableEmission(false);
	MovableMan:AddParticle(self.generator1);

	self.generator2 = CreateAEmitter("Zombie Generator");
	self.generator2.Pos = SceneMan.Scene:GetArea("Zombie Generator 2"):GetCenterPoint();
	self.generator2.Team = self.zombieTeam;
	self.generator2:EnableEmission(false);
	MovableMan:AddParticle(self.generator2);

	self.bombMaker1 = CreateAEmitter("Bomb Maker");
	self.bombMaker1.Pos = Vector(468, 276);
	self.bombMaker1.RotAngle = 5.1;
	self.bombMaker1.Team = self.zombieTeam;
	self.bombMaker1:EnableEmission(false);
	MovableMan:AddParticle(self.bombMaker1);

	self.bombMaker2 = CreateAEmitter("Bomb Maker");
	self.bombMaker2.Pos = Vector(1128, 276);
	self.bombMaker2.RotAngle = 5.9;
	self.bombMaker2.Team = self.zombieTeam;
	self.bombMaker2:EnableEmission(false);
	MovableMan:AddParticle(self.bombMaker2);

	self.controlCase = CreateMOSRotating("Control Chip Case");
	self.controlCase.Pos = Vector(203, 494);
	self.controlCase.Team = self.zombieTeam;
	MovableMan:AddParticle(self.controlCase);

	self:SetupHumanPlayerBrains();
end

function ZombieCaveMission:SetupHumanPlayerBrains()
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			if not self:GetPlayerBrain(player) and self:GetTeamOfPlayer(player) ~= self.zombieTeam then
				self.brainDead[player] = false;
				local brainBot = CreateAHuman("Brain Robot");
				local gun = CreateHDFirearm("Pistol");
				brainBot:AddInventoryItem(gun);
				brainBot.AIMode = Actor.AIMODE_SENTRY;

				local rocket = CreateACRocket("Rocket MK1");
				rocket.Pos = Vector(3100 - 50 * (player + 1), -50);
				rocket.Team = self:GetTeamOfPlayer(player);
				rocket:SetControllerMode(Controller.CIM_AI, -1);
				rocket:AddInventoryItem(brainBot);
				MovableMan:AddActor(rocket);

				self:SetPlayerBrain(rocket, player);
				self:SetViewState(Activity.ACTORSELECT, player);
				self:SetActorSelectCursor(Vector(3024, 324), player);
				self:SetLandingZone(self:GetPlayerBrain(player).Pos, player);
				self:SetObservationTarget(self:GetPlayerBrain(player).Pos, player);
			end
		end
	end
end

function ZombieCaveMission:ResumeLoadedGame()
	self.currentFightStage = self:LoadNumber("currentFightStage");

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			self.brainDead[player] = self:LoadNumber("brainDead." .. tostring(player)) ~= 0;
		end
	end

	for particle in MovableMan.AddedParticles do
		if particle.PresetName == "Zombie Generator" then
			if SceneMan.Scene:GetArea("Zombie Generator 1"):IsInside(particle.Pos) then
				self.generator1 = ToAEmitter(particle);
			elseif SceneMan.Scene:GetArea("Zombie Generator 2"):IsInside(particle.Pos) then
				self.generator2 = ToAEmitter(particle);
			end
		elseif particle.PresetName == "Bomb Maker" then
			if (particle.Pos - Vector(468, 276)):MagnitudeIsLessThan(5) then
				self.bombMaker1 = ToAEmitter(particle);
			elseif (particle.Pos - Vector(1128, 276)):MagnitudeIsLessThan(5) then
				self.bombMaker2 = ToAEmitter(particle);
			end
		elseif particle.PresetName == "Control Chip Case" then
			self.controlCase = ToMOSRotating(particle);
		end
	end
end

function ZombieCaveMission:EndActivity()
	if self.humanTeam == self.WinnerTeam then
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				FrameMan:ClearScreenText(player);
				FrameMan:SetScreenText("Well done, you retrieved the control chip. Now to put it to use!", player, 0, -1, false);
			end
		end
	end
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

function ZombieCaveMission:UpdateActivity()
	if (self.ActivityState == Activity.EDITING) then
		return;
	end

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			local team = self:GetTeamOfPlayer(player);

			if not (self.ActivityState == Activity.OVER) then
				if team ~= self.zombieTeam then
					local brain = self:GetPlayerBrain(player);
					if not brain or not MovableMan:IsActor(brain) or not brain:HasObjectInGroup("Brains") then
						self:SetPlayerBrain(nil, player);
						-- Try to find a new unasigned brain this player can use instead, or if his old brain entered a craft
						local newBrain = MovableMan:GetUnassignedBrain(team);
						-- Found new brain actor, assign it and keep on truckin'
						if newBrain and self.brainDead[player] == false then
							self:SetPlayerBrain(newBrain, player);
							if MovableMan:IsActor(newBrain) then
								self:SwitchToActor(newBrain, player, team);
							end
							self:GetBanner(GUIBanner.RED, player):ClearText();
						else
							FrameMan:SetScreenText("Your brain has been lost!", player, 333, -1, false);
							self.brainDead[player] = true;
							-- Now see if all brains of self player's team are dead, and if so, end the game
							if not MovableMan:GetFirstBrainActor(team) then
								self.WinnerTeam = self:OtherTeam(team);
								ActivityMan:EndActivity();
							end
							self:ResetMessageTimer(player);
						end
					else
						-- Update the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
						self:SetObservationTarget(brain.Pos, player);
					end
				end
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

	if self.currentFightStage < self.fightStage.outerCave and playerInCave then
		self.currentFightStage = self.fightStage.outerCave;
	end

	if self.currentFightStage < self.fightStage.innerCave and playerInInnerCave then
		self.currentFightStage = self.fightStage.innerCave;
	end

	local genOuterEnabled = self.currentFightStage >= self.fightStage.outerCave;
	local genInnerEnabled = playerInCave or self.generator2 == nil;

	-- OUTER CAVE BATTLE
	-- See if the outer generator is still alive
	if self.generator2 and MovableMan:IsParticle(self.generator2) then
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
		if self.bombMaker2 and MovableMan:IsParticle(self.bombMaker2) then
			self.bombMaker2:EnableEmission(bombCount < 1);
		end

		-- Enable/disable the zombie generator as ordered
		self.generator2:EnableEmission(genOuterEnabled);
	else
		self.generator2 = nil;
		if self.bombMaker2 and MovableMan:IsParticle(self.bombMaker2) then
			self.bombMaker2:EnableEmission(false);
		end
	end

	-- INNER CAVE BATTLE
	-- Check if the generators are still alive, and if so, have the active only when the player is in the cave
	if self.generator1 and MovableMan:IsParticle(self.generator1) then
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
		if self.bombMaker1 and MovableMan:IsParticle(self.bombMaker1) then
			self.bombMaker1:EnableEmission(bombCount < 2);
		end

		-- Enable/disable the zombie generator as ordered
		self.generator1:EnableEmission(genInnerEnabled);
	else
		self.generator1 = nil;
		if self.bombMaker1 and MovableMan:IsParticle(self.bombMaker1) then
			self.bombMaker1:EnableEmission(false);
		end
	end

	-- MARK THE OBJECTIVES
	-- Clear all objective markers, they get re-added each frame
	self:ClearObjectivePoints();

	if not (self.ActivityState == Activity.OVER) then
		-- Control box
		if MovableMan:IsParticle(self.controlCase) then
			self:AddObjectivePoint("Destroy!", self.controlCase.AboveHUDPos, Activity.TEAM_1, GameActivity.ARROWDOWN);
			self:AddObjectivePoint("Protect!", self.controlCase.AboveHUDPos, self.zombieTeam, GameActivity.ARROWDOWN);
		else
			self.controlCase = nil;
		end

		-- Chip on the ground
		for item in MovableMan.Items do
			if item:HasObject("Control Chip") then
				self:AddObjectivePoint("Pick up!", item.AboveHUDPos, Activity.TEAM_1, GameActivity.ARROWDOWN);
				self:AddObjectivePoint("Protect!", item.AboveHUDPos, self.zombieTeam, GameActivity.ARROWDOWN);
			end
		end

		-- Actor markers
		local team1Count = 0;
		for actor in MovableMan.Actors do
			if actor.Team == Activity.TEAM_1 and not actor:IsInGroup("Brains") then
				team1Count = team1Count + 1;
			end

			if actor:HasObject("Control Chip") then
				if actor:IsInGroup("Craft") then
					self:AddObjectivePoint("Launch into orbit!", actor.AboveHUDPos + Vector(0, -32), Activity.TEAM_1, GameActivity.ARROWUP);
					self:AddObjectivePoint("Destroy!", actor.AboveHUDPos + Vector(0, -32), self.zombieTeam, GameActivity.ARROWUP);
				elseif self.caveArea:IsInside(actor.Pos) then
					self:AddObjectivePoint("Carry chip outside!", actor.AboveHUDPos + Vector(80, 0), Activity.TEAM_1, GameActivity.ARROWRIGHT);
					self:AddObjectivePoint("KILL!", actor.AboveHUDPos + Vector(80, 0), self.zombieTeam, GameActivity.ARROWUP);
				else
					self:AddObjectivePoint("Load into a ship!", actor.AboveHUDPos, Activity.TEAM_1, GameActivity.ARROWDOWN);
					self:AddObjectivePoint("KILL!", actor.AboveHUDPos, self.zombieTeam, GameActivity.ARROWDOWN);
				end
			elseif actor:HasObjectInGroup("Brains") then
				self:AddObjectivePoint("Protect!", actor.AboveHUDPos, Activity.TEAM_1, GameActivity.ARROWDOWN);
				self:AddObjectivePoint("Destroy!", actor.AboveHUDPos, self.zombieTeam, GameActivity.ARROWDOWN);
			end
		end

		if team1Count < 1 and self.currentFightStage == self.fightStage.beginFight then
			self:AddObjectivePoint("Buy more bodies to help you!", Vector(3060, 340), Activity.TEAM_1, GameActivity.ARROWDOWN);
		end

		-- Sort the objective points
		self:YSortObjectivePoints();
	end

	-- ambush STAGE
	-- Triggered ambush stage
	if self.currentFightStage ~= self.fightStage.ambush and playerInArtifactArea == true then
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
			local ship1 = CreateACDropShip("Dropship MK1");
			local ronin = self:MakeEnemy(Actor.AIMODE_GOTO);
			ronin:ClearAIWaypoints();
			ronin:AddAISceneWaypoint(Vector(200, 500));
			ship1:AddInventoryItem(ronin);
			ronin = self:MakeEnemy(Actor.AIMODE_GOTO);
			ronin:ClearAIWaypoints();
			ronin:AddAISceneWaypoint(Vector(200, 500));
			ship1:AddInventoryItem(ronin);
			local ship2 = CreateACDropShip("Dropship MK1");
			ship2:AddInventoryItem(self:MakeEnemy(Actor.AIMODE_BRAINHUNT));
			ship2:AddInventoryItem(self:MakeEnemy(Actor.AIMODE_BRAINHUNT));

			-- Only land over the proper LZ
			ship1.Pos.X = attackLZ:GetRandomPoint().X;
			ship2.Pos.X = 2300;
			ship1.Pos.Y = 0;
			ship2.Pos.Y = -50;
			ship1.Team = self.ambusherTeam;
			ship2.Team = self.ambusherTeam;

			-- Let the spawn into the world, passing ownership
			MovableMan:AddActor(ship1);
			MovableMan:AddActor(ship2);

			-- Advance the stage
			self.currentFightStage = self.fightStage.ambush;
		end
	end

	-- Any ronin guys who reach the innermost cave, should go brain hunt afterward
	if self.currentFightStage == self.fightStage.ambush then
		for actor in MovableMan.Actors do
			if actor.Team == self.ambusherTeam and self.artifactArea:IsInside(actor.Pos) then
				actor.AIMode = Actor.AIMODE_BRAINHUNT;
			end
		end
	end
end

function ZombieCaveMission:MakeEnemy(whichMode)
	local passenger = RandomAHuman("Any", self.ambusherTechName);
	if passenger then
		passenger:AddInventoryItem(RandomHDFirearm("Weapons - Primary", self.ambusherTechName));
		passenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.ambusherTechName));
		if PosRand() < 0.25 then
			passenger:AddInventoryItem(RandomHDFirearm("Tools - Diggers", self.ambusherTechName));
		end
	end

	passenger.AIMode = whichMode or 0;
	return passenger;
end

function ZombieCaveMission:CraftEnteredOrbit(orbitedCraft)
	if orbitedCraft:HasObject("Control Chip") then
		self.WinnerTeam = Activity.TEAM_1;
		ActivityMan:EndActivity();
	end
end