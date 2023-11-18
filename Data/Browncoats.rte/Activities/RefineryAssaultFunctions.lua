function RefineryAssault:HandleMessage(message, object)

	self.tacticsHandler:OnMessage(message, object);

	print("activitygotmessage")
	
	print(message)
	print(object)

	if message == "Captured_RefineryLCHackConsole1" then
	
		self.stage2HoldTimer:Reset();

		print(self.humanTeam .. " team vs object: " .. object);
		
		if object == self.humanTeam then
		
			print("HUMAN CAPTURED 1")
			
			self.stage2HoldingLC1 = true;
		
			-- if we have the other one, we have both, initiate win condition timer
			if self.stage2HoldingLC2 then
				self.stage2HoldingBothConsoles = true;
			end
	
			table.insert(self.buyDoorTables.teamAreas[self.humanTeam], "LC1");
			self.buyDoorTables.teamAreas[self.aiTeam].LC1 = nil;
			
			for k, v in pairs(self.buyDoorTables.LC1) do
				v.Team = self.humanTeam;
			end
		else
			print("NOTHUMAN CAPPED 1");
			print(self.humanTeam .. " team vs object: " .. object);
			self.stage2HoldingLC1 = false;
			self.stage2HoldingBothConsoles = false;
		
			table.insert(self.buyDoorTables.teamAreas[self.aiTeam], "LC1");
			self.buyDoorTables.teamAreas[self.humanTeam].LC1 = nil;
			
			for k, v in pairs(self.buyDoorTables.LC1) do
				v.Team = self.aiTeam;
			end		
		end
		
		-- as soon as any of the hack consoles are captured, we don't wanna bother with the stage 1 counterattack anymore.
		self.tacticsHandler:RemoveTask("Counterattack", self.aiTeam);
	

	elseif message == "Captured_RefineryLCHackConsole2" then
	
		self.stage2HoldTimer:Reset();
	
		if object == self.humanTeam then
		
			print("HUMAN CAPTURED 2")
			
			self.stage2HoldingLC2 = true;
		
			-- if we have the other one, we have both, initiate win condition timer
			if self.stage2HoldingLC1 then
				self.stage2HoldingBothConsoles = true;
			end
	
			table.insert(self.buyDoorTables.teamAreas[self.humanTeam], "LC2");
			self.buyDoorTables.teamAreas[self.aiTeam].LC2 = nil;
			
			for k, v in pairs(self.buyDoorTables.LC2) do
				v.Team = self.humanTeam;
			end
		else
			self.stage2HoldingLC2 = false;
			self.stage2HoldingBothConsoles = false;
			
			table.insert(self.buyDoorTables.teamAreas[self.aiTeam], "LC2");
			self.buyDoorTables.teamAreas[self.humanTeam].LC2 = nil;
			
			for k, v in pairs(self.buyDoorTables.LC2) do
				v.Team = self.aiTeam;
			end		
		end
		
		-- as soon as any of the hack consoles are captured, we don't wanna bother with the stage 1 counterattack anymore.
		self.tacticsHandler:RemoveTask("Counterattack", self.aiTeam);
		
	elseif message == "Captured_RefineryS3OilCapturable" then
	
		self.humanAIGoldIncreaseAmount = self.humanAIGoldIncreaseAmount + 20;		
		self.playerGoldIncreaseAmount = self.playerGoldIncreaseAmount + 20;
		
		local soundContainer = CreateSoundContainer("Yskely Refinery Oil Spout Engage", "Browncoats.rte");
		soundContainer:Play(Vector(0, 0));
		
	elseif message == "RefineryAssault_RefineryConsoleBroken" then
		
		self.stage3ConsolesBroken = self.stage3ConsolesBroken + 1;
		
	end

end



