package.loaded.Constants = nil; require("Constants");

-----------------------------------------------------------------------------------------
-- Test a Scene for Compatibility
-----------------------------------------------------------------------------------------

function DoainarMission:SceneTest()
--[[ THIS TEST IS DONE AUTOMATICALLY BY THE GAME NOW; IT SCANS THE SCRIPT FOR ANY MENTIONS OF "GetArea" AND TESTS THE SCENES FOR HAVING THOSE USED AREAS DEFINED!
	-- See if the required areas are present in the test scene
	if not (TestScene:HasArea("Cave Inside A") and TestScene:HasArea("Cave Inside B") and
			TestScene:HasArea("Console") and TestScene:HasArea("Pitfall")) then
		-- If the test scene failed the compatibility test, invalidate it
		TestScene = nil;
	end
--]]
end

-----------------------------------------------------------------------------------------
-- Start Activity
-----------------------------------------------------------------------------------------

function DoainarMission:StartActivity()
		print("START! -- DoainarMission:StartActivity()!");
	
		self.FightStage = { BEGINFIGHT = 0, OUTERCAVE = 1, INNERCAVE = 2, AMBUSH = 3, FIGHTSTAGECOUNT = 4 };
		self.AreaTimer = Timer();
		self.StepTimer = Timer();
		self.SpawnTimer = Timer();
		self.CurrentFightStage = self.FightStage.BEGINFIGHT;
		self.aggress = false;
	self.downhole = false;
		self.mamacrab = nil;
		self.Sac = nil;
		self.caveAreaA = SceneMan.Scene:GetArea("Cave Inside A");
		self.caveAreaB = SceneMan.Scene:GetArea("Cave Inside B");
		self.consoleArea = SceneMan.Scene:GetArea("Console");
		self.pitfall = SceneMan.Scene:GetArea("Pitfall");
		self.mamadead = false;
		self.deciphtimer = Timer();
		self.sacdestroyed = false;
		self.BrainHasLanded = {};
		self.braindead = {};
		self.mamajumptime = Timer();
	self.litscreen = nil;
	
		--------------------------
		-- Set up teams

		-- Team 2 is always CPU
		self.CPUTeam = Activity.TEAM_2;
	
		--------------------------
		-- Set up players
-- Position of pieces that should conceal the cave.
--		self.piece1.Pos = Vector(1261,359);
--		self.piece2.Pos = Vector(1448,467);

		self.Sac = CreateAEmitter("Eggsac");
		self.Sac.Pos = Vector(1274, 294);
		self.Sac.Team = self.CPUTeam;
		self.Sac:EnableEmission(true);
		MovableMan:AddParticle(self.Sac);

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			-- Check if we already have a brain assigned
			if not self:GetPlayerBrain(player) then
			self.braindead[player] = false;
				local ship = CreateACRocket("Drop Crate");
				local brain = CreateAHuman("Brain Robot");
				local gun = CreateHDFirearm("Assault Rifle");
				brain:AddInventoryItem(gun);
			brain.AIMode = Actor.AIMODE_SENTRY;
				ship:AddInventoryItem(brain);
				ship.Pos = Vector(150+(player+1)*50, -50);
				ship.Team = self:GetTeamOfPlayer(player);
				ship:SetControllerMode(Controller.CIM_AI, -1);
				-- Let the spawn into the world, passing ownership
				MovableMan:AddActor(ship);
				-- Set the found brain to be the selected actor at start
				self:SetPlayerBrain(brain, player);
				self:SetViewState(Activity.ACTORSELECT, player);
				SceneMan:SetScroll(self:GetPlayerBrain(player).Pos, player);
				self:SetActorSelectCursor(Vector(3024, 324), player);
				self:SetLandingZone(self:GetPlayerBrain(player).Pos, player);
				-- Set the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
				self:SetObservationTarget(self:GetPlayerBrain(player).Pos, player);
			self.BrainHasLanded[player] = false;
			end
		end
	end

	self.mamacrab = CreateACrab("Mega Crab");
	self.mamacrab.Pos = Vector(1080,315);
	self.mamacrab.Team = -1;
	self.mamacrab.HUDVisible = false;
	self.mamacrab.AIMode = Actor.AIMODE_BRAINHUNT;

	self.target = self:GetPlayerBrain(Activity.PLAYER_1);
	
	-- Set up AI modes for the Actors that have been added to the scene by the scene definition
	for actor in MovableMan.AddedActors do
		if actor.Team == self.CPUTeam then
--			actor:SetControllerMode(Controller.CIM_AI, -1);
			actor.HUDVisible = false;
			actor.AIMode = Actor.AIMODE_PATROL;
		end
	end
	
	--------------------------
	-- Set up tutorial
	
	self.AreaTimer:Reset();
	self.StepTimer:Reset();
	self.SpawnTimer:Reset();
	
	SceneMan:MakeAllUnseen(Vector(25, 25), Activity.TEAM_1);
