package.loaded.Constants = nil; require("Constants");

-----------------------------------------------------------------------------------------
-- Start Activity
-----------------------------------------------------------------------------------------

function RefineryAssault:StartActivity()
	print("START! -- Test:StartActivity()!");

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
	
	
	
	
	
	-- Set up docks
	
	self.activeDSDockTable = {};
	
	self.activeDSDockTable[1] = {["dockPosition"] = SceneMan.Scene:GetArea("Dropship dock 1").Center + Vector(0, 0),["activeCraft"] =  nil,["dockingStage"] =  nil};
	self.activeDSDockTable[2] = {["dockPosition"] = SceneMan.Scene:GetArea("Dropship dock 2").Center + Vector(0, 0),["activeCraft"] =  nil,["dockingStage"] =  nil};
	
	
	self.activeRocketDockTable = {};
	
	self.activeRocketDockTable[1] = {["dockPosition"] = SceneMan.Scene:GetArea("Rocket dock 1").Center + Vector(0, 0),["activeCraft"] =  nil,["dockingStage"] =  nil};
	self.activeRocketDockTable[2] = {["dockPosition"] = SceneMan.Scene:GetArea("Rocket dock 2").Center + Vector(0, 0),["activeCraft"] =  nil,["dockingStage"] =  nil};
	
	-- Place rocket capturer docks
	
	for i, dockTable in ipairs(self.activeRocketDockTable) do
		local dockObject = CreateMOSRotating("Rocket Dock 2", "Base.rte");
		dockObject.Pos = dockTable.dockPosition
		dockObject.MissionCritical = true;
		dockObject.GibImpulseLimit = 9999999999;
		dockObject.GibWoundLimit = 9999999999;
		dockObject.PinStrength = 9999999999;
		MovableMan:AddParticle(dockObject);
	end
	
	
end

function RefineryAssault:OnSave()
	-- Don't have to do anything, just need this to allow saving/loading.
end

-----------------------------------------------------------------------------------------
-- Pause Activity
-----------------------------------------------------------------------------------------

function RefineryAssault:PauseActivity(pause)
	print("PAUSE! -- Test:PauseActivity()!");
end

-----------------------------------------------------------------------------------------
-- End Activity
-----------------------------------------------------------------------------------------

function RefineryAssault:EndActivity()
	print("END! -- Test:EndActivity()!");
end

-----------------------------------------------------------------------------------------
-- Update Activity
-----------------------------------------------------------------------------------------

