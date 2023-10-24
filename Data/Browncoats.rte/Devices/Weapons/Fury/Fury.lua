function OnFire(self)

	self.InheritedRotAngleTarget = self.recoilAngleSize * RangeRand(self.recoilAngleVariation, 1)

end

function Create(self)

	self.cockSound = CreateSoundContainer("Cock Browncoat R-500", "Browncoats.rte");
	self.reloadStartSound = CreateSoundContainer("Reload Start Browncoat R-500", "Browncoats.rte");
	self.reloadEndSound = CreateSoundContainer("Reload End Browncoat R-500", "Browncoats.rte");
	self.preSound = CreateSoundContainer("Pre Browncoat R-500", "Browncoats.rte");
	self.roundInSound = CreateSoundContainer("Round In Browncoat R-500", "Browncoats.rte");

	self.reloadTimer = Timer();
	self.loadedShell = false;
	self.reloadCycle = false;

	self.reloadDelay = 150;
	self.origReloadTime = 1200;
	
	self.origReloadAngle = self.ReloadAngle
	self.origOneHandedReloadAngle = self.OneHandedReloadAngle;

	self.ammoCounter = self.RoundInMagCount;
	self.maxAmmoCount = self.Magazine.Capacity;
	
	self.shellsToEject = 0;
	self.shellMOSParticle = self:StringValueExists("CylinderShellMOSParticle") and self:GetStringValue("CylinderShellMOSParticle") or "Base.rte/Casing";
	self.shellMOSRotating = self:StringValueExists("CylinderShellMOSRotating") and self:GetStringValue("CylinderShellMOSRotating") or nil;
	
	self.delayedFire = false
	self.delayedFireTimer = Timer();
	self.delayedFireTimeMS = 75;
	self.delayedFireEnabled = true;
	self.fireDelayTimer = Timer();
	self.activated = false;
	self.delayedFirstShot = true;
	
	self.InheritedRotAngleTarget = 0;
	self.InheritedRotAngleOffset = 0;
	self.recoilAngleSize = 0.45;
	self.recoilAngleVariation = 0.02;
	self.rotationSpeed = 0.1;
	
	self.cockTimer = Timer();
	self.cockDelay = 300;

end

function Update(self)

	self.cockSound.Pos = self.Pos;
	self.preSound.Pos = self.Pos;

	if self.FiredFrame then
		self.ammoCounter = self.ammoCounter - 1;
		self.Frame = 1;
		self.cockTimer:Reset();
		self.cockDelay = 300;
	end
	if self.Magazine then
	
		if not self.reloadCycle and self.Frame == 1 then
			self:Deactivate();
			self.delayedFire = false;
			
			if self.cockTimer:IsPastSimMS(self.cockDelay) then
				self.cockSound:Play(self.Pos);
				self.InheritedRotAngleTarget = 0;
				self.Frame = 0;
			end
		end
	
		self.shellsToEject = self.Magazine.Capacity - self.Magazine.RoundCount;
	
		if self.loadedShell then
			self.ReloadAngle = -0.25;
			self.OneHandedReloadAngle = -0.4;
			self.BaseReloadTime = self.reloadDelay * 3;
			self.ammoCounter = math.min(self.Magazine.Capacity, self.ammoCounter + 1);
			self.Magazine.RoundCount = self.ammoCounter;
			self.loadedShell = false;
		end
		if self.reloadCycleEndNext == true then
			self.ReloadStartSound = self.reloadStartSound;
			self.reloadCycleEndNext = false;
			self.BaseReloadTime = self.origReloadTime;
			self.ReloadAngle = self.origReloadAngle
			self.OneHandedReloadAngle = self.origOneHandedReloadAngle;
			self.reloadCycle = false;
		end
		if self.reloadCycle and self.reloadTimer:IsPastSimMS(self.reloadDelay) then
			local actor = self:GetRootParent();
			if MovableMan:IsActor(actor) then
				self.shellsToEject = 0;
				self:Reload();
			end
		end
	else
	
		self.cockTimer:Reset();
	
		if self.ammoCounter == self.maxAmmoCount then
			self.ReloadEndSound = self.reloadEndSound;
			self.reloadCycleEndNext = true;			
			self.BaseReloadTime = self.reloadDelay;
		end
	
		self.reloadTimer:Reset();
		
		if self.reloadCycle ~= true then
			--self.cockDelay = 300;
			self.InheritedRotAngleTarget = 0.1; -- not respected by the game currently
			self.ReloadEndSound = self.roundInSound;
			self.ReloadStartSound = nil;
			self.reloadCycle = true;
			if self.shellsToEject > 0 then
				for i = 1, self.shellsToEject do
					local shell = self.shellMOSRotating and CreateMOSRotating(self.shellMOSRotating) or CreateMOSParticle(self.shellMOSParticle);
					shell.Pos = self.Pos;
					shell.Vel = self.Vel + Vector(RangeRand(-3, 0) * self.FlipFactor, 0):RadRotate(self.RotAngle + RangeRand(-0.3, 0.3));
					shell.AngularVel = RangeRand(-1, 1);
					MovableMan:AddParticle(shell);
				end
			end
		end
		
		self.shellsToEject = 0;
		self.loadedShell = true;
	end
	if self:IsActivated() then
		self.reloadCycle = false;
	end
	
	if self:DoneReloading() then
		self.fireDelayTimer:Reset();
		self.activated = false;
		self.delayedFire = false;
		
	end
	
	if self.delayedFire and self.delayedFireTimer:IsPastSimMS(self.delayedFireTimeMS) then
		self:Activate();
		self.delayedFire = false
		self.delayedFirstShot = false;
	end

	local fire = self:IsActivated() and self.RoundInMagCount > 0 and self.Frame == 0;

	if self.delayedFirstShot == true then
		if self.RoundInMagCount > 0 then
			self:Deactivate()
		end
		
		if fire and not self:IsReloading() then
			if not self.Magazine or self.RoundInMagCount < 1 then
				self:Activate()
			elseif not self.activated and not self.delayedFire and self.fireDelayTimer:IsPastSimMS(1 / (self.RateOfFire / 60) * 1000) then
				self.activated = true
				
				self.preSound:Play(self.Pos);
				
				self.fireDelayTimer:Reset()
				
				self.delayedFire = true
				self.delayedFireTimer:Reset()
			end
		else
			
			if self.activated then
				self.activated = false
			end
		end
	elseif fire == false then
		self.firstShot = true;
		self.delayedFirstShot = true;	
	end
	
	if self.InheritedRotAngleOffset ~= self.InheritedRotAngleTarget then
		self.InheritedRotAngleOffset = self.InheritedRotAngleOffset - (self.rotationSpeed * (self.InheritedRotAngleOffset - self.InheritedRotAngleTarget))
	end
	
	if self.InheritedRotAngleTarget > 0 then
		self.InheritedRotAngleTarget = math.max(self.InheritedRotAngleTarget - TimerMan.DeltaTimeSecs, 0);
	end

end