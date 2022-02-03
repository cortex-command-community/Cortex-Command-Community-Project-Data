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

	for actor in MovableMan.AddedActors do
		--Set all actors in the scene to the defending team
		--To-do: allow attackers to spawn near the brain?
		if actor.Team ~= self.defenderTeam then
			MovableMan:ChangeActorTeam(actor, self.defenderTeam);
		end
	end
	--Add player brains
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			local team = self:GetTeamOfPlayer(player);
			local brain;
			if team == self.attackerTeam then
				brain = self:CreateBrainBot(team);
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
				brain.Pos = SceneMan:MovePointToGround(Vector(lzX, 0), brain.Radius * 0.5, 3);
				MovableMan:AddActor(brain);
				
			elseif team == self.defenderTeam then
				if SceneMan.Scene:HasArea("Brain") then
					--Remove any existing brains and prioritize the designated area
					for actor in MovableMan.Actors do
						if actor.Team == team and actor:IsInGroup("Brains") then
							actor.ToDelete = true;
						end
					end
					brain = self:CreateBrainBot(team);
					brain.Pos = SceneMan.Scene:GetOptionalArea("Brain"):GetCenterPoint();
					MovableMan:AddActor(brain);
				else
					--Look for brains among actors created by the deployments
					for actor in MovableMan.AddedActors do
						if actor.Team == team and actor:IsInGroup("Brains") then
							if brain then
								actor.ToDelete = true;
							else
								brain = actor;
							end
						end
					end
				end
				self.defenderBrain = brain;
			end
			self:SetPlayerBrain(brain, player);
			self:SetObservationTarget(brain.Pos, player);
			self:SetLandingZone(brain.Pos, player);
		end
	end
	
	if self.CPUTeam ~= -1 then
		self.CPUTechName = self:GetTeamTech(self.CPUTeam);
		self.CPUTechID = PresetMan:GetModuleID(self.CPUTechName);
		self:SetTeamFunds(5000 * (0.5 + math.floor(self.difficultyRatio * 10)/10), self.CPUTeam);
		if self.CPUTeam == self.defenderTeam then
			local brain;
			if SceneMan.Scene:HasArea("Brain") then
				--Remove any existing brains and prioritize the designated area
				for actor in MovableMan.Actors do
					if actor.Team == team and actor:IsInGroup("Brains") then
						actor.ToDelete = true;
					end
				end
				brain = self:CreateBrainBot(self.CPUTeam);
				brain.Pos = SceneMan.Scene:GetOptionalArea("Brain"):GetCenterPoint();
				MovableMan:AddActor(brain);
			else
				--Look for brains among actors created by the deployments
				for actor in MovableMan.AddedActors do
					if actor.Team == team and actor:IsInGroup("Brains") then
						if brain then
							actor.ToDelete = true;
						else
							brain = actor;
						end
					end
				end
			end
			self.defenderBrain = brain;
		else
			--Start spawning attackers faster
			self.CPUSpawnDelay = self.CPUSpawnDelay * 0.5;
		end
		self.playerTeam = self:OtherTeam(self.CPUTeam);
	end
	--[[To-do: figure out what this part is *actually* supposed to do
	if SceneMan.Scene:HasArea("Brain Chamber") then
		self.BrainChamber = SceneMan.Scene:GetOptionalArea("Brain Chamber");
		--Set all useless actors, i.e. those who should guard brain in the brain chamber but their brain is in another castle
		--to delete themselves, because otherwise they are most likely to stand there for the whole battle and waste MOs
		for actor in MovableMan.AddedActors do
			if not actor:HasObjectInGroup("Brains") and actor.Team == self.defenderTeam and self.BrainChamber:IsInside(actor.Pos) and (actor.ClassName == "AHuman" or actor.ClassName == "ACrab") then
				actor.ToDelete = true;
			end
		end
	end
	]]--
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
	self.enemyForcesCount = 0;
	self.enemyDiggersCount = 0;
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
	
	if self.checkTimer:IsPastRealTimeLimit() then
		--Check win conditions
		self.checkTimer:Reset();

		if not MovableMan:IsActor(self.defenderBrain) then
			local findBrain = MovableMan:GetUnassignedBrain(self.defenderTeam);
			if findBrain then
				self.defenderBrain = findBrain;
			else
				self.WinnerTeam = self.attackerTeam;
				MovableMan:KillAllEnemyActors(self.attackerTeam);
				ActivityMan:EndActivity();
				return
			end
		else
			local players = 0;
			for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
				if self:PlayerActive(player) and self:PlayerHuman(player) then
					local team = self:GetTeamOfPlayer(player);
					local brain = self:GetPlayerBrain(player);
					--Look for a new brain
					if not brain or not MovableMan:ValidMO(brain) then
						brain = MovableMan:GetUnassignedBrain(team);
						if brain then
							self:SetPlayerBrain(brain, player);
							self:SwitchToActor(brain, player, team);
						else
							self:SetPlayerBrain(nil, player);
						end
					end
					if brain then
						players = players + 1;
						self:SetObservationTarget(brain.Pos, player);
					else
						self:ResetMessageTimer(player);
						FrameMan:ClearScreenText(self:ScreenOfPlayer(player));
						FrameMan:SetScreenText("Your brain has been destroyed!", self:ScreenOfPlayer(player), 2000, -1, false);
					end
				end
			end
			if players == 0 then
				self.WinnerTeam = self.CPUTeam;
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
				if actor.Team == self.PlayerTeam then
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
						FrameMan:SetScreenText("Enemy budget: " .. funds, self:ScreenOfPlayer(player), 0, 2500, false);
					end
				end
			end
			if self.CPUSpawnTimer:IsPastSimMS(self.CPUSpawnDelay) then
				self.CPUSpawnTimer:Reset();
				
				local unitRatio = enemyCount/math.max(allyCount, 1);
				--Send CPU to dig for gold if funds are low and a digger hasn't recently been sent
				self.sendGoldDiggers = not self.sendGoldDiggers and diggerCount < 3 and (funds < 500 or math.random() < 0.1);
				
				if self.CPUTeam == self.attackerTeam then
					if self.sendGoldDiggers then
						self:CreateDrop(self.CPUTeam, "Engineer");
					elseif unitRatio < 1.75 then
						self:CreateDrop(self.CPUTeam);
						self.CPUSpawnDelay = (30000 - self.difficultyRatio * 15000 + unitRatio * 5000) * rte.SpawnIntervalScale;
					else
						self.CPUSpawnDelay = self.CPUSpawnDelay * 0.9;
					end
				elseif self.CPUTeam == self.defenderTeam then
				
					local dist = Vector();
					local searchRadius = (SceneMan.SceneWidth + SceneMan.SceneHeight) * 0.2;
					local targetActor = MovableMan:GetClosestEnemyActor(self.CPUTeam, Vector(self.defenderBrain.Pos.X, SceneMan.SceneHeight * 0.5), searchRadius, dist);
					if targetActor and not SceneMan:IsUnseen(targetActor.Pos.X, targetActor.Pos.Y, self.CPUTeam) then
						self.attackPos = targetActor.Pos;
						
						self.CPUSpawnDelay = self.CPUSpawnDelay * 0.5;--* dist.Magnitude/searchRadius;
						--TODO: Fix GetClosestTeamActor and use that instead
						local closestGuard = MovableMan:GetClosestEnemyActor(targetActor.Team, targetActor.Pos, searchRadius - dist.Magnitude, Vector());
						if closestGuard and math.random() > dist.Magnitude/searchRadius then
							--Send a nearby alerted guard after the intruder
							closestGuard.AIMode = Actor.AIMODE_GOTO;
							closestGuard:SetAIMOWayPoint(targetActor);
							self.attackPos = nil;
							--A guard has been sent, the next unit should spawn faster
							self.CPUSpawnDelay = self.CPUSpawnDelay * 0.8;
						else
							self:CreateDrop(self.CPUTeam);
							self.CPUSpawnDelay = (40000 - self.difficultyRatio * 20000 + unitRatio * 7500) * rte.SpawnIntervalScale;
							if math.random() < 0.5 then
								--Change target for the next attack
								self.attackPos = nil;
							end
						end
					else
						self.attackPos = nil;
						
						if unitRatio < 1.25 then
							if self.sendGoldDiggers then
								self:CreateDrop(self.CPUTeam, "Engineer");
							else
								self:CreateDrop(self.CPUTeam);
							end
							self.CPUSpawnDelay = (40000 - self.difficultyRatio * 20000 + unitRatio * 7500) * rte.SpawnIntervalScale;
						else
							self.CPUSpawnDelay = self.CPUSpawnDelay * 0.9;
						end
					end
				end
			end
		elseif enemyCount < 1 then
			MovableMan:KillAllEnemyActors(self.playerTeam);
			self.WinnerTeam = self.playerTeam;
			self:ClearObjectivePoints();
			ActivityMan:EndActivity();
			return
		end
	end
