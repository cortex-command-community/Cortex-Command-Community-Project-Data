package.loaded.Constants = nil; require("Constants");

function RefineryAssault:OnMessage(message, object)

	self.tacticsHandler:OnMessage(message, object);

	--print("activitygotmessage")
	
	--print(message)

	if message == "Captured_RefineryTestCapturable1" then
	
		table.insert(self.buyDoorTables.teamAreas[self.humanTeam], "LC1");
		self.buyDoorTables.teamAreas[self.aiTeam].LC1 = nil;
		
		for k, v in pairs(self.buyDoorTables.LC1) do
			v.Team = self.humanTeam;
		end
		
		local taskPos = SceneMan.Scene:GetOptionalArea("CaptureArea_RefineryTestCapturable2").Center;
		
		self.tacticsHandler:AddTask("Attack Hack Console 2", 0, taskPos, "Attack", 10);
		self.tacticsHandler:AddTask("Defend Hack Console 2", 1, taskPos, "Defend", 10);		
	
		self.tacticsHandler:RemoveTask("Attack Hack Console 1", 0)
		self.tacticsHandler:RemoveTask("Defend Hack Console 1", 1)
	
		MovableMan:SendGlobalMessage("DeactivateCapturable_RefineryTestCapturable1");
		MovableMan:SendGlobalMessage("ActivateCapturable_RefineryTestCapturable2");
		print("triedtoswitchcapturables")
	elseif message == "Captured_RefineryTestCapturable2" then
	
		table.insert(self.buyDoorTables.teamAreas[self.humanTeam], "LC2");
		self.buyDoorTables.teamAreas[self.aiTeam].LC2 = nil;

		for k, v in pairs(self.buyDoorTables.LC2) do
			v.Team = self.humanTeam;
		end
	
		MovableMan:SendGlobalMessage("DeactivateCapturable_RefineryTestCapturable2");
		self:GetBanner(GUIBanner.YELLOW, 0):ShowText("YOU'RE WINNER!", GUIBanner.FLYBYLEFTWARD, 1500, Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), 0.4, 4000, 0)
	end

end

-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Custom functions
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Create Delivery
-----------------------------------------------------------------------------------------

function RefineryAssault:SendDockDelivery(team, task, forceRocketUsage, squadType)

	local craft, goldCost = self.deliveryCreationHandler:CreateSquadWithCraft(team, forceRocketUsage);
	
	local squadTable = {};
	for item in craft.Inventory do
		if IsActor(item) then
			item = ToActor(item);
			table.insert(squadTable, item);
			if task then
				if task.Type == "Defend" or task.Type == "Attack" then
					item.AIMode = Actor.AIMODE_GOTO;
					if task.Position.PresetName then -- ghetto check if this is an MO
						item:AddAIMOWaypoint(task.Position);
					else
						item:AddAISceneWaypoint(task.Position);
					end
				else
					item.AIMode = Actor.AIMODE_BRAINHUNT;
				end
			end
		end
	end
		
	local success = self.dockingHandler:SpawnDockingCraft(craft)
			
	if success then
		self:SetTeamFunds(self:GetTeamFunds(team) - goldCost, team);
		return squadTable
	end
	
	return false;
	
end

