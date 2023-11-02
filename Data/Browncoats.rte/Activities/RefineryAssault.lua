package.loaded.Constants = nil; require("Constants");

-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Custom functions
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------
-- Create Infantry
-----------------------------------------------------------------------------------------

function RefineryAssault:CreateInfantry(team, infantryType)
	local tech = team == self.humanTeam and self.humanTeamTech or self.aiTeamTech;
	if infantryType == nil then
		local infantryTypes = {"Light", "Sniper", "Heavy", "CQB"};
		infantryType = infantryTypes[math.random(#infantryTypes)];
	end
	local allowAdvancedEquipment = team == self.humanTeam or self.bunkerRegions["Main Bunker Armory"].ownerTeam == team;
	if not allowAdvancedEquipment and self.difficultyRatio > 1 then
		allowAdvancedEquipment = math.random() < (1 - (4 / (self.difficultyRatio * 3)));
	end
	
	
	-- todo change debug behavior
	allowAdvancedEquipment = nil;

	local actorType = (infantryType == "Heavy" or infantryType == "CQB") and "Actors - Heavy" or "Actors - Light";
	if infantryType == "CQB" and math.random() < 0.25 then
		actorType = "Actors - Light";
	end
	local actor = RandomAHuman(actorType, tech);
	if actor.ModuleID ~= tech then
		actor = RandomAHuman("Actors", tech);
	end
	actor.Team = team;
	actor.PlayerControllable = true or self.humansAreControllingAlliedActors;

	if infantryType == "Light" then
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", tech));
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
		if allowAdvancedEquipment then
			if math.random() < 0.5 then
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
			elseif math.random() < 0.1 then
				actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", tech));
			elseif math.random() < 0.3 then
				actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
			end
		end
	elseif infantryType == "Sniper" then
		if allowAdvancedEquipment then
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Sniper", tech));
		else
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Light", tech));
		end
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
		if allowAdvancedEquipment then
			if math.random() < 0.3 then
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
			elseif math.random() < 0.5 then
				actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
			end
		end
	elseif infantryType == "Heavy" then
		if allowAdvancedEquipment then
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Heavy", tech));
		else
			actor:AddInventoryItem(RandomHDFirearm("Weapons - Primary", tech));
		end
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
		if allowAdvancedEquipment and math.random() < 0.3 then
			if math.random() < 0.5 then
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
				if math.random() < 0.1 then
					actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", tech));
				end
			else
				actor:AddInventoryItem(RandomHeldDevice("Shields", tech));
				if math.random() < 0.3 then
					actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
				end
			end
		end
	elseif infantryType == "CQB" then
		actor:AddInventoryItem(RandomHDFirearm("Weapons - CQB", tech));
		actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
		if allowAdvancedEquipment then
			if math.random() < 0.3 then
				actor:AddInventoryItem(RandomHeldDevice("Shields", tech));
				if math.random() < 0.3 then
					actor:AddInventoryItem(CreateHDFirearm("Medikit", "Base.rte"));
				end
			else
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", tech));
				if math.random() < 0.1 then
					actor:AddInventoryItem(RandomTDExplosive("Bombs - Grenades", tech));
				end
			end
		end
	end

	return actor;
end

-----------------------------------------------------------------------------------------
-- Create Crab
-----------------------------------------------------------------------------------------

function RefineryAssault:CreateCrab(team, createTurret)
	local tech = team == self.humanTeam and self.humanTeamTech or self.aiTeamTech;
	local crabToHumanSpawnRatio = self:GetCrabToHumanSpawnRatio(tech);
	local group = createTurret and "Actors - Turrets" or "Actors - Mecha";

	local actor;
	if crabToHumanSpawnRatio > 0 then
		actor = RandomACrab(group, tech);
	end
	if actor == nil or (createTurret and not actor:IsInGroup("Actors - Turrets")) then
		if createTurret then
			actor = CreateACrab("TradeStar Turret", "Base.rte");
		else
			return self:CreateInfantry(team, "Heavy");
		end
	end
	actor.Team = team;
	actor.PlayerControllable = createTurret or self.humansAreControllingAlliedActors;
	return actor;
end

-----------------------------------------------------------------------------------------
-- Create Delivery
-----------------------------------------------------------------------------------------

function RefineryAssault:CreateDelivery(team, useRocketsInsteadOfDropShips, infantryType, passengerCount, useBuyDoor)
	local tech = team == self.humanTeam and self.humanTeamTech or self.aiTeamTech;
	local crabToHumanSpawnRatio = self:GetCrabToHumanSpawnRatio(tech);
	crabToHumanSpawnRatio = 0;

	local craft = useRocketsInsteadOfDropShips and RandomACRocket("Craft", tech) or RandomACDropShip("Craft", tech);
	if not craft or craft.MaxInventoryMass <= 0 then
		craft = useRocketsInsteadOfDropShips and RandomACRocket("Craft", "Base.rte") or RandomACDropShip("Craft", "Base.rte");
	end
	craft.Team = team;
	--craft.PlayerControllable = false;
	--craft.HUDVisible = team ~= self.humanTeam;
	if team == self.humanTeam then
		craft:SetGoldValue(0);
	end

	if passengerCount == nil then
		passengerCount = math.random(math.ceil(craft.MaxPassengers * 0.5), craft.MaxPassengers);
	end
	passengerCount = math.min(passengerCount, craft.MaxPassengers);
	for i = 1, passengerCount do
		local actor;
		if infantryType then
			passenger = self:CreateInfantry(team, infantryType);
		elseif math.random() < crabToHumanSpawnRatio then
			passenger = self:CreateCrab(team);
		else
			passenger = self:CreateInfantry(team);
		end

		if passenger then
			passenger.Team = team;
			craft:AddInventoryItem(passenger);
			if craft.InventoryMass > craft.MaxInventoryMass then
				break;
			end
		end
	end
	
	if useBuyDoor then
	
		-- TODO non debug behavior
		
		-- i would call this hacky if it wasn't the tidiest most genius way to do it.
		-- we have already constructed our exact order and packaged it neatly in a craft,
		-- so instead of trying to construct some other fake list or fake AI buy menu cart,
		-- why not just... send the craft over?
		self.buyDoorSavedCraft = craft;
		self.buyDoorSavedCraft.Team = team;
		self.buyDoorTable[1]:SetNumberValue("BuyDoor_CraftInventoryOrderUniqueID", self.buyDoorSavedCraft.UniqueID);
	
	else
	
		local dockingSuccess = false;
		
		craft.AIMode = Actor.AIMODE_GOTO;
		--craft.DeliveryState = ACraft.STANDBY;
		
		if IsACDropShip(craft) then
		
			for i, dockTable in ipairs(self.activeDSDockTable) do
				if not dockTable.activeCraft and not self.activeRocketDockTable[i].activeCraft then
					
					craft.Pos = Vector(dockTable.dockPosition.X, SceneMan.Scene.Height - 100);
					
					self.lastAddedCraftUniqueID = craft.UniqueID;
					
					-- Mark this craft's dock number, not used except to see if there's any dock at all
					craft:SetNumberValue("Dock Number", i);
					
					craft:AddAISceneWaypoint(dockTable.dockPosition + Vector(0, 500));
					craft:AddAISceneWaypoint(dockTable.dockPosition);
					local direction = i % 2 == 0 and -1 or 1;	
					craft:AddAISceneWaypoint(dockTable.dockPosition + Vector(150 * direction, 0))
					
					dockTable.activeCraft = craft.UniqueID;
					dockTable.dockingStage = 1;
					
					dockingSuccess = true;
					
					break;
				end
			end
			
		else
		
			for i, dockTable in ipairs(self.activeRocketDockTable) do
				if not dockTable.activeCraft and not self.activeDSDockTable[i].activeCraft then
					
					craft.Pos = Vector(dockTable.dockPosition.X, SceneMan.Scene.Height - 100);
					craft.Vel = Vector(0, -30);
					
					self.lastAddedCraftUniqueID = craft.UniqueID;
					
					-- Mark this craft's dock number, not used except to see if there's any dock at all
					craft:SetNumberValue("Dock Number", i);
					
					craft:AddAISceneWaypoint(dockTable.dockPosition);
					
					dockTable.activeCraft = craft.UniqueID;
					dockTable.dockingStage = 1;
					
					dockingSuccess = true;
					
					break;
				end
			end
		end
	end
		
	if dockingSuccess == true then
		MovableMan:AddActor(craft);
		craft:UpdateMovePath();
	else
		return false;
	end
	
	return craft;
end

-----------------------------------------------------------------------------------------
-- Update Docking Craft
-----------------------------------------------------------------------------------------

function RefineryAssault:UpdateDockingCraft()

	-- Dropship docking explanation:
	
	-- Stage 1 is below the dock, to line up any stray dropships such as detected player dropships awaiting AI delivery
	-- This is the most prone stage to collisions, but we just have to live with them in lieu of real pathfinding
	-- Stage 2 is in the dock, still in open air
	-- Stage 3 is in the dock's dropoff zone
	-- Stage 4 is back in the open air area of the dock
	-- Stage 5 is all the way outside the map, straight down


	-- Docking system initial tests
	
	self.lastAddedCraftUniqueID = nil;
	
	-- Monitor for unknown crafts that might want to deliver stuff
	
	for actor in MovableMan.AddedActors do
		if actor.UniqueID ~= self.lastAddedCraftUniqueID then
			if IsACDropShip(actor) then
				local craft = ToACDropShip(actor);
				
				-- See if we have any docks available right now
				
				local noDockFound = true;
			
				for i, dockTable in ipairs(self.activeDSDockTable) do
					if not dockTable.activeCraft and not self.activeRocketDockTable[i].activeCraft then
						
						craft.AIMode = Actor.AIMODE_GOTO;
						--craft.Team = 0
						--craft.Pos = Vector(dockTable.dockPosition.X, SceneMan.Scene.Height - 100);
						--craft.DeliveryState = ACraft.STANDBY;
						
						-- Mark this craft's dock number, not used except to see if there's any dock at all
						craft:SetNumberValue("Dock Number", i);
						
						craft:AddAISceneWaypoint(dockTable.dockPosition + Vector(0, 500));
						craft:AddAISceneWaypoint(dockTable.dockPosition);
						local direction = i % 2 == 0 and -1 or 1;	
						craft:AddAISceneWaypoint(dockTable.dockPosition + Vector(150 * direction, 0))
						
						dockTable.activeCraft = craft.UniqueID;
						dockTable.dockingStage = 1;
						
						noDockFound = false;
						
						break;
					end
				end
				
				if noDockFound then
				
					-- Put the craft in the wait table
					
					table.insert(self.playerDSDockWaitList, craft.UniqueID);
					
				end		
				
			end
		end
	end
	
	if self.playerDSDockCheckTimer:IsPastSimMS(self.playerDSDockCheckDelay) then
		
		self.playerDSDockCheckTimer:Reset();
		
		-- Iterate back to front so we can remove things safely
		
		for i=#self.playerDSDockWaitList, 1, -1 do
		
			local craft = MovableMan:FindObjectByUniqueID(self.playerDSDockWaitList[i]);
			
			if not craft then
				table.remove(self.playerDSDockWaitList, i)
				
				-- this break will make everyone wait for 4 seconds again, but that's fine
				break;
			end
			
			craft = ToACDropShip(craft);
		
			-- See if we have any docks available
	
			for i2, dockTable in ipairs(self.activeDSDockTable) do
				if not dockTable.activeCraft and not self.activeRocketDockTable[i2].activeCraft then
					
					craft.AIMode = Actor.AIMODE_GOTO;
					--craft.Team = 0
					--craft.Pos = Vector(dockTable.dockPosition.X, SceneMan.Scene.Height - 100);
					--craft.DeliveryState = ACraft.STANDBY;
					
					-- Mark this craft's dock number, not used except to see if there's any dock at all
					craft:SetNumberValue("Dock Number", i2);
					
					craft:AddAISceneWaypoint(dockTable.dockPosition + Vector(0, 500));
					
					dockTable.activeCraft = craft.UniqueID;
					dockTable.dockingStage = 1;
					
					table.remove(self.playerDSDockWaitList, i)
					
					break;
				end
			end
		end
	end
				
	-- Monitor dropship activity
	
	for i, dockTable in ipairs(self.activeDSDockTable) do
		if dockTable.activeCraft then
			
			local direction = i % 2 == 0 and -1 or 1;	
			local craft = MovableMan:FindObjectByUniqueID(dockTable.activeCraft);
			
			if craft and MovableMan:ValidMO(craft) then
			
				craft = ToACraft(craft)
				
				--craft.DeliveryState = ACraft.STANDBY;
				
				if dockTable.dockingStage == 4 then
				
					--print(SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition, true))
				
					local distFromDockArea = SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition, true).Magnitude
					--print(distFromDockArea)
					if distFromDockArea < 20 then
						dockTable.dockingStage = 5;
						craft:CloseHatch();
						
					end	
					
				elseif dockTable.dockingStage == 3 then
				
					--print(SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition + Vector(200 * direction, 0), true))
				
					local distFromDockArea = SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition + Vector(150 * direction, 0), true).Magnitude
					--print(distFromDockArea)
					if distFromDockArea < 20 then
						craft:OpenHatch();
						craft.AIMode = Actor.AIMODE_NONE;
						if craft:IsInventoryEmpty() then
							craft:ClearAIWaypoints();
							craft:AddAISceneWaypoint(dockTable.dockPosition);
							craft:AddAISceneWaypoint(dockTable.dockPosition + Vector(0, SceneMan.Scene.Height + 1000));
							craft.AIMode = Actor.AIMODE_GOTO;
							dockTable.dockingStage = 5;
							craft:CloseHatch();
						end
					end	
					
				elseif dockTable.dockingStage == 2 then
				
					--print(SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition, true))
				
					local distFromDockArea = SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition, true).Magnitude
					--print(distFromDockArea)
					if distFromDockArea < 20 then
						dockTable.dockingStage = 3;
					end			
					
				elseif dockTable.dockingStage == 1 then
				
					--print(SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition, true))
				
					local distFromDockArea = SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition  + Vector(0, 500), true).Magnitude
					--print(distFromDockArea)
					if distFromDockArea < 20 then
						dockTable.dockingStage = 2;
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
				
				--craft.DeliveryState = ACraft.STANDBY;
				craft.AIMode = Actor.AIMODE_GOTO;
				
				if dockTable.dockingStage ~= 3 then
					-- help these fucking things along, i'm sorry they're too stupid
					local distVectorFromDockArea = SceneMan:ShortestDistance(craft.Pos, dockTable.dockPosition, true)
					if math.abs(distVectorFromDockArea.X) > 1 then -- we're helplessly off-course, abort
						print(distVectorFromDockArea.X)
						print("aborted")
						print(craft.Pos);
						print(dockTable.dockPosition)
						dockTable.dockingStage = 3;
						craft:ClearAIWaypoints();
						craft:AddAISceneWaypoint(Vector(craft.Pos.X, SceneMan.Scene.Height + 500));
						craft:CloseHatch();		
					elseif distVectorFromDockArea.X > 0.5 then
						craft.Vel.X = math.max(craft.Vel.X - 0.02 * TimerMan.DeltaTimeSecs, 0)
					elseif distVectorFromDockArea.X < -0.5 then
						craft.Vel.X = math.min(craft.Vel.X + 0.02 * TimerMan.DeltaTimeSecs, 0)
					end
					
					craft.AngularVel = craft.AngularVel/10;
						
					
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
					craft:ClearAIWaypoints();
					craft:AddAISceneWaypoint(Vector(craft.Pos.X, SceneMan.Scene.Height + 500));
					craft:OpenHatch();
				end

			else
				dockTable.activeCraft = nil;
				dockTable.dockingStage = nil;
			end

		end
	end
	
	if UInputMan:KeyPressed(Key.SPACE) then
		self.ActivityState = Activity.EDITING;
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
	
	-- Find and save all buy doors
	
	self.buyDoorTable = {};
	
	for mo in MovableMan.AddedParticles do
		print(mo)
		if mo.PresetName == "Reinforcement Door" then
			table.insert(self.buyDoorTable, ToMOSRotating(mo));
			print("yes")
		end
	end
	
	self.attackerBuyDoorTable = {};
	self.defenderBuyDoorTable = {};
	
	
	-- Set up player dropship dock wait list
	
	self.playerDSDockWaitList = {};
	
	self.playerDSDockCheckTimer = Timer();
	self.playerDSDockCheckDelay = 4000;
	
	
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

	self:UpdateDockingCraft();
	
	local debugDoorTrigger = UInputMan:KeyPressed(Key.J)	
	
	local debugTrigger = UInputMan:KeyPressed(Key.I)
	
	local debugRocketTrigger = UInputMan:KeyPressed(Key.U)
	
	if debugDoorTrigger then
	
		self:CreateDelivery(0, false, "Light", 1, true);
		
	end
	
	if debugTrigger then
	
		self:CreateDelivery(0, false, "Heavy", 2);
		
	end
	
	if debugRocketTrigger then
	
		self:CreateDelivery(0, true, "Light", 2);
		
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
