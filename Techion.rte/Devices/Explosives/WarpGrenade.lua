function Update(self)
    --Get the holder.
    local newHolder = MovableMan:GetMOFromID(self.RootID);
	if MovableMan:IsActor(newHolder) then
        self.holder = newHolder;
    end
    
    --Detonate.
	if self.fuze then
		if self.fuze:IsPastSimMS(3000) then
			local effect = CreateMOSRotating("Warp Grenade Effect", "Techion.rte");
            effect.Pos = self.Pos;
            MovableMan:AddParticle(effect);
            effect:GibThis();
            
            if MovableMan:IsActor(self.holder) then
                self.holder.Pos = self.Pos + Vector(0, -20);
                ToActor(self.holder):FlashWhite(250);
            end
			self:GibThis();
		end
	elseif self:IsActivated() then
		self.fuze = Timer();
	end
end