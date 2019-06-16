function Create(self)
	self.switched = false;
end

function Update(self)
	if self.switched == false then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if actor and actor.Sharpness ~= 0 then
			if actor.Sharpness == 3 then
				self.switched = true;
				self.Mass = 5;
			else
				self.ToDelete = true;
			end
		end
	end
end
