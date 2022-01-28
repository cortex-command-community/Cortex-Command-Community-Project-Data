package.loaded.Constants = nil; require("Constants");

-----------------------------------------------------------------------------------------
-- Start Activity
-----------------------------------------------------------------------------------------

function DoainarMission:StartActivity()
	print("START! -- DoainarMission:StartActivity()!");
	--TODO: Clean up this ugly-ass script!
	self.SpawnTimer = Timer();
	self.aggress = false;
	self.downhole = false;
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

	self.PlayerTeam = Activity.TEAM_1;
	self.CPUTeam = Activity.TEAM_2;

	self.Sac = CreateAEmitter("Eggsac");
	self.Sac.Pos = Vector(1274, 315);
	self.Sac.Team = self.CPUTeam;
	MovableMan:AddParticle(self.Sac);
	
	--Set all the underground doors to be quiet so that we don't ruin the surprise!
	for actor in MovableMan.AddedActors do
		if actor.ClassName == "ADoor" then
			actor = ToADoor(actor);
			actor.DoorMoveSound = nil;
			actor.DoorMoveStartSound = nil;
			actor.DoorMoveEndSound = nil;
			actor.DoorDirectionChangeSound = nil;
		end
	end

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		-- Check if we already have a brain assigned
		if self:PlayerActive(player) and self:PlayerHuman(player) and not self:GetPlayerBrain(player) then
			self.braindead[player] = false;
			local ship = CreateACRocket("Drop Crate");
			local brain = CreateAHuman("Brain Robot");
			brain:AddInventoryItem(CreateHDFirearm("Assault Rifle"));
			brain.AIMode = Actor.AIMODE_SENTRY;
			ship:AddInventoryItem(brain);
			ship.Pos.X = 50 + player * ship.Radius;
			ship.Vel.X = math.random(8, 12);
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

	self.mamacrab = CreateACrab("Mega Crab");
	self.mamacrab.Pos = Vector(1176, 368);
	self.mamacrab.Team = self.CPUTeam;
	MovableMan:AddActor(self.mamacrab);
	self.mamacrab.SpriteAnimDuration = self.mamacrab.SpriteAnimDuration * 10;
	self.mamacrab.Status = Actor.INACTIVE;
	self.mamacrab.PinStrength = 1;

	self.target = self:GetPlayerBrain(Activity.PLAYER_1);
	
	SceneMan:MakeAllUnseen(Vector(36, 36), self.PlayerTeam);
end

-----------------------------------------------------------------------------------------
-- Pause Activity
-----------------------------------------------------------------------------------------

