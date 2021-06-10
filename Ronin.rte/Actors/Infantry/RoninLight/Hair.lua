function Update(self)
	self.HFlipped = false;
	local gravity = self.Vel - SceneMan.GlobalAcc * rte.PxTravelledPerFrame;
	self.RotAngle = gravity.AbsRadAngle;
	self.Frame = gravity.Magnitude > 5 and 0 or 1;
	if not IsActor(self:GetRootParent()) then
		self.ToDelete = true;
	end
end