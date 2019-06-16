function Create(self)

	self.fireTimer = Timer();
	self.chargeTimer = Timer();
	self.chargeCounter = 1;

	self.maxCharge = 10;
	self.chargesPerSecond = 3;

end

function Update(self)

	if self:IsActivated() and self.fireTimer:IsPastSimMS(500) then
		self.fireTimer:Reset();

		if self.HFlipped == false then
			self.reverseNum = 1;
		else
			self.reverseNum = -1;
		end

		local actor = MovableMan:GetMOFromID(self.RootID);

		for i = 1, self.chargeCounter do
			local damagePar = CreateMOPixel("Laser Cannon Particle");
			damagePar.Pos = self.MuzzlePos + Vector(((i-1)*-2)*self.reverseNum,0):RadRotate(self.RotAngle);
			damagePar.Vel = Vector(200*self.reverseNum,0):RadRotate(self.RotAngle);
			damagePar:SetWhichMOToNotHit(MovableMan:GetMOFromID(self.RootID),-1);

			if MovableMan:IsActor(actor) then
				damagePar.Team = ToActor(actor).Team;
				damagePar.IgnoresTeamHits = true;
			end

			MovableMan:AddParticle(damagePar);
		end

		local soundfx = CreateAEmitter("Dummy Laser Musket Sound Fire");
		soundfx.Pos = self.MuzzlePos;
		MovableMan:AddParticle(soundfx);

		self.chargeCounter = 1;

	else
		if self.chargeCounter <= self.maxCharge then
			self.chargeCounter = math.min(self.chargeCounter + ((self.chargeTimer.ElapsedSimTimeMS/1000)*self.chargesPerSecond),self.maxCharge);
			self.chargeTimer:Reset();
		end
	end

	if self.Magazine ~= nil then
		self.Magazine.RoundCount = self.chargeCounter;
	end

end