function Update(self)
	if self.FGArm and (self.FGLeg or self.BGLeg) then
		self.Health = self.MaxHealth;
	end
end