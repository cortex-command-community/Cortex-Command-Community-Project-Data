function Create(self)
	self.baseStrength = 10;
	
	self.confirmSound = CreateSoundContainer("Confirm", "Base.rte");
	self.errorSound = CreateSoundContainer("Error", "Base.rte");
end
function Update(self)
	if self.FiredFrame then
		local parent = self:GetRootParent();
		if parent and IsActor(parent) then
			parent = ToActor(parent);
			local target = parent;
			local extend = parent:GetController():IsState(Controller.AIM_SHARP) and self.Radius or 0;

			for actor in MovableMan.Actors do
				local dist = SceneMan:ShortestDistance(self.MuzzlePos, actor.Pos, SceneMan.SceneWrapsX);
				if dist:MagnitudeIsLessThan(actor.Radius + extend) and actor.Team == self.Team and actor.ID ~= parent.ID then
					target = actor;
					break;
				end
			end
			if target and (target.Health < target.MaxHealth or target.WoundCount > 0) then
				local strength = self.baseStrength + math.ceil(3000/(1 + math.abs(target.Mass - target.InventoryMass + target.Material.StructuralIntegrity) * 0.5));
				if target.Health < target.MaxHealth then
					target.Health = math.min(target.Health + strength, target.MaxHealth);
				end
				if target.WoundCount > 0 then
					target:RemoveWounds(math.ceil(strength * 0.15), true, false, false);
				end
				target:FlashWhite(50);
				self.confirmSound:Play(self.Pos);

				local particleCount = math.ceil(1 + target.Radius * 0.5);
				for i = 1, particleCount do
					local part = CreateMOPixel("Heal Glow", "Base.rte");
					local vec = Vector(particleCount * 2, 0):RadRotate(math.pi * 2 * i/particleCount);
					part.Pos = target.Pos + Vector(0, -particleCount * 0.3):RadRotate(target.RotAngle) + vec;
					part.Vel = target.Vel * 0.5 - Vector(vec.X, vec.Y) * 0.25;
					MovableMan:AddParticle(part);
				end
				local cross = CreateMOSParticle("Particle Heal Effect", "Base.rte");
				cross.Pos = target.AboveHUDPos + Vector(0, 5);
				MovableMan:AddParticle(cross);
			else
				self.errorSound:Play(self.Pos);
				if self.Magazine then
					self.Magazine.RoundCount = self.Magazine.RoundCount + self.RoundsFired;
				end
			end
		end
		if self.RoundInMagCount == 0 then
			self.ToDelete = true;
		end
	end
end