function DoainarMission:PauseActivity()
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
	-- Clear all objective markers, they get re-added each frame
	self:ClearObjectivePoints();
	if self.mamacrab and MovableMan:IsActor(self.mamacrab) then
		if not MovableMan:IsActor(self.target) then
			self.target = MovableMan:GetClosestTeamActor(self.PlayerTeam, Activity.PLAYER_NONE, self.mamacrab.Pos, SceneMan.SceneWidth, Vector(), self.mamacrab);
		end
	else
		self.mamacrab = nil;
	end
	local crabcount = 0;
	local crabsOutside = 0;
	for actor in MovableMan.Actors do
		if actor.PresetName == "Crab" then
			crabcount = crabcount + 1;
			if not self.mamacrab then
				self:AddObjectivePoint("Kill!", actor.AboveHUDPos, self.PlayerTeam, GameActivity.ARROWDOWN);
			elseif not self.aggress and not self.caveAreaA:IsInside(actor.Pos) and not self.caveAreaB:IsInside(actor.Pos) then
				self:AddObjectivePoint("Kill!", actor.AboveHUDPos, self.PlayerTeam, GameActivity.ARROWDOWN);
				crabsOutside = crabsOutside + 1;
			end
			if actor.Age < TimerMan.DeltaTimeMS then
				actor.AIMode = math.random() < 0.5 and Actor.AIMODE_BRAINHUNT or Actor.AIMODE_PATROL;
			end
		end
	end

	local consoleobj = 0;
	local invest2obj = 0;
	if not (self.ActivityState == Activity.OVER) then
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
					if self.aggress == false then
						if MovableMan:IsActor(self.mamacrab) and (crabsOutside == 0 or self.mamacrab.PinStrength == 0 or self.mamacrab.Health < self.mamacrab.MaxHealth) then
							self.mamacrab.SpriteAnimDuration = self.mamacrab.SpriteAnimDuration * 0.1;
							self.aggress = true;

							self.mamacrab.PinStrength = 0;
							self.mamacrab.Status = Actor.UNSTABLE;
							
							self.target = MovableMan:GetClosestTeamActor(self.PlayerTeam, Activity.PLAYER_NONE, self.mamacrab.Pos, SceneMan.SceneWidth, Vector(), self.mamacrab);

							self:ResetMessageTimer(player);
							FrameMan:ClearScreenText(player);
							FrameMan:SetScreenText("Uh oh, looks like you angered the mother crab!  Kill it before it kills you!", player, 0, 5000, false);
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

					if not self.mamacrab and self.mamadead == false and self.aggress == true then
						self.mamadead = true;
						self:ResetMessageTimer(player);
						FrameMan:ClearScreenText(player);
						FrameMan:SetScreenText("That was a close one.  Go finish off their den!", player, 0, 5000, false);
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
							FrameMan:SetScreenText("What the...?  It's some kind of ancient bunker?  There seems to be a control panel inside, go see what's on it...", player, 0, 5000, false);
							AudioMan:ClearMusicQueue();
							AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/ruinexploration.ogg", 0, -1);
							self.downhole = true;
						end
						if self.consoleArea:IsInside(self:GetControlledActor(player).Pos) then
							consoleobj = 1;
						end
					end

					if self.sacdestroyed == true and self.downhole == false then
						invest2obj = 1;
					end

					if MovableMan:IsActor(brain) then--self.braindead[player] == false then
						self:AddObjectivePoint("Protect!", brain.AboveHUDPos + Vector(0, -8), self.PlayerTeam, GameActivity.ARROWDOWN);
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

	if self.mamadead == false and MovableMan:IsActor(self.mamacrab) and self.mamacrab.Status ~= Actor.INACTIVE then
		self:AddObjectivePoint("Kill!", self.mamacrab.AboveHUDPos+Vector(0, -16), self.PlayerTeam, GameActivity.ARROWDOWN);
		if self.mamajumptime:LeftTillSimMS(3000) < 0 and MovableMan:IsActor(self.target) and SceneMan:GetTerrMatter(self.mamacrab.Pos.X, self.mamacrab.Pos.Y + self.mamacrab:GetSpriteHeight() * 0.5) then				
			local jumpVector = Vector((self.target.Pos.X - self.mamacrab.Pos.X) * 0.045, -15 + ((self.target.Pos.Y - self.mamacrab.Pos.Y) * 0.025));
			self.mamacrab.Vel = self.mamacrab.Vel + jumpVector:SetMagnitude(math.min(jumpVector.Magnitude, 30));
			self.mamacrab.Status = Actor.UNSTABLE;
			self.mamajumptime:Reset();
		end
	elseif self.aggress == true and MovableMan:IsParticle(self.Sac) then
		self:AddObjectivePoint("Destroy!", self.Sac.Pos+Vector(0,-16), self.PlayerTeam, GameActivity.ARROWDOWN);
	end
	if self.Sac and MovableMan:IsParticle(self.Sac) then
		self.Sac.Throttle = 2/(1 + (crabcount + self.Sac.WoundCount) * 0.1) - 1;
		self.Sac.SpriteAnimDuration = 600 - 300 * self.Sac.Throttle;
	else
		self.Sac = nil;
	end

	--Reading the console
	if consoleobj == 1 then
		if MovableMan:IsParticle(self.litscreen) == false then
			self.litscreen = CreateAEmitter("Lit Screen");
			self.litscreen:EnableEmission(true);
			self.litscreen.Pos = Vector(1104, 612);
			MovableMan:AddParticle(self.litscreen);
		end
		if self.deciphtimer:LeftTillSimMS(3000) > 0 then
			self:AddObjectivePoint("Loading... " .. math.ceil(self.deciphtimer:LeftTillSimMS(3000)/1000) .. " seconds left.", Vector(1104, 600), self.PlayerTeam, GameActivity.ARROWDOWN);
		end
		if -self.deciphtimer:LeftTillSimMS(0) > 3000 then
			self.WinnerTeam = self.PlayerTeam;
			self:ClearObjectivePoints();
			ActivityMan:EndActivity();
		end
	else
		self.deciphtimer:Reset();
		if MovableMan:IsParticle(self.litscreen) then
			self.litscreen.Lifetime = 1;
		end
	end

	if self.downhole == true and consoleobj == 0 then
		self:AddObjectivePoint("Investigate!", Vector(1104, 600), self.PlayerTeam, GameActivity.ARROWDOWN);
	end
	
	if invest2obj == 1 then
		self:AddObjectivePoint("Get a digging tool and dig!", Vector(1390, 380), self.PlayerTeam, GameActivity.ARROWDOWN);
	end
	 --Sort the objective points
	self:YSortObjectivePoints();
end