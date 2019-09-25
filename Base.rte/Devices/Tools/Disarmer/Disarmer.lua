function Create(self)

	self.delayTimer = Timer();
	self.overallTimer = Timer();
	self.scanTimer = Timer();
	self.actionPhase = 0;
	self.blink = false;
	self.fireOn = false;

end

function Update(self)

	if self.ID ~= self.RootID then
		if self.scanTimer:IsPastSimMS(500) then
			self.scanTimer:Reset();
			if coalitionMineTable ~= nil then
				for i = 1, #coalitionMineTable do
					if MovableMan:IsParticle(coalitionMineTable[i]) and SceneMan:ShortestDistance(self.Pos,coalitionMineTable[i].Pos,SceneMan.SceneWrapsX).Magnitude < 100 then
						local detectPar = CreateMOPixel("Disarmer Detection Particle");
						detectPar.Pos = coalitionMineTable[i].Pos;
						MovableMan:AddParticle(detectPar);
					end
				end
			end

			if coalitionC4TableA ~= nil and coalitionC4TableB ~= nil then
				for i = 1, #coalitionC4TableA do
					if MovableMan:IsParticle(coalitionC4TableA[i]) and SceneMan:ShortestDistance(self.Pos,coalitionC4TableA[i].Pos,SceneMan.SceneWrapsX).Magnitude < 100 then
						local detectPar = CreateMOPixel("Disarmer Detection Particle");
						detectPar.Pos = coalitionC4TableA[i].Pos;
						MovableMan:AddParticle(detectPar);
					end
				end
			end
		end
	end

	if self:IsActivated() then

		if self.fireOn == false then
			self.Magazine.RoundCount = 4000-self.overallTimer.ElapsedSimTimeMS;
			if self.delayTimer:IsPastSimMS(1000) then
				self.delayTimer:Reset();
				self.actionPhase = self.actionPhase + 1;
				self.blink = false;
			end
			if self.actionPhase > 0 and self.actionPhase < 4 then
				if self.blink == false then
					self.blink = true;
					local soundfx = CreateAEmitter("Disarmer Sound Blip");
					soundfx.Pos = self.Pos;
					MovableMan:AddParticle(soundfx);
				end
			elseif self.actionPhase == 4 then
				if coalitionMineTable ~= nil then
					for i = 1, #coalitionMineTable do
						if MovableMan:IsParticle(coalitionMineTable[i]) and SceneMan:ShortestDistance(self.Pos,coalitionMineTable[i].Pos,SceneMan.SceneWrapsX).Magnitude < 100 then
							local storePos = coalitionMineTable[i].Pos;
							coalitionMineTable[i].Sharpness = 1;
						--	coalitionMineTable[i].ToDelete = true;
							local mine = CreateTDExplosive("Anti Personnel Mine");
							mine.Pos = storePos;
							MovableMan:AddParticle(mine);
						end
					end
				end

				if coalitionC4TableA ~= nil and coalitionC4TableB ~= nil then
					for i = 1, #coalitionC4TableA do
						if MovableMan:IsParticle(coalitionC4TableA[i]) and SceneMan:ShortestDistance(self.Pos,coalitionC4TableA[i].Pos,SceneMan.SceneWrapsX).Magnitude < 100 then
							local storePos = coalitionC4TableA[i].Pos;
							coalitionC4TableA[i].Sharpness = 1;
						--	coalitionC4TableA[i].ToDelete = true;
							local c4 = CreateTDExplosive("Remote Explosive");
							c4.Pos = storePos;
							MovableMan:AddParticle(c4);
						end
					end
				end

				local soundfx = CreateAEmitter("Disarmer Sound Disarm");
				soundfx.Pos = self.Pos;
				MovableMan:AddParticle(soundfx);
				self.fireOn = true;
			end
		end
	else
		self.delayTimer:Reset();
		self.overallTimer:Reset();
		self.Magazine.RoundCount = 4000;
		self.fireOn = false;
		self.actionPhase = 0;
	end

end