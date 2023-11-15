package.loaded.Constants = nil; require("Constants");

dofile("Browncoats.rte/Activities/RefineryAssaultFunctions.lua");

function RefineryAssault:OnMessage(message, object)

	self.tacticsHandler:OnMessage(message, object);

	--print("activitygotmessage")
	
	--print(message)

	if message == "Captured_RefineryTestCapturable1" then
	
		self.stage2HoldTimer:Reset();
	
		-- as soon as any of the hack consoles are captured, we don't wanna bother with the stage 1 counterattack anymore.
		self.tacticsHandler:RemoveTask("Counterattack", self.aiTeam);
	
		if object == self.humanTeam then
		
			-- if we have the other one, we have both, initiate win condition timer
			if self.buyDoorTables.teamAreas[self.humanTeam].LC2 then
				self.stage2HoldingBothConsoles = true;
			end
	
			table.insert(self.buyDoorTables.teamAreas[self.humanTeam], "LC1");
			self.buyDoorTables.teamAreas[self.aiTeam].LC1 = nil;
			
			for k, v in pairs(self.buyDoorTables.LC1) do
				v.Team = self.humanTeam;
			end
		else
			self.stage2HoldingBothConsoles = false;
		
			table.insert(self.buyDoorTables.teamAreas[self.aiTeam], "LC1");
			self.buyDoorTables.teamAreas[self.humanTeam].LC1 = nil;
			
			for k, v in pairs(self.buyDoorTables.LC1) do
				v.Team = self.aiTeam;
			end		
		end
	

	elseif message == "Captured_RefineryTestCapturable2" then
	
		self.stage2HoldTimer:Reset();
	
		-- as soon as any of the hack consoles are captured, we don't wanna bother with the stage 1 counterattack anymore.
		self.tacticsHandler:RemoveTask("Counterattack", self.aiTeam);
	
		if object == self.humanTeam then
		
			-- if we have the other one, we have both, initiate win condition timer
			if self.buyDoorTables.teamAreas[self.humanTeam].LC1 then
				self.stage2HoldingBothConsoles = true;
			end
	
			table.insert(self.buyDoorTables.teamAreas[self.humanTeam], "LC2");
			self.buyDoorTables.teamAreas[self.aiTeam].LC2 = nil;
			
			for k, v in pairs(self.buyDoorTables.LC2) do
				v.Team = self.humanTeam;
			end
		else
			self.stage2HoldingBothConsoles = false;
			
			table.insert(self.buyDoorTables.teamAreas[self.aiTeam], "LC2");
			self.buyDoorTables.teamAreas[self.humanTeam].LC2 = nil;
			
			for k, v in pairs(self.buyDoorTables.LC2) do
				v.Team = self.aiTeam;
			end		
		end
	end

end