end

-----------------------------------------------------------------------------------------
-- Pause Activity
-----------------------------------------------------------------------------------------

function DoainarMission:PauseActivity(pause)
	print("PAUSE! -- DoainarMission:PauseActivity()!");
end

-----------------------------------------------------------------------------------------
-- End Activity
-----------------------------------------------------------------------------------------

function DoainarMission:EndActivity()
	print("END! -- DoainarMission:EndActivity()!");
end

-----------------------------------------------------------------------------------------
-- Update Activity
-----------------------------------------------------------------------------------------

function DoainarMission:UpdateActivity()
	if MovableMan:IsActor(self.mamacrab) then
		for actor in MovableMan.Actors do
			if actor.Team == Activity.TEAM_1 then
				if not MovableMan:IsActor(self.target) then
					self.target = actor;
				else
					local thisPos = actor.Pos.X - self.mamacrab.Pos.X;
					if thisPos < 0 then
						thisPos = thisPos*-1;
					end
					local otherPos = self.target.Pos.X - self.mamacrab.Pos.X;
					if otherPos < 0 then
						otherPos = otherPos*-1;
					end
					if thisPos < otherPos and actor.Team == Activity.TEAM_1 then
						self.target = actor;
					end
				end
			end
		end
	end
		-- Clear all objective markers, they get re-added each frame
		self:ClearObjectivePoints();
	local consoleobj = 0;
	local invest2obj = 0;
	if not (self.ActivityState == Activity.OVER) then
			--------------------------
			-- Iterate through all human players
		for player = 0, self.PlayerCount - 1 do
				-- The current player's team
				local team = self:GetTeamOfPlayer(player);
				-- Make sure the game is not already ending
					-- Check if any player's brain is dead
					local brain = self:GetPlayerBrain(player);
					if not brain or not MovableMan:IsActor(brain) or not brain:HasObjectInGroup("Brains") then
						self:SetPlayerBrain(nil, player);
						-- Try to find a new unasigned brain this player can use instead, or if his old brain entered a craft
						local newBrain = MovableMan:GetUnassignedBrain(team);
						-- Found new brain actor, assign it and keep on truckin'
						if newBrain and self.braindead[player] == false then
								self:SetPlayerBrain(newBrain, player);
								self:SwitchToActor(newBrain, player, team);
						else
								FrameMan:SetScreenText("Your brain has been lost!", player, 333, -1, false);
					self.braindead[player] = true;
								-- Now see if all brains of self player's team are dead, and if so, end the game
								if not MovableMan:GetFirstBrainActor(team) then
									self.WinnerTeam = self:OtherTeam(team);
									ActivityMan:EndActivity();
								end
						end
					else
						-- Update the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
						self:SetObservationTarget(brain.Pos, player)
				end
			if self.braindead[player] == false then
					if (-self.SpawnTimer:LeftTillSimMS(0) >= 25) then
					--Check if all the outside crabs have died, and if so, enter the "aggression" stage, where all the crabs try to kill you.
					local crabcount = 0;
					if self.aggress == false then
						for actor in MovableMan.Actors do
							if not self.caveAreaA:IsInside(actor.Pos) and not self.caveAreaB:IsInside(actor.Pos) and actor.PresetName == "Crab" then
								crabcount = crabcount + 1;
							end
						end

						if crabcount == 0 then
							MovableMan:AddActor(self.mamacrab);
							self.aggress = true;
							self.mamacrab.Vel = Vector((self.target.Pos.X - self.mamacrab.Pos.X)*0.025,-15 + ((self.target.Pos.Y - self.mamacrab.Pos.Y)*0.025));
							self.mamajumptime:Reset();
							self:ResetMessageTimer(player);
								FrameMan:ClearScreenText(player);
							FrameMan:SetScreenText("Uh oh.  Looks like you angered the mother crab.  Kill it before it kills you!", player, 0, 5000, false);
								AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/bossfight.ogg", 0, -1);
						end
					end

					if MovableMan:IsActor(brain) and self.BrainHasLanded[player] == false then
						self:SwitchToActor(brain, player, team);
						self.BrainHasLanded[player] = true;
						self:ResetMessageTimer(player);
							FrameMan:ClearScreenText(player);
						FrameMan:SetScreenText("Looks like there's a crab den down here.  We'll have to clear them out first.", player, 0, 5000, false);
					end

					if MovableMan:IsActor(self.mamacrab) == false and self.mamadead == false and self.aggress == true then
						self.mamadead = true;
						self.mamacrab = nil;
						self:ResetMessageTimer(player);
							FrameMan:ClearScreenText(player);
						FrameMan:SetScreenText("That was a close one.  Go finish off their den.", player, 0, 5000, false);
							AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/cc2g.ogg", 0, -1);
					end

					if MovableMan:IsParticle(self.Sac) == false and self.sacdestroyed == false then
						self:ResetMessageTimer(player);
							FrameMan:ClearScreenText(player);
						FrameMan:SetScreenText("Looks like a cave-in happened down here.  Dig through that sand, there might be something under it.", player, 0, 5000, false);
						self.sacdestroyed = true;
					end

					if MovableMan:IsActor(self:GetControlledActor(player)) then
						if self.pitfall:IsInside(self:GetControlledActor(player).Pos) and self.downhole == false then
							self:ResetMessageTimer(player);
								FrameMan:ClearScreenText(player);
							FrameMan:SetScreenText("What the...?  Some kind of ancient bunker?  There's a computer of some kind down there, go see what's on it...", player, 0, 5000, false);
							AudioMan:ClearMusicQueue();
								AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/ruinexploration.ogg", 0, -1);
							self.downhole = true;
						end
					end

					if self.consoleArea:IsInside(self:GetControlledActor(player).Pos) then
						consoleobj = 1;
					end

					if self.sacdestroyed == true and self.downhole == false then
						invest2obj = 1;
					end

					if MovableMan:IsActor(brain) then--self.braindead[player] == false then
						self:AddObjectivePoint("Protect!", brain.AboveHUDPos + Vector(0,-8), Activity.TEAM_1, GameActivity.ARROWDOWN);
					end				
				end
			end
		end
		-- Game over, show the appropriate messages until a certain time
		elseif not self.GameOverTimer:IsPastSimMS(self.GameOverPeriod) then
		for player = 0, self.PlayerCount - 1 do
				local team = self:GetTeamOfPlayer(player);
				-- TODO: make more appropriate messages here for run out of funds endings
					if team == self.WinnerTeam then
						FrameMan:SetScreenText("These are cartesian coordinates...  Where could they possibly lead to?", player, 0, -1, false);
					else
						FrameMan:SetScreenText("Your brain has been lost!", player, 0, -1, false);
					end
		end
	end
		-- MARK THE OBJECTIVES
	for actor in MovableMan.Actors do
		if self.aggress == false then
			if not self.caveAreaA:IsInside(actor.Pos) and not self.caveAreaB:IsInside(actor.Pos) and actor.PresetName == "Crab" then
				self:AddObjectivePoint("Kill!", actor.AboveHUDPos, Activity.TEAM_1, GameActivity.ARROWDOWN);
			end
		end
		if self.mamadead == true then
			if actor.PresetName == "Crab" then
				self:AddObjectivePoint("Kill!", actor.AboveHUDPos, Activity.TEAM_1, GameActivity.ARROWDOWN);
			end
		end
	end

	if self.mamadead == false and MovableMan:IsActor(self.mamacrab) then
		self:AddObjectivePoint("Kill!", self.mamacrab.AboveHUDPos+Vector(0,-16), Activity.TEAM_1, GameActivity.ARROWDOWN);
		if self.mamajumptime:LeftTillSimMS(3000) < 0 and MovableMan:IsActor(self.target) then				
			self.mamacrab.Vel = Vector((self.target.Pos.X - self.mamacrab.Pos.X)*0.045,-15 + ((self.target.Pos.Y - self.mamacrab.Pos.Y)*0.025));
			self.mamajumptime:Reset();
		end
	elseif self.aggress == true and MovableMan:IsParticle(self.Sac) then
		self:AddObjectivePoint("Destroy!", self.Sac.Pos+Vector(0,-16), Activity.TEAM_1, GameActivity.ARROWDOWN);
	end

	--Reading the console
	if consoleobj == 1 then
		if MovableMan:IsParticle(self.litscreen) == false then
			self.litscreen = CreateAEmitter("Lit Screen");
			self.litscreen:EnableEmission(true);
			self.litscreen.Pos = Vector(1104,612);
			MovableMan:AddParticle(self.litscreen);
		end
		if self.deciphtimer:LeftTillSimMS(3000) > 0 then
				self:AddObjectivePoint("Loading... " .. math.ceil(self.deciphtimer:LeftTillSimMS(3000)/1000) .. " seconds left.", Vector(1104, 600), Activity.TEAM_1, GameActivity.ARROWDOWN);
		end
		if -self.deciphtimer:LeftTillSimMS(0) > 3000 then
			self.WinnerTeam = Activity.TEAM_1;
			ActivityMan:EndActivity();
		end
	else
		self.deciphtimer:Reset();
		if MovableMan:IsParticle(self.litscreen) then
			self.litscreen.Lifetime = 1;
		end
	end

	if self.downhole == true and consoleobj == 0 then
		self:AddObjectivePoint("Investigate!", Vector(1104, 600), Activity.TEAM_1, GameActivity.ARROWDOWN);
	end
	
	if invest2obj == 1 then
		self:AddObjectivePoint("Buy a digging tool and dig!", Vector(1350,350), Activity.TEAM_1, GameActivity.ARROWDOWN);
	end

	  	 -- Sort the objective points
	  	self:YSortObjectivePoints();
end