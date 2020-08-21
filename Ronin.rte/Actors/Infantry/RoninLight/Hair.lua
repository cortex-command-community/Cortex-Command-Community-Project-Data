function Update(self)
	self.HFlipped = false;
	local gravity = self.Vel - SceneMan.GlobalAcc/3;
	self.RotAngle = gravity.AbsRadAngle;
	if gravity.Magnitude > 5 then
		self.Frame = 0;
	else
		self.Frame = 1;
	end
end