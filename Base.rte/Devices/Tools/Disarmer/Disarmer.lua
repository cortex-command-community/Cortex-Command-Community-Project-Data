function Create(self)

	self.delayTimer = Timer();
	self.overallTimer = Timer();
	self.scanTimer = Timer();
	self.actionPhase = 0;
	self.blink = false;
	self.fireOn = false;

	self.disarmRange = FrameMan.PPM * 5;
	self.targetTable = {};
end

function Update(self)

	if self.Magazine then
		if self:IsActivated() then
			if self.fireOn == false then
				self.Magazine.RoundCount = 4000-self.overallTimer.ElapsedSimTimeMS;
				if self.delayTimer:IsPastSimMS(1000) then
					self.delayTimer:Reset();
					self.blink = false;
					local targetCount = 0;
					self.actionPhase = self.actionPhase + 1;
					for i = 1, #self.targetTable do
						if self.targetTable[i] and IsMOSRotating(self.targetTable[i]) and SceneMan:ShortestDistance(self.Pos, self.targetTable[i].Pos, SceneMan.SceneWrapsX).Magnitude < (self.disarmRange + 5) then
							targetCount = targetCount + 1;
							local detectPar = CreateMOPixel("Disarmer Detection Particle ".. (self.actionPhase == 4 and "Safe" or "Neutral"));
							detectPar.Pos = self.targetTable[i].Pos;
							MovableMan:AddParticle(detectPar);

							if self.actionPhase == 4 then
								local itemName = string.gsub(self.targetTable[i]:GetModuleAndPresetName(), " Active", "");
								local disarmedItem = CreateTDExplosive(itemName);
								disarmedItem.Pos = self.targetTable[i].Pos;
								disarmedItem.RotAngle = self.targetTable[i].RotAngle;
								MovableMan:AddParticle(disarmedItem);
								self.targetTable[i].Sharpness = 1;
							end
						else
							self.targetTable[i] = nil;
						end
					end
					if targetCount == 0 then
						self.actionPhase = 0;
						self.overallTimer:Reset();
						AudioMan:PlaySound("Base.rte/Sounds/GUIs/UserError.wav", SceneMan:TargetDistanceScalar(self.Pos), false, true, -1);
					elseif self.actionPhase == 4 then
						self.ReloadTime = 1000 + (1000 * targetCount);
						self:Reload();
					end
				end
				if self.actionPhase > 0 and self.actionPhase < 4 then
					if self.blink == false then
						self.blink = true;
						local soundfx = CreateAEmitter("Disarmer Sound Blip");
						soundfx.Pos = self.Pos;
						MovableMan:AddParticle(soundfx);
					end
				elseif self.actionPhase == 4 then
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

			if self.ID ~= self.RootID then
				if self.scanTimer:IsPastSimMS(500) then
					self.targetTable = {};
					self.scanTimer:Reset();
					local alarm = false;
					local alarmType = "Safe";
					if coalitionMineTable ~= nil then
						for i = 1, #coalitionMineTable do
							if MovableMan:IsParticle(coalitionMineTable[i]) and SceneMan:ShortestDistance(self.Pos,coalitionMineTable[i].Pos,SceneMan.SceneWrapsX).Magnitude < self.disarmRange then
								alarm = true;
								local isFriendly = coalitionMineTable[i].Team == self.Team;
								alarmType = isFriendly and alarmType or "Danger";
								local detectPar = CreateMOPixel("Disarmer Detection Particle ".. (isFriendly and "Safe" or "Danger"));
								detectPar.Pos = coalitionMineTable[i].Pos;
								MovableMan:AddParticle(detectPar);
								table.insert(self.targetTable, coalitionMineTable[i]);
							end
						end
					end
					if coalitionC4TableA ~= nil and coalitionC4TableB ~= nil then
						for i = 1, #coalitionC4TableA do
							if MovableMan:IsParticle(coalitionC4TableA[i]) and SceneMan:ShortestDistance(self.Pos,coalitionC4TableA[i].Pos,SceneMan.SceneWrapsX).Magnitude < self.disarmRange then
								alarm = true;
								local isFriendly = coalitionC4TableA[i].Team == self.Team;
								alarmType = isFriendly and alarmType or "Danger";
								local detectPar = CreateMOPixel("Disarmer Detection Particle ".. (isFriendly and "Safe" or "Danger"));
								detectPar.Pos = coalitionC4TableA[i].Pos;
								MovableMan:AddParticle(detectPar);
								table.insert(self.targetTable, coalitionC4TableA[i]);
							end
						end
					end
					if alarm and not self:IsActivated() then
						AudioMan:PlaySound("Base.rte/Devices/Tools/Disarmer/Sounds/".. alarmType .."Blip.wav", SceneMan:TargetDistanceScalar(self.Pos), false, true, -1);
					end
				end
			end
		end
	end
end