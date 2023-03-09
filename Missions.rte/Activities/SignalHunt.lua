package.loaded.Constants = nil;
require("Constants");

function SignalHunt:StartActivity(isNewGame)
	self.humanLZ = SceneMan.Scene:GetArea("LZ Team 1");
	self.ambusherLZ = SceneMan.Scene:GetArea("LZ Team 2");

	self.caveArea = SceneMan.Scene:GetArea("Cave");
	self.innerCaveArea = SceneMan.Scene:GetArea("Inner Cave");
	self.innermostCaveArea = SceneMan.Scene:GetArea("Innermost Cave");

	self.outerZombieGeneratorArea = SceneMan.Scene:GetArea("Outer Zombie Generator");
	self.outerBombMakerArea = SceneMan.Scene:GetArea("Outer Bomb Maker");
	self.outerBombPickupArea = SceneMan.Scene:GetArea("Outer Bomb Pickup");

	self.innerZombieGeneratorArea = SceneMan.Scene:GetArea("Inner Zombie Generator");
	self.innerBombMakerArea = SceneMan.Scene:GetArea("Inner Bomb Maker");
	self.innerBombPickupArea = SceneMan.Scene:GetArea("Inner Bomb Pickup");

	self.controlCaseArea = SceneMan.Scene:GetArea("Control Case");

	self.fightStage = { beginFight = 0, inOuterCaveArea = 1, inInnerCaveArea = 2, inInnermostCaveArea = 3, ambushAndExtraction = 5 };

	self.zombieTeam = Activity.NOTEAM;
	self.humanTeam = Activity.TEAM_1;
	self.ambusherTeam = Activity.TEAM_2;
	self:ForceSetTeamAsActive(self.ambusherTeam); -- NOTE: This is necessary for the ambusher actors to work properly. WIthout it, their team is considered inactive, and their AI will be unable to shoot because of the game's spatial partitioning grid.
	self:SetTeamAISkill(self.zombieTeam, self.Difficulty);
	self:SetTeamAISkill(self.ambusherTeam, self.Difficulty);

	--TODO this stuff may be totally pointless, but I don't really wanna do the testing to remove it.
	self:SetLZArea(self.humanTeam, self.humanLZ);
	self:SetLZArea(self.ambusherTeam, self.ambusherLZ);
	self:SetBrainLZWidth(Activity.PLAYER_1, 0);
	self:SetBrainLZWidth(Activity.PLAYER_2, 0);
	self:SetBrainLZWidth(Activity.PLAYER_3, 0);
	self:SetBrainLZWidth(Activity.PLAYER_4, 0);

	self.screenTextTimer = Timer();
	self.screenTextTimeLimit = 7500;
	self.noControlChipTimer = Timer();

	self.humanTeamTechName = self:GetTeamTech(self.humanTeam);
	self.ambusherTeamTechName = "Ronin.rte";

	self.zombieSpawnDifficultyMultiplier = 1;
	self.numberOfLooseBombsPerBombMaker = 1;
	self.numberOfAmbushingCraft = 3;
	if self.Difficulty <= Activity.CAKEDIFFICULTY then
		self.zombieSpawnDifficultyMultiplier = 0.25;
		self.numberOfAmbushingCraft = 0;
	elseif self.Difficulty <= Activity.EASYDIFFICULTY then
		self.zombieSpawnDifficultyMultiplier = 0.5;
		self.numberOfAmbushingCraft = 1;
	elseif self.Difficulty <= Activity.MEDIUMDIFFICULTY then
		self.zombieSpawnDifficultyMultiplier = 1;
		self.numberOfAmbushingCraft = 2;
	elseif self.Difficulty <= Activity.HARDDIFFICULTY then
		self.zombieSpawnDifficultyMultiplier = 2;
		self.numberOfLooseBombsPerBombMaker = 2;
		self.numberOfAmbushingCraft = 3;
	elseif self.Difficulty <= Activity.NUTSDIFFICULTY then
		self.zombieSpawnDifficultyMultiplier = 3;
		self.numberOfLooseBombsPerBombMaker = 3;
		self.numberOfAmbushingCraft = 4;
	else
		self.zombieSpawnDifficultyMultiplier = 4;
		self.numberOfLooseBombsPerBombMaker = 5;
		self.numberOfAmbushingCraft = 5;
	end

	self.brainDead = {};

	if isNewGame then
		self:StartNewGame();
	else
		self:ResumeLoadedGame();
	end
