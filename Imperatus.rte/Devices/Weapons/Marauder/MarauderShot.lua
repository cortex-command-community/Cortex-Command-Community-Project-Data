function Create(self)
	self.width = math.floor(ToMOSprite(self):GetSpriteWidth() * 0.5 + 0.5);
end
function OnCollideWithMO(self, mo, rootMO)
	if not self.hit then
		local hitPos = Vector(self.PrevPos.X, self.PrevPos.Y);
		if SceneMan:CastFindMORay(self.PrevPos, self.PrevVel * rte.PxTravelledPerFrame, mo.ID, hitPos, rte.airID, true, 1) then
			self.hit = true;
			local penetration = (self.Mass * self.PrevVel.Magnitude * self.Sharpness)/math.max(mo.Material.StructuralIntegrity, 1);
			if penetration > 1 then
				local dist = SceneMan:ShortestDistance(mo.Pos, hitPos, SceneMan.SceneWrapsX);
				local stickOffset = Vector(dist.X * mo.FlipFactor, dist.Y):RadRotate(-mo.RotAngle * mo.FlipFactor);

				local setAngle = stickOffset.AbsRadAngle - (mo.HFlipped and math.pi or 0);
				local setOffset = Vector(stickOffset.X, stickOffset.Y):SetMagnitude(stickOffset.Magnitude - self.width);

				local woundName = mo:GetEntryWoundPresetName();
				local multiplier = math.min(math.sqrt(penetration), self.WoundDamageMultiplier);
				local mildMultiplier = math.sqrt(multiplier);
				local milderMultiplier = math.sqrt(mildMultiplier);
				if woundName ~= "" then
					local wound = CreateAEmitter(woundName);
					wound.DamageMultiplier = multiplier;
					wound.EmitCountLimit = math.ceil(wound.EmitCountLimit * mildMultiplier);
					wound.Scale = wound.Scale * milderMultiplier;
					if wound.BurstSound then
						wound.BurstSound.Pitch = wound.BurstSound.Pitch/milderMultiplier;
						wound.BurstSound.Volume = wound.BurstSound.Volume * milderMultiplier;
					end
					for em in wound.Emissions do
						em.ParticlesPerMinute = em.ParticlesPerMinute * multiplier;
						em.MaxVelocity = em.MaxVelocity * mildMultiplier;
						em.MinVelocity = em.MinVelocity * mildMultiplier;
					end
					wound.InheritedRotAngleOffset = setAngle;
					wound.DrawAfterParent = true;
					mo:AddWound(wound, setOffset, true);
				end

				if penetration > 2 then
					woundName = mo:GetExitWoundPresetName();
					if woundName ~= "" then
						local wound = CreateAEmitter(woundName);
						wound.DamageMultiplier = multiplier;
						wound.EmitCountLimit = math.ceil(wound.EmitCountLimit * mildMultiplier);
						wound.Scale = wound.Scale * milderMultiplier;
						if wound.BurstSound then
							wound.BurstSound.Pitch = wound.BurstSound.Pitch/milderMultiplier;
							wound.BurstSound.Volume = wound.BurstSound.Volume * milderMultiplier;
						end
						for em in wound.Emissions do
							em.ParticlesPerMinute = em.ParticlesPerMinute * multiplier;
							em.MaxVelocity = em.MaxVelocity * mildMultiplier;
							em.MinVelocity = em.MinVelocity * mildMultiplier;
						end
						wound.InheritedRotAngleOffset = setAngle;
						wound.DrawAfterParent = true;
						mo:AddWound(wound, setOffset, true);
					end
				end
			end
			self.Vel = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(self.Vel.Magnitude^0.9);
		end
	end
end