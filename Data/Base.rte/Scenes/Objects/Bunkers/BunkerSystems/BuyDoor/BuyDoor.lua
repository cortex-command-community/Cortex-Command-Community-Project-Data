function OnMessage(self, message, orderList)


	if not self.currentOrder then
		if message == "BuyDoor_CustomTableOrder" then
			self.Unusable = true;
			local finalOrder = BuyDoorSetupOrder(self, orderList, true);
			
			if finalOrder then
			
				self.orderTimer:Reset();
				self.currentOrder = finalOrder;
				self.orderDelivering = true;
				
			else
				print("Buy Door was given a custom table order, but it had no items!");
			end
		end
	end

end

function BuyDoorSetupOrder(self, orderList, isCustomOrder)

	local preActorItemList = {};
	local lastActor
	local finalOrder = {};

	if isCustomOrder then
		for i = 1, #orderList do
			local item = orderList[i];
			--print(item)
			table.insert(finalOrder, item);
			self.currentTeam = item.Team;
		end
	else

		for item in orderList do
			local class = item.ClassName;
			local typeCast = "To" .. class
			
			local clonedItem = _G[typeCast](item):Clone();
			if IsAHuman(item) then
				lastActor = clonedItem;
				if preActorItemList and #preActorItemList > 0 then
					for k, preActorItem in ipairs(preActorItemList) do
						lastActor:AddInventoryItem(preActorItem);
					end
					preActorItemList = nil;
				end
				table.insert(finalOrder, lastActor);
			elseif IsActor(item) then			
				item = clonedItem;
				table.insert(finalOrder, item);
			elseif IsHeldDevice(item) then
				item = clonedItem;
				if lastActor then
					ToAHuman(lastActor):AddInventoryItem(item);
				else
					table.insert(preActorItemList, item);
				end
			else
				print("Buy Door was given an order item with a class it couldn't handle: " .. item);
			end
				
			
		end
	end
	
	-- No AHumans could take the items we bought
	if preActorItemList and #preActorItemList > 0 then
		for k, preActorItem in ipairs(preActorItemList) do
			table.insert(finalOrder, preActorItem);
		end
		preActorItemList = nil;
	end
	
	if #finalOrder == 0 then
		self.Message = "Nothing to order!"
		self.messageTime = 4000;
		self.messageTimer:Reset();
		return nil;
	end
	
	local serializedFinalOrder = self.saveLoadHandler:SerializeTable()
	
	return finalOrder;

end

function Create(self)

	-- Frame 0 is used to display the control console that we will place
	
	self.saveLoadHandler = require("Activities/Utility/SaveLoadHandler");
	self.saveLoadHandler:Initialize(self);
	
	self.console = CreateMOSRotating("Buy Door Console", "Base.rte");
	self.console.Pos = self.Pos + Vector(0, -26);
	self.console.Team = self.Team;
	
	MovableMan:AddParticle(self.console);

	self.Frame = 1;

	self.isStayingOpen = false;
	self.isClosing = false;

	self.stayOpenTimer = Timer();
	self.stayOpenTimer:SetSimTimeLimitMS(self:NumberValueExists("StayOpenDuration") and self:GetNumberValue("StayOpenDuration") or 2000);

	self.openCloseSound = CreateSoundContainer("Background Door Open Close Sound", "Base.rte");
	self.openCloseSound.Pos = self.Pos;
	self.openCloseSound:Play();
	
	self.Activity = ToGameActivity(ActivityMan:GetActivity());
	
	self.cooldownTimer = Timer();
	self.cooldownTime = 3000;
	
	self.orderTimer = Timer();
	self.orderDelay = 5000;

	self.spawnTimer = Timer();
	self.spawnDelay = 500;
	
	self.Message = "";
	self.messageTimer = Timer();
	self.messageTime = 0;
	
	self.closeActorTable = {};
	self.actorUpdateTimer = Timer();
	self.actorUpdateDelay = 50;
	
	self.detectRange = 200;
	
	self.orderPieSlice = CreatePieSlice("Buy Door Order", "Base.rte");
end