end

function SignalHunt:OnSave()
	self:SaveNumber("screenTextTimer.ElapsedSimTimeMS", self.screenTextTimer.ElapsedSimTimeMS);

	self:SaveNumber("currentFightStage", self.currentFightStage);
	self:SaveNumber("evacuationRocketSpawned", self.evacuationRocketSpawned and 1 or 0);

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			self:SaveNumber("brainDead." .. tostring(player), self.brainDead[player] and 1 or 0);
		end
	end
end

function SignalHunt:StartNewGame()
	self:SetTeamFunds(self:GetStartingGold(), self.humanTeam);

	self.currentFightStage = self.fightStage.beginFight;
	self.evacuationRocketSpawned = false;

	for actor in MovableMan.AddedActors do
		if actor.Team == self.zombieTeam then
			actor.AIMode = Actor.AIMODE_PATROL;
		end
	end

	-- Hide everything inside the cave from the human player.
	if self:GetFogOfWarEnabled() then
		SceneMan:MakeAllUnseen(Vector(20, 20), self.humanTeam);
		local topRightCornerOfCave;
		for box in self.caveArea.Boxes do
			topRightCornerOfCave = box.Corner + Vector(box.Width, 0); -- Note: This assumes that there's only one box in the area, so its top right corner is the top right corner of the area.
			break;
		end
		SceneMan:RevealUnseenBox(topRightCornerOfCave.X, topRightCornerOfCave.Y, SceneMan.SceneWidth, SceneMan.SceneHeight, self.humanTeam)
	end

	self.outerZombieGenerator = CreateAEmitter("Zombie Generator");
	self.outerZombieGenerator.Pos = self.outerZombieGeneratorArea:GetCenterPoint();
	self.outerZombieGenerator.Team = self.zombieTeam;
	self.outerZombieGenerator:EnableEmission(false);
	for emission in self.outerZombieGenerator.Emissions do
		emission.ParticlesPerMinute = emission.ParticlesPerMinute * self.zombieSpawnDifficultyMultiplier;
	end
	self.outerZombieGenerator.SpriteAnimDuration = self.outerZombieGenerator.SpriteAnimDuration / self.zombieSpawnDifficultyMultiplier;
	MovableMan:AddParticle(self.outerZombieGenerator);

	self.outerBombMaker = CreateAEmitter("Bomb Maker");
	self.outerBombMaker.Pos = self.outerBombMakerArea:GetCenterPoint();
	self.outerBombMaker.RotAngle = 5.9;
	self.outerBombMaker.Team = self.zombieTeam;
	self.outerBombMaker:EnableEmission(false);
	for emission in self.outerBombMaker.Emissions do
		emission.ParticlesPerMinute = emission.ParticlesPerMinute * self.zombieSpawnDifficultyMultiplier;
	end
	MovableMan:AddParticle(self.outerBombMaker);

	self.innerZombieGenerator = CreateAEmitter("Zombie Generator");
	self.innerZombieGenerator.Pos = self.innerZombieGeneratorArea:GetCenterPoint();
	self.innerZombieGenerator.Team = self.zombieTeam;
	self.innerZombieGenerator:EnableEmission(false);
	for emission in self.innerZombieGenerator.Emissions do
		emission.ParticlesPerMinute = emission.ParticlesPerMinute * self.zombieSpawnDifficultyMultiplier;
	end
	self.innerZombieGenerator.SpriteAnimDuration = self.innerZombieGenerator.SpriteAnimDuration / self.zombieSpawnDifficultyMultiplier;
	MovableMan:AddParticle(self.innerZombieGenerator);

	self.innerBombMaker = CreateAEmitter("Bomb Maker");
	self.innerBombMaker.Pos = self.innerBombMakerArea:GetCenterPoint();
	self.innerBombMaker.RotAngle = 5.1;
	self.innerBombMaker.Team = self.zombieTeam;
	self.innerBombMaker:EnableEmission(false);
	for emission in self.innerBombMaker.Emissions do
		emission.ParticlesPerMinute = emission.ParticlesPerMinute * self.zombieSpawnDifficultyMultiplier;
	end
	MovableMan:AddParticle(self.innerBombMaker);

	self.controlCase = CreateMOSRotating("Control Chip Case");
	self.controlCase.Pos = self.controlCaseArea:GetCenterPoint();
	self.controlCase.Team = self.zombieTeam;
	MovableMan:AddParticle(self.controlCase);

	self:SetupHumanPlayerBrains();