function RefineryAssault:SendBuyDoorDelivery(team, task, squadType, specificIndex)

	local order, goldCost = self.deliveryCreationHandler:CreateSquad(team);
	
	--print("tried order for team: " .. team);
	
	if order then
		for i = 1, #order do
			if task then
				if task.Type == "Defend" or task.Type == "Attack" then
					order[i].AIMode = Actor.AIMODE_GOTO;
					if task.Position.PresetName then -- ghetto check if this is an MO
						order[i]:AddAIMOWaypoint(task.Position);
					else
						order[i]:AddAISceneWaypoint(task.Position);
					end
				else
					order[i].AIMode = Actor.AIMODE_BRAINHUNT;
				end
			end
				
		end
		
		local taskPos = task.Position.PresetName and task.Position.Pos or task.Position; -- ghetto MO check
		-- check if it's in an area this team owns
		local areaThisIsIn
		for i = 1, #self.buyDoorTables.teamAreas[team] do
			local area = SceneMan.Scene:GetOptionalArea("BuyDoorArea_" .. self.buyDoorTables.teamAreas[team][i]);
			if area:IsInside(taskPos) then
				areaThisIsIn = area;
				break;
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
					self:SetTeamFunds(self:GetTeamFunds(team) - goldCost, team);
					return order;
				end
			end
		end
	end
	
	return false;
	
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

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			-- Check if we already have a brain assigned
			if not self:GetPlayerBrain(player) then
				local foundBrain = MovableMan:GetUnassignedBrain(self:GetTeamOfPlayer(player));
				-- If we can't find an unassigned brain in the scene to give each player, then force to go into editing mode to place one
				if not foundBrain then
					self.ActivityState = Activity.EDITING;
					-- Open all doors so we can do pathfinding through them with the brain placement
					MovableMan:OpenAllDoors(true, Activity.NOTEAM);
					AudioMan:ClearMusicQueue();
					AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/ccambient4.ogg", -1, -1);
					self:SetLandingZone(Vector(player*SceneMan.SceneWidth/4, 0), player);
				else
					-- Set the found brain to be the selected actor at start
					self:SetPlayerBrain(foundBrain, player);
					self:SwitchToActor(foundBrain, player, self:GetTeamOfPlayer(player));
					self:SetLandingZone(self:GetPlayerBrain(player).Pos, player);
					-- Set the observation target to the brain, so that if/when it dies, the view flies to it in observation mode
					self:SetObservationTarget(self:GetPlayerBrain(player).Pos, player);
				end
			end
		end
	end
	
	self.humansAreControllingAlliedActors = false;
	
	self.humanTeam = Activity.TEAM_1;
	self.aiTeam = Activity.TEAM_2;
	self.humanTeamTech = PresetMan:GetModuleID(self:GetTeamTech(self.humanTeam));
	self.aiTeamTech = PresetMan:GetModuleID(self:GetTeamTech(self.aiTeam));
	
	self.goldTimer = Timer();
	self.goldIncreaseDelay = 4000;
	self.goldIncreaseAmount = 500;
	
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
	
	if newGame then
	
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
		

		local automoverController = CreateActor("Invisible Automover Controller", "Base.rte");
		automoverController.Pos = Vector();
		automoverController.Team = self.aiTeam;
		MovableMan:AddActor(automoverController);

		--SceneMan.Scene:AddNavigatableArea("Mission Stage Area 1");
		--SceneMan.Scene:AddNavigatableArea("Mission Stage Area 2");
		--SceneMan.Scene:AddNavigatableArea("Mission Stage Area 3");
		--SceneMan.Scene:AddNavigatableArea("Mission Stage Area 4");
		
		-- Grand Strategic WhateverTheFuck
		
		-- Capturable setup
		
		MovableMan:SendGlobalMessage("DeactivateCapturable_RefineryTestCapturable2");
		
		-- Test tasks
		
		self:SetTeamFunds(self.humanTeam, 200);
		self:SetTeamFunds(self.aiTeam, 200);
		
		local taskPos = SceneMan.Scene:GetOptionalArea("CaptureArea_RefineryTestCapturable1").Center;
		
		self.tacticsHandler:AddTask("Attack Hack Console 1", 0, taskPos, "Attack", 10);
		self.tacticsHandler:AddTask("Defend Hack Console 1", 1, taskPos, "Defend", 10);
	
	else
		self:ResumeLoadedGame();
	end
end

function RefineryAssault:ResumeLoadedGame()

	print("loading local refineryassault buy door table...");
	self.buyDoorTables = self.saveLoadHandler:ReadSavedStringAsTable("buyDoorTables");
	print("loaded local refineryassault buy door table!");
	
	self.goldTimer.ElapsedRealTimeMS = self:LoadNumber("goldTimer");
	
	-- Handlers
	self.tacticsHandler:OnLoad(self.saveLoadHandler);
	self.dockingHandler:OnLoad(self.saveLoadHandler);
	self.buyDoorHandler:OnLoad(self.saveLoadHandler);
	
	self.buyDoorHandler:ReplaceBuyDoorTable(self.buyDoorTables.All);
		
end

function RefineryAssault:OnSave()
	
	self.saveLoadHandler:SaveTableAsString("buyDoorTables", self.buyDoorTables);
	
	self:SaveNumber("goldTimer", self.goldTimer.ElapsedRealTimeMS);
	
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
