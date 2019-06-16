function Create(self)

	self.lastVel = Vector(self.Vel.X,self.Vel.Y);

end

function Update(self)

	if math.abs(self.lastVel.AbsRadAngle-self.Vel.AbsRadAngle) > 0.25 then
		--self.bounceTimer:Reset();
		self.Vel = Vector(self.Vel.Magnitude,0):RadRotate(self.Vel.AbsRadAngle+(math.random()*0.8)-0.4);
	end
	self.lastVel = Vector(self.Vel.X,self.Vel.Y);

end