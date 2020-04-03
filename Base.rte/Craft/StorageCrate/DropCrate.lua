function Create(self)
	self.GibTimer = Timer();
	self.GibTimer:SetSimTimeLimitMS(1000 + self.InventorySize * 100);
	-- Choose a random horizontal direction
	local randomDirection = math.random() > 0.5 and 1 or -1;
	-- Randomize velocities
	self.AngularVel = -randomDirection * math.random(1, 5);
	self.Vel = Vector(randomDirection * math.random(5, 20), 30);
end
function Update(self)
	-- Apply damage to the actors inside based on impulse forces
	if self.TravelImpulse.Magnitude > self.Mass then
		for i = 1, self.InventorySize do
			local actor = self:Inventory();
			if actor and IsActor(actor) and string.find(actor.Material.PresetName, "Flesh") then
				actor = ToActor(actor);
				-- The following method is a slightly revised version of the hardcoded impulse damage system
				local impulse = self.TravelImpulse.Magnitude - actor.ImpulseDamageThreshold;
				local damage = impulse / (actor.GibImpulseLimit * 0.1 + actor.Material.StructuralIntegrity * 10);
				actor.Health = damage > 0 and actor.Health - damage or actor.Health;
				actor.Status = actor.Status < Actor.DYING and Actor.UNSTABLE or actor.Status;
			end
			self:SwapNextInventory(actor, true);
		end
	end
	if self.GibTimer:IsPastSimTimeLimit() then
		self:GibThis();
	elseif self.Vel.Largest > 5 or self.AIMode == Actor.AIMODE_STAY then
		self.GibTimer:Reset();
	end
end
function Destroy(self)
	ActivityMan:GetActivity():ReportDeath(self.Team, -1);
end