--[[

*** INSTRUCTIONS ***

This activity can be run on any scene with a "Bunker Breach LZ" and "Brain" area.
The player brains spawn in the "Bunker Breach LZ" area and the AI brain bot in the "Brain" area.
The script will look for player units and send reinforcements to attack them.

When using with randomized bunkers which has multiple brain chambers or other non-Brain Hideout deployments
only one brain at random chamber will be spawned. To avoid wasting MOs for this actors you may define a "Brain Chamber"
area. All actors inside "Brain Chamber" but without a brain nearby will be removed as useless.

Add defender units by placing areas named:
"Sniper1" to "Sniper10"
"Light1" to "Light10"	<-- light actors, light weapons
"Heavy1" to "Heavy10"	<-- heavy actors, heavy weapons
"Crab1" to "Crab10"
"Turret1" to "Turret10"
"Engineer1" to "Engineer10"	<-- light actors, digger, gold dig AI-mode
"Anti-Air1" to "Anti-Air5"

Don't place more defenders than the MOID limit can handle (15 defenders plus 3 doors equals about 130 of 255 available IDs).
--]]

dofile("Base.rte/Constants.lua")

function BunkerBreach:StartActivity()
	collectgarbage("collect")

	-- Select a tech for the CPU player
	self.CPUTechName = self:GetTeamTech(self.CPUTeam);	-- Select a tech for the CPU player
	gPrevAITech = self.CPUTechName	-- Store the AI tech in a global so we don't pick the same tech again next round
	self.CPUTechID = PresetMan:GetModuleID(self.CPUTechName)
	
	self:SetTeamFunds(math.ceil((3000 + self.Difficulty * 50) * rte.StartingFundsScale), self.CPUTeam)
	self:SetTeamFunds(self:GetStartingGold(), Activity.TEAM_1)
	
	-- This line will filter out all scenes witout any "Bunker Breach LZ" area
	local PlayerLZ = SceneMan.Scene:GetArea("Bunker Breach LZ")

	-- Timers
	self.WinTimer = Timer()
	self.SpawnTimer = Timer()
	self.spawnDelay = (80000 - self.Difficulty * 250) * rte.SpawnIntervalScale
	self.HunterTimer = Timer()
	self.HunterDelay = self.spawnDelay + 10000
	self.IntruderAlertTimer = Timer()
	self.IntruderDisbatchDelay = 5000

	-- Add player brains
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			local Brain = CreateAHuman("Brain Robot", "Base.rte")
			if Brain then
				local Weapon = RandomHDFirearm("Light Weapons", self:GetTeamTech(self:GetTeamOfPlayer(player)))
				if Weapon then
					Brain:AddInventoryItem(Weapon)
				end

				local Digger = CreateHDFirearm("Medium Digger", "Base.rte")
				if Digger then
					Brain:AddInventoryItem(Digger)
				end

				Brain.AIMode = Actor.AIMODE_SENTRY
				Brain.Team = self:GetTeamOfPlayer(player)

				local lzX = PlayerLZ:GetRandomPoint().X

				-- make sure we are inside the scene
				if SceneMan.SceneWrapsX then
					if lzX < 0 then
						lzX = lzX + SceneMan.SceneWidth
					elseif lzX >= SceneMan.SceneWidth then
						lzX = lzX - SceneMan.SceneWidth
					end
				else
					lzX = math.max(math.min(lzX, SceneMan.SceneWidth-50), 50)
				end
				
				Brain.Pos = SceneMan:MovePointToGround(Vector(lzX, 0), Brain.Height*0.3, 3)
				self:SetPlayerBrain(Brain, player)
				self:SetObservationTarget(Brain.Pos, player)
				MovableMan:AddActor(Brain)
			end
		end
	end

	if SceneMan.Scene:HasArea("Brain") then
		self.CPUBrain = self:CreateBrainBot()
		if self.CPUBrain then
			self.CPUBrain.Pos = SceneMan.Scene:GetOptionalArea("Brain"):GetCenterPoint()
			MovableMan:AddActor(self.CPUBrain)
		end
	else
		-- Look for a brain among actors created by the deployments
		for actor in MovableMan.AddedActors do
			if actor.Team == self.CPUTeam and actor:IsInGroup("Brains") then
				self.CPUBrain = actor
			end
		end
	end
	
	if SceneMan.Scene:HasArea("Brain Chamber") then
		self.BrainChamber = SceneMan.Scene:GetOptionalArea("Brain Chamber")
		
		-- Set all useless actors, i.e. those who should guard brain in the brain chamber but their brain is in another castle
		-- to delete themselves, because otherwise they are most likely to stand there for the whole battle and waste MOs
		for actor in MovableMan.AddedActors do
			if actor.Team == self.CPUTeam and self.BrainChamber:IsInside(actor.Pos) and
				SceneMan:ShortestDistance(actor.Pos, self.CPUBrain.Pos, false).Magnitude > 200 and 
				actor.ClassName == "AHuman" or actor.ClassName == "ACrab" then
				-- actor.AIMode = Actor.AIMODE_BRAINHUNT;
				actor.ToDelete = true
			end
		end
	end

	local GuardArea = "Sniper"
	for i = 1, 10 do
		if SceneMan.Scene:HasArea(GuardArea..i) then
			local Guard = self:CreateSniper(Actor.AIMODE_SENTRY)
			if Guard then
				Guard.Pos = SceneMan.Scene:GetArea(GuardArea..i):GetCenterPoint()
				MovableMan:AddActor(Guard)
			end
		else
			break
		end
	end

	GuardArea = "Light"
	for i = 1, 10 do
		if SceneMan.Scene:HasArea(GuardArea..i) then
			local Guard = self:CreateLightInfantry(Actor.AIMODE_SENTRY)
			if Guard then
				Guard.Pos = SceneMan.Scene:GetArea(GuardArea..i):GetCenterPoint()
				MovableMan:AddActor(Guard)
			end
		else
			break
		end
	end

	GuardArea = "Heavy"
	for i = 1, 10 do
		if SceneMan.Scene:HasArea(GuardArea..i) then
			local Guard = self:CreateHeavyInfantry(Actor.AIMODE_SENTRY)
			if Guard then
				Guard.Pos = SceneMan.Scene:GetArea(GuardArea..i):GetCenterPoint()
				MovableMan:AddActor(Guard)
			end
		else
			break
		end
	end

	GuardArea = "Crab"
	for i = 1, 10 do
		if SceneMan.Scene:HasArea(GuardArea..i) then
			local Guard = self:CreateCrab(Actor.AIMODE_SENTRY)
			if Guard then
				Guard.Pos = SceneMan.Scene:GetArea(GuardArea..i):GetCenterPoint()
				MovableMan:AddActor(Guard)
			end
		else
			break
		end
	end

	GuardArea = "Turret"
	for i = 1, 10 do
		if SceneMan.Scene:HasArea(GuardArea..i) then
			local Guard = self:CreateTurret()
			if Guard then
				Guard.Pos = SceneMan.Scene:GetArea(GuardArea..i):GetCenterPoint()
				MovableMan:AddActor(Guard)
			end
		else
			break
		end
	end

	GuardArea = "Engineer"
	for i = 1, 10 do
		if SceneMan.Scene:HasArea(GuardArea..i) then
			local Guard = self:CreateEngineer()
			if Guard then
				Guard.Pos = SceneMan.Scene:GetArea(GuardArea..i):GetCenterPoint()
				MovableMan:AddActor(Guard)
			end
		else
			break
		end
	end
	
	GuardArea = "Anti-Air"
	for i = 1, 5 do
		if SceneMan.Scene:HasArea(GuardArea..i) then
			local Guard = self:CreateAntiAir()
			if Guard then
				Guard.Pos = SceneMan.Scene:GetArea(GuardArea..i):GetCenterPoint()
				MovableMan:AddActor(Guard)
			end
		else
			break
		end
	end

	-- Add fog
	if self:GetFogOfWarEnabled() then
		SceneMan:MakeAllUnseen(Vector(65, 65), self.CPUTeam)
		SceneMan:MakeAllUnseen(Vector(25, 25), Activity.TEAM_1)

		-- Lift the fog around friendly actors
		for Act in MovableMan.AddedActors do
			for ang = 0, math.pi*2, 0.1 do
				SceneMan:CastSeeRay(Act.Team, Act.EyePos, Vector(130+FrameMan.PlayerScreenWidth*0.5, 0):RadRotate(ang), Vector(), 1, 4)
			end
		end
		
		-- Assume that the AI has scouted the terrain
		for x = 0, SceneMan.SceneWidth-1, 65 do
			SceneMan:CastSeeRay(self.CPUTeam, Vector(x,0), Vector(0, SceneMan.SceneHeight), Vector(), 1, 9)
		end
	end
	
	-- Store data about terrain and enemy actors in the LZ map, use it to pick safe landing zones
	self.LZMap = require("Activities/LandingZoneMap")
	--self.LZMap = dofile("Base.rte/Activities/LandingZoneMap.lua")
	self.LZMap:Initialize({self.CPUTeam})	-- a list of AI teams