function RefineryAssault:SendDockDelivery(team, task, forceRocketUsage, squadType)

	local squadCount = math.random(3, 4);

	local craft;
	local order;
	local goldCost;

	if squadType == "Elite" then
		craft, squad, goldCost = self.deliveryCreationHandler:CreateEliteSquadWithCraft(team, forceRocketUsage, squadCount);
	else
		craft, squad, goldCost = self.deliveryCreationHandler:CreateSquadWithCraft(team, forceRocketUsage, squadCount, squadType);
	end
	
	local success = self.dockingHandler:SpawnDockingCraft(craft)
			
	if success then
		self.tacticsHandler:ApplyTaskToSquadActors(squad, task);
		self:ChangeAIFunds(team, -goldCost);
		return squad
	end
	
	return false;
	
end

function RefineryAssault:SendBuyDoorDelivery(team, task, squadType, specificIndex)

	local squadCount = math.random(1, 2);

	local order;
	local goldCost;

	if squadType == "Elite" then
		order, goldCost = self.deliveryCreationHandler:CreateEliteSquad(team, squadCount);
	else
		order, goldCost = self.deliveryCreationHandler:CreateSquad(team, squadCount, squadType);
	end
	
	--print("tried order for team: " .. team);
	
	if order then
		if task then
			
			local taskPos = task.Position.PresetName and task.Position.Pos or task.Position; -- ghetto MO check
			if taskPos.Name then -- ghetto-er Area check
				taskPos = taskPos.RandomPoint;
			end
			-- check if it's in an area this team owns
			local areaThisIsIn
			for i = 1, #self.buyDoorTables.teamAreas[team] do
				local area = SceneMan.Scene:GetOptionalArea("BuyDoorArea_" .. self.buyDoorTables.teamAreas[team][i]);
				if area:IsInside(taskPos) then
					areaThisIsIn = area;
					break;
				end
			end
		end
		
		if not areaThisIsIn or not self.buyDoorHandler:GetAvailableBuyDoorsInArea(areaThisIsIn, team) then
			-- select any owned area if we don't own the task area
			-- everyone should always own at least one buy door area after stage 2, so.....
			if #self.buyDoorTables.teamAreas[team] > 0 then
				areaThisIsIn = SceneMan.Scene:GetOptionalArea("BuyDoorArea_" .. self.buyDoorTables.teamAreas[team][math.random(1, #self.buyDoorTables.teamAreas[team])]);
				--print(areaThisIsIn.Name)
				--print("reverted to any buy door area pick")
			else
				--print("team " .. team .. " doesn't have a backup area");
			end
		end
		
		if areaThisIsIn then
			--print(areaThisIsIn.Name)
			
			local randomSelection;
			local usableBuyDoorTable = self.buyDoorHandler:GetAvailableBuyDoorsInArea(areaThisIsIn, team)
			
			if usableBuyDoorTable then
				randomSelection = usableBuyDoorTable[math.random(1, #usableBuyDoorTable)]
			end
			
			if randomSelection then
				local success = self.buyDoorHandler:SendCustomOrder(order, team, randomSelection);
				if success then
					self.tacticsHandler:ApplyTaskToSquadActors(order, task);
					self:ChangeAIFunds(team, -goldCost);
					return order;
				end
			end
		end
	end
	
	return false;
	
end

function RefineryAssault:SetupStartingActors()

	self.enemyActorTables = {};
	
	local AHumanTable = {};
	-- brownies don't really have acrabs, do they?
	local ACrabTable = {};

	for actor in MovableMan.AddedActors do
		-- any actors that are just Actor are likely buy doors or
		-- other misc objects. however, ahumans and acrabs are only actual units
		-- we care about.
		if IsAHuman(actor) then
			table.insert(AHumanTable, actor);
		elseif IsACrab(actor) then
			table.insert(ACrabTable, actor);
		end
	end
	
	-- i think sending a local table to tacticshandler avoids some issue, but as i write this comment
	-- i can't remember what they are...
	
	self.enemyActorTables.stage1 = {};
	self.enemyActorTables.stage1CounterAttActors = {};
	
	local stage1Squad = {};
	
	for i, actor in ipairs(AHumanTable) do
	
		if SceneMan.Scene:WithinArea("Mission Stage Area 1", actor.Pos) then
			table.insert(self.enemyActorTables.stage1, actor);
			table.insert(stage1Squad, actor);
			
			-- Set up HUD handler objectives
			
			self.HUDHandler:AddObjective(self.humanTeam,
			"S1KillEnemies" .. i,
			"Kill",
			"Attack",
			"Clear the first hanging building of enemies",
			"Secure an FOB for us to stage further attacks from.",
			actor,
			true,
			true);
			
			-- Test
			
			self.HUDHandler:QueueCameraPanEvent(self.humanTeam, "S1KillEnemies" .. i, actor, 0.1, 2500, false);
			
		end
		
		if SceneMan.Scene:WithinArea("RefineryAssault_S1CounterAttActors", actor.Pos) then
			table.insert(self.enemyActorTables.stage1CounterAttActors, actor);
			actor.HFlipped = true; -- look the right way numbnuts
		end		
		
	end
	
	-- One big happy squad
	
	self.tacticsHandler:AddTaskedSquad(self.aiTeam, stage1Squad, "Sentry");
	
	self.enemyActorTables.stage3FacilityOperator = {};
	
	-- note index access, we get a table back
	local facilityOperator = self.deliveryCreationHandler:CreateEliteSquad(self.aiTeam, 1, "Heavy")[1];
	local area = SceneMan.Scene:GetOptionalArea("RefineryAssault_S3FacilityOperator");
	local pos = SceneMan:MovePointToGround(area.Center, 50, 3);
	
	facilityOperator.Pos = pos;
	MovableMan:AddActor(facilityOperator);
	facilityOperator.AIMode = Actor.AIMODE_SENTRY;
	
	table.insert(self.enemyActorTables.stage3FacilityOperator, facilityOperator);
	
end

function RefineryAssault:SetupFirstStage()

	-- Unique function just to hide away init stuff - every other stage setup is immediately done upon completion of its
	-- Monitor function
	
	-- Disable all buy doors, not using them quite yet
	
	for k, v in pairs(self.buyDoorTables.All) do
		v.Team = -1
	end
	
	-- Set up stage 1 enemy actors
	
	self.tacticsHandler:AddTask("Sentry", self.aiTeam, Vector(0, 0), "Sentry", 10);
	
	self:SetupStartingActors();
	
	-- Set up the 2 dock squads
	
	local taskArea = SceneMan.Scene:GetOptionalArea("TacticsPatrolArea_MissionStage1");
	local task = self.tacticsHandler:AddTask("Search And Destroy", self.humanTeam, taskArea, "PatrolArea", 10);
	
	local squad = self:SendDockDelivery(self.humanTeam, task, false, "Elite");
	
	self.tacticsHandler:AddTaskedSquad(self.humanTeam, squad, task.Name);
	
	squad = self:SendDockDelivery(self.humanTeam, task, false, "Elite");
	
	self.tacticsHandler:AddTaskedSquad(self.humanTeam, squad, task.Name);
	
	-- Set up player squad and dropship
	
	local dropShip = self.deliveryCreationHandler:CreateEliteSquadWithCraft(self.humanTeam, false, 5);
	local dropShipPos = SceneMan.Scene:GetOptionalArea("RefineryAssault_HumanBrainSpawn").Center;
	dropShip.Team = self.humanTeam;
	dropShip.Pos = dropShipPos;
	dropShip.AIMode = Actor.AIMODE_SENTRY;
	dropShip.PlayerControllable = true;
	
	for _, player in pairs(self.humanPlayers) do
		local brain = PresetMan:GetLoadout("Infantry Brain", self.humanTeamTech, false);
		if brain then
			brain:RemoveInventoryItem("Constructor");
		else
			brain = RandomAHuman("Brains", self.humanTeamTech);
			brain:AddToGroup("Brain " .. tostring(player));
			brain:AddInventoryItem(RandomHDFirearm("Weapons - Light", self.humanTeamTech));
			brain:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", self.humanTeamTech));
		end
		brain.Team = self.humanTeam;
		brain.AIMode = Actor.AIMODE_SENTRY;
		self:SetPlayerBrain(brain, player);
		self:SetObservationTarget(dropShip.Pos, player);
		self:SwitchToActor(dropShip, player, self.humanTeam);
		dropShip:AddInventoryItem(brain);
	end
		
	MovableMan:AddActor(dropShip)
	dropShip:OpenHatch();
	
	-- HUD handler listed objective
	
	self.HUDHandler:AddObjective(self.humanTeam,
	"S1KillEnemies",
	"Kill",
	"Attack",
	"Clear the first hanging building of enemies",
	"Secure an FOB for us to stage further attacks from.",
	actor,
	false,
	true);

end

function RefineryAssault:MonitorStage1()

	local noActors = true;

	for i, actor in ipairs(self.enemyActorTables.stage1) do
		if not actor or not MovableMan:ValidMO(actor) or actor:IsDead() then
			self.enemyActorTables.stage1[i] = false;
			self.HUDHandler:RemoveObjective(self.humanTeam, "S1KillEnemies" .. i);
		else
			noActors = false;
		end
	end
	
	if noActors then
		-- stage completion!
		self.Stage = 2;
		
		self:GetBanner(GUIBanner.YELLOW, 0):ShowText("STAGE 1 DONE!", GUIBanner.FLYBYLEFTWARD, 1500, Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), 0.4, 4000, 0)
		
		-- Start using buydoors
		
		for k, v in pairs(self.buyDoorTables.LC1) do
			v.Team = self.aiTeam;
		end
		
		for k, v in pairs(self.buyDoorTables.LC2) do
			v.Team = self.aiTeam;
		end
		
		-- Capturable setup
		
		MovableMan:SendGlobalMessage("ActivateCapturable_RefineryLCHackConsole1");
		MovableMan:SendGlobalMessage("ActivateCapturable_RefineryLCHackConsole2");
		
		-- Task setup
		
		local taskPos = SceneMan.Scene:GetOptionalArea("CaptureArea_RefineryLCHackConsole1").Center;
		
		self.tacticsHandler:AddTask("Attack Hack Console 1", self.humanTeam, taskPos, "Attack", 10);
		self.tacticsHandler:AddTask("Defend Hack Console 1", self.aiTeam, taskPos, "Defend", 10);
		
		taskPos = SceneMan.Scene:GetOptionalArea("CaptureArea_RefineryLCHackConsole2").Center;
		
		self.tacticsHandler:AddTask("Attack Hack Console 2", self.humanTeam, taskPos, "Attack", 10);
		self.tacticsHandler:AddTask("Defend Hack Console 2", self.aiTeam, taskPos, "Defend", 10);
		
		self.tacticsHandler:RemoveTask("Sentry", self.aiTeam);
		self.tacticsHandler:RemoveTask("Search And Destroy", self.humanTeam);
		
		-- Send the counterattack by setting up squad
		
		-- First check they still exist, could be dealing with a wise guy
		
		for k, actor in pairs(self.enemyActorTables.stage1CounterAttActors) do
			if not actor or not MovableMan:ValidMO(actor) or actor:IsDead() then
				table.remove(self.enemyActorTables.stage1CounterAttActors, k);
			end
		end
		
		if #self.enemyActorTables.stage1CounterAttActors > 0 then
		
			local taskArea = SceneMan.Scene:GetOptionalArea("TacticsPatrolArea_MissionStage1");
			local task = self.tacticsHandler:AddTask("Counterattack", self.aiTeam, taskArea, "PatrolArea", 10);
			
			self.tacticsHandler:AddTaskedSquad(self.aiTeam, self.enemyActorTables.stage1CounterAttActors, task.Name);
			
		end
		
		--Monies
		
		self.humanAIFunds = math.max(self.humanAIFunds, 0);
		
		self.aiTeamGoldIncreaseAmount = self.aiTeamGoldIncreaseAmount + 100;
		self.humanAIGoldIncreaseAmount = self.humanAIGoldIncreaseAmount + 30;
		
		-- HUD handler
		
		self.HUDHandler:RemoveAllObjectives(self.humanTeam);
		
		self.HUDHandler:AddObjective(self.humanTeam,
		"S2HackConsoles",
		"Hack and hold",
		"Attack",
		"Hack and hold the logistics center control consoles",
		"Gain control of the facility's logistics computers and hold them until we finish downloading crucial intelligence.",
		nil,
		false,
		true);
		
		local objPos = SceneMan.Scene:GetOptionalArea("CaptureArea_RefineryLCHackConsole1").Center;
		
		self.HUDHandler:AddObjective(self.humanTeam,
		"S2HackConsole1",
		"Hack and hold",
		"Attack",
		"",
		"",
		objPos,
		true,
		true);
		
		local objPos = SceneMan.Scene:GetOptionalArea("CaptureArea_RefineryLCHackConsole2").Center;
		
		self.HUDHandler:AddObjective(self.humanTeam,
		"S2HackConsole2",
		"Hack and hold",
		"Attack",
		"",
		"",
		objPos,
		true,
		true);
	
	end	
	
end

function RefineryAssault:MonitorStage2()

	--print("stage 2 timer: " .. self.stage2HoldTimer.ElapsedSimTimeMS);
	--print(self.stage2HoldingBothConsoles)

	if self.stage2HoldingBothConsoles == true and self.stage2HoldTimer:IsPastSimMS(self.stage2TimeToHoldConsoles) then
		self:GetBanner(GUIBanner.YELLOW, 0):ShowText("YOU'RE S2 WINNER!", GUIBanner.FLYBYLEFTWARD, 1500, Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), 0.4, 4000, 0)
		self.Stage = 3;
		
		-- Capturable setup
		
		MovableMan:SendGlobalMessage("DeactivateCapturable_RefineryLCHackConsole1");
		MovableMan:SendGlobalMessage("DeactivateCapturable_RefineryLCHackConsole2");
		
		MovableMan:SendGlobalMessage("ActivateCapturable_RefineryS3OilCapturable");
		
		-- Setup stage 3 consoles
		
		self.stage3Consoles = {};
		
		local i = 1;
		
		for particle in MovableMan.Particles do
			if particle.PresetName == "Browncoat Refinery Console Breakable Objective" then
				table.insert(self.stage3Consoles, particle)
				self.tacticsHandler:AddTask("Defend Refinery Console " .. i, self.aiTeam, particle, "Defend", 10);
				self.tacticsHandler:AddTask("Attack Refinery Console " .. i, self.humanTeam, particle, "Attack", 10);
				i = i + 1;
				print("found refinery breakable console and added task")
			end
		end
		
		self.tacticsHandler:RemoveTask("Attack Hack Console 1", self.humanTeam);
		self.tacticsHandler:RemoveTask("Defend Hack Console 1", self.aiTeam);
		
		self.tacticsHandler:RemoveTask("Attack Hack Console 2", self.humanTeam);
		self.tacticsHandler:RemoveTask("Defend Hack Console 2", self.aiTeam);
		
		-- HUD handler
		
		self.HUDHandler:RemoveAllObjectives(self.humanTeam);
		
	end
	
end

function RefineryAssault:MonitorStage3()

	if self.stage3ConsolesBroken == 3 then
	
		for k, actor in pairs(self.enemyActorTables.stage1) do
			if not actor or not MovableMan:ValidMO(actor) or actor:IsDead() then
				table.remove(self.enemyActorTables.stage3FacilityOperator, k);
			end
		end
		
		if #self.enemyActorTables.stage3FacilityOperator == 0 then	
	
			self:GetBanner(GUIBanner.YELLOW, 0):ShowText("DOORS OPEN WOW!", GUIBanner.FLYBYLEFTWARD, 1500, Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), 0.4, 4000, 0)
			self.Stage = 4;
		
		end
		
	end
	
end

function RefineryAssault:MonitorStage4()

end