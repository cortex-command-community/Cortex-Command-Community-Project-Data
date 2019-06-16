function Update(self)

	if self.Magazine ~= nil and self.Magazine.RoundCount <= 0 then
		self:Reload();
	end

end