package.loaded.Constants = nil; require("Constants");

function RefineryAssault:OnMessage(message, object)

	print("activitygotmessage")
	
	print(message)

	if message == "Captured_RefineryTestCapturable1" then
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

function RefineryAssault:SendDockDelivery(team, forceRocketusage, squadType)

	local craft = self.deliveryCreationHandler:CreateSquadWithCraft(team, forceRocketUsage);
	
	local dockingSuccess = self.dockingHandler:SpawnDockingCraft(craft)
			
	return dockingSuccess;
	
end

function RefineryAssault:SendBuyDoorDelivery(team, squadType, specificIndex)

	local order = self.deliveryCreationHandler:CreateSquad(team);
	
	if order then
		self.buyDoorHandler:SendCustomOrder(order);
		return true;
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
	
	self.dockingHandler = require("Activities/Utility/DockingHandler");
	self.dockingHandler:Initialize(self);
	
	self.buyDoorHandler = require("Activities/Utility/BuyDoorHandler");
	self.buyDoorHandler:Initialize(self);
	
	self.deliveryCreationHandler = require("Activities/Utility/DeliveryCreationHandler");
	self.deliveryCreationHandler:Initialize(self);
	
	print(self.buyDoorHandler.buyDoorTable)
	
	self.attackerBuyDoorTable = {};
	self.defenderBuyDoorTable = {};
	
	-- Capturable setup
	
	MovableMan:SendGlobalMessage("DeactivateCapturable_RefineryTestCapturable2");
	
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
