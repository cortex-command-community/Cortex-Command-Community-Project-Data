function Create(self)

	self.detTimer = Timer();

end

function Update(self)

	if self.detTimer:IsPastSimMS(1500) then
		self:GibThis();
	end

end
