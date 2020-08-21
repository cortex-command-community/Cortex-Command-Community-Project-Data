function Create(self)
	self.shake = 0.5;
end
function Update(self)
	if self.Age > self.Lifetime then
		self:GibThis();
	else
		self.Vel = Vector(self.Vel.X, self.Vel.Y):DegRotate(RangeRand(-self.shake, self.shake) * math.sqrt(1 + self.Vel.Magnitude));
	end
end