function Update(self)

	if UInputMan:KeyPressed(Key.Y) then
		self:ReloadScripts();
	end

	if self.Frame == self.FrameCount - 1 and not self.isStayingOpen and not self.isClosing then
		self.isStayingOpen = true;
		self.stayOpenTimer:Reset();
		self.SpriteAnimMode = MOSprite.NOANIM;
	elseif self.isStayingOpen and self.currentOrder then
		-- Spawn the next object
		if self.spawnTimer:IsPastSimMS(self.spawnDelay) then
			local item = table.remove(self.currentOrder, 1);
			item.Pos = self.Pos;
			item.Team = self.currentTeam;
			if IsActor(item) then
				MovableMan:AddActor(item);
			else
				MovableMan:AddItem(item);
			end
			self.spawnTimer:Reset();
		end

		-- Wait until we spawn the next guy
		if #self.currentOrder == 0 then
			self.cooldownTimer:Reset();
			self.currentOrder = nil;
		end
	elseif self.isStayingOpen and not self.isClosing and self.stayOpenTimer:IsPastSimTimeLimit() then
		self.SpriteAnimMode = MOSprite.ALWAYSPINGPONG;
		self.isStayingOpen = false;
		self.isClosing = true;
		self.openCloseSound:Play();
	elseif self.Frame == 1 and self.isClosing then
		self.isClosing = false;
		self.SpriteAnimMode = MOSprite.NOANIM;
	end
	
	if self.cooldownTimer:IsPastSimMS(self.cooldownTime) then
		self.Unusable = false;
		if self.orderDelivering then
			self.Unusable = true;
			if self.orderTimer:IsPastSimMS(self.orderDelay) then
				self.SpriteAnimMode = MOSprite.ALWAYSPINGPONG;
				self.isClosing = false;
				self.orderDelivering = false;
				self.openCloseSound:Play();
				
				self.cooldownTimer:Reset();
			else
				PrimitiveMan:DrawTextPrimitive(self.console.Pos, tostring(math.ceil(self.orderDelay/1000 - self.orderTimer.ElapsedSimTimeS)), true, 1);
			end
		end
	elseif self.currentOrder == nil then
		self.Unusable = true;
		PrimitiveMan:DrawTextPrimitive(self.console.Pos + Vector(0, -10), "Reorganizing...", true, 1);
		PrimitiveMan:DrawTextPrimitive(self.console.Pos, tostring(math.ceil(self.cooldownTime/1000 - self.cooldownTimer.ElapsedSimTimeS)), true, 1);
		self.orderDelivering = false;
	end
	
	if self.actorUpdateTimer:IsPastSimMS(self.actorUpdateDelay) then
		for actor in MovableMan:GetMOsInRadius(self.Pos, self.detectRange) do
			if (not self.closeActorTable[actor.UniqueID]) and IsAHuman(actor) or IsACrab(actor) then
				actor = ToActor(actor);
				-- nearby enemies disable use
				if actor.Team ~= self.Team then
					self.Unusable = true;
				end
				actor.PieMenu:AddPieSliceIfPresetNameIsUnique(self.orderPieSlice:Clone(), self);
				self.closeActorTable[actor.UniqueID] = actor.UniqueID;
			end
		end
		
		for k, v in pairs(self.closeActorTable) do
			local actor = MovableMan:FindObjectByUniqueID(v);
			if actor and MovableMan:ValidMO(actor) then
				actor = ToActor(actor);
				local dist = SceneMan:ShortestDistance(self.Pos, actor.Pos, true).Magnitude;
				if dist > self.detectRange then
					actor.PieMenu:RemovePieSlicesByPresetName(self.orderPieSlice.PresetName);
					actor:RemoveNumberValue("BuyDoor_Order");
					self.closeActorTable[k] = nil;
				else
					if actor:NumberValueExists("BuyDoor_Order") then
						actor:RemoveNumberValue("BuyDoor_Order");
						if not self.currentOrder and not self.Unusable then
							-- Set up order here
							
							-- We have to rebuild this table each time, because teams can change
							
							-- self.playerTeamTable = {};
							-- for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
								-- if self.Activity:PlayerActive(player) and self.Activity:PlayerHuman(player) then
									-- self.playerTeamTable[self.Activity:GetTeamOfPlayer(player)] = player;
								-- end
							-- end
							
							local team = actor.Team;
							local player = actor:GetController().Player;		
							local buyGUI = self.Activity:GetBuyGUI(player);
							local orderCost = buyGUI:GetTotalCartCost();
							
							local funds = self.Activity:GetTeamFunds(team);
							
							--print("cost: "..orderCost)
							--print("funds: "..funds)
							
							if funds < orderCost then
								self.Message = "Insufficient funds!"
								self.messageTime = 4000;
								self.messageTimer:Reset();
								return;
							else
								self.Activity:SetTeamFunds(funds - orderCost, team);
							end
							
							local orderList = buyGUI:GetOrderList();
							
							local finalOrder = BuyDoorSetupOrder(self, orderList);
							
							if finalOrder then
							
								self.orderTimer:Reset();
								self.currentOrder = finalOrder;
								self.currentTeam = actor.Team;
								self.orderDelivering = true;
								
							end
						end
						
					end
				end
			else
				self.closeActorTable[k] = nil;
			end
		end
	end
	
	if not self.messageTimer:IsPastSimMS(self.messageTime) then
		PrimitiveMan:DrawTextPrimitive(self.console.Pos, self.Message, true, 1);
	end
	
	PrimitiveMan:DrawTextPrimitive(self.console.Pos + Vector(0, 20), "Team: " .. self.Team, true, 1);
	
	if self.Unusable then
		PrimitiveMan:DrawTextPrimitive(self.console.Pos + Vector(0, -20), "UNUSABLE", true, 1);
		self:SetNumberValue("BuyDoor_Unusable", 1);
	else
		self:RemoveNumberValue("BuyDoor_Unusable");
	end
	
end