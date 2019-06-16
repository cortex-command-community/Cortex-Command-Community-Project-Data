function Create(self)

	self.delayTimer = Timer();
	self.overallTimer = Timer();
	self.actionPhase = 0;
	self.fireOn = false;
	self.alliedTeam = -1;

end

function Update(self)

	if self.ID ~= self.RootID then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if MovableMan:IsActor(actor) then
			self.alliedTeam = ToActor(actor).Team;
		end
	end

	if self:IsActivated() then

		if self.fireOn == false then
			self.Magazine.RoundCount = 500-self.overallTimer.ElapsedSimTimeMS;
			if self.delayTimer:IsPastSimMS(500) then
				self.delayTimer:Reset();
				self.actionPhase = self.actionPhase + 1;
				self.blink = false;
			end
			if self.actionPhase >= 1 then

				if coalitionC4TableA ~= nil and coalitionC4TableB ~= nil then
					for i = 1, #coalitionC4TableA do
						if MovableMan:IsParticle(coalitionC4TableA[i]) and coalitionC4TableB[i] == self.alliedTeam then
							coalitionC4TableA[i].Sharpness = 2;
						end
					end
				end

				local soundfx = CreateAEmitter("Mine Sound Detonate");
				soundfx.Pos = self.Pos;
				MovableMan:AddParticle(soundfx);
				self.fireOn = true;
			end
		end
	else
		self.delayTimer:Reset();
		self.overallTimer:Reset();
		self.Magazine.RoundCount = 500;
		self.fireOn = false;
		self.actionPhase = 0;
	end

end