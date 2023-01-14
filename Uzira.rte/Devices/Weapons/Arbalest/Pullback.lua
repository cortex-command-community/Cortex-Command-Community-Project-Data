function Update(self)
	if self:IsReloading() then
		self.Frame = 1;
	else
		self.Frame = 0;
	end
end