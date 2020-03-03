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
				local strength = self.strength;
				local strSumCheck = SceneMan:CastStrengthSumRay(self.Pos, self.Pos + dist, 3, 0);
				if strSumCheck < strength then
					strength = strength - strSumCheck;
					local massFactor = math.sqrt(1 + math.abs(mo.Mass));
					local distFactor = 1 + dist.Magnitude * 0.1;
					local forceVector =	dist:SetMagnitude(strength / distFactor);
					mo.Vel = mo.Vel + forceVector / massFactor;
					mo.AngularVel = mo.AngularVel - forceVector.X / (massFactor + math.abs(mo.AngularVel));
					mo:AddForce(forceVector * massFactor, Vector());
				end
			end
		end	
	end
	-- Debug: visualize effect range
	-- FrameMan:DrawCirclePrimitive(self.Pos, self.range, 254);
	self.ToDelete = true;
end