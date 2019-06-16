function Update(self)
	local actor = MovableMan:GetMOFromID(self.RootID);
	if actor and actor.Sharpness == 0 then
		actor.Sharpness = math.floor(math.random()*6)+1;
		self.ToDelete = true;
	end
end