end

function SignalHunt:SetupHumanPlayerBrains()
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			if not self:GetPlayerBrain(player) and self:GetTeamOfPlayer(player) ~= self.zombieTeam then
				self.brainDead[player] = false;

				local humanTeamTechId = PresetMan:GetModuleID(self.humanTeamTechName);
				local actor;
				if humanTeamTechId ~= -1 and team == self.attackerTeam then
					actor = PresetMan:GetLoadout("Infantry Brain", humanTeamTechId, false);
					actor:RemoveInventoryItem("Constructor");
				else
					actor = RandomAHuman("Brains", humanTeamTechId);
					actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", humanTeamTechId));
					actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", humanTeamTechId));
				end
				actor.AIMode = Actor.AIMODE_SENTRY;

				local rocket = CreateACRocket("Rocket MK2");
				rocket.Pos = Vector(3100 - 50 * (player + 1), -100);
				rocket.Team = self:GetTeamOfPlayer(player);
				rocket:SetGoldValue(0);
				rocket:SetControllerMode(Controller.CIM_AI, -1);
				rocket.PlayerControllable = false;
				rocket:AddInventoryItem(actor);
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

function SignalHunt:ResumeLoadedGame()
	self.screenTextTimer.ElapsedSimTimeMS = self:LoadNumber("screenTextTimer.ElapsedSimTimeMS");

	self.currentFightStage = self:LoadNumber("currentFightStage");
	self.evacuationRocketSpawned = self:LoadNumber("evacuationRocketSpawned") ~= 0;

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			self.brainDead[player] = self:LoadNumber("brainDead." .. tostring(player)) ~= 0;
		end
	end

	for particle in MovableMan.AddedParticles do
		if particle.PresetName == "Zombie Generator" then
			if self.innerZombieGeneratorArea:IsInside(particle.Pos) then
				self.innerZombieGenerator = ToAEmitter(particle);
			elseif self.outerZombieGeneratorArea:IsInside(particle.Pos) then
				self.outerZombieGenerator = ToAEmitter(particle);
			end
		elseif particle.PresetName == "Bomb Maker" then
			if (particle.Pos - Vector(468, 276)):MagnitudeIsLessThan(5) then
				self.innerBombMaker = ToAEmitter(particle);
			elseif (particle.Pos - Vector(1128, 276)):MagnitudeIsLessThan(5) then
				self.outerBombMaker = ToAEmitter(particle);
			end
		elseif particle.PresetName == "Control Chip Case" then
			self.controlCase = ToMOSRotating(particle);
		end
	end

	for actor in MovableMan.AddedActors do
		if self.evacuationRocketSpawned and not self.evacuationRocket and actor.Team == self.humanTeam and actor.ClassName == "ACRocket" then
			self.evacuationRocket = actor;
		end
	end
end

function SignalHunt:EndActivity()
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

