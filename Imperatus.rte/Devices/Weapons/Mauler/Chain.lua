function Create(self)
	self.maxLength = 2;
	self.maxForce = 6;
	self.maxDistance = 4;
	self.forceMultiplier = 10;
	self.dampMultiplier = 0.2;
	--Get the link connection ID from Sharpness
	--TODO: replace it with NumberValue once MOPixels and MOSParticles are supported?
	self.linkID = self.Sharpness;
	self.Sharpness = math.random(15, 20);

	self.Lifetime = self.Lifetime * RangeRand(0.5, 1.0);
	self.detachDelay = self.Lifetime * 0.5;
	
	self.PinStrength = 0;
end

function Update(self)
	if self.Age > self.detachDelay then
		self.linkID = nil;
		return
	end
	self.Sharpness = math.max(self.Sharpness - TimerMan.DeltaTimeSecs * math.random(10, 0), 0);

	if self.linkID then
		local linkMO = MovableMan:FindObjectByUniqueID(self.linkID);
		if linkMO then
			local dist = SceneMan:ShortestDistance(self.Pos, linkMO.Pos, SceneMan.SceneWrapsX);
			--Spring joint: apply a force proportional to the distance between the two MOs
			local str = math.min(math.max((dist.Magnitude/self.maxLength) - 1, 0), self.maxForce) * TimerMan.DeltaTimeSecs * self.forceMultiplier;
			self.Vel = self.Vel + dist * str;
			linkMO.Vel = linkMO.Vel - dist * str;

			--Distance joint: limit distance between two MOs
			if dist.Magnitude > (self.maxDistance * 4) then
				self.linkID = nil;
			else
				self.Pos = linkMO.Pos - dist:SetMagnitude(math.min(dist.Magnitude, self.maxDistance));
				--Distance dampening joint: apply a force proportional to the velocity difference between MOs
				local dampeningFactor = 1 - (self.Vel - linkMO.Vel).Magnitude * TimerMan.DeltaTimeSecs * self.dampMultiplier;
				self.Vel = self.Vel * dampeningFactor;
				linkMO.Vel = linkMO.Vel * dampeningFactor;
				
				self.linked = true;
			end
		elseif self.linked then	--Joint has been broken
			self.linkID = nil;
			self.linked = false;

			local part = CreateMOPixel("Drop Oil", "Base.rte");
			part.Pos = self.Pos;
			part.Vel = self.Vel + Vector(math.random(5), 0):RadRotate(6.28 * math.random());
			MovableMan:AddParticle(part);
		end
	end
end
function OnCollideWithTerrain(self, terrainID)
	self.Sharpness = self.Sharpness * 0.5;
end