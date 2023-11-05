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
	
		local dockingSuccess = self.dockingHandler:SpawnDockingCraft(craft)
			
		return dockingSuccess;
		
	end
	
	return true;
	
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
	self.dockingHandler:Initialize();
	
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
	
		self:CreateDelivery(0, false, "Light", 1, true);
		
	end
	
	if debugTrigger then
	
		self:CreateDelivery(0, false, "Heavy", 2);
		print("tried dropship")
		
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
