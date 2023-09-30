function Create(self)
	self.updateTimer = Timer();
	self.healTimer = Timer();
	self.HoldTimer = Timer();
	self.ReleaseTimer = Timer();
	self.HoldTime = 5000;
	self.ReleaseTime = 800;
	self.detectionRange = 45; -- Default 40
	self.HasDockedCraft = false;
end

function Update(self)

	if UInputMan:KeyPressed(Key.U) then
		self:ReloadScripts();
	end

	--Settle into terrain instead of gibbing
	if self.WoundCount > (self.GibWoundLimit * 0.9) then
		self.ToSettle = true;
	end
	if self.craft and MovableMan:ValidMO(self.craft) then
		--This block runs before HoldTimer it's passed
		if not self.HoldTimer:IsPastSimMS(self.HoldTime) then
			if not self.HasDockedCraft then
				self.craft.AIMode = Actor.AIMODE_STAY;
				self.HasDockedCraft = true;
				self.craft:SetNumberValue("Docked", 1);
			end
			self.ReleaseTimer:Reset(); -- During the time the HoldTimer isn't reached, prevent ReleaseTimer from going
		end
		if self.HasDockedCraft then
			--Disable collisions with the ship
			self.craft:SetWhichMOToNotHit(self, 100);
			--Pin the ship and pull it nicely into the docking unit.
			local dist = SceneMan:ShortestDistance(self.craft.Pos, self.Pos + Vector(0, -self.craft.Radius * 0.5), SceneMan.SceneWrapsX);
			self.craft.Vel = self.craft.Vel * 0.9 + dist/(3 + self.craft.Vel.Magnitude);
			self.craft.AngularVel = self.craft.AngularVel * 0.9 - self.craft.RotAngle * 3;

			if self.craft.Status < Actor.DYING then
				self.craft.Status = Actor.UNSTABLE;	--Deactivated
			end
			--Heal the craft
			if self.healTimer:IsPastSimMS(self.craft.Mass) then
				self.healTimer:Reset();
				if self.craft.WoundCount > 0 then
					self.craft:RemoveWounds(1);
				elseif self.craft.Health < self.craft.MaxHealth then
					self.craft.Health = math.min(self.craft.Health + 1, self.craft.MaxHealth);
				end
			end
		end
		if self.ReleaseTimer:IsPastSimMS(self.ReleaseTime) then -- Once ReleaseTimer stops resetting it can finally run
			self.craft.AIMode = Actor.AIMODE_RETURN
			self.craft:RemoveNumberValue("Docked");
			self.craft = nil; --Forget about the craft thus starting all over again
			self.ReleaseTimer:Reset();
		end
	elseif self.ReleaseTimer:IsPastSimMS(self.ReleaseTime * 4) and self.updateTimer:IsPastSimMS(200) then
		self.craft = nil;
		for mo in MovableMan:GetMOsInRadius(self.Pos, self.detectionRange, -1, true) do
			--See if a live rocket is within 45 pixel range of the docking unit
			if mo.ClassName == "ACRocket" and not ToActor(mo):IsDead() then
				self.craft = ToACRocket(mo);
			end
		end
		self.HoldTimer:Reset();
		self.updateTimer:Reset();
	end
end