function Create(self)
	self.GibTimer = Timer();
	-- Choose horizontal direction
	local dir = 1;
	if math.random() > 0.5 then
		dir = -1;
	end
	-- Randomize velocities
	self.AngularVel = -dir * math.random(1, 5);
	self.Vel = Vector(dir * math.random(5, 20), 30);
end
function Update(self)
	-- Apply damage to the actors inside based on impulse forces
	if self.TravelImpulse.Magnitude > self.Mass then
		-- Take crate damage to account?
		for i = 1, self.InventorySize do
			local actor = self:Inventory();
			if actor and IsActor(actor) then
				actor = ToActor(actor);
				-- The following method is a slightly revised version of the hardcoded impulse damage system
				local impulse = self.TravelImpulse.Magnitude - actor.ImpulseDamageThreshold;
				local damage = impulse / (actor.GibImpulseLimit * 0.1 + actor.Material.StructuralIntegrity * 10);
				if damage > 0 then
					actor.Health = actor.Health - damage;
				end
				if actor.Status < 3 then
					actor.Status = 1;
				end
			end
			self:SwapNextInventory(actor, true);
		end
	end
	if self.GibTimer:IsPastSimMS(2000) then
		self:GibThis();
	elseif self.Vel.Largest > 5 or self.AIMode == Actor.AIMODE_STAY then
		self.GibTimer:Reset();
	end
end
function Destroy(self)
	ActivityMan:GetActivity():ReportDeath(self.Team, -1);
end