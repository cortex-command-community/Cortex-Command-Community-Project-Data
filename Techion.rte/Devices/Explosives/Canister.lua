function Update(self)
	if self.fuze then
		if self.fuze:IsPastSimMS(3000) then
			local effect = CreateMOSRotating("Nanoswarm Canister Effect", "Techion.rte");
            effect.Pos = self.Pos;
            MovableMan:AddParticle(effect);
            effect:GibThis();
            
            local swarm = CreateAEmitter("Nanoswarm", "Techion.rte");
            swarm.Pos = self.Pos;
            swarm.Team = self.throwTeam;
            MovableMan:AddParticle(swarm);
            
			self:GibThis()
		end
	elseif self:IsActivated() then
		self.fuze = Timer();
        self.throwTeam = self.Team;
	end
end