function Update(self)
	if self.FiredFrame then
		self.Frame = self.FrameCount - 1;
	elseif self:IsReloading() then
		self.Frame = math.min(math.ceil((self.FrameCount) * (1 - self.ReloadProgress)), self.Frame);
	elseif self:DoneReloading() then
		self.Frame = 0;
	end
end
function OnDetach(self, exParent)
	if MovableMan:ValidMO(self) then
		if self.Magazine then
			self:RemoveAttachable(self.Magazine, true, true);
		else
			self.Frame = self.FrameCount - 1;
		end
	end
end