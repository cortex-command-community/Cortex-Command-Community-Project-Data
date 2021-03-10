function Update(self)
	if self.RoundInMagCount == 0 then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if MovableMan:IsActor(actor) then
			self:Reload();
		end
	end
end