function SignalHunt:DoGameOverCheck()
	if self.WinnerTeam ~= self.humanTeam then
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				local team = self:GetTeamOfPlayer(player);
				local brain = self:GetPlayerBrain(player);
				if not brain or not MovableMan:IsActor(brain) or not brain:HasObjectInGroup("Brains") then
					self:SetPlayerBrain(nil, player);

					local newBrain = MovableMan:GetUnassignedBrain(team);
					if newBrain and self.brainDead[player] == false and MovableMan:IsActor(newBrain) then
						self:SetPlayerBrain(newBrain, player);
						self:SwitchToActor(newBrain, player, team);
						self:GetBanner(GUIBanner.RED, player):ClearText();
					else
						self.brainDead[player] = true;
						if not MovableMan:GetFirstBrainActor(team) then
							self.WinnerTeam = self:OtherTeam(team);
							ActivityMan:EndActivity();
						end
						self:ResetMessageTimer(player);
					end
				else
					-- Update the observation target to the brain, so that if/when it dies, the view flies to it in observation mode.
					self:SetObservationTarget(brain.Pos, player);
				end
			end
		end
	elseif self.WinnerTeam == self.humanTeam then
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				self:GetBanner(GUIBanner.RED, player):ClearText();
			end
		end
		if self.screenTextTimer:IsPastSimMS(self.screenTextTimeLimit) then
			ActivityMan:EndActivity();
		end
	end
end

function SignalHunt:DoAmbush()
	if self.ambusherLZ and self.numberOfAmbushingCraft > 0 then
		for craftNumber = 1, self.numberOfAmbushingCraft do
			local ambushingCraft = RandomACRocket("Craft", self.ambusherTeamTechName);
			if not ambushingCraft then
				ambushingCraft = RandomACRocket("Craft", "Base.rte");
			end
			ambushingCraft.Team = self.ambusherTeam;
			for box in self.ambusherLZ.Boxes do
				ambushingCraft.Pos = Vector(box.Corner.X + (75 * craftNumber), -100); -- Assumes only one box for LZ!
				break;
			end

			for passengerNumber = 1, 2 do
				local ambushingPassenger = RandomAHuman("Any", self.ambusherTeamTechName);
				ambushingPassenger.Team = self.ambusherTeam;
				if ambushingPassenger then
					ambushingPassenger:AddInventoryItem(RandomHDFirearm("Weapons - Primary", self.ambusherTeamTechName));
					ambushingPassenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.ambusherTeamTechName));
					if PosRand() < 0.25 then
						ambushingPassenger:AddInventoryItem(RandomHDFirearm("Tools - Diggers", self.ambusherTeamTechName));
					end

					if craftNumber == 1 then
						ambushingPassenger.AIMode = Actor.AIMODE_GOTO;
						ambushingPassenger:ClearAIWaypoints();
						ambushingPassenger:AddAISceneWaypoint(self.innermostCaveArea:GetCenterPoint());
					else
						ambushingPassenger.AIMode = Actor.AIMODE_BRAINHUNT;
					end
				end
				ambushingCraft:AddInventoryItem(ambushingPassenger);
			end
			MovableMan:AddActor(ambushingCraft);
		end
	end
end

function SignalHunt:DoZombieAndBombSpawns(zombieActorCount)
	for i = 1, 2 do
		local generatorToUse = i == 1 and self.outerZombieGenerator or self.innerZombieGenerator;
		local generatorEnabled = zombieActorCount < rte.AIMOIDMax and (i == 1 and (self.currentFightStage >= self.fightStage.inOuterCaveArea) or (self.currentFightStage >= self.fightStage.inInnerCaveArea or self.outerZombieGenerator == nil));
		local bombMakerToUse = i == 1 and self.outerBombMaker or self.innerBombMaker;
		local bombPickupAreaToUse = i == 1 and self.outerBombPickupArea or self.innerBombPickupArea;

		if generatorToUse and MovableMan:IsParticle(generatorToUse) then
			local bombCount = 0;
			for item in MovableMan.Items do
				if bombPickupAreaToUse:IsInside(item.Pos) and item.PresetName == "Blue Bomb" then
					bombCount = bombCount + 1;
				end
			end
			if bombMakerToUse and MovableMan:IsParticle(bombMakerToUse) then
				bombMakerToUse:EnableEmission(generatorEnabled and bombCount < self.numberOfLooseBombsPerBombMaker);
			end
			generatorToUse:EnableEmission(generatorEnabled);
		else
			bombMakerToUse:EnableEmission(false);
		end
	end