function RefineryAssault:SetupBuyDoorAreaTable(self, area)

	-- remove BuyDoorArea_ from the area name to get our table key
	local areaKey = string.sub(area.Name, 13, -1);
	
	print("area key: " .. areaKey);

	self.buyDoorTables[areaKey] = {};
	
	-- does not work, actors are not added properly yet at this stage
	
	-- for box in area.Boxes do
		-- print("onebox")
		-- for mo in MovableMan:GetMOsInBox(box, -1, false) do
			-- print(mo)
			-- if mo.PresetName == "Reinforcement Door" then
				-- table.insert(self.buyDoorTables.All, mo)
				-- self.buyDoorTables[areaKey][tostring(#self.buyDoorTables.All)] = mo;
			-- end
		-- end
	-- end
	
	for mo in MovableMan.AddedActors do
		if mo.PresetName == "Reinforcement Door" and area:IsInside(mo.Pos) then
			table.insert(self.buyDoorTables.All, mo)
			self.buyDoorTables[areaKey][tonumber(#self.buyDoorTables.All)] = mo;
		end
	end
		

end

-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Game functions
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------




-----------------------------------------------------------------------------------------
-- Start Activity
-----------------------------------------------------------------------------------------

function RefineryAssault:StartActivity(newGame)
	print("START! -- RefineryAssault:StartActivity()!");
	
	self.humansAreControllingAlliedActors = false;
	
	self.humanTeam = Activity.TEAM_1;
	self.aiTeam = Activity.TEAM_2;
	self.humanTeamTech = PresetMan:GetModuleID(self:GetTeamTech(self.humanTeam));
	self.aiTeamTech = PresetMan:GetModuleID(self:GetTeamTech(self.aiTeam));
	
	self.humanPlayers = {};
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) and self:GetTeamOfPlayer(player) == self.humanTeam then
			self.humanPlayers[#self.humanPlayers + 1] = player;
		end
	end
	
	self.goldTimer = Timer();
	self.goldIncreaseDelay = 4000;
	self.goldIncreaseAmount = 250;
	
	self.saveLoadHandler = require("Activities/Utility/SaveLoadHandler");
	self.saveLoadHandler:Initialize(self);
	
	self.tacticsHandler = require("Activities/Utility/TacticsHandler");
	self.tacticsHandler:Initialize(self, newGame);
	
	self.dockingHandler = require("Activities/Utility/DockingHandler");
	self.dockingHandler:Initialize(self, newGame);
	
	self.buyDoorHandler = require("Activities/Utility/BuyDoorHandler");
	self.buyDoorHandler:Initialize(self, newGame);
	
	self.deliveryCreationHandler = require("Activities/Utility/DeliveryCreationHandler");
	self.deliveryCreationHandler:Initialize(self);
	
	
	-- Stage stuff
	
	self.stage2HoldTimer = Timer();
	self.stage2TimeToHoldConsoles = 5000;
	
	if newGame then
		
		-- Always active base task for defenders
		self.tacticsHandler:AddTask("Brainhunt", self.aiTeam, Vector(0, 0), "Brainhunt", 2);
	
		-- Set up buy door areas
		-- it would be great to handle this generically, but we have specific
		-- areas and capturing of buy doors within those areas etc and that's
		-- not generic enough anymore
		
		-- the All table holds all buy doors so we can supply them to the handler,
		-- and also get what index to save in the area-specific tables.
		-- so each area-specific table will be made up of the actual indexes
		-- in the All table which we can SendCustomOrder with.
		
		self.buyDoorTables = {};
		self.buyDoorTables.All = {};
		
		local area = SceneMan.Scene:GetOptionalArea("BuyDoorArea_LC1");
		self:SetupBuyDoorAreaTable(self, area);
		
		area = SceneMan.Scene:GetOptionalArea("BuyDoorArea_LC2");
		self:SetupBuyDoorAreaTable(self, area);

		self.buyDoorHandler:ReplaceBuyDoorTable(self.buyDoorTables.All);
		
		self.buyDoorTables.teamAreas = {};
		self.buyDoorTables.teamAreas[self.humanTeam] = {};
		self.buyDoorTables.teamAreas[self.aiTeam] = {"LC1", "LC2"};
		
		for k, v in pairs(self.buyDoorTables.All) do
			print(v)
			v.Team = self.aiTeam;
		end
		
		-- Stages and stage function table
		
		self.Stage = 1;
		
		self:SetupFirstStage();
		
		self.stageFunctionTable = {};
		table.insert(self.stageFunctionTable, self.MonitorStage1);
		table.insert(self.stageFunctionTable, self.MonitorStage2);

		local automoverController = CreateActor("Invisible Automover Controller", "Base.rte");
		automoverController.Pos = Vector();
		automoverController.Team = self.aiTeam;
		MovableMan:AddActor(automoverController);

		SceneMan.Scene:AddNavigatableArea("Mission Stage Area 1");
		SceneMan.Scene:AddNavigatableArea("Mission Stage Area 2");
		--SceneMan.Scene:AddNavigatableArea("Mission Stage Area 3");
		--SceneMan.Scene:AddNavigatableArea("Mission Stage Area 4");
		
		-- Tell capturables to deactivate, we'll activate them as we go along
		
		MovableMan:SendGlobalMessage("DeactivateCapturable_RefineryTestCapturable1");
		MovableMan:SendGlobalMessage("DeactivateCapturable_RefineryTestCapturable2");
	
	else
		self:ResumeLoadedGame();
	end
	
	-- for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		-- if self:PlayerActive(player) and self:PlayerHuman(player) then
			-- -- Check if we already have a brain assigned
			-- if not self:GetPlayerBrain(player) then
				-- local foundBrain = MovableMan:GetUnassignedBrain(self:GetTeamOfPlayer(player));
				-- -- If we can't find an unassigned brain in the scene to give each player, then force to go into editing mode to place one
				-- if not foundBrain then
					-- self.ActivityState = Activity.EDITING;
					-- -- Open all doors so we can do pathfinding through them with the brain placement
					-- MovableMan:OpenAllDoors(true, Activity.NOTEAM);
					-- AudioMan:ClearMusicQueue();
					-- AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/ccambient4.ogg", -1, -1);
					-- self:SetLandingZone(Vector(player*SceneMan.SceneWidth/4, 0), player);
				-- else
					-- -- Set the found brain to be the selected actor at start
					-- self:SetPlayerBrain(foundBrain, player);
					-- self:SwitchToActor(foundBrain, player, self:GetTeamOfPlayer(player));
					-- self:SetLandingZone(self:GetPlayerBrain(player).Pos, player);
					-- -- Set the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
					-- self:SetObservationTarget(self:GetPlayerBrain(player).Pos, player);
				-- end
			-- end
		-- end
	-- end	
	
end

function RefineryAssault:ResumeLoadedGame()

	print("loading local refineryassault buy door table...");
	self.buyDoorTables = self.saveLoadHandler:ReadSavedStringAsTable("buyDoorTables");
	print("loaded local refineryassault buy door table!");
	
	self.goldTimer.ElapsedRealTimeMS = self:LoadNumber("goldTimer");
	
	self.stage2HoldingBothConsoles = self:LoadNumber("stage2HoldingBothConsoles") == 1 and true or false;
	self.stage2HoldTimer.ElapsedRealTimeMS = self:LoadNumber("stage2HoldTimer");
	
	-- Handlers
	self.tacticsHandler:OnLoad(self.saveLoadHandler);
	self.dockingHandler:OnLoad(self.saveLoadHandler);
	self.buyDoorHandler:OnLoad(self.saveLoadHandler);
	
	self.buyDoorHandler:ReplaceBuyDoorTable(self.buyDoorTables.All);
		
end

function RefineryAssault:OnSave()
	
	self.saveLoadHandler:SaveTableAsString("buyDoorTables", self.buyDoorTables);
	
	self:SaveNumber("goldTimer", self.goldTimer.ElapsedRealTimeMS);
	
	self:SaveNumber("stage2HoldingBothConsoles", self.stage2HoldingBothConsoles and 1 or 0);
	self:SaveNumber("stage2HoldTimer", self.stage2HoldTimer.ElapsedRealTimeMS);
	
	-- Handlers
	self.tacticsHandler:OnSave(self.saveLoadHandler);
	self.dockingHandler:OnSave(self.saveLoadHandler);
	self.buyDoorHandler:OnSave(self.saveLoadHandler);
	
end

-----------------------------------------------------------------------------------------
-- Pause Activity
-----------------------------------------------------------------------------------------

function RefineryAssault:PauseActivity(pause)
	print("PAUSE! -- RefineryAssault:PauseActivity()!");
end

-----------------------------------------------------------------------------------------
-- End Activity
-----------------------------------------------------------------------------------------

function RefineryAssault:EndActivity()
	print("END! -- RefineryAssault:EndActivity()!");
end

-----------------------------------------------------------------------------------------
-- Update Activity
-----------------------------------------------------------------------------------------

function RefineryAssault:UpdateActivity()

	-- Monitor stage objectives
	
	self.stageFunc = self.stageFunctionTable[self.Stage];
	self:stageFunc();

	-- Gold increasing for teams

	if self.goldTimer:IsPastSimMS(self.goldIncreaseDelay) then
	
		self.goldTimer:Reset();
		
		self:ChangeTeamFunds(self.goldIncreaseAmount, self.humanTeam);
		self:ChangeTeamFunds(self.goldIncreaseAmount, self.aiTeam);
	
	end
	
	-- Seek tasks to create squads for
	-- Only human team uses docks
	
	local goldAmountsTable = {};
	goldAmountsTable[0] = self:GetTeamFunds(self.humanTeam);
	goldAmountsTable[1] = self:GetTeamFunds(self.aiTeam);
	
	local team, task = self.tacticsHandler:UpdateTacticsHandler(goldAmountsTable);
	
	if task then
		--print("gottask")
		local squad = self:SendBuyDoorDelivery(team, task);
		if squad then
			self.tacticsHandler:AddTaskedSquad(team, squad, task.Name);
		elseif team == self.humanTeam then
			squad = self:SendDockDelivery(team, task);
			if squad then
				self.tacticsHandler:AddTaskedSquad(team, squad, task.Name);
			end
		end
	end
	
	-- Update docking craft
	
	self.dockingHandler:UpdateDockingCraft();
	
	
	
	
	
	
	-- Debug
	
	local debugDoorTrigger = UInputMan:KeyPressed(Key.J)	
	
	local debugTrigger = UInputMan:KeyPressed(Key.I)
	
	local debugRocketTrigger = UInputMan:KeyPressed(Key.U)
	
	if debugDoorTrigger then
	
		self:SendBuyDoorDelivery(self.humanTeam);
		
	end
	
	if debugTrigger then
	
		self:SendDockDelivery(self.humanTeam, false);
		print("tried dropship")
		
	end
	
	if debugRocketTrigger then
	
		self:SendDockDelivery(self.humanTeam, true);
		print("triedrocket")
		
	end	
end