end


function BunkerBreach:EndActivity()
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


function BunkerBreach:UpdateActivity()
	if self.ActivityState == Activity.OVER then
		return
	end
	
	if self.WinTimer:IsPastRealMS(3000) then
		-- Check win conditions
		self.WinTimer:Reset()

		if not MovableMan:IsActor(self.CPUBrain) then
			self.WinnerTeam = Activity.TEAM_1
			MovableMan:KillAllActors(self.WinnerTeam)
			ActivityMan:EndActivity()
			return
		else
			local players = 0
			for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
				if self:PlayerActive(player) and self:PlayerHuman(player) then
					local Brain = self:GetPlayerBrain(player)
					
					-- Look for a new brain
					if not Brain or not MovableMan:ValidMO(Brain) then
						Brain = MovableMan:GetUnassignedBrain(Activity.TEAM_1)
						if Brain then
							self:SetPlayerBrain(Brain, player)
							self:SwitchToActor(Brain, player, self:GetTeamOfPlayer(player))
						else
							self:SetPlayerBrain(nil, player)
						end
					end
					
					if Brain then
						players = players + 1
						self:SetObservationTarget(Brain.Pos, player)
					else
						self:ResetMessageTimer(player)
						FrameMan:ClearScreenText(player)
						FrameMan:SetScreenText("Your brain has been destroyed!", player, 2000, -1, false)
					end
				end
			end
			
			if players < 1 then
				self.WinnerTeam = self.CPUTeam
				MovableMan:KillAllActors(self.WinnerTeam)
				ActivityMan:EndActivity()
				return
			end
		end
	elseif self.HunterTimer:IsPastSimMS(self.HunterDelay) then
		self.HunterTimer:Reset()
		self.HunterDelay = 11000
		
		for Hunter in MovableMan.Actors do
			if Hunter.Team == self.CPUTeam and Hunter.AIMode == Actor.AIMODE_GOTO then
				local Pray = Hunter.MOMoveTarget
				if not MovableMan:IsActor(Pray) then
					Hunter:ClearAIWaypoints()
					Hunter.AIMode = Actor.AIMODE_BRAINHUNT
				end
			end
		end
	end
	
	self.LZMap:Update()
	
	if self:GetTeamFunds(self.CPUTeam) > 0 then
		if self.SpawnTimer:IsPastSimMS(self.spawnDelay) then
			if self.AttackActor and MovableMan:IsActor(self.AttackActor) then
				-- We have a target actor, search for a suitable LZ
				local easyPathLZx, easyPathLZobst, closeLZx, closeLZobst = self.LZMap:FindLZ(self.CPUTeam, self.AttackPos)
				if closeLZx then	-- Search done
					self.SpawnTimer:Reset()
					
					local xPosLZ, obstacleHeight
					if closeLZobst < 30 and easyPathLZobst < 30 then
						if math.random() < 0.5 then
							xPosLZ = closeLZx
							obstacleHeight = closeLZobst
						else
							xPosLZ = easyPathLZx
							obstacleHeight = easyPathLZobst
						end
					elseif closeLZobst > 100 and easyPathLZobst < 100 then
						xPosLZ = easyPathLZx
						obstacleHeight = easyPathLZobst
					else
						if math.random() < 0.4 then
							xPosLZ = closeLZx
							obstacleHeight = closeLZobst
						else
							xPosLZ = easyPathLZx
							obstacleHeight = easyPathLZobst
						end
					end
					
					if obstacleHeight > 200 and math.random() < 0.6 then
						-- This target is very difficult to reach: cancel this attack and search for another target
						self.AttackActor = nil
						self.AttackPos = nil
					else
						-- Attack target
						self.SpawnTimer:Reset()
						if MovableMan:IsActor(self.CPUBrain) and SceneMan:ShortestDistance(self.AttackActor.Pos, self.CPUBrain.Pos, false).Magnitude < 1000 then
							-- The player is close to the AI brain so spawn again soon
							self.spawnDelay = (30000 - self.Difficulty * 150) * rte.SpawnIntervalScale
						else
							self.spawnDelay = (70000 - self.Difficulty * 250) * rte.SpawnIntervalScale
						end
						
						if obstacleHeight < 30 then
							self:CreateHeavyDrop(xPosLZ)
						elseif obstacleHeight < 90 then
							self:CreateMediumDrop(xPosLZ)
						elseif obstacleHeight < 180 then
							self:CreateLightDrop(xPosLZ)
						else
							self:CreateScoutDrop(xPosLZ)
							
							-- This target is very difficult to reach: change target for the next attack
							self.AttackActor = nil
							self.AttackPos = nil
						end
						
						if self.AttackActor then
							if math.random() < 0.4 then
								-- Change target for the next attack
								self.AttackActor = nil
								self.AttackPos = nil
							else
								self.AttackPos = Vector(self.AttackActor.Pos.X, self.AttackActor.Pos.Y)
							end
						end
					end
				end
			else
				self.AttackActor = nil
				
				if MovableMan:GetTeamMOIDCount(self.CPUTeam) < rte.AIMOIDMax * 3 / self:GetActiveCPUTeamCount() and MovableMan:IsActor(self.CPUBrain) then
					-- Check if the player is within a certain distance of the CPU brain
					local Intruders = {}
					local intruder_tally = 0
					for Intruder in MovableMan.Actors do
						if Intruder.Team ~= self.CPUTeam and Intruder.Health > 0 and
							not SceneMan:IsUnseen(Intruder.Pos.X, Intruder.Pos.Y, self.CPUTeam) and
							(Intruder.ClassName == "AHuman" or Intruder.ClassName == "ACrab" or Intruder.ClassName == "Actor")
						then
							local range = SceneMan:ShortestDistance(Intruder.Pos, self.CPUBrain.Pos, false).Largest
							table.insert(Intruders, {Act=Intruder, score=range+math.random(400)})
							intruder_tally = intruder_tally + 1
						end
					end
					
					if intruder_tally < 1 then
						self.SpawnTimer:Reset()
						self.spawnDelay = 10000
					else
						table.sort(Intruders, function(A, B) return A.score > B.score end)	-- the nearest intruder last
						self.AttackActor = table.remove(Intruders).Act
						self.AttackPos = Vector(self.AttackActor.Pos.X, self.AttackActor.Pos.Y)
					end
				else
					self.SpawnTimer:Reset()
					self.spawnDelay = 10000
					
					-- Go and get any existing intruders using nearby sentry actors
					if self.IntruderAlertTimer:IsPastSimMS(self.IntruderDisbatchDelay) and MovableMan:IsActor(self.CPUBrain) then
						-- Check if the player is within a certain distance of the CPU brain
						local Intruders = {}
						local intruder_tally = 0
						
						local Defenders = {}
						local defender_tally = 0
						
						-- Look for nearby intruder which is close to the brain
						for actor in MovableMan.Actors do
							if actor.Team ~= self.CPUTeam and actor.Health > 0 and
								not SceneMan:IsUnseen(actor.Pos.X, actor.Pos.Y, self.CPUTeam) and
								SceneMan:ShortestDistance(actor.Pos, self.CPUBrain.Pos, false).Magnitude < 1000 and
								(actor.ClassName == "AHuman" or actor.ClassName == "ACrab" or actor.ClassName == "Actor")
							then
								local range = SceneMan:ShortestDistance(actor.Pos, self.CPUBrain.Pos, false).Magnitude
								table.insert(Intruders, {Act=actor, score=range+math.random(400)})
								intruder_tally = intruder_tally + 1
							end
						end
						
						if intruder_tally > 0 then
							local intruder = table.remove(Intruders).Act
						
							-- Look for nearby defenders, but ignore brain guards
							for actor in MovableMan.Actors do
								if actor.Team == self.CPUTeam and actor.Health > 0 and actor.AIMode == Actor.AIMODE_SENTRY and
									SceneMan:ShortestDistance(actor.Pos, self.CPUBrain.Pos, false).Magnitude > 85 and
									(actor.ClassName == "AHuman" or actor.ClassName == "ACrab" or actor.ClassName == "Actor")
								then
									local range = SceneMan:ShortestDistance(actor.Pos, self.CPUBrain.Pos, false).Magnitude
									table.insert(Defenders, {Act=actor, score=range + math.random(100)})
									defender_tally = defender_tally + 1
								end
							end
							
							-- If we've found a suitable defender then make it intercept the intruder
							if defender_tally > 0 then
								table.sort(Defenders, function(A, B) return A.score > B.score end)	-- the nearest intruder last
								
								local defender = table.remove(Defenders).Act
								if defender and intruder then
									defender:ClearAIWaypoints()
									defender.AIMode = Actor.AIMODE_GOTO;
									defender:AddAIMOWaypoint(intruder)
								end
							end
						end
						
						self.IntruderAlertTimer:Reset();
					end
				end
			end
		end
	end
