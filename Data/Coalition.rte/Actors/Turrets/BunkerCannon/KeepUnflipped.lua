function Create(self)

	if self:GetNumberValue("KeepUnflipped") == -1 then
		self.keepFlipped = true;
	else
		self.keepFlipped = false;
	end
	
	self.pinPos = Vector(self.Pos.X, self.Pos.Y);

end

function Update(self)

	-- keep anything from moving us
	self.Pos = self.pinPos;

	self.HFlipped = self.keepFlipped;
	
end