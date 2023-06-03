function Create(self)
	self.safetyRadius = 180;
end
function Update(self)
	if self.TravelImpulse:MagnitudeIsGreaterThan(self.Mass) then
		if self.DistanceTravelled > self.safetyRadius then
			self:GibThis();
		else
			self:DisableScript("Ronin.rte/Devices/Weapons/M79/GrenadeBounce.lua");
		end
	end
end