end

function SignalHunt:UpdateScreenTextAndObjectiveArrows(humanActorCount)
	if self.WinnerTeam ~= self.humanTeam then
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				local brain = self:GetPlayerBrain(player);
				if brain and self.currentFightStage > self.fightStage.beginFight and (not self.actorHoldingControlChip or self.actorHoldingControlChip.UniqueID ~= brain.UniqueID) and (not self.evacuationRocket or self.evacuationRocket.UniqueID ~= brain.UniqueID) then
					self:AddObjectivePoint("Protect!", brain.AboveHUDPos, self.humanTeam, GameActivity.ARROWDOWN);
				elseif not brain then
					FrameMan:ClearScreenText(player);
					FrameMan:SetScreenText("Your brain has been lost!", player, 333, -1, false);
				end
			end
		end

		if self.currentFightStage < self.fightStage.inOuterCaveArea then
			if not self.screenTextTimer:IsPastSimMS(self.screenTextTimeLimit) then
				for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
					if self:PlayerActive(player) and self:PlayerHuman(player) then
						FrameMan:ClearScreenText(player);
						FrameMan:SetScreenText("Contractor, we at Alchiral appreciate your cooperation and confidentiality on this assignment.\nPlease enter the cave to ascertain the source of the signal.", player, 0, 1, false);
					end
				end
			else
				self:AddObjectivePoint("Enter the cave to find the source of the signal!", self.outerBombPickupArea:GetCenterPoint(), self.humanTeam, GameActivity.ARROWDOWN);
			end
			if humanActorCount < 1 and not self.screenTextTimer:IsPastSimMS(self.screenTextTimeLimit * 2) and self:GetTeamFunds(self.humanTeam) > 0 then
				self:AddObjectivePoint("More bodies are recommended to complete this contract!", self.humanLZ:GetCenterPoint(), self.humanTeam, GameActivity.ARROWDOWN);
			end
		elseif self.currentFightStage < self.fightStage.inInnerCaveArea then
			self:AddObjectivePoint("Proceed farther into the cave!", self.innerBombPickupArea:GetCenterPoint(), self.humanTeam, GameActivity.ARROWDOWN);
		elseif self.currentFightStage < self.fightStage.inInnermostCaveArea then
			if not self.screenTextTimer:IsPastSimMS(self.screenTextTimeLimit) then
				for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
					if self:PlayerActive(player) and self:PlayerHuman(player) then
						FrameMan:ClearScreenText(player);
						FrameMan:SetScreenText("Contractor, these cloning tubes are not your primary target.\nYou may destroy them if they are obstructing your progress, but your task is to find the source of the signal.\nProceed farther into the cave.", player, 0, 1, false);
					end
				end
			else
				self:AddObjectivePoint("The signal is getting stronger, proceed farther into the cave!", self.controlCase.Pos + Vector(0, -100), self.humanTeam, GameActivity.ARROWDOWN);
			end
		elseif self.currentFightStage < self.fightStage.ambushAndExtraction and self.controlCase then
			if not self.screenTextTimer:IsPastSimMS(self.screenTextTimeLimit) then
				for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
					if self:PlayerActive(player) and self:PlayerHuman(player) then
						FrameMan:ClearScreenText(player);
						FrameMan:SetScreenText("Contractor, the signal is coming from that case; there is a modified Alchiral Cloning Control Chip inside it.\nDestroy the case and retrieve our property, once the chip is outside we will send a rocket to evacuate it to orbit.", player, 0, 1, false);
					end
				end
			end
			self:AddObjectivePoint("Destroy the case and retrieve the control chip inside!", self.controlCase.Pos, self.humanTeam, GameActivity.ARROWDOWN);
		elseif self.currentFightStage == self.fightStage.ambushAndExtraction then
			if not self.screenTextTimer:IsPastSimMS(self.screenTextTimeLimit) then
				if not self.evacuationRocketSpawned and self.numberOfAmbushingCraft > 0 then
					for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
						if self:PlayerActive(player) and self:PlayerHuman(player) then
							FrameMan:ClearScreenText(player);
							FrameMan:SetScreenText("ALERT: Contractor, unknown hostiles are entering the area. They must not retrieve the Cloning Control Chip!", player, 500, 8000, true);
						end
					end
				elseif self.evacuationRocketSpawned then
					for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
						if self:PlayerActive(player) and self:PlayerHuman(player) then
							FrameMan:ClearScreenText(player);
							FrameMan:SetScreenText("Contractor, we have sent a rocket to extract the Cloning Control Chip.", player, 500, 8000, true);
						end
					end
				end
			end
			if self.controlChip and not self.actorHoldingControlChip then
				self:AddObjectivePoint("Pick up the Cloning Control Chip!", self.controlChip.Pos, self.humanTeam, GameActivity.ARROWDOWN);
			elseif self.actorHoldingControlChip then
				if self.actorHoldingControlChip.Team == self.humanTeam and (not self.evacuationRocket or self.actorHoldingControlChip.UniqueID ~= self.evacuationRocket.UniqueID) then
					self:AddObjectivePoint("Evacuate the Cloning Control Chip!", self.actorHoldingControlChip.AboveHUDPos, self.humanTeam, GameActivity.ARROWDOWN);
				elseif self.actorHoldingControlChip.Team ~= self.humanTeam then
					self:AddObjectivePoint("Kill to retrieve the Cloning Control Chip!", self.actorHoldingControlChip.AboveHUDPos, self.humanTeam, GameActivity.ARROWDOWN);
				end
			end
			if self.evacuationRocket and (not self.actorHoldingControlChip or self.actorHoldingControlChip.UniqueID ~= self.evacuationRocket.UniqueID) then
				self:AddObjectivePoint("Get the Cloning Control Chip to the rocket!", self.evacuationRocket.AboveHUDPos, self.humanTeam, GameActivity.ARROWDOWN);
			end
		end
	elseif self.WinnerTeam == self.humanTeam and not self.screenTextTimer:IsPastSimMS(self.screenTextTimeLimit) then
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				FrameMan:ClearScreenText(player);
				FrameMan:SetScreenText("Contractor, thank you for your efficient work. Your agreed-upon fee has been deposited to your account.\nWe at Alchiral are pleased with your performance, and look forward to a productive relationship with you in future.", player, 0, 1, true);
			end
		end
	end

	self:YSortObjectivePoints();
