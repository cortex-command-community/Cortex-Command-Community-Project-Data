-- Initializes the regeneration system.
function Create(self)
	self.healAmount = 1; -- Health increment per healing tick.
	self.regenDelayNext = 100; -- Delay for next healing tick.
	self.regenTimer = Timer(); -- Timer for healing ticks.
	self.regenSoftcap = self.MaxHealth; -- Health threshold for healing.
	self.lastWoundCount = self.WoundCount; -- Last wound count.
	self.lastHelthCount = self.Health; -- Last health count.
end

-- Applies healing to the object.
function ApplyHealing(self)
	self:AddHealth(self.healAmount); -- Increment health.
	self.lastHelthCount = self.lastHelthCount + self.healAmount; -- Update last health count.
	-- Visual effect for healing.
	local cross = CreateMOSParticle("Particle Heal Effect", "Base.rte");
	cross.Pos = self.AboveHUDPos + Vector(math.random(-3, 3), math.random(6, 10));
	MovableMan:AddParticle(cross);
end

-- Controls the regeneration system.
function ThreadedUpdate(self)
	if self.regenTimer:IsPastSimMS(self.regenDelayNext) then
		self.regenTimer:Reset(); -- Reset timer.
		self.regenDelayNext = 100 + math.random(0, 200); -- Randomize delay.

		if self.Health > -5 then
			self.regenSoftcap = math.min(self.regenSoftcap, self.MaxHealth - (self.MaxHealth - self.Health)/2, self.MaxHealth); -- Adjust soft cap.

			if self.Health < self.regenSoftcap then -- Check health against soft cap.
				if self.Health < 5 or math.random() < 1 - (self.Health/self.regenSoftcap) then
					ApplyHealing(self); -- Apply healing if necessary.
				end
			end

			self.damageAbsolute = math.max(0, self.WoundCount - self.lastWoundCount) + math.max(0, self.Health - self.lastHelthCount)

			if self.damageAbsolute > 0 then -- Increase delay if damaged.
				self.regenDelayNext = self.regenDelayNext + 500;
			else
				local healed = self:RemoveWounds(1); -- Remove a wound if not damaged.

				if healed > 0 then
					self.regenSoftcap = self.regenSoftcap -1;
					local cross = CreateMOSParticle("Particle Heal Effect", "Base.rte");
					cross.Pos = self.AboveHUDPos + Vector(math.random(-3, 3), math.random(6, 10));
					MovableMan:AddParticle(cross);
				end

				if healed ~= 0 and self.Health < self.MaxHealth then
					ApplyHealing(self); -- Apply healing if health is below max.
					if self.Health > self.MaxHealth then -- Cap health at max.
						self.Health = self.MaxHealth;
					end
				end
			end
		end
		self.lastWoundCount = self.WoundCount; -- Update last wound count.
		self.lastHelthCount = self.Health; -- Update last health count.
	end
end

