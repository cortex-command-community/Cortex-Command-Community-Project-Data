function Create(self)
	for particle in MovableMan.Particles do
		if particle:IsInGroup("Movator Nodes") then
			if particle.Pos.X == self.Pos.X and particle.Pos.Y == self.Pos.Y then
				particle.ToDelete = true;
				self.ToDelete = true;
			end
		end
	end
end
