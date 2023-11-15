function RefineryAssault:SendDockDelivery(team, task, forceRocketUsage, squadType)

	local craft, squad, goldCost = self.deliveryCreationHandler:CreateSquadWithCraft(team, forceRocketUsage);
		
	local success = self.dockingHandler:SpawnDockingCraft(craft)
			
	if success then
		self.tacticsHandler:ApplyTaskToSquadActors(squad, task);
		self:SetTeamFunds(self:GetTeamFunds(team) - goldCost, team);
		return squad
	end
	
	return false;
	
end

function RefineryAssault:SendBuyDoorDelivery(team, task, squadType, specificIndex)

	local order, goldCost = self.deliveryCreationHandler:CreateSquad(team);
	
	--print("tried order for team: " .. team);
	
	if order then
		if task then
			
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
					self:SetTeamFunds(self:GetTeamFunds(team) - goldCost, team);
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
	
	for k, actor in ipairs(AHumanTable) do
	
		if SceneMan.Scene:WithinArea("Mission Stage Area 1", actor.Pos) then
			table.insert(self.enemyActorTables.stage1, actor);
			table.insert(stage1Squad, actor);
		end
		
		if SceneMan.Scene:WithinArea("RefineryAssault_S1CounterAttActors", actor.Pos) then
			table.insert(self.enemyActorTables.stage1CounterAttActors, actor);
			actor.HFlipped = true; -- look the right way numbnuts
		end		
		
	end
	
	-- One big happy squad
	
	self.tacticsHandler:AddTaskedSquad(self.aiTeam, stage1Squad, "Sentry");
	
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
	
	local squad = self:SendDockDelivery(self.humanTeam, task);
	
	self.tacticsHandler:AddTaskedSquad(self.humanTeam, squad, task.Name);
	
	squad = self:SendDockDelivery(self.humanTeam, task);
	
	self.tacticsHandler:AddTaskedSquad(self.humanTeam, squad, task.Name);
	
	-- Set up player squad and dropship
	
	local dropShip = self.deliveryCreationHandler:CreateSquadWithCraft(self.humanTeam, false, 3);
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

end

function RefineryAssault:MonitorStage1()

	for k, actor in pairs(self.enemyActorTables.stage1) do
		if not actor or not MovableMan:ValidMO(actor) or actor:IsDead() then
			table.remove(self.enemyActorTables.stage1, k);
		end
	end
	
	if #self.enemyActorTables.stage1 == 0 then
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
		
		MovableMan:SendGlobalMessage("ActivateCapturable_RefineryTestCapturable1");
		MovableMan:SendGlobalMessage("ActivateCapturable_RefineryTestCapturable2");
		
		-- Task setup
		
		local taskPos = SceneMan.Scene:GetOptionalArea("CaptureArea_RefineryTestCapturable1").Center;
		
		self.tacticsHandler:AddTask("Attack Hack Console 1", self.humanTeam, taskPos, "Attack", 10);
		self.tacticsHandler:AddTask("Defend Hack Console 1", self.aiTeam, taskPos, "Defend", 10);
		
		taskPos = SceneMan.Scene:GetOptionalArea("CaptureArea_RefineryTestCapturable2").Center;
		
		self.tacticsHandler:AddTask("Attack Hack Console 2", self.humanTeam, taskPos, "Attack", 10);
		self.tacticsHandler:AddTask("Defend Hack Console 2", self.aiTeam, taskPos, "Defend", 10);
		
		self.tacticsHandler:RemoveTask("Sentry", self.aiTeam);
		self.tacticsHandler:RemoveTask("Search And Destroy", self.humanTeam);
		
		-- Send the counterattack by setting up squad
		
		-- First check they still exist, could be dealing with a wise guy
		
		for k, actor in pairs(self.enemyActorTables.stage1CounterAttActors) do
			if not actor or not MovableMan:ValidMO(actor) or actor:IsDead() then
				table.remove(stage1CounterAttActors, k);
			end
		end
		
		if #self.enemyActorTables.stage1CounterAttActors > 0 then
		
			local taskArea = SceneMan.Scene:GetOptionalArea("TacticsPatrolArea_MissionStage1");
			local task = self.tacticsHandler:AddTask("Counterattack", self.aiTeam, taskArea, "PatrolArea", 10);
			
			self.tacticsHandler:AddTaskedSquad(self.aiTeam, self.enemyActorTables.stage1CounterAttActors, task.Name);
			
		end
		
	end	
	
end

function RefineryAssault:MonitorStage2()
	
end