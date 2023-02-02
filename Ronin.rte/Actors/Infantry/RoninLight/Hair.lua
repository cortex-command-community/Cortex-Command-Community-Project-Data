function Update(self)
	local pullForce = (self.Vel + self.PrevVel)/2 - SceneMan.GlobalAcc * rte.PxTravelledPerFrame;
	self.RotAngle = pullForce.AbsRadAngle;
	self.Frame = not pullForce:MagnitudeIsGreaterThan(8) and 1 or 0;
end