end


function BunkerBreach:CreateHeavyDrop(xPosLZ)
	local Craft = RandomACDropShip("Craft", self.CPUTechName)	-- Pick a craft to deliver with
	if Craft then
		-- The max allowed weight of this craft plus cargo
		local craftMaxMass = Craft.MaxMass
		if craftMaxMass < 0 then
			craftMaxMass = math.huge
		elseif craftMaxMass < 1 then
			craftMaxMass = Craft.Mass + 400	-- MaxMass not defined
		end
		
		Craft.Team = self.CPUTeam
		Craft.Pos = Vector(xPosLZ, -30)	-- Set the spawn point of the craft
		
		for i = 1, Craft.MaxPassengers do
			if math.random() < self:GetCrabToHumanSpawnRatio(PresetMan:GetModuleID(self.CPUTechName)) + self.Difficulty / 800 then
				Passenger = self:CreateCrab()
			elseif RangeRand(0, 105) < self.Difficulty then
				Passenger = self:CreateHeavyInfantry()
			else
				Passenger = self:CreateRandomInfantry()
			end
			
			if Passenger then
				if self.AttackActor and MovableMan:IsActor(self.AttackActor) then
					Passenger:AddAIMOWaypoint(self.AttackActor)
				else
					Passenger.AIMode = Actor.AIMODE_BRAINHUNT
				end
				
				Craft:AddInventoryItem(Passenger)
				
				-- Stop adding actors when exceeding the weight limit
				if Craft.Mass > craftMaxMass then 
					break
				end
			end
		end
		
		-- Subtract the total value of the craft+cargo from the CPU team's funds
		self:ChangeTeamFunds(-Craft:GetTotalValue(PresetMan:GetModuleID(self.CPUTechName), 2), self.CPUTeam)
		
		-- Spawn the Craft onto the scene
		MovableMan:AddActor(Craft)
	end
