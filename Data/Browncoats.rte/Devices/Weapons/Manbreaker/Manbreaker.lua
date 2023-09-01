-- This script incorporates Filipawn Industries code
-- There are likely better ways of doing a lot of this, potentially even standardizing it so it can be easily used more widely

-- Last worked on 01/09/2023

function OnFire(self)

	CameraMan:AddScreenShake(3, self.Pos);
	
	self.mechTailSound:Play(self.Pos);
	
	if self.firstShot then
		self.firstShotSound:Play(self.Pos);
		self.firstShot = false;
		self.overheatLoopSound:Play(self.Pos);
	else
		self.shotSound:Play(self.Pos);
	end
	
	self.InheritedRotAngleTarget = self.InheritedRotAngleOffset + (self.recoilAngleSize * RangeRand(self.recoilAngleVariation, 1))
	
	-- Heat mechanics
	
	-- unsteady rate of fire
	--self.RateOfFire = self.originalRateOfFire + math.max(0, math.random(-100, 0)* (self.Heat-70)/100)

	-- FireSound is our mechanical sound, have it rise as we overheat
	self.FireSound.Volume = 0.8 + self.Heat / 200
	
	if self.Heat > 80 then
		self.preSound.Volume = 1.5;
		self.preSound:Play(self.Pos);
		local particle = CreateMOSParticle("Side Thruster Blast Ball 1", "Base.rte");
		particle.HitsMOs = false;
		particle.Lifetime = math.random(250, 600);
		particle.Vel = self.Vel + Vector(math.random(-100, 100)/100, -4);
		particle.Pos = self.Pos;
		MovableMan:AddParticle(particle);
	end
	
	self.Heat = math.min(100, self.Heat + 2.5);
	
	if self.Heat == 100 then
	
		self.overheatFixSound:Play(self.Pos);
		self.Overheated = true;
		self.overheatStuckShell = true;
		
		self.overheatFixTimer:Reset();
		
		for i = 1, 10 do
			local particle = CreateMOSParticle("Tiny Smoke Ball 1", "Base.rte");
			particle.Lifetime = math.random(250, 600);
			particle.Vel = self.Vel + Vector(math.random(-100, 100)/100, -2);
			particle.Pos = self.Pos;
			MovableMan:AddParticle(particle);
		end		
		
		for i = 1, 5 do
			local particle = CreateMOSParticle("Small Smoke Ball 1", "Base.rte");
			particle.Lifetime = math.random(250, 600);
			particle.Vel = self.Vel + Vector(math.random(-100, 100)/100, -2);
			particle.Pos = self.Pos;
			MovableMan:AddParticle(particle);
		end
		
		for i = 1, 3 do
			local particle = CreateMOSParticle("Side Thruster Blast Ball 1", "Base.rte");
			particle.HitsMOs = false;
			particle.Lifetime = math.random(250, 600);
			particle.Vel = self.Vel + Vector(math.random(-200, 200)/100, -3);
			particle.Pos = self.Pos;
			MovableMan:AddParticle(particle);
		end
		
	end
	
end

function Create(self)

	self.preSound = CreateSoundContainer("Pre Browncoat MG-85", "Browncoat.rte");
	
	self.firstShotSound = CreateSoundContainer("First Shot Browncoat MG-85", "Browncoat.rte");
	self.shotSound = CreateSoundContainer("Shot Browncoat MG-85", "Browncoat.rte");
	
	self.overheatLoopSound = CreateSoundContainer("Overheat Loop Browncoat MG-85", "Browncoat.rte");
	self.overheatFixSound = CreateSoundContainer("Overheat Fix Browncoat MG-85", "Browncoat.rte");
	
	self.mechTailSound = CreateSoundContainer("Mech Tail Browncoat MG-85", "Browncoat.rte");
	
	self.firstShot = true;
	
	self.delayedFire = false
	self.delayedFireTimer = Timer();
	self.delayedFireTimeMS = 80;
	self.delayedFireEnabled = true;
	self.fireDelayTimer = Timer();
	self.activated = false;
	self.delayedFirstShot = true;
	
	self.originalStanceOffset = Vector(self.StanceOffset.X, self.StanceOffset.Y);
	self.originalSharpStanceOffset = Vector(self.SharpStanceOffset.X, self.SharpStanceOffset.Y);
	self.originalSupportOffset = Vector(self.SupportOffset.X, self.SupportOffset.Y);
	self.originalRateOfFire = self.RateOfFire
	
	self.heatFXTimer = Timer();
	self.Heat = 0;
	
	self.overheatFixTimer = Timer();
	self.overheatFixDelay = 2300;
	
	self.InheritedRotAngleOffset = 0;
	self.recoilAngleSize = 5;
	self.recoilAngleVariation = 0.2;
	self.rotationSpeed = 0.01;

end

