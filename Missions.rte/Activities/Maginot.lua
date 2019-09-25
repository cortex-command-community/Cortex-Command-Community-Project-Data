package.loaded.Constants = nil; require("Constants");

-----------------------------------------------------------------------------------------
-- Test a Scene for Compatibility
-----------------------------------------------------------------------------------------

function MaginotMission:SceneTest()
--[[ THIS TEST IS DONE AUTOMATICALLY BY THE GAME NOW; IT SCANS THE SCRIPT FOR ANY MENTIONS OF "GetArea" AND TESTS THE SCENES FOR HAVING THOSE USED AREAS DEFINED!
	-- See if the required areas are present in the test scene
	if not (TestScene:HasArea("LZ Team 2") and TestScene:HasArea("EnemySneakSpawn2") and
			TestScene:HasArea("RescueTrigger") and TestScene:HasArea("RescueArea")) then
		-- If the test scene failed the compatibility test, invalidate it
		TestScene = nil;
	end
--]]
end

-----------------------------------------------------------------------------------------
-- Start Activity
-----------------------------------------------------------------------------------------

function MaginotMission:StartActivity()
	--Set the fight stage.
	self.FightStage = { NOFIGHT = 0, DEFENDA = 1, DEFENDB = 2, RUN = 3 }
	self.CurrentFightStage = self.FightStage.NOFIGHT

	--Front landing zone.
	self.attackLZ1 = SceneMan.Scene:GetArea("LZ Team 2")

	--Back sneaky entrance.
	self.attackLZ2 = SceneMan.Scene:GetArea("EnemySneakSpawn2")

	--Trigger zone for arrival of escape craft.
	self.RescueTrigger = SceneMan.Scene:GetArea("RescueTrigger")

	--Zone for the escape craft to land in.
	self.RescueLZ = SceneMan.Scene:GetArea("RescueArea")

	--This times the round.
	self.RoundTimer = Timer()

	--How long to wait between spawns.
	self.SpawnTimer = Timer()
	self.spawnTime = 30000 * math.exp(self.Difficulty*-0.014) * rte.SpawnIntervalScale	-- Scale spawn time from 20s to 5s. Normal = 10s

	--Stores who has died.
	self.braindead = {}

	--Stores the brain's ideal frozen position.
	self.spawnPos = {}
	
	-- Set the funds
	self:SetTeamFunds(self:GetStartingGold(), Activity.TEAM_1)
	
	self.EnemyTech = self:GetTeamTech(Activity.TEAM_2);

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) and not self:GetPlayerBrain(player) then
			self.braindead[player] = false
			--Create the brain.
			local brain = CreateAHuman("Brain Robot", "Base.rte")
			--Move the brain to the right spot.
			brain.Pos = Vector(2328 + player * 24,1240)
			--Store this position.
			self.spawnPos[player] = brain.Pos
			--Equip the brain with a pistol.
			brain:AddInventoryItem(CreateHDFirearm("Pistol", "Coalition.rte"))
			--Set the brains to players.
			self:SetPlayerBrain(brain, player)
			--Set the default landing zone.
			self:SetLandingZone(self:GetPlayerBrain(player).Pos, player)
			-- Set the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
			self:SetObservationTarget(self:GetPlayerBrain(player).Pos, player)
			-- Let the spawn into the world, passing ownership
			MovableMan:AddActor(brain)
			-- Set the brain to Sentry mode so it doesn't try to leave on you.
			brain.AIMode = Actor.AIMODE_SENTRY
			self:ResetMessageTimer(player)
			FrameMan:ClearScreenText(player)
		end
	end

	if self:GetFogOfWarEnabled() then
		SceneMan:MakeAllUnseen(Vector(25, 25), Activity.TEAM_1)
	end
end


function MaginotMission:EndActivity()
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

