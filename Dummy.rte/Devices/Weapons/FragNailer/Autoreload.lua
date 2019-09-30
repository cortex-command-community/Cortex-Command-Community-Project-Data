function Update(self)
	if not (self.Magazine) or (self.Magazine and self.Magazine.RoundCount == 0) then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if MovableMan:IsActor(actor) then
			ToActor(actor):GetController():SetState(Controller.WEAPON_RELOAD,true);
		end
	end
end