function Create(self)
	self.strength = self.Mass * self.Vel.Magnitude;
	self.range = self.Lifetime * self.Vel.Magnitude;
end
function Update(self)
	-- Run the effect on Update() to give other particles a chance to reach the target
	for i = 1 , MovableMan:GetMOIDCount() - 1 do
		local mo = MovableMan:GetMOFromID(i);
		if mo and mo.PinStrength == 0 then
			local dist = SceneMan:ShortestDistance(self.Pos, mo.Pos, SceneMan.SceneWrapsX);
			if dist.Magnitude < self.range then
				local strSumCheck = SceneMan:CastStrengthSumRay(self.Pos, self.Pos + dist, 3, 0);
				if strSumCheck < self.strength then
					local massFactor = math.sqrt(1 + math.abs(mo.Mass));
					local distFactor = 1 + dist.Magnitude * 0.1;
					local forceVector =	dist:SetMagnitude((self.strength - strSumCheck) /distFactor);
					mo.Vel = mo.Vel + forceVector /massFactor;
					mo.AngularVel = mo.AngularVel - forceVector.X /(massFactor + math.abs(mo.AngularVel));
					mo:AddForce(forceVector * massFactor, Vector());
				end
			end
		end	
	end
	self.ToDelete = true;
end