end

function BunkerBreach:CreateMediumDrop(xPosLZ)
	-- Pick a craft to deliver with
	local Craft
	if math.random() < 0.6 then
		Craft = RandomACDropShip("Craft", self.CPUTechName)
	else
		Craft = RandomACRocket("Craft", self.CPUTechName)
	end
	
	if Craft then
		-- The max allowed weight of this craft plus cargo
		local craftMaxMass = Craft.MaxMass
		if craftMaxMass < 0 then
			craftMaxMass = math.huge
		elseif craftMaxMass < 1 then
			craftMaxMass = Craft.Mass + 400	-- MaxMass not defined
		end
		
		Craft.Team = self.CPUTeam
		Craft.Pos = Vector(xPosLZ, -30)	-- Set the spawn point of the craft
		
		for i = 1, Craft.MaxPassengers do
			if RangeRand(-5, 125) < self.Difficulty then
				Passenger = self:CreateMediumInfantry()
			elseif math.random() < 0.65 then
				Passenger = self:CreateRandomInfantry()
			else
				Passenger = self:CreateLightInfantry()
			end
			
			if Passenger then
				if self.AttackActor and MovableMan:IsActor(self.AttackActor) then
					Passenger:AddAIMOWaypoint(self.AttackActor)
				else
					Passenger.AIMode = Actor.AIMODE_BRAINHUNT
				end
				
				Craft:AddInventoryItem(Passenger)
				
				-- Stop adding actors when exceeding the weight limit
				if Craft.Mass > craftMaxMass then 
					break
				end
			end
		end
		
		-- Subtract the total value of the craft+cargo from the CPU team's funds
		self:ChangeTeamFunds(-Craft:GetTotalValue(PresetMan:GetModuleID(self.CPUTechName), 2), self.CPUTeam)
		
		-- Spawn the Craft onto the scene
		MovableMan:AddActor(Craft)
	end
