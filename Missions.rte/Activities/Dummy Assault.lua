package.loaded.Constants = nil; require("Constants")

-----------------------------------------------------------------------------------------
-- Start Activity
-----------------------------------------------------------------------------------------

function DummyAssault:StartActivity()
	self.SpawnTimer = Timer()
	self.AlarmZone = SceneMan.Scene:GetArea("Dummy Base Alarm")
	self.FactoryZone = SceneMan.Scene:GetArea("Dummy Factory Invasion")
	self.SearchArea = SceneMan.Scene:GetArea("Search Area")
	self.braindead = {}
	self.spawnTime = 30000*math.exp(self.Difficulty*-0.011)	-- Scale spawn time from 30s to 10s. Normal is ~17s
	--------------------------
	-- Set up teams

	-- Team 2 is always CPU
	self.CPUTeam = Activity.TEAM_2
	self.CPUTech = self:GetTeamTech(Activity.TEAM_2);
	
	--------------------------
	-- Set up players
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			-- Check if we already have a brain assigned
			if not self:GetPlayerBrain(player) then
				self.braindead[player] = false
				local brain = CreateActor("Brain Case", "Base.rte")
				brain.Pos = Vector(3348, 1128-player*24)
				brain.RotAngle = math.rad(270)
				
				-- Let the spawn into the world, passing ownership
				MovableMan:AddActor(brain)
				
				-- Set the found brain to be the selected actor at start
				self:SetPlayerBrain(brain, player)
				SceneMan:SetScroll(brain.Pos, player)
				self:SetLandingZone(brain.Pos, player)
				
				-- Set the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
				self:SetObservationTarget(brain.Pos, player)
			end
		end
	end

	-- Set up AI modes for the Actors that have been added to the scene by the scene definition
	for actor in MovableMan.AddedActors do
		if actor.Team == self.CPUTeam then
			actor.AIMode = Actor.AIMODE_SENTRY
			if actor.PresetName == "Dummy Controller" then
				self.CPUBrain = actor
			end
		end
	end

	-- Set the funds
	self:SetTeamFunds(self:GetStartingGold(), Activity.TEAM_1)
	
	if self:GetFogOfWarEnabled() then
		-- Make the scene unseen for the player team
		SceneMan:MakeAllUnseen(Vector(25, 25), Activity.TEAM_1)
		for x = SceneMan.SceneWidth-1000, SceneMan.SceneWidth-20, 25 do	-- Reveal the LZ
			SceneMan:CastSeeRay(Activity.TEAM_1, Vector(x,-25), Vector(0,SceneMan.SceneHeight), Vector(), 4, 20)
		end
		
		-- Hide the player LZ
		SceneMan:MakeAllUnseen(Vector(50, 50), Activity.TEAM_2)
		for y = 0, SceneMan.SceneHeight, 50 do
			for x = 0, SceneMan.SceneWidth-1000, 50 do
				SceneMan:RevealUnseen(x, y, Activity.TEAM_2)
			end
		end
	end
end


function DummyAssault:EndActivity()
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


-----------------------------------------------------------------------------------------
-- Update Activity
-----------------------------------------------------------------------------------------

function DummyAssault:UpdateActivity()
	-- Clear all objective markers, they get re-added each frame
	self:ClearObjectivePoints()
	if self.ActivityState ~= Activity.OVER then
		-- Iterate through all human players
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				-- The current player's team
				local team = self:GetTeamOfPlayer(player)
				-- Make sure the game is not already ending
				-- Check if any player's brain is dead
				local brain = self:GetPlayerBrain(player)
				if not brain or not MovableMan:IsActor(brain) or not brain:HasObjectInGroup("Brains") then
					self:SetPlayerBrain(nil, player)
					-- Try to find a new unasigned brain this player can use instead, or if his old brain entered a craft
					local newBrain = MovableMan:GetUnassignedBrain(team)
					-- Found new brain actor, assign it and keep on truckin'
					if newBrain and not self.braindead[player] then
						self:SetPlayerBrain(newBrain, player)
						self:SwitchToActor(newBrain, player, team)
					else
						FrameMan:SetScreenText("Your brain has been lost!", player, 333, -1, false)
						self.braindead[player] = true
						-- Now see if all brains of self player's team are dead, and if so, end the game
						if not MovableMan:GetFirstBrainActor(team) then
							self.WinnerTeam = self:OtherTeam(team)
							ActivityMan:EndActivity()
						end
					end
				else
					-- Update the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
					self:SetObservationTarget(brain.Pos, player)
				end
			end
		end
		
		-- Mark the enemy brain.
		if MovableMan:IsActor(self.CPUBrain) then
			self:AddObjectivePoint("Destroy!", self.CPUBrain.AboveHUDPos+Vector(0,-16), Activity.TEAM_1, GameActivity.ARROWDOWN)
		else
			--If it doesn't exist, it's gone!  Player wins!
			self.WinnerTeam = Activity.TEAM_1
			ActivityMan:EndActivity()
		end
	-- Game over, show the appropriate messages until a certain time
	elseif not self.GameOverTimer:IsPastSimMS(self.GameOverPeriod) then
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				local team = self:GetTeamOfPlayer(player)
				-- TODO: make more appropriate messages here for run out of funds endings
				if team == self.WinnerTeam then
					FrameMan:SetScreenText("Congratulations, you've destroyed the enemy base!", player, 0, -1, false)
				else
					FrameMan:SetScreenText("Your brain has been lost!", player, 0, -1, false)
				end
			end
		end
	end

	if self.AlarmTriggered then
		if self.SpawnTimer:IsPastSimMS(self.spawnTime) then
			self.SpawnTimer:Reset()
			
			if MovableMan:GetTeamMOIDCount(Activity.TEAM_2) < rte.DefenderMOIDMax then
				local actor
				if math.random() > 0.05 then
					actor = RandomAHuman("Infantry Light", self.CPUTech)
					if math.random() > 0.5 then
						actor.AIMode = Actor.AIMODE_BRAINHUNT
						if math.random() > 0.5 then
							actor:AddInventoryItem(RandomHDFirearm("Diggers", self.CPUTech))
						end
					else
						actor.AIMode = Actor.AIMODE_GOTO
						actor:ClearAIWaypoints()
						actor:AddAISceneWaypoint(self.SearchArea:GetRandomPoint())
					end
					
					actor:AddInventoryItem(RandomHDFirearm("Primary Weapons", self.CPUTech))
					if math.random() > 0.1 then
						actor:AddInventoryItem(RandomTDExplosive("Grenades", self.CPUTech))
					end
				else
					actor = RandomACrab("Mecha", self.CPUTech)
					actor.AIMode = Actor.AIMODE_BRAINHUNT
				end
				
				actor.Team = Activity.TEAM_2
				actor.Pos = Vector(5,550)
				MovableMan:AddActor(actor)
			end
		end
	elseif self.SpawnTimer:IsPastSimMS(1000) then	-- Check the alarm once per second
		self.SpawnTimer:Reset()
		
		for actor in MovableMan.Actors do
			if actor.Team == Activity.TEAM_1 and self.AlarmZone:IsInside(actor.Pos) then
				self.AlarmTriggered = true
				break
			end
		end
	end

	-- Sort the objective points
	self:YSortObjectivePoints()
end