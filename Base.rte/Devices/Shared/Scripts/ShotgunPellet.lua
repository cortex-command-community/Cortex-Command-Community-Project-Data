function Create(self)
	self.GlobalAccScalar = self.GlobalAccScalar * RangeRand(0.5, 1.0);
	self.AirResistance = self.AirResistance * RangeRand(0.9, 1.1);

	self.Lifetime = self.Lifetime * RangeRand(0.5, 1.0);
	self.Sharpness = self.Sharpness * RangeRand(0.9, 1.1);
end