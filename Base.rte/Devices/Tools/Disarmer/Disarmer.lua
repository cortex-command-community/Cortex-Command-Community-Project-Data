function Create(self)
	self.delayTimer = Timer();
	self.overallTimer = Timer();
	self.scanTimer = Timer();
	self.actionPhase = 0;
	self.blink = false;

	self.disarmRange = GetPPM() * 4;
	self.MuzzleOffset = Vector(self.disarmRange * 0.5, 0);
	self.targetTable = {};

	self.errorSound = CreateSoundContainer("Error", "Base.rte");
	self.safeSound = CreateSoundContainer("Disarmer Blip Safe", "Base.rte");
	self.dangerSound = CreateSoundContainer("Disarmer Blip Danger", "Base.rte");
end

function Update(self)
	if self.Magazine then
		if self:IsActivated() then
			self.Magazine.RoundCount = math.ceil(4000 - self.overallTimer.ElapsedSimTimeMS);
			if self.delayTimer:IsPastSimMS(1000) then
				self.delayTimer:Reset();
				self.blink = false;
				local targetCount = 0;
				self.actionPhase = self.actionPhase + 1;
				for i = 1, #self.targetTable do
					if self.targetTable[i] and IsMOSRotating(self.targetTable[i]) and SceneMan:ShortestDistance(self.MuzzlePos, self.targetTable[i].Pos, SceneMan.SceneWrapsX):MagnitudeIsLessThan(self.disarmRange + 5) then
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
					self.errorSound:Play(self.Pos);
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
			end
		else
			self.delayTimer:Reset();
			self.overallTimer:Reset();
			self.Magazine.RoundCount = 4000;
			self.actionPhase = 0;

			if self:GetParent() and self.scanTimer:IsPastSimMS(500) then
				self.targetTable = {};
				self.scanTimer:Reset();
				local alarm = false;
				local alarmSound = self.safeSound;
				local disarmTables = {AntiPersonnelMineTable, RemoteExplosiveTableA, TimedExplosiveTable};
				for _, bombTable in pairs(disarmTables) do
					if bombTable then
						for _, explosive in pairs(bombTable) do
							if MovableMan:IsParticle(explosive) and SceneMan:ShortestDistance(self.MuzzlePos, explosive.Pos, SceneMan.SceneWrapsX):MagnitudeIsLessThan(self.disarmRange) then
								alarm = true;
								local isFriendly = explosive.Team == self.Team;
								alarmSound = isFriendly and alarmSound or self.dangerSound;
								local detectPar = CreateMOPixel("Disarmer Detection Particle ".. (isFriendly and "Safe" or "Danger"));
								detectPar.Pos = explosive.Pos;
								MovableMan:AddParticle(detectPar);
								table.insert(self.targetTable, explosive);
							end
						end
					end
				end
				if alarm and not self:IsActivated() then
					alarmSound:Play(self.Pos);
				end
			end
		end
	end
end