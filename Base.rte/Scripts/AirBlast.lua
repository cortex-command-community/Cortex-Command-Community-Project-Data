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
					local forceVector =	dist:SetMagnitude((self.strength - strSumCheck)/distFactor);
					mo.Vel = mo.Vel + forceVector/massFactor;
					mo.AngularVel = mo.AngularVel - forceVector.X/(massFactor + math.abs(mo.AngularVel));
					mo:AddForce(forceVector * massFactor, Vector());
					-- Add some additional points damage to actors
					if IsActor(mo) then
						local actor = ToActor(mo);
						local impulse = (forceVector.Magnitude * self.strength/massFactor) - actor.ImpulseDamageThreshold;
						local damage = impulse/(actor.GibImpulseLimit * 0.1 + actor.Material.StructuralIntegrity * 10);
						actor.Health = damage > 0 and actor.Health - damage or actor.Health;
						actor.Status = (actor.Status == Actor.STABLE and damage > (actor.Health/2)) and Actor.UNSTABLE or actor.Status;
					end
				end
			end
		end	
	end
	self.ToDelete = true;
end