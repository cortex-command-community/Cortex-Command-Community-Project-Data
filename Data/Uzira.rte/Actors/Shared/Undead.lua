function Update(self)
	if self.Health > 0 and self.FGArm and (self.FGLeg or self.BGLeg) then
		local limbs = {self.Head, self.FGArm, self.BGArm, self.FGLeg, self.BGLeg};
		self.Health = self.MaxHealth * (1 - self.WoundCount/self:GetGibWoundLimit(true, false, false)) * #limbs/5;
	end
end