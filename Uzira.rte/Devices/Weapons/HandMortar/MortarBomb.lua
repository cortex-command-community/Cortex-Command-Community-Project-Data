function Create(self)
	self.explodeTimer = Timer();
	self.explodeInterval = RangeRand(1500, 3500);
end

function Update(self)
	if self.explodeTimer:IsPastSimMS(self.explodeInterval) then
		self:GibThis();
	else
		self.ToSettle = false;
	end
end