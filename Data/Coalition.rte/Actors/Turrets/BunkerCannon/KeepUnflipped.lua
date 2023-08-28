function Create(self)

	if self:NumberValueExists("KeepUnflipped") then
		self.keepFlipped = true;
	else
		self.keepFlipped = false;
	end
	
	self.pinPos = self.Pos;
	

end

function Update(self)

	-- keep anything from moving us
	self.Pos = self.pinPos;

	self.HFlipped = self.keepFlipped;
	
end