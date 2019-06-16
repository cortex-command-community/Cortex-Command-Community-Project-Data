function Create(self)
	self.switched = false;
end

function Update(self)
	if self.switched == false then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if actor.Sharpness ~= 0 then
			if actor.Sharpness == 3 then
				for i = 1,MovableMan:GetMOIDCount()-1 do
					local part = MovableMan:GetMOFromID(i);
					if part and part.RootID == self.RootID and part.PresetName == "Ronin Heavy Leg FG" then
						self.partWatch = part;
						break;
					end
				end
				self.switched = true;
				self.GetsHitByMOs = false;
			else
				self.ToDelete = true;
			end
		end
	else
		if self.partWatch ~= nil and self.partWatch.ID ~= 255 and self.partWatch.PresetName == "Ronin Heavy Leg FG" then
			--self.Frame = self.partWatch.Frame;
			--print(self.partWatch.Frame);
		else
			self.ToDelete = true;
		end
	end
end