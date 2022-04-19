--[[

*** INSTRUCTIONS ***

This activity can be run on any scene with "LZ Attacker", "LZ Defender" and "Brain" areas.
The attacking brain spawns in the "LZ Attacker" area and the defending brain in the "Brain" area.
The script will look for player units and send reinforcements to attack them.

When using with randomized bunkers which has multiple brain chambers or other non-Brain Hideout deployments
only one brain at random chamber will be spawned. To avoid wasting MOs for this actors you may define a "Brain Chamber"
area. All actors inside "Brain Chamber" but without a brain nearby will be removed as useless.

Add defender units by placing areas named:
"Sniper1" to "Sniper10"
"Light1" to "Light10"
"Heavy1" to "Heavy10"
"Mecha1" to "Mecha10"
"Turret1" to "Turret10"
"Engineer1" to "Engineer10"

Don't place more defenders than the recommended MOID limit! (15 defenders plus 3 doors equals about 130 IDs, see recommended limit in Base.rte/Constants.lua)
--]]

dofile("Base.rte/Constants.lua")

function BunkerBreach:StartActivity()
	collectgarbage("collect")
	
	self.attackerTeam = Activity.TEAM_1;
	self.defenderTeam = Activity.TEAM_2;
	
	self.TechName = {};
	
	self.TechName[self.attackerTeam] = self:GetTeamTech(self.attackerTeam);	-- Select a tech for the CPU player
	self.TechName[self.defenderTeam] = self:GetTeamTech(self.defenderTeam);	-- Select a tech for the CPU player
	
	self:SetTeamFunds(self:GetStartingGold(), Activity.TEAM_1);
	self:SetTeamFunds(self:GetStartingGold(), Activity.TEAM_2);

	--This line will filter out all scenes without any predefined landing zones, as they serve as compatibility markers for this activity
	local attackerLZ = SceneMan.Scene:GetArea("LZ Attacker");
	local defenderLZ = SceneMan.Scene:GetOptionalArea("LZ Defender");	--Optional! To-do: define these in all Bunker Breach scenes?
	self:SetLZArea(self.attackerTeam, attackerLZ);
	if defenderLZ then
		self:SetLZArea(self.defenderTeam, defenderLZ);
	end

	self.difficultyRatio = self.Difficulty/Activity.MAXDIFFICULTY;
	-- Timers
	self.checkTimer = Timer();
	self.checkTimer:SetRealTimeLimitMS(1000);
	self.CPUSpawnTimer = Timer();
	self.CPUSpawnDelay = (40000 - self.difficultyRatio * 20000) * rte.SpawnIntervalScale;
	self.CPUSearchRadius = math.sqrt(SceneMan.SceneWidth^2 + SceneMan.SceneHeight^2) * 0.5 * self.difficultyRatio;

	--Set all actors in the scene to the defending team
	for actor in MovableMan.AddedActors do
		--To-do: allow attackers to spawn near the brain?
		if actor.Team ~= self.defenderTeam then
			MovableMan:ChangeActorTeam(actor, self.defenderTeam);
		end
	end
	
	--Clear wonky default scene launch text
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			FrameMan:ClearScreenText(self:ScreenOfPlayer(player));
		end
	end
	
	--CPU team setup
	if self.CPUTeam ~= Activity.NOTEAM then
		self:SetTeamFunds(4000 + 8000 * math.floor(self.difficultyRatio * 5)/5, self.CPUTeam);
		if (self.CPUTeam ~= self.defenderTeam) then
			self.CPUSpawnDelay = self.CPUSpawnDelay * 0.5;
		end
		self.playerTeam = self:OtherTeam(self.CPUTeam);
	end
		
	
	--Add attacker brains for human attackers
	if self.attackerTeam ~= self.CPUTeam then
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) and self:GetTeamOfPlayer(player) == self.attackerTeam then
				local attackingBrain = self:CreateBrainBot(self:GetTeamOfPlayer(player));
				
				local lzX = attackerLZ:GetRandomPoint().X;
				if SceneMan.SceneWrapsX then
					if lzX < 0 then
						lzX = lzX + SceneMan.SceneWidth;
					elseif lzX >= SceneMan.SceneWidth then
						lzX = lzX - SceneMan.SceneWidth;
					end
				else
					lzX = math.max(math.min(lzX, SceneMan.SceneWidth - 50), 50);
				end
				attackingBrain.Pos = SceneMan:MovePointToGround(Vector(lzX, 0), attackingBrain.Radius * 0.5, 3);
				
				MovableMan:AddActor(attackingBrain);
				self:SetPlayerBrain(attackingBrain, player);
				self:SetObservationTarget(attackingBrain.Pos, player);
				self:SetLandingZone(attackingBrain.Pos, player);
			end
		end
	end
	
	--Add defender brains, either using the Brain area or picking randomly from those created by deployments
	if SceneMan.Scene:HasArea("Brain") then
		for actor in MovableMan.Actors do
			if actor.Team == self.defenderTeam and actor:IsInGroup("Brains") then
				actor.ToDelete = true;
			end
		end
		
		self.defenderBrain = self:CreateBrainBot(self.defenderTeam);
		self.defenderBrain.Pos = SceneMan.Scene:GetOptionalArea("Brain"):GetCenterPoint();
		MovableMan:AddActor(self.defenderBrain);
	else
		--Pick the defender brain randomly from among those created by deployments, and delete the others and clean up some of their guards
		local deploymentBrains = {};
		for actor in MovableMan.AddedActors do
			if actor.Team == self.defenderTeam and actor:IsInGroup("Brains") then
				deploymentBrains[#deploymentBrains + 1] = actor;
			end
		end
		local brainIndexToChoose = math.random(1, #deploymentBrains);
		self.defenderBrain = deploymentBrains[brainIndexToChoose];
		table.remove(deploymentBrains, brainIndexToChoose);
		
		--Delete brains that weren't the chosen one, and also randomly delete most of their guards
        self.BrainChamber = SceneMan.Scene:GetOptionalArea("Brain Chamber");
		for _, unchosenDeploymentBrain in pairs(deploymentBrains) do
			unchosenDeploymentBrain.ToDelete = true;
			for actor in MovableMan.AddedActors do
				if actor.Team == self.defenderTeam and math.random() < 0.75 and self.BrainChamber:IsInside(actor.Pos) and (actor.ClassName == "AHuman" or actor.ClassName == "ACrab") and SceneMan:ShortestDistance(actor.Pos, self.defenderBrain.Pos, false).Magnitude > 200 then
					actor.ToDelete = true;
				end
			end
		end
	end
	
	--Make sure all defending human players have brains
	if (self.defenderTeam ~= self.CPUTeam) then
		local playerDefenderBrainsAssignedCount = 0;
		local brainToAssignToPlayer;
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) and self:GetTeamOfPlayer(player) == self.defenderTeam then
				if playerDefenderBrainsAssignedCount == 0 then
					brainToAssignToPlayer = self.defenderBrain;
				else
					brainToAssignToPlayer = self:CreateBrainBot(self.defenderTeam);
					brainToAssignToPlayer.Pos = self.defenderBrain.Pos + Vector(playerDefenderBrainsAssignedCount * 10 * self.defenderBrain.FlipFactor, 0);
					MovableMan:AddActor(brainToAssignToPlayer);
				end
				self:SwitchToActor(brainToAssignToPlayer, player, self.defenderTeam);
				self:SetPlayerBrain(brainToAssignToPlayer, player);
				self:SetObservationTarget(brainToAssignToPlayer.Pos, player);
				self:SetLandingZone(brainToAssignToPlayer.Pos, player);
				
				playerDefenderBrainsAssignedCount = playerDefenderBrainsAssignedCount + 1;
			end
		end
	end
	
	self.loadouts = {"Light", "Heavy", "Sniper", "Engineer", "Mecha", "Turret"};
	self.infantryLoadouts = {"Light", "Heavy", "Sniper"};
	--Add defending units in predefined areas
	for _, loadout in pairs(self.loadouts) do
		for i = 1, 10 do
			if SceneMan.Scene:HasArea(loadout .. i) then
				local guard = self:CreateInfantry(self.defenderTeam, loadout);
				if guard then
					guard.Pos = SceneMan.Scene:GetArea(loadout .. i):GetCenterPoint();
					MovableMan:AddActor(guard);
				end
			else
				break
			end
		end
	end

	if self:GetFogOfWarEnabled() then
		SceneMan:MakeAllUnseen(Vector(24, 24), self.attackerTeam);
		SceneMan:MakeAllUnseen(Vector(24, 24), self.defenderTeam);
		if self.CPUTeam ~= -1 then
			SceneMan:MakeAllUnseen(Vector(70, 70), self.CPUTeam);
			--Assume that the AI has scouted the terrain
			for x = 0, SceneMan.SceneWidth - 1, 65 do
				SceneMan:CastSeeRay(self.CPUTeam, Vector(x, 0), Vector(0, SceneMan.SceneHeight), Vector(), 1, 9);
			end
		end
		--Lift the fog around friendly actors
		for actor in MovableMan.AddedActors do
			for ang = 0, math.pi * 2, 0.1 do
				SceneMan:CastSeeRay(actor.Team, actor.EyePos, Vector(130 + FrameMan.PlayerScreenWidth * 0.5, 0):RadRotate(ang), Vector(), 1, 4);
			end
		end
	end
end


function BunkerBreach:EndActivity()
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


function BunkerBreach:UpdateActivity()
	if self.ActivityState == Activity.OVER then
		return
	end
	
	--Check win conditions
	if self.checkTimer:IsPastRealTimeLimit() then
		self.checkTimer:Reset();

		if not MovableMan:IsActor(self.defenderBrain) then
			local findBrain = MovableMan:GetFirstBrainActor(self.defenderTeam);
			if findBrain then
				self.defenderBrain = findBrain;
			else
				self.WinnerTeam = self.attackerTeam;
				for actor in MovableMan.Actors do
					if actor.Team == self.defenderTeam then
						actor.Status = Actor.INACTIVE;
					end
				end
				ActivityMan:EndActivity();
				return
			end
		else
			local survivingAttackingPlayers = 0;
			for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
				if self:PlayerActive(player) and self:PlayerHuman(player) then
					local team = self:GetTeamOfPlayer(player);
					local brain = self:GetPlayerBrain(player);
					--Look for a new brain
					if not brain or not MovableMan:IsActor(brain) then
						brain = MovableMan:GetUnassignedBrain(team);
						if brain and MovableMan:IsActor(brain) then
							self:SetPlayerBrain(brain, player);
							self:SwitchToActor(brain, player, team);
						else
							brain = nil;
							self:SetPlayerBrain(nil, player);
						end
					end
					if brain and team == self.attackerTeam and self.CPUTeam ~= self.attackerTeam then
						survivingAttackingPlayers = survivingAttackingPlayers + 1;
						self:SetObservationTarget(brain.Pos, player);
					elseif not brain then
						self:ResetMessageTimer(player);
						FrameMan:ClearScreenText(self:ScreenOfPlayer(player));
						FrameMan:SetScreenText("Your brain has been destroyed!", self:ScreenOfPlayer(player), 2000, -1, false);
					end
				end
			end
			if self.CPUTeam ~= self.attackerTeam and survivingAttackingPlayers == 0 then
				self.WinnerTeam = self.defenderTeam;
				for actor in MovableMan.Actors do
					if actor.Team == self.attackerTeam then
						actor.Status = Actor.INACTIVE;
					end
				end
				ActivityMan:EndActivity();
				return
			end
		end
	end
	self:ClearObjectivePoints();
	if self.CPUTeam ~= -1 then
		local funds = self:GetTeamFunds(self.CPUTeam);
		local enemyCount = 0;
		local allyCount = 0;
		local diggerCount = 0;
		for actor in MovableMan.Actors do
			if actor.ClassName ~= "ADoor" and actor.Health > 0 then
				--Units will weigh in based on their Health
				if actor.Team == self.playerTeam then
					allyCount = allyCount + actor.Health/actor.MaxHealth;
				elseif actor.Team == self.CPUTeam then
					enemyCount = enemyCount + actor.Health/actor.MaxHealth;
					if actor:HasObjectInGroup("Tools - Diggers") and actor.AIMode == Actor.AIMODE_GOLDDIG then
						diggerCount = diggerCount + 1;
					end
					if funds < 0 and self.CPUTeam == self.attackerTeam then
						self:AddObjectivePoint("Destroy!", actor.AboveHUDPos, self.playerTeam, GameActivity.ARROWDOWN)
					end
				end
			end
		end
		if funds > 0 then
			if self.CPUTeam == self.attackerTeam then
				for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
					if self:PlayerActive(player) and self:PlayerHuman(player) then
						FrameMan:SetScreenText("Enemy budget: " .. math.floor(funds), self:ScreenOfPlayer(player), 0, 2500, false);
					end
				end
			end
			if self.CPUSpawnTimer:IsPastSimMS(self.CPUSpawnDelay) then
				self.CPUSpawnTimer:Reset();
				
				local enemyUnitRatio = enemyCount/math.max(allyCount, 1);
				--Send CPU to dig for gold if funds are low and a digger hasn't recently been sent
				self.sendGoldDiggers = not self.sendGoldDiggers and diggerCount < 3 and (funds < 500 or math.random() < 0.1);
				
				if self.CPUTeam == self.attackerTeam then
					if self.sendGoldDiggers then
						self:CreateDrop(self.CPUTeam, "Engineer", Actor.AIMODE_GOLDDIG);
					elseif enemyUnitRatio < 1.75 then
						self:CreateDrop(self.CPUTeam, "Any", Actor.AIMODE_BRAINHUNT);
						self.CPUSpawnDelay = (30000 - self.difficultyRatio * 15000 + enemyUnitRatio * 5000) * rte.SpawnIntervalScale;
					else
						self.CPUSpawnDelay = self.CPUSpawnDelay * 0.9;
					end
				elseif self.CPUTeam == self.defenderTeam then
				
					local dist = Vector();
					local targetActor = MovableMan:GetClosestEnemyActor(self.CPUTeam, Vector(self.defenderBrain.Pos.X, SceneMan.SceneHeight * 0.5), self.CPUSearchRadius, dist);
					if targetActor then
						self.chokePoint = targetActor.Pos;
						local closestGuard = MovableMan:GetClosestTeamActor(self.CPUTeam, Activity.PLAYER_NONE, targetActor.Pos, self.CPUSearchRadius - dist.Magnitude, Vector(), self.defenderBrain);
						if closestGuard and closestGuard.AIMODE == Actor.AIMODE_PATROL then
							--Send a nearby alerted guard after the intruder
							closestGuard.AIMode = Actor.AIMODE_GOTO;
							closestGuard:AddAIMOWaypoint(targetActor);
							self.chokePoint = nil;
							--A guard has been sent, the next unit should spawn faster
							self.CPUSpawnDelay = self.CPUSpawnDelay * 0.8;
						else
							self:CreateDrop(self.CPUTeam, "Any", Actor.AIMODE_GOTO);
							self.CPUSpawnDelay = (30000 - self.difficultyRatio * 15000 + enemyUnitRatio * 5000) * rte.SpawnIntervalScale;
							if math.random() < 0.5 then
								--Change target for the next attack
								self.chokePoint = nil;
							end
						end
					else
						self.chokePoint = nil;
					
						if self.sendGoldDiggers then
							self:CreateDrop(self.CPUTeam, "Engineer", Actor.AIMODE_GOLDDIG);
						else
							self:CreateDrop(self.CPUTeam, "Any", enemyUnitRatio > math.random() and Actor.AIMODE_BRAINHUNT or Actor.AIMODE_PATROL);
						end
						self.CPUSpawnDelay = (40000 - self.difficultyRatio * 20000 + enemyUnitRatio * 7500) * rte.SpawnIntervalScale;
					end
				end
			end
		elseif enemyCount < 0.5 then
			for actor in MovableMan.Actors do
				if actor.Team ~= self.playerTeam then
					actor.Status = Actor.INACTIVE;
				end
			end
			self.WinnerTeam = self.playerTeam;
			self:ClearObjectivePoints();
			ActivityMan:EndActivity();
			return
		end
	end
end


function BunkerBreach:CreateDrop(team, loadout, aiMode)
	local tech = self:GetTeamTech(team);
	local crabRatio = self:GetCrabToHumanSpawnRatio(PresetMan:GetModuleID(tech));

	if loadout == "Any" then
		loadout = nil;
	end
	local craft = RandomACDropShip("Craft", tech);
	if not craft or craft.MaxInventoryMass <= 0 then
		--MaxMass not defined, spawn a default craft
		craft = RandomACDropShip("Craft", "Base.rte");
	end
	
	craft.Team = team;
	local xPos;
	local lz = self:GetLZArea(team);
	if lz then
		xPos = lz:GetRandomPoint().X;
	elseif team == self.defenderTeam and self.defenderBrain then
		xPos = math.max(math.min(self.defenderBrain.Pos.X + math.random(-100, 100), SceneMan.SceneWidth - 100), 100);
	else
		xPos = math.random(100, SceneMan.SceneWidth - 100);
	end
	craft.Pos = Vector(xPos, -30);
	local passengerCount = math.random(math.ceil(craft.MaxPassengers * 0.5), craft.MaxPassengers);
	
	for i = 1, passengerCount do

		if craft.InventoryMass > craft.MaxInventoryMass then 
			break;
		end
		local passenger;
		if loadout then
			passenger = self:CreateInfantry(team, loadout);
		else
			passenger = math.random() < crabRatio and self:CreateCrab(team) or self:CreateInfantry(team);
		end
		
		if passenger then
			if aiMode then
				passenger.AIMode = aiMode;
				if aiMode == Actor.AIMODE_GOTO then
					if self.chokePoint then
						passenger:AddAISceneWaypoint(self.chokePoint);
					else
						passenger.AIMode = Actor.AIMODE_BRAINHUNT;
					end
				end
			end
			craft:AddInventoryItem(passenger);
		end
	end
	--Subtract the total value of the craft + cargo from the team's funds
	self:ChangeTeamFunds(-craft:GetTotalValue(PresetMan:GetModuleID(tech), 2), team);
	--Spawn the craft onto the scene
	MovableMan:AddActor(craft);
end


function BunkerBreach:CreateInfantry(team, loadout)
	if loadout == nil then
		loadout = self.infantryLoadouts[math.random(#self.infantryLoadouts)];
	elseif loadout == "Mecha" or loadout == "Turret" then
		--Do not attempt creating Infantry out of a Mecha loadout!
		return self:CreateCrab(team, loadout);
	end
	local techID = PresetMan:GetModuleID(self:GetTeamTech(team));
	local actor;
	if math.random() < 0.5 then	--Pick a unit from the loadout presets occasionally
		if loadout == "Light" then
			actor = PresetMan:GetLoadout("Infantry " .. (math.random() < 0.7 and "Light" or "CQB"), techID, false);
		elseif loadout == "Heavy" then
			actor = PresetMan:GetLoadout("Infantry " .. (math.random() < 0.7 and "Heavy" or "Grenadier"), techID, false);
		else
			actor = PresetMan:GetLoadout("Infantry " .. loadout, techID, false);
		end
	end
	if not actor then
		if loadout == "Light" then
			actor = RandomAHuman("Actors - Light", techID);
			if actor.ModuleID ~= techID then
				actor = RandomAHuman("Actors", techID);
			end
			
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", techID));
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", techID));
			local rand = math.random();
			if rand < 0.5 then
				actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", techID));
			elseif rand < 0.8 then
				actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
			else
				actor:AddInventoryItem(RandomHDFirearm("Tools - Breaching", techID));
			end
			
		elseif loadout == "Heavy" then
			actor = RandomAHuman("Actors - Heavy", techID);
			if actor.ModuleID ~= techID then
				actor = RandomAHuman("Actors", techID);
			end
			
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Heavy", techID));
			if math.random() < 0.3 then
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", techID));
				if math.random() < 0.25 then
					actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", techID));
				elseif math.random() < 0.35 then
					actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
				end
			else
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", techID));
				if math.random() < 0.3 then
					actor:AddInventoryItem(RandomHeldDevice("Shields", techID));
					actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
				else
					actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", techID));
				end
			end
			
		elseif loadout == "Sniper" then
			actor = RandomAHuman("Actors", techID);
			
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Sniper", techID));
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", techID));
			if math.random() < 0.3 then
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", techID));
			else
				actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
			end
			
		elseif loadout == "Engineer" then
			actor = RandomAHuman("Actors - Light", techID);
			if actor.ModuleID ~= techID then
				actor = RandomAHuman("Actors", techID);
			end
			
			if math.random() < 0.7 then
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", techID));
			else
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", techID));
				local rand = math.random();
				if rand < 0.2 then
					actor:AddInventoryItem(RandomHeldDevice("Shields", techID));
				elseif rand < 0.4 then
					actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
				else
					actor:AddInventoryItem(RandomTDExplosive("Tools - Breaching", techID));
				end
			end
			actor:AddInventoryItem(RandomHDFirearm("Tools - Diggers", techID));
		else
			actor = RandomAHuman("Actors", techID);
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Primary", techID));
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", techID));
			
			local rand = math.random();
			if rand < 0.25 then
				actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", techID));
			elseif rand < 0.50 then
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", techID));
			elseif rand < 0.75 then
				actor:AddInventoryItem(RandomHeldDevice("Shields", techID));
			else
				actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
			end
		end
	end
	actor.AIMode = Actor.AIMODE_SENTRY;
	actor.Team = team;
	return actor;
end


function BunkerBreach:CreateCrab(team, loadout)
	if loadout == nil then
		loadout = "Mecha";
	end
	local techID = PresetMan:GetModuleID(self:GetTeamTech(team));
	if self:GetCrabToHumanSpawnRatio(PresetMan:GetModuleID(techID)) > 0 then
		local actor;
		if math.random() < 0.5 then
			actor = PresetMan:GetLoadout(loadout, techID, false);
		else
			actor = loadout == "Turret" and RandomACrab("Actors - Turrets", techID) or RandomACrab("Actors - Mecha", techID);
		end
		actor.Team = team;
		return actor;
	else
		return self:CreateInfantry(team, "Heavy");
	end
end


function BunkerBreach:CreateBrainBot(team)
	local techID = PresetMan:GetModuleID(self:GetTeamTech(team));
	local actor;
	if techID ~= -1 and team == self.attackerTeam then
		actor = PresetMan:GetLoadout("Infantry Brain", techID, false);
	else
		actor = RandomAHuman("Brains", techID);
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", techID));
		if team == self.attackerTeam then
			actor:AddInventoryItem(CreateHDFirearm("Constructor", "Base.rte"));
		else
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", techID));
		end
	end
	actor.AIMode = Actor.AIMODE_SENTRY;
	actor.Team = team;
	return actor;
end