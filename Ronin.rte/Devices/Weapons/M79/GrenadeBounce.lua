function Create(self)
	self.detonationDelay = 3000;
	self.startPos = Vector(self.Pos.X, self.Pos.Y);
	self.safetyRadius = 180;
end

function Update(self)
	if not self.safetyTriggered then
		if self.Age > self.detonationDelay or self.TravelImpulse:MagnitudeIsGreaterThan(self.Mass) then
			if SceneMan:ShortestDistance(self.startPos, self.Pos, SceneMan.SceneWrapsX):MagnitudeIsGreaterThan(self.safetyRadius) then
				self:GibThis();
			else
				self.safetyTriggered = true;
			end
		else
			self.ToDelete = false;
			self.ToSettle = false;
		end
	end
end