end


function BunkerBreach:CreateDrop(team, loadout)
	local tech = self:GetTeamTech(team);
	local crabRatio = self:GetCrabToHumanSpawnRatio(PresetMan:GetModuleID(tech));

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
	local tech = self:GetTeamTech(team);
	local actor;
	if math.random() < 0.5 then	--Pick a unit from the loadout presets occasionally
		if loadout == "Light" then
			actor = PresetMan:GetLoadout("Infantry " .. (math.random() < 0.7 and "Light" or "CQB"), tech, false);
		elseif loadout == "Heavy" then
			actor = PresetMan:GetLoadout("Infantry " .. (math.random() < 0.7 and "Heavy" or "Grenadier"), tech, false);
		else
			actor = PresetMan:GetLoadout("Infantry " .. loadout, tech, false);
		end
	end
	if not actor then
		if loadout == "Light" then
			actor = RandomAHuman("Actors - Light", tech);
			
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", tech));
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
			if math.random() < 0.6 then
				actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", tech));
			else
				actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
			end
			
		elseif loadout == "Heavy" then
			actor = RandomAHuman("Actors - Heavy", tech);
			
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Heavy", tech));
			if math.random() < 0.3 then
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", tech));
			else
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
				if math.random() < 0.3 then
					actor:AddInventoryItem(RandomHeldDevice("Shields", tech));
				else
					actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
				end
			end
			
		elseif loadout == "Sniper" then
			actor = RandomAHuman("Actors", tech);
			
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Sniper", tech));
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
			if math.random() < 0.3 then
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
			else
				actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
			end
			
		elseif loadout == "Engineer" then
			actor = RandomAHuman("Actors - Light", tech);
			
			if math.random() < 0.7 then
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", tech));
			else
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
				if math.random() < 0.3 then
					actor:AddInventoryItem(RandomHeldDevice("Shields", tech));
				else
					actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
				end
			end
			actor:AddInventoryItem(RandomHDFirearm("Tools - Diggers", tech));
		else
			actor = RandomAHuman("Actors", tech);
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Primary", tech));
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
			
			local rand = math.random();
			if rand < 0.25 then
				actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", tech));
			elseif rand < 0.50 then
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
			elseif rand < 0.75 then
				actor:AddInventoryItem(RandomHeldDevice("Shields", tech));
			else
				actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
			end
		end
	end
	if loadout == "Engineer" and self.sendGoldDiggers then
		actor.AIMode = Actor.AIMODE_GOLDDIG;
	elseif self.attackPos then
		actor:AddAISceneWaypoint(self.attackPos);
	elseif team == self.attackerTeam then
		actor.AIMode = Actor.AIMODE_BRAINHUNT;
	else
		actor.AIMode = math.random() < 0.7 and Actor.AIMODE_SENTRY or Actor.AIMODE_PATROL;
	end
	actor.Team = team;
	return actor;
end


function BunkerBreach:CreateCrab(team, loadout)
	if loadout == nil then
		loadout = "Mecha";
	end
	local tech = self:GetTeamTech(team);
	if self:GetCrabToHumanSpawnRatio(PresetMan:GetModuleID(tech)) > 0 then
		local actor;
		if math.random() < 0.5 then
			actor = PresetMan:GetLoadout(loadout, tech, false);
		else
			actor = loadout == "Turret" and RandomACrab("Actors - Turrets", tech) or RandomACrab("Actors - Mecha", tech);
		end
		actor.Team = team;
		return actor;
	else
		return self:CreateInfantry(team, "Heavy");
	end
end


function BunkerBreach:CreateBrainBot(team)
	local tech = self:GetTeamTech(team);
	local actor;
	if tech ~= -1 and team == self.attackerTeam then
		actor = PresetMan:GetLoadout("Infantry Brain", tech, false);
	else
		actor = RandomAHuman("Brains", tech);
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", tech));
		if team == self.attackerTeam then
			actor:AddInventoryItem(CreateHDFirearm("Constructor", "Base.rte"));
		else
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
		end
		actor.AIMode = Actor.AIMODE_SENTRY;
		actor.Team = team;
	end
	return actor;
end