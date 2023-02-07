function Update(self)
	if self.FiredFrame then
		self.Frame = self.FrameCount - 1;
	elseif self:IsReloading() then
		local inverseProgress = 1 - self.ReloadProgress;
		self.Frame = math.min(math.ceil((self.FrameCount) * inverseProgress), self.Frame);
		local parent = self:GetRootParent();
		if IsAHuman(parent) then
			parent = ToAHuman(parent);
			if parent.FGArm and parent.BGArm then
				pullArm = self:GetParent().ID == parent.BGArm.ID and parent.FGArm or parent.BGArm;
				pullArm:ClearHandTargets();
				pullArm.HandPos = self.Pos + Vector(6 * self.FlipFactor * math.sin(inverseProgress * math.pi), -2):RadRotate(self.RotAngle);
			end
		end
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