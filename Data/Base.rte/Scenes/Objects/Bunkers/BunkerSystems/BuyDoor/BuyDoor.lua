function Create(self)

	-- Frame 0 is used to display the control console that we will place
	
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
	
	
	self.closeActorTable = {};
	self.actorUpdateTimer = Timer();
	self.actorUpdateDelay = 50;
	
	self.detectRange = 100;
	
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
	elseif self.isStayingOpen and not self.isClosing and self.stayOpenTimer:IsPastSimTimeLimit() then
		self.SpriteAnimMode = MOSprite.ALWAYSPINGPONG;
		self.isStayingOpen = false;
		self.isClosing = true;
		self.openCloseSound:Play();
	elseif self.Frame == 1 and self.isClosing then
		self.isClosing = false;
		self.SpriteAnimMode = MOSprite.NOANIM;
	end
	
	if self.actorUpdateTimer:IsPastSimMS(self.actorUpdateDelay) then
		for actor in MovableMan:GetMOsInRadius(self.Pos, self.detectRange) do
			if (not self.closeActorTable[actor.UniqueID]) and IsAHuman(actor) or IsACrab(actor) then
				actor = ToActor(actor);
				actor.PieMenu:AddPieSliceIfPresetNameIsUnique(self.orderPieSlice:Clone(), self);
				table.insert(self.closeActorTable, actor.UniqueID);
			end
		end
		
		for k, v in ipairs(self.closeActorTable) do
			local actor = ToActor(MovableMan:FindObjectByUniqueID(v));
			if actor and MovableMan:ValidMO(actor) then
				local dist = SceneMan:ShortestDistance(self.Pos, actor.Pos, true).Magnitude;
				if dist > self.detectRange then
					actor.PieMenu:RemovePieSlicesByPresetName(self.orderPieSlice.PresetName);
					actor:RemoveNumberValue("BuyDoor_Order");
					self.closeActorTable[k] = nil;
				else
					if actor:NumberValueExists("BuyDoor_Order") then
						actor:RemoveNumberValue("BuyDoor_Order");
						self.order = true;
					end
				end
			else
				self.closeActorTable[k] = nil;
			end
		end
	end
	
	if self.order then
	
	end
	
end