end

function BunkerBreach:CreateLightDrop(xPosLZ)
	-- Pick a craft to deliver with
	local Craft
	if math.random() < 0.6 then
		Craft = RandomACDropShip("Craft", self.CPUTechName)
	else
		Craft = RandomACRocket("Craft", self.CPUTechName)
	end
	
	if Craft then
		-- The max allowed weight of this craft plus cargo
		local craftMaxMass = Craft.MaxMass
		if craftMaxMass < 0 then
			craftMaxMass = math.huge
		elseif craftMaxMass < 1 then
			craftMaxMass = Craft.Mass + 400	-- MaxMass not defined
		end
		
		Craft.Team = self.CPUTeam
		Craft.Pos = Vector(xPosLZ, -30)	-- Set the spawn point of the craft
		
		for i = 1, Craft.MaxPassengers do
			if RangeRand(10, 200) < self.Difficulty then
				Passenger = self:CreateMediumInfantry()
			else
				Passenger = self:CreateLightInfantry()
			end
			
			if Passenger then
				if self.AttackActor and MovableMan:IsActor(self.AttackActor) then
					Passenger:AddAIMOWaypoint(self.AttackActor)
				else
					Passenger.AIMode = Actor.AIMODE_BRAINHUNT
				end
				
				Craft:AddInventoryItem(Passenger)
				
				-- Stop adding actors when exceeding the weight limit
				if Craft.Mass > craftMaxMass then 
					break
				end
			end
		end
		
		-- Subtract the total value of the craft+cargo from the CPU team's funds
		self:ChangeTeamFunds(-Craft:GetTotalValue(PresetMan:GetModuleID(self.CPUTechName), 2), self.CPUTeam)
		
		-- Spawn the Craft onto the scene
		MovableMan:AddActor(Craft)
	end