function Update(self)

	self.preSound.Pos = self.Pos;
	self.overheatLoopSound.Pos = self.Pos;
	self.overheatFixSound.Pos = self.Pos;
	self.mechTailSound.Pos = self.Pos;
	
	self.overheatLoopSound.Volume = self.Heat * 3 / 225; -- will rise to 1.3
	
	if self:DoneReloading() or self:IsReloading() then
		self.fireDelayTimer:Reset();
		self.activated = false;
		self.delayedFire = false;
	end
	
	if self.delayedFire and self.delayedFireTimer:IsPastSimMS(self.delayedFireTimeMS) then
		self:Activate();
		self.delayedFire = false
		self.delayedFirstShot = false;
	end

	local fire = self:IsActivated() and self.RoundInMagCount > 0 and not self.Overheated;

	if self.delayedFirstShot == true then
		if self.RoundInMagCount > 0 then
			self:Deactivate()
		end
		
		--if self.parent:GetController():IsState(Controller.WEAPON_FIRE) and not self:IsReloading() then
		if fire and not self:IsReloading() then
			if not self.Magazine or self.RoundInMagCount < 1 then
				--self:Reload()
				self:Activate()
			elseif not self.activated and not self.delayedFire and self.fireDelayTimer:IsPastSimMS(1 / (self.RateOfFire / 60) * 1000) then
				self.activated = true
				
				self.preSound.Volume = 1;
				
				self.preSound:Play(self.Pos);
				
				self.fireDelayTimer:Reset()
				
				self.delayedFire = true
				self.delayedFireTimer:Reset()
			end
		else
		
			self.Heat = math.max(0, self.Heat - TimerMan.DeltaTimeSecs * 30);
			
			if self.activated then
				self.activated = false
			end
		end
	elseif fire == false then
		self.firstShot = true;
		self.delayedFirstShot = true;
		
	end
	
	if self.Overheated then
	
		self.Heat = math.max(0, self.Heat - TimerMan.DeltaTimeSecs * 30);
		
		if self.overheatFixTimer:IsPastSimMS(self.overheatFixDelay) then
		
			self.Heat = 0;
		
			self.rotationSpeed = 0.01;
		
			self.Overheated = false;
			
			self.SupportOffset = self.originalSupportOffset;
			
			self.InheritedRotAngleTarget = 0;
			
		elseif self.overheatFixTimer:IsPastSimMS(self.overheatFixDelay / 1.5) then
			
			self.rotationSpeed = 0.03;
			
			self.SupportOffset = Vector(-1, -2);
			
			self.InheritedRotAngleTarget = 0;
			
		elseif self.overheatFixTimer:IsPastSimMS(self.overheatFixDelay / 2) then
		
			if self.overheatStuckShell == true then
		
				self.SupportOffset = Vector(-5, -2);
				
				local shell = CreateAEmitter("Smoking Large Casing", "Base.rte");
				shell.Pos = self.Pos+Vector(0,-1):RadRotate(self.RotAngle);
				shell.Vel = self.Vel+Vector(-math.random(2,4)*self.FlipFactor,-math.random(5,6)):RadRotate(self.RotAngle);
				shell.AngularVel = 10 * self.FlipFactor;
				shell.RotAngle = self.RotAngle
				shell.HFlipped = self.HFlipped
				MovableMan:AddParticle(shell);
				
				self.overheatStuckShell = false;
				
				self.InheritedRotAngleTarget = -0.05;
				
			end
				
		elseif self.overheatFixTimer:IsPastSimMS(self.overheatFixDelay / 4) then
		
			self.rotationSpeed = 0.05;
		
			self.SupportOffset = Vector(0, -2)
			
			self.InheritedRotAngleTarget = -0.15;
			
		end
		
	end			
	
	if self.heatFXTimer:IsPastSimMS(500) then
	
		self.heatFXTimer:Reset();
		
		for i = 1, self.Heat / 20 do
			local particle = CreateMOSParticle("Tiny Smoke Ball 1", "Base.rte");
			particle.Lifetime = math.random(250, 600);
			particle.Vel = self.Vel + Vector(math.random(-100, 100)/100, -1);
			particle.Pos = self.Pos;
			MovableMan:AddParticle(particle);
		end
		
		for i = 1, self.Heat / 50 do
			local particle = CreateMOSParticle("Small Smoke Ball 1", "Base.rte");
			particle.Lifetime = math.random(250, 600);
			particle.Vel = self.Vel + Vector(math.random(-100, 100)/100, -1);
			particle.Pos = self.Pos;
			MovableMan:AddParticle(particle);
		end	
		
	end
	
	if self.InheritedRotAngleOffset ~= self.InheritedRotAngleTarget then
		self.InheritedRotAngleOffset = self.InheritedRotAngleOffset - (self.rotationSpeed * (self.InheritedRotAngleOffset - self.InheritedRotAngleTarget))
	end
	
end

function OnDetach(self)

	self.Overheated = false;
	self.overheatStuckShell = false;
	self.InheritedRotAngleTarget = 0;
	self.rotationSpeed = 0.01;
	
end

function Destroy(self)

	self.overheatLoopSound:Stop(-1);
	self.overheatFixSound:Stop(-1);
	
end