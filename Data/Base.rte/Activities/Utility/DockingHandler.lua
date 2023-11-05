local DockingHandler = {};

function DockingHandler:Create()
	local Members = {};

	setmetatable(Members, self);
	self.__index = self;

	return Members;
end

function DockingHandler:Initialize()
	
	print("dockhandler inited")
	
	-- Set up player dropship dock wait list
	
	self.playerDSDockWaitList = {};
	
	self.playerDSDockCheckTimer = Timer();
	self.playerDSDockCheckDelay = 4000;
	
	
	-- Set up docks
	-- TODO make better with iteration

	self.activeDSDockTable = {};
	
	self.activeDSDockTable[1] = {["dockPosition"] = SceneMan.Scene:GetArea("Dropship UnderDock 1").Center + Vector(0, 0),
	["activeCraft"] =  nil,
	["dockingStage"] =  nil};
	
	self.activeDSDockTable[2] = {["dockPosition"] = SceneMan.Scene:GetArea("Dropship UnderDock 2").Center + Vector(0, 0),
	["activeCraft"] =  nil, 
	["dockingStage"] =  nil};
	
	
	self.activeRocketDockTable = {};
	
	self.activeRocketDockTable[1] = {["dockPosition"] = SceneMan.Scene:GetArea("Rocket UnderDock 1").Center + Vector(0, 0),
	["activeCraft"] =  nil, 
	["dockingStage"] =  nil};
	
	self.activeRocketDockTable[2] = {["dockPosition"] = SceneMan.Scene:GetArea("Rocket UnderDock 2").Center + Vector(0, 0),
	["activeCraft"] =  nil, 
	["dockingStage"] =  nil};
	
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

function DockingHandler:SpawnDockingCraft(craft, specificDock)
	
	local dockingSuccess = false;
	
	craft.AIMode = Actor.AIMODE_GOTO;
	--craft.DeliveryState = ACraft.STANDBY;
	
	if IsACDropShip(craft) then
	
		local dockToDockAt = nil;
		local dockTable;
		if specificDock == nil then
			for i, dockInfoTable in ipairs(self.activeDSDockTable) do
				if not dockInfoTable.activeCraft and not self.activeRocketDockTable[i].activeCraft then
					dockToDockAt = i;
					dockTable = dockInfoTable;
					break;
				end
			end
		else
			dockToDockAt = specificDock;
		end
	
		if dockToDockAt then
			craft.Pos = Vector(dockTable.dockPosition.X, SceneMan.Scene.Height - 100);
			
			self.lastAddedCraftUniqueID = craft.UniqueID;
			
			-- Mark this craft's dock number, not used except to see if there's any dock at all
			craft:SetNumberValue("Dock Number", dockToDockAt);
			
			craft:AddAISceneWaypoint(dockTable.dockPosition + Vector(0, 500));
			craft:AddAISceneWaypoint(dockTable.dockPosition);
			local direction = dockToDockAt % 2 == 0 and -1 or 1;	
			craft:AddAISceneWaypoint(dockTable.dockPosition + Vector(150 * direction, 0))
			
			dockTable.activeCraft = craft.UniqueID;
			dockTable.dockingStage = 1;
			
			dockingSuccess = true;
		end
		
	else
	
		local dockToDockAt = nil;
		local dockTable;
		if specificDock == nil then
			for i, dockInfoTable in ipairs(self.activeRocketDockTable) do
				if not dockInfoTable.activeCraft and not self.activeDSDockTable[i].activeCraft then
					dockToDockAt = i;
					dockTable = dockInfoTable;
					break;
				end
			end
		else
			dockToDockAt = specificDock;
		end
	
		if dockToDockAt then
				
			craft.Pos = Vector(dockTable.dockPosition.X, SceneMan.Scene.Height - 100);
			craft.Vel = Vector(0, -30);
			
			self.lastAddedCraftUniqueID = craft.UniqueID;
			
			-- Mark this craft's dock number, not used except to see if there's any dock at all
			craft:SetNumberValue("Dock Number", dockToDockAt);
			
			craft:AddAISceneWaypoint(dockTable.dockPosition);
			
			dockTable.activeCraft = craft.UniqueID;
			dockTable.dockingStage = 1;
			
			dockingSuccess = true;
			
		end
	end
		
	if dockingSuccess == true then
		MovableMan:AddActor(craft);
		craft:UpdateMovePath();
	else
		print("failed")
		return false;
	end
	
	return true;
end

function DockingHandler:UpdateDockingCraft()

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
	
end

return DockingHandler:Create();