end

function BunkerBreach:CreateScoutDrop(xPosLZ)
	-- Pick a craft to deliver with
	local Craft, actorsInCargo
	if math.random() < 0.6 then
		Craft = RandomACDropShip("Craft", self.CPUTechName)
	else
		Craft = RandomACRocket("Craft", self.CPUTechName)
	end
	
	if Craft then
		-- The max allowed weight of this craft plus cargo
		local craftMaxMass = Craft.MaxMass
		if craftMaxMass < 0 then
			craftMaxMass = math.huge
		elseif craftMaxMass < 1 then
			craftMaxMass = Craft.Mass + 400	-- MaxMass not defined
		end
		
		Craft.Team = self.CPUTeam
		Craft.Pos = Vector(xPosLZ, -30)	-- Set the spawn point of the craft
		
		for i = 1, Craft.MaxPassengers do
			if math.random() < 0.3 then
				Passenger = self:CreateLightInfantry()
			else
				Passenger = self:CreateScoutInfantry()
			end
			
			if Passenger then
				if self.AttackActor and MovableMan:IsActor(self.AttackActor) then
					Passenger:AddAIMOWaypoint(self.AttackActor)
				else
					Passenger.AIMode = Actor.AIMODE_BRAINHUNT
				end
				
				Craft:AddInventoryItem(Passenger)
				
				-- Stop adding actors when exceeding the weight limit
				if Craft.Mass > craftMaxMass then 
					break
				end
			end
		end
		
		-- Subtract the total value of the craft+cargo from the CPU team's funds
		self:ChangeTeamFunds(-Craft:GetTotalValue(self.CPUTechID, 2), self.CPUTeam)
		
		-- Spawn the Craft onto the scene
		MovableMan:AddActor(Craft)
	end
