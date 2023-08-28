-- This script incorporates Filipawn Industries code and the vanilla burstfire script together
-- There is likely better ways of doing a lot of this, potentially even standardizing it so it can be easily used more widely

-- Last worked on 12/4/2023

function OnFire(self)

	self.FireTimer:Reset();
	
end

function Create(self)

	self.preSound = CreateSoundContainer("Coalition Bunker Cannon Pre", "Coalition.rte");
	
	self.FireTimer = Timer();
	
	self.delayedFire = false
	self.delayedFireTimer = Timer();
	self.delayedFireTimeMS = 50
	self.delayedFireEnabled = true	
	self.fireDelayTimer = Timer()
	self.activated = false
	self.delayedFirstShot = true;
	

	self.shotsPerBurst = self:NumberValueExists("ShotsPerBurst") and self:GetNumberValue("ShotsPerBurst") or 3;
	self.coolDownDelay = 500;	
	

end

function Update(self)

	self.parent = IsActor(self:GetRootParent()) and ToActor(self:GetRootParent()) or nil;
	
	-- Mathemagical firing anim by filipex
	local f = math.max(1 - math.min((self.FireTimer.ElapsedSimTimeMS) / 200, 1), 0)
	self.Frame = math.floor(f * 8 + 0.55);
	
	if self:DoneReloading() or self:IsReloading() then
		self.fireDelayTimer:Reset()
		self.activated = false;
		self.delayedFire = false;
	end
	
	local fire = self:IsActivated() and self.RoundInMagCount > 0;

	if self.parent and self.delayedFirstShot == true then
		if self.RoundInMagCount > 0 then
			self:Deactivate()
		end
		
		--if self.parent:GetController():IsState(Controller.WEAPON_FIRE) and not self:IsReloading() then
		if fire and not self:IsReloading() then
			if not self.Magazine or self.Magazine.RoundCount < 1 then
				--self:Reload()
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
		self.delayedFirstShot = true;
	end
	
	if self.delayedFire and self.delayedFireTimer:IsPastSimMS(self.delayedFireTimeMS) then
		self:Activate();
		self.delayedFire = false
		self.delayedFirstShot = false;
	end
	
	
	if self.Magazine then
		if self.coolDownTimer then
			if self.coolDownTimer:IsPastSimMS(self.coolDownDelay) and not (self:IsActivated() and self.triggerPulled) then
				self.coolDownTimer, self.shotCounter = nil;
			else
				self:Deactivate();
				if self.parent and ToActor(self.parent):IsPlayerControlled() then
					self.triggerPulled = false;
				end
			end
		elseif self.shotCounter then

			self.triggerPulled = self:IsActivated();
				
			self:Activate();
			if self.FiredFrame then
				self.shotCounter = self.shotCounter + 1;
				if self.shotCounter >= self.shotsPerBurst then
					self.coolDownTimer = Timer();
				end
			end
		elseif self.FiredFrame then
			self.shotCounter = 1;
		end
	else
		self.coolDownTimer, self.shotCounter = nil;
	end	

	
end