function RefineryAssault:UpdateActivity()


	-- Docking system initial tests
	
	local debugTrigger = UInputMan:KeyPressed(Key.I)
	
	local debugRocketTrigger = UInputMan:KeyPressed(Key.U)
	
	if debugTrigger then
	
		for i, dockTable in ipairs(self.activeDSDockTable) do
			if not dockTable.activeCraft and not self.activeRocketDockTable[i].activeCraft then
				
				local craft = RandomACDropShip("Craft", "Base.rte");
				craft.AIMode = Actor.AIMODE_NONE;
				craft.Team = 0
				craft.Pos = Vector(dockTable.dockPosition.X, SceneMan.Scene.Height - 100);
				craft.DeliveryState = ACraft.STANDBY;
				
				local passenger = CreateAHuman("Green Dummy");
				passenger.Team = 0;
				
				craft:AddInventoryItem(passenger);
				
				local passenger2 = CreateAHuman("Green Dummy");
				passenger2.Team = 0;
				
				craft:AddInventoryItem(passenger2);
				
				MovableMan:AddActor(craft);
				
				craft:AddAISceneWaypoint(dockTable.dockPosition);
				
				dockTable.activeCraft = craft.UniqueID;
				dockTable.dockingStage = 1;
			end
		end
	end
	
	if debugRocketTrigger then
	
		for i, dockTable in ipairs(self.activeRocketDockTable) do
			if not dockTable.activeCraft and not self.activeDSDockTable[i].activeCraft then
				
				local craft = RandomACRocket("Craft", "Base.rte");
				craft.AIMode = Actor.AIMODE_NONE;
				craft.Team = 0
				craft.Pos = Vector(dockTable.dockPosition.X, SceneMan.Scene.Height - 100);
				craft.Vel = Vector(0, -30);
				craft.DeliveryState = ACraft.STANDBY;
				
				local passenger = CreateAHuman("Green Dummy");
				passenger.Team = 0;
				
				craft:AddInventoryItem(passenger);
				
				local passenger2 = CreateAHuman("Green Dummy");
				passenger2.Team = 0;
				
				craft:AddInventoryItem(passenger2);
				
				MovableMan:AddActor(craft);
				
				craft:AddAISceneWaypoint(dockTable.dockPosition);
				
				dockTable.activeCraft = craft.UniqueID;
				dockTable.dockingStage = 1;
			end
		end
	end
	
	-- Monitor dropship activity
	
	for i, dockTable in ipairs(self.activeDSDockTable) do
		if dockTable.activeCraft then
			
			local direction = i % 2 == 0 and 1 or -1;	
			local craft = MovableMan:FindObjectByUniqueID(dockTable.activeCraft);
			
			if craft and MovableMan:ValidMO(craft) then
			
				craft = ToACraft(craft)
				
				craft.DeliveryState = ACraft.STANDBY;
				craft.AIMode = Actor.AIMODE_NONE;
				
				if dockTable.dockingStage == 3 then
				
					--print(SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition, true))
				
					local distFromDockArea = SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition, true).Magnitude
					--print(distFromDockArea)
					if distFromDockArea < 20 then
						dockTable.dockingStage = 3;
						craft:ClearAIWaypoints();
						craft:AddAISceneWaypoint(dockTable.dockPosition + Vector(0, SceneMan.Scene.Height + 500));
						craft:CloseHatch();
						
					end	
					
				elseif dockTable.dockingStage == 2 then
				
					--print(SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition + Vector(200 * direction, 0), true))
				
					local distFromDockArea = SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition + Vector(150 * direction, 0), true).Magnitude
					--print(distFromDockArea)
					if distFromDockArea < 20 then
						craft:OpenHatch();
						if craft:IsInventoryEmpty() then
							dockTable.dockingStage = 3;
							craft:ClearAIWaypoints();
							craft:AddAISceneWaypoint(dockTable.dockPosition);
							craft:CloseHatch();
						end
					end	
					
				elseif dockTable.dockingStage == 1 then
				
					--print(SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition, true))
				
					local distFromDockArea = SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition, true).Magnitude
					--print(distFromDockArea)
					if distFromDockArea < 20 then
						dockTable.dockingStage = 2;
						craft:ClearAIWaypoints();
						craft:AddAISceneWaypoint(dockTable.dockPosition + Vector(150 * direction, 0));
					end
					
				end
				
						
			else
				dockTable.activeCraft = nil;
				dockTable.dockingStage = nil;
			end

		end
	end
	
	-- Monitor rocket activity
	
	for i, dockTable in ipairs(self.activeRocketDockTable) do
		if dockTable.activeCraft then

			local craft = MovableMan:FindObjectByUniqueID(dockTable.activeCraft);

			if craft and MovableMan:ValidMO(craft) then
			
				craft = ToACraft(craft)
				
				craft.DeliveryState = ACraft.STANDBY;
				craft.AIMode = Actor.AIMODE_NONE;
				
				-- help these fucking things along, i'm sorry they're too stupid
				local distVectorFromDockArea = SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition, true)
				if distVectorFromDockArea.X > 1 then
					craft.Vel.X = math.max(craft.Vel.X - 1 * TimerMan.DeltaTimeSecs, 0)
				elseif distVectorFromDockArea.X < -1 then
					craft.Vel.X = math.min(craft.Vel.X + 1 * TimerMan.DeltaTimeSecs, 0)
				end
				
				if dockTable.dockingStage == 2 then
					craft:OpenHatch();
					if craft:IsInventoryEmpty() then
						dockTable.dockingStage = 3;
						craft:ClearAIWaypoints();
						craft:AddAISceneWaypoint(Vector(dockTable.dockPosition.X, SceneMan.Scene.Height + 500));
						craft:CloseHatch();
					end
				elseif dockTable.dockingStage == 1 and craft:NumberValueExists("Docked") then
					dockTable.dockingStage = 2;
					craft:OpenHatch();
				end

			else
				dockTable.activeCraft = nil;
				dockTable.dockingStage = nil;
			end

		end
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

	if UInputMan.FlagAltState and UInputMan:KeyPressed(Key.K_1) then
		MovableMan:OpenAllDoors(not self.allDoorsOpened, Activity.NOTEAM);
		self.allDoorsOpened = not self.allDoorsOpened;
	end
end
