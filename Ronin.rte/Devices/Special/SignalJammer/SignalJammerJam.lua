function Create(self)

	self.lifeTimer = Timer();
	self.soundTimer = Timer();
	self.flashTimer = Timer();
	self.noiseDelay = 1000;
	self.flashDelay = 500;

	self.detectWidthAndHeight = 250;
	self.spaceSkip = 10;

	self.scanDots = self.detectWidthAndHeight/self.spaceSkip
	self.backAmount = self.detectWidthAndHeight*(-0.5);

end

function Update(self)

	if self.lifeTimer:IsPastSimMS(1000) and not self.lifeTimer:IsPastSimMS(12000) then
		if self.soundTimer:IsPastSimMS(self.noiseDelay) then
			self.soundTimer:Reset();
			self.noiseDelay = math.ceil(math.random()*1000);
			local soundfx = CreateAEmitter("Ronin Signal Jammer Sound "..math.floor(1+(math.random()*15)));
			soundfx.Pos = self.Pos;
			soundfx.LifeTime = self.noiseDelay;
			MovableMan:AddParticle(soundfx);
		end
		local canParaFlash = false;
		if self.flashTimer:IsPastSimMS(self.flashDelay) then
			self.flashTimer:Reset();
			local effectPar = CreateMOPixel("Ronin Signal Jammer Glow Particle");
			effectPar.Pos = self.Pos;
			MovableMan:AddParticle(effectPar);
			canParaFlash = true;
		end

		for x = 1, self.scanDots do
			for y = 1, self.scanDots do
				local checkPos = self.Pos + Vector(self.backAmount+(x*self.spaceSkip),self.backAmount+(y*self.spaceSkip));
				if SceneMan.SceneWrapsX == true then
					if checkPos.X > SceneMan.SceneWidth then
						checkPos = Vector(checkPos.X - SceneMan.SceneWidth,checkPos.Y);
					elseif checkPos.X < 0 then
						checkPos = Vector(SceneMan.SceneWidth + checkPos.X,checkPos.Y);
					end
				end
				local moCheck = SceneMan:GetMOIDPixel(checkPos.X,checkPos.Y);
				if moCheck ~= 255 then
					local actor = MovableMan:GetMOFromID( MovableMan:GetMOFromID(moCheck).RootID );
					if MovableMan:IsActor(actor) and actor.Team ~= self.Sharpness then
						if canParaFlash then
							ToActor(actor):FlashWhite(250);
						end
						ToActor(actor):GetController():SetState(Controller.BODY_JUMP,false);
						ToActor(actor):GetController():SetState(Controller.BODY_JUMPSTART,false);
						ToActor(actor):GetController():SetState(Controller.BODY_CROUCH,true);
						ToActor(actor):GetController():SetState(Controller.PIE_MENU_ACTIVE,false);
						ToActor(actor):GetController():SetState(Controller.WEAPON_FIRE,false);
						ToActor(actor):GetController():SetState(Controller.AIM_SHARP,false);
						ToActor(actor):GetController():SetState(Controller.MOVE_RIGHT,false);
						ToActor(actor):GetController():SetState(Controller.MOVE_LEFT,false);
					end
				end
			end
		end

	else
		if self.lifeTimer:IsPastSimMS(12000) then
			self.ToDelete = true;
		end
	end

end