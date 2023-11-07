package.loaded.Constants = nil; require("Constants");

function RefineryAssault:OnMessage(message, object)

	print("activitygotmessage")
	
	print(message)

	if message == "Captured_RefineryTestCapturable1" then
	
		self.tacticsHandler:RemoveTask("Attack Hack Console 1", 0)
		self.tacticsHandler:RemoveTask("Defend Hack Console 1", 1)
		
		local taskPos = SceneMan.Scene:GetArea("CaptureArea_RefineryTestCapturable2").Center;
		
		self.tacticsHandler:AddTask("Attack Hack Console 2", 0, taskPos, "Attack", 10);
		self.tacticsHandler:AddTask("Defend Hack Console 2", 1, taskPos, "Defend", 10);		
	
		MovableMan:SendGlobalMessage("DeactivateCapturable_RefineryTestCapturable1");
		MovableMan:SendGlobalMessage("ActivateCapturable_RefineryTestCapturable2");
		print("triedtoswitchcapturables")
	elseif message == "Captured_RefineryTestCapturable2" then
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

function RefineryAssault:SendDockDelivery(team, forceRocketUsage, squadType)

	local craft = self.deliveryCreationHandler:CreateSquadWithCraft(team, forceRocketUsage);
	
	table.insert(self.actorList, craft)
	for item in craft.Inventory do
		if IsActor(item) then
			table.insert(self.actorList, item)
		end
	end
		
	local dockingSuccess = self.dockingHandler:SpawnDockingCraft(craft)
			
	return dockingSuccess;
	
end

function RefineryAssault:SendBuyDoorDelivery(team, task, squadType, specificIndex)

	local order, goldCost = self.deliveryCreationHandler:CreateSquad(team);
	
	if order then
		for i = 1, #order do
			table.insert(self.actorList, order[i]);
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
		local success = self.buyDoorHandler:SendCustomOrder(order);
		if success then
			self:SetTeamFunds(self:GetTeamFunds(team) - goldCost, team);
			return order;
		end
	end
	
	return false;
	
end

-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Game functions
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------




-----------------------------------------------------------------------------------------
-- Start Activity
-----------------------------------------------------------------------------------------

function RefineryAssault:StartActivity()
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

	self.doorMessageTimer = Timer();
	self.doorMessageTimer:SetSimTimeLimitMS(5000);
	self.allDoorsOpened = false;
	
	self.humansAreControllingAlliedActors = false;
	
	self.humanTeam = Activity.TEAM_1;
	self.aiTeam = Activity.TEAM_2;
	self.humanTeamTech = PresetMan:GetModuleID(self:GetTeamTech(self.humanTeam));
	self.aiTeamTech = PresetMan:GetModuleID(self:GetTeamTech(self.aiTeam));
	
	self.goldTimer = Timer();
	self.goldIncreaseDelay = 4000;
	self.goldIncreaseAmount = 10;
	
	self.tacticsHandler = require("Activities/Utility/TacticsHandler");
	self.tacticsHandler:Initialize(self);
	
	self.dockingHandler = require("Activities/Utility/DockingHandler");
	self.dockingHandler:Initialize(self);
	
	self.buyDoorHandler = require("Activities/Utility/BuyDoorHandler");
	self.buyDoorHandler:Initialize(self);
	
	self.deliveryCreationHandler = require("Activities/Utility/DeliveryCreationHandler");
	self.deliveryCreationHandler:Initialize(self);
	
	self.attackerBuyDoorTable = {};
	self.defenderBuyDoorTable = {};

	local automoverController = CreateActor("Invisible Automover Controller", "Base.rte");
	automoverController.Pos = Vector();
	automoverController.Team = self.aiTeam;
	MovableMan:AddActor(automoverController);

	SceneMan.Scene:AddNavigatableArea("Mission Stage Area 1");
	SceneMan.Scene:AddNavigatableArea("Mission Stage Area 2");
	SceneMan.Scene:AddNavigatableArea("Mission Stage Area 3");
	SceneMan.Scene:AddNavigatableArea("Mission Stage Area 4");
	
	-- Grand Strategic WhateverTheFuck
	
	self.actorList = {};
	
	-- Capturable setup
	
	MovableMan:SendGlobalMessage("DeactivateCapturable_RefineryTestCapturable2");
	
	-- Test tasks
	
	self:SetTeamFunds(self.humanTeam, 200);
	self:SetTeamFunds(self.aiTeam, 200);
	
	local taskPos = SceneMan.Scene:GetArea("CaptureArea_RefineryTestCapturable1").Center;
	
	self.tacticsHandler:AddTask("Attack Hack Console 1", 0, taskPos, "Attack", 10);
	self.tacticsHandler:AddTask("Defend Hack Console 1", 1, taskPos, "Defend", 10);
end

function RefineryAssault:OnSave()
	-- Don't have to do anything, just need this to allow saving/loading.
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

	if self.goldTimer:IsPastSimMS(self.goldIncreaseDelay) then
	
		self.goldTimer:Reset();
		
		self:ChangeTeamFunds(self.goldIncreaseAmount, self.humanTeam);
		self:ChangeTeamFunds(self.goldIncreaseAmount, self.aiTeam);
	
	end
	
	local goldAmountsTable = {};
	goldAmountsTable[0] = self:GetTeamFunds(self.humanTeam);
	goldAmountsTable[1] = self:GetTeamFunds(self.aiTeam);
	
	local team, task = self.tacticsHandler:UpdateTacticsHandler(goldAmountsTable);
	
	if task then
		local squad = self:SendBuyDoorDelivery(team, task);
		if squad then
			self.tacticsHandler:AddTaskedSquad(team, squad, task.Name);
		end
	end
	
	self.dockingHandler:UpdateDockingCraft();
	
	
	
	
	
	
	
	
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

	if self.doorMessageTimer then
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				FrameMan:SetScreenText("NOTE: You can press ALT + 1 to open or close all doors", player, 0, -1, false);
			end
		end
		if self.doorMessageTimer:IsPastSimTimeLimit() then
			self.doorMessageTimer = nil;
			for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
				if self:PlayerActive(player) and self:PlayerHuman(player) then
					FrameMan:ClearScreenText(player);
				end
			end
		end
	end

	if UInputMan:KeyPressed(Key.N) then
		-- Find and save all buy doors
	
		self.buyDoorTable = {};
	
		for mo in MovableMan.Particles do
			print(mo)
			if mo.PresetName == "Reinforcement Door" then
				table.insert(self.buyDoorTable, ToMOSRotating(mo));
				print("yes")
			end
		end
		
		self.attackerBuyDoorTable = {};
		self.defenderBuyDoorTable = {};
		MovableMan:OpenAllDoors(not self.allDoorsOpened, Activity.NOTEAM);
		self.allDoorsOpened = not self.allDoorsOpened;
	end
end