function MaginotMission:UpdateActivity()
	self:ClearObjectivePoints()	-- Clear the points, as they are re-added each frame.
	
	-- Iterate through all human players
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			-- The current player's team
			local team = self:GetTeamOfPlayer(player)
			
			-- Make sure the game is not already ending
			if self.ActivityState ~= Activity.OVER then
				-- Check if any player's brain is dead
				local brain = self:GetPlayerBrain(player)
				if not brain or not MovableMan:IsActor(brain) or not brain:HasObjectInGroup("Brains") then
					self:SetPlayerBrain(nil, player)
					-- Try to find a new unasigned brain this player can use instead, or if his old brain entered a craft
					local newBrain = MovableMan:GetUnassignedBrain(team)
					-- Found new brain actor, assign it and keep on truckin'
					if newBrain and not self.braindead[player] then
						self:SetPlayerBrain(newBrain, player)
						if MovableMan:IsActor(newBrain) then
							self:SwitchToActor(newBrain, player, team)
						end
					else
						FrameMan:SetScreenText("Your brain has been lost!", player, 333, -1, false)
						self.braindead[player] = true
						
						-- Now see if all brains of self player's team are dead, and if so, end the game
						local gameOver = true
						for plr = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
							if self:PlayerActive(plr) and self:PlayerHuman(plr) and not self.braindead[plr] then
								gameOver = false
								break
							end
						end
					
						if gameOver then
							self.WinnerTeam = self:OtherTeam(team)
							ActivityMan:EndActivity()
						end
						self:ResetMessageTimer(player)
					end
				else
					self:AddObjectivePoint("Protect!", brain.AboveHUDPos, Activity.TEAM_1, GameActivity.ARROWDOWN)
					
					-- Update the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
					self:SetObservationTarget(brain.Pos, player)
					-- If it's not time to escape yet, stop the brain from moving.
					if self.CurrentFightStage ~= self.FightStage.RUN then
						local b = self:GetPlayerBrain(player)
						b.Vel = Vector(0,0)
						b.Pos = self.spawnPos[player]
						b.AngularVel = 0
						b.RotAngle = 0
					end
				end
			-- Game over, show the appropriate messages until a certain time
			elseif not self.GameOverTimer:IsPastSimMS(self.GameOverPeriod) then
				-- TODO: make more appropriate messages here for run out of funds endings
				if team == self.WinnerTeam then
					FrameMan:SetScreenText("At least you survived...  But where are they coming from?", player, 0, -1, false)
				else
					FrameMan:SetScreenText("Your brain has been lost!", player, 0, -1, false)
				end
			end
		end
	end

	--Set up the AI modes once everything is spawned.
	if self.RoundTimer:IsPastSimMS(250) and not self.initialized then
		self.initialized = true
		
		for actor in MovableMan.Actors do
			actor.AIMode = Actor.AIMODE_SENTRY
		end
	end

	--Check whether to advance the fight stage.
	if self.RoundTimer:IsPastSimMS(15000) and self.CurrentFightStage < self.FightStage.DEFENDA then
		-- X seconds before starting the fight.
		self.CurrentFightStage = self.FightStage.DEFENDA
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				self:ResetMessageTimer(player)
				FrameMan:ClearScreenText(player)
				FrameMan:SetScreenText("DEFEND THE BASE AGAINST THE ATTACK!", player, 1500, 9000, true)
			end
		end
	elseif self.RoundTimer:IsPastSimMS(220000) and self.CurrentFightStage < self.FightStage.DEFENDB then
		-- Y seconds before the enemies come through the back entrance.
		self.CurrentFightStage = self.FightStage.DEFENDB
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				self:ResetMessageTimer(player)
				FrameMan:ClearScreenText(player)
				FrameMan:SetScreenText("CAUTION! MORE ENEMIES INCOMING FROM THE RIGHT SIDE ENTRANCE!", player, 1500, 9000, true)
			end
		end
	elseif self.RoundTimer:IsPastSimMS(400000) and self.CurrentFightStage < self.FightStage.RUN then
		-- After Z seconds, begin the escape.
		self.CurrentFightStage = self.FightStage.RUN
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				self:ResetMessageTimer(player)
				FrameMan:ClearScreenText(player)
				if self.PlayerCount == 1 then
					FrameMan:SetScreenText("ENEMIES ARE TOO OVERWHELMING! EVACUATE BUNKER IMMEDIATELY! GET YOUR BRAIN TO THE TOP OF THE BUNKER", player, 1500, 10000, true)
				else
					FrameMan:SetScreenText("ENEMIES ARE TOO OVERWHELMING! EVACUATE BUNKER IMMEDIATELY! GET ATLEAST ONE BRAIN TO THE TOP OF THE BUNKER", player, 1500, 10000, true)
				end
			end
		end
	end

	--Spawn enemies.
	if self.SpawnTimer:IsPastSimMS(self.spawnTime) and MovableMan:GetTeamMOIDCount(Activity.TEAM_2) <= rte.DefenderMOIDMax then
		self.SpawnTimer:Reset()	-- Wait another period for next spawn
		
		if self.CurrentFightStage >= self.FightStage.DEFENDA then
			--Spawn 2 Dummies in a Dummy Drops Ship with a randomly-selected weapon, a digger, and maybe a grenade.
			local ship = RandomACDropShip("Craft", self.EnemyTech)
			if not ship then
				ship = CreateACDropship("Drop Ship MK1", "Base.rte");
			end
			
			if ship then
				local dummya = RandomAHuman("Light Infantry", self.EnemyTech)
				if dummya then
					local guna = RandomHDFirearm("Primary Weapons", self.EnemyTech)
					if guna then
						dummya:AddInventoryItem(guna)
					end
				end
				
				if math.random() > 0.4 then
					dummya:AddInventoryItem(RandomTDExplosive("Grenades", self.EnemyTech))
				else
					local digger = RandomHDFirearm("Diggers", self.EnemyTech)
					if not digger then
						digger = RandomHDFirearm("Diggers", "Base.rte")
					end
					if digger then
						dummya:AddInventoryItem(digger)
					end
				end
				
				if dummya then
					ship:AddInventoryItem(dummya)
				end
				
				if math.random() > 0.7 then
					local dummyb = RandomAHuman("Light Infantry", self.EnemyTech)
					if dummyb then
						local gunb = RandomHDFirearm("Primary Weapons", self.EnemyTech)
						if gunb then
							dummyb:AddInventoryItem(gunb)
						end
					end
						
					if math.random() > 0.4 then
						dummyb:AddInventoryItem(RandomTDExplosive("Grenades", self.EnemyTech))
					else
						local digger = RandomHDFirearm("Diggers", self.EnemyTech)
						if not digger then
							digger = RandomHDFirearm("Diggers", "Base.rte")
						end
						if digger then
							dummyb:AddInventoryItem(digger)
						end
					end

					if dummyb then
						ship:AddInventoryItem(dummyb)
					end
				end
				-- See if there is a designated LZ Area for attackers, and only land over it
				if self.attackLZ1 then
					ship.Pos = Vector(self.attackLZ1:GetRandomPoint().X, 0)
				else
					-- Will appear anywhere when there is no designated LZ
					ship.Pos = Vector(SceneMan.Scene.Width * PosRand(), 0)
				end
				
				ship.Team = Activity.TEAM_2
				ship:SetControllerMode(Controller.CIM_AI, -1)
				-- Let the spawn into the world, passing ownership
				MovableMan:AddActor(ship)
			end
		end
		
		if self.CurrentFightStage >= self.FightStage.DEFENDB then
			--Spawn a fully-equipped Dummy or a Dreadnought to sneak in from the right.
			if MovableMan:GetTeamMOIDCount(Activity.TEAM_2) <= rte.DefenderMOIDMax then
				local actor
				local y = math.random()
				if y > 0.05 then
					actor = RandomAHuman("Light Infantry", self.EnemyTech)
					if actor then
						actor:AddInventoryItem(RandomHDFirearm("Primary Weapons", self.EnemyTech))
						if math.random() > 0.1 then
							actor:AddInventoryItem(RandomTDExplosive("Grenades", self.EnemyTech))
						else
							actor:AddInventoryItem(RandomHDFirearm("Diggers", self.EnemyTech))
						end
					end
				else
					actor = RandomACrab("Mecha", self.EnemyTech)
				end

				if actor then
					actor.Team = Activity.TEAM_2
					actor.AIMode = Actor.AIMODE_BRAINHUNT				
					actor.Pos = Vector(SceneMan.Scene.Width-6, self.attackLZ2:GetCenterPoint().Y)
					MovableMan:AddActor(actor)
				end
			end
		end
	end

	--Escape mechanism.  If the fight stage is the part where you must escape...
	if self.CurrentFightStage == self.FightStage.RUN then
		--For all players, do the following.
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) and not self.braindead[player] then
				--If the player's brain is in the escape zone and the escape ship hasn't spawned yet...
				if self.RescueTrigger:IsInside(self:GetPlayerBrain(player).Pos) and not MovableMan:IsActor(self.EscapeShip) then
					--Make a ship land in the escape zone.
					self.EscapeShip = CreateACRocket("Rocket MK2", "Base.rte")
					self.EscapeShip.Pos = Vector(self.RescueLZ:GetRandomPoint().X, 0)
					self.EscapeShip.Team = Activity.TEAM_1
					self.EscapeShip:SetControllerMode(Controller.CIM_AI, -1)
					
					--Run through all players and give them a message that a ship is arriving.
					for plr = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
						if self:PlayerActive(plr) and self:PlayerHuman(plr) and not self.braindead[plr] then
							self:ResetMessageTimer(plr)
							FrameMan:ClearScreenText(plr)
							FrameMan:SetScreenText("Sending down a ship...", plr, 0, 5000, false)
						end
					end
					
					MovableMan:AddActor(self.EscapeShip)
				end
			end
		end
	end

	--OBJECTIVES
	if self.CurrentFightStage == self.FightStage.RUN then
		self:AddObjectivePoint("Escape!", self.RescueLZ:GetCenterPoint() - Vector(0,32), Activity.TEAM_1, GameActivity.ARROWDOWN)
	end

	-- Sort the objective points
	self:YSortObjectivePoints()
	
	if not self.garbage then
		collectgarbage("step")
		self.garbage = 10
	else
		self.garbage = self.garbage - 1
		if self.garbage < 1 then
			self.garbage = nil
		end
	end
end

-----------------------------------------------------------------------------------------
-- Craft Entered Orbit
-----------------------------------------------------------------------------------------

function MaginotMission:CraftEnteredOrbit()
	--If a craft leaves with the brain robot...
	if self.OrbitedCraft:HasObjectInGroup("Brains") then
		--Team 1 wins!
		self.WinnerTeam = Activity.TEAM_1
		ActivityMan:EndActivity()
		
		--Tell the script to stop running for brains as the game has ended.
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			self.braindead[player] = true
			self:SetPlayerBrain(nil, player)
		end
	end
end