end


function BunkerBreach:CreateCrab(mode)
	local Passenger = RandomACrab("Mecha", self.CPUTechName)
	if Passenger then
		-- Set AI mode and team so it knows who and what to fight for!
		Passenger.AIMode = mode or Actor.AIMODE_GOTO
		Passenger.Team = self.CPUTeam
		return Passenger
	end
end

function BunkerBreach:CreateTurret(mode)
	local Passenger = RandomACrab("Turret", self.CPUTechName)
	if Passenger then
		-- Set AI mode and team so it knows who and what to fight for!
		Passenger.AIMode = mode or Actor.AIMODE_SENTRY
		Passenger.Team = self.CPUTeam
		return Passenger
	end
end

-- Get any Actor from the CPU's native tech
function BunkerBreach:CreateRandomInfantry(mode)
	local	Passenger = RandomAHuman("Actors", self.CPUTechName)
	if Passenger then
		Passenger:AddInventoryItem(RandomHDFirearm("Primary Weapons", self.CPUTechName))
		Passenger:AddInventoryItem(RandomHDFirearm("Secondary Weapons", self.CPUTechName))
		
		if math.random() < 0.4 then
			Passenger:AddInventoryItem(RandomTDExplosive("Grenades", self.CPUTechName))
			if math.random() < 0.5 then
				Passenger:AddInventoryItem(RandomTDExplosive("Grenades", self.CPUTechName))
			end
		elseif math.random() < 0.5 then
			Passenger:AddInventoryItem(RandomHDFirearm("Diggers", self.CPUTechName))
		end
		
		-- Set AI mode and team so it knows who and what to fight for!
		Passenger.AIMode = mode or Actor.AIMODE_GOTO
		Passenger.Team = self.CPUTeam
		return Passenger
	end
end

function BunkerBreach:CreateLightInfantry(mode)
	local	Passenger = RandomAHuman("Light Infantry", self.CPUTechName)
	if Passenger then
		Passenger:AddInventoryItem(RandomHDFirearm("Light Weapons", self.CPUTechName))
		Passenger:AddInventoryItem(RandomHDFirearm("Secondary Weapons", self.CPUTechName))
		
		if math.random() < 0.2 then
			Passenger:AddInventoryItem(RandomTDExplosive("Grenades", self.CPUTechName))
		end
		
		-- Set AI mode and team so it knows who and what to fight for!
		Passenger.AIMode = mode or Actor.AIMODE_GOTO
		Passenger.Team = self.CPUTeam
		return Passenger
	end
end

function BunkerBreach:CreateHeavyInfantry(mode)
	local	Passenger = RandomAHuman("Heavy Infantry", self.CPUTechName)
	if Passenger then
		Passenger:AddInventoryItem(RandomHDFirearm("Heavy Weapons", self.CPUTechName))
		Passenger:AddInventoryItem(RandomHDFirearm("Secondary Weapons", self.CPUTechName))
		
		if math.random() < 0.6 then
			Passenger:AddInventoryItem(RandomTDExplosive("Grenades", self.CPUTechName))
			Passenger:AddInventoryItem(RandomTDExplosive("Grenades", self.CPUTechName))
			if math.random() < 0.4 then
				Passenger:AddInventoryItem(RandomTDExplosive("Grenades", self.CPUTechName))
			end
		else
			Passenger:AddInventoryItem(RandomHDFirearm("Diggers", self.CPUTechName))
		end
		
		-- Set AI mode and team so it knows who and what to fight for!
		Passenger.AIMode = mode or Actor.AIMODE_GOTO
		Passenger.Team = self.CPUTeam
		return Passenger
	end
