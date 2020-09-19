function Create(self)
	self.chainCount = 15;
	self.spread = math.rad(self.ParticleSpreadRange);
end
function Update(self)
	if self.FiredFrame then
		local lastChainID = 0;
		for i = 1, self.chainCount do
			local chain = CreateMOSParticle("Particle Mauler Chainshot ".. i % 2 + 1);
			chain.Pos = self.MuzzlePos;
			chain.Vel = self.Vel + Vector(math.random(50, 70) * self.FlipFactor, 0):RadRotate(self.RotAngle + self.spread * 0.5 - self.spread * i/self.chainCount);
			chain.PinStrength = 5000;	--Prevent any movement in the first frame

			chain.AirResistance = chain.AirResistance * RangeRand(0.5, 1);
			chain.AirThreshold = chain.AirThreshold * RangeRand(0.5, 1);
			chain.AngularVel = math.random(-5, 5);

			chain.Team = self.Team;
			chain.IgnoresTeamHits = true;

			MovableMan:AddParticle(chain);

			if lastChainID then --Create a Link/Joint connection
				--TODO: replace it with NumberValue once MOPixels and MOSParticles are supported?
				--chain:SetNumberValue("LinkID", lastChainID);
				chain.Sharpness = lastChainID;
			end
			lastChainID = chain.UniqueID;
		end
	end
end