end

function SignalHunt:UpdateActivity()
	self:ClearObjectivePoints();

	if (self.ActivityState == Activity.OVER) then
		return;
	end

	self:DoGameOverCheck();

	if self.currentFightStage < self.fightStage.inOuterCaveArea then
		for actor in MovableMan.Actors do
			if actor.Team == self.humanTeam and self.caveArea:IsInside(actor.Pos) then
				self.currentFightStage = self.fightStage.inOuterCaveArea;
				self.screenTextTimer:Reset();
				break;
			end
		end
	elseif self.currentFightStage < self.fightStage.inInnerCaveArea then
		for actor in MovableMan.Actors do
			if actor.Team == self.humanTeam and self.innerCaveArea:IsInside(actor.Pos) then
				self.currentFightStage = self.fightStage.inInnerCaveArea;
				self.screenTextTimer:Reset();
				break;
			end
		end
	elseif self.currentFightStage < self.fightStage.inInnermostCaveArea then
		for actor in MovableMan.Actors do
			if actor.Team == self.humanTeam and self.innermostCaveArea:IsInside(actor.Pos) then
				self.currentFightStage = self.fightStage.inInnermostCaveArea;
				self.screenTextTimer:Reset();
				break;
			end
		end
	elseif self.currentFightStage < self.fightStage.ambushAndExtraction and self.controlChip then
		self.currentFightStage = self.fightStage.ambushAndExtraction;
		self.screenTextTimer:Reset();
		self:DoAmbush();
	elseif self.currentFightStage == self.fightStage.ambushAndExtraction then
		for actor in MovableMan.Actors do
			if actor.Team == self.ambusherTeam and self.innermostCaveArea:IsInside(actor.Pos) then
				actor.AIMode = Actor.AIMODE_BRAINHUNT;
			end
		end

		if not self.evacuationRocketSpawned and self.actorHoldingControlChip and self.actorHoldingControlChip.Team == self.humanTeam and not self.caveArea:IsInside(self.actorHoldingControlChip.Pos) then
			self.evacuationRocket = CreateACRocket("Rocket MK2", "Base.rte");
			self.evacuationRocket.Pos = Vector(self.humanLZ:GetCenterPoint().X, -100);
			self.evacuationRocket.Team = self.humanTeam;
			self.evacuationRocket:SetControllerMode(Controller.CIM_AI, -1);
			self.evacuationRocket.PlayerControllable = false;
			self.evacuationRocket.AIMode = Actor.AIMODE_STAY;
			self.evacuationRocket:SetGoldValue(0);
			MovableMan:AddActor(self.evacuationRocket);
			self.evacuationRocketSpawned = true;
		end
	end

	if self.controlCase and not MovableMan:IsParticle(self.controlCase) then -- Note: ValidMO cannot be used here, because it currently doesn't work with AddedParticles, so this gets lost on save/load since it isn't refereshed.
		self.controlCase = nil;
		self.noControlChipTimer:Reset();
	elseif not self.controlCase and not self.controlChip then
		for item in MovableMan.Items do
			if item.PresetName == "Control Chip" then
				self.controlChip = item;
				break;
			end
		end
	elseif self.controlChip and not MovableMan:ValidMO(self.controlChip) then
		self.controlChip = nil;
	end

	local humanActorCount = 0;
	local zombieActorCount = 0;
	for actor in MovableMan.Actors do
		if actor.Team == self.humanTeam and not actor:IsInGroup("Brains") then
			humanActorCount = humanActorCount + 1;
		end
		if actor.Team == self.zombieTeam then
			zombieActorCount = zombieActorCount + 1;
		end
		if actor:HasObject("Control Chip") then
			self.actorHoldingControlChip = actor;
		end
	end
	if self.actorHoldingControlChip and (not MovableMan:ValidMO(self.actorHoldingControlChip) or not self.actorHoldingControlChip:HasObject("Control Chip")) then
		self.actorHoldingControlChip = nil;
	end

	if self.evacuationRocket and not MovableMan:IsActor(self.evacuationRocket) then
		self.evacuationRocket = nil;
		self.evacuationRocketSpawned = false;
	elseif self.evacuationRocket then
		if not self.evacuationRocket:HasObject("Control Chip") and self.evacuationRocket.Vel:MagnitudeIsLessThan(1) then
			self.evacuationRocket:OpenHatch();
		elseif self.evacuationRocket:HasObject("Control Chip") then
			self.evacuationRocket.AIMode = Actor.AIMODE_RETURN;
		end
	end

	if not self.controlCase and not self.controlChip and not self.actorHoldingControlChip then
		if self.noControlChipTimer:IsPastSimMS(100) then
			self.controlChip = CreateHeldDevice("Control Chip", "Missions.rte");
			self.controlChip.Pos = self.controlCaseArea:GetCenterPoint();
			MovableMan:AddItem(self.controlChip);
		end
	else
		self.noControlChipTimer:Reset();
	end
	
	self:DoZombieAndBombSpawns(zombieActorCount);

	self:UpdateScreenTextAndObjectiveArrows(humanActorCount);
end

function SignalHunt:CraftEnteredOrbit(orbitedCraft)
	if orbitedCraft:HasObject("Control Chip") then
		self.WinnerTeam = self.humanTeam;
		self.screenTextTimer:Reset();
	end
end