end

function BunkerBreach:CreateMediumInfantry(mode)
	local	Passenger = RandomAHuman("Heavy Infantry", self.CPUTechName)
	if Passenger then
		Passenger:AddInventoryItem(RandomHDFirearm("Light Weapons", self.CPUTechName))
		Passenger:AddInventoryItem(RandomHDFirearm("Secondary Weapons", self.CPUTechName))
		
		-- Set AI mode and team so it knows who and what to fight for!
		Passenger.AIMode = mode or Actor.AIMODE_GOTO
		Passenger.Team = self.CPUTeam
		return Passenger
	end
end

function BunkerBreach:CreateScoutInfantry(mode)
	local	Passenger = RandomAHuman("Light Infantry", self.CPUTechName)
	if Passenger then
		Passenger:AddInventoryItem(RandomHDFirearm("Secondary Weapons", self.CPUTechName))
		
		if math.random() < 0.6 then
			Passenger:AddInventoryItem(RandomTDExplosive("Grenades", self.CPUTechName))
		else
			Passenger:AddInventoryItem(RandomHDFirearm("Secondary Weapons", self.CPUTechName))
		end
		
		-- Set AI mode and team so it knows who and what to fight for!
		Passenger.AIMode = mode or Actor.AIMODE_GOTO
		Passenger.Team = self.CPUTeam
		return Passenger
	end
end

function BunkerBreach:CreateSniper(mode)
	local	Passenger
	if math.random() < 0.7 then
		Passenger = RandomAHuman("Light Infantry", self.CPUTechName)
	else
		Passenger = RandomAHuman("Heavy Infantry", self.CPUTechName)
	end
	
	if Passenger then
		Passenger:AddInventoryItem(RandomHDFirearm("Sniper Weapons", self.CPUTechName))
		Passenger:AddInventoryItem(RandomHDFirearm("Secondary Weapons", self.CPUTechName))
		
		-- Set AI mode and team so it knows who and what to fight for!
		Passenger.AIMode = mode or Actor.AIMODE_GOTO
		Passenger.Team = self.CPUTeam
		return Passenger
	end
end

function BunkerBreach:CreateEngineer(mode)
	local Passenger = RandomAHuman("Light Infantry", self.CPUTechName)
	if Passenger then
		Passenger:AddInventoryItem(RandomHDFirearm("Light Weapons", self.CPUTechName))
		Passenger:AddInventoryItem(CreateHDFirearm("Medium Digger", "Base.rte"))
		
		-- Set AI mode and team so it knows who and what to fight for!
		Passenger.AIMode = mode or Actor.AIMODE_GOLDDIG
		Passenger.Team = self.CPUTeam
		return Passenger
	end
end

function BunkerBreach:CreateAntiAir(mode)
	local Passenger = RandomACrab("Anti-Air", self.CPUTechName)
	if Passenger then
		-- Set AI mode and team so it knows who and what to fight for!
		Passenger.AIMode = mode or Actor.AIMODE_SENTRY
		Passenger.Team = self.CPUTeam
		return Passenger
	end
end

function BunkerBreach:CreateBrainBot(mode)
	local Act = RandomAHuman("Brains", self.CPUTechName)
	if Act then
		Act:AddInventoryItem(RandomHDFirearm("Light Weapons", self.CPUTechName))
		Act:AddInventoryItem(CreateHDFirearm("Medium Digger", "Base.rte"))

		if PosRand() < 0.5 then
			Act:AddInventoryItem(RandomHDFirearm("Secondary Weapons", self.CPUTechName))
		end

		-- Set AI mode and team so it knows who and what to fight for!
		Act.AIMode = mode or Actor.AIMODE_SENTRY
		Act.Team = self.CPUTeam
		return Act
	end
end
