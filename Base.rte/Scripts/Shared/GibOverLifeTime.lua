function Update(self)
	if self.Age > (self.Lifetime - 17) then
		self:GibThis();
	end
end