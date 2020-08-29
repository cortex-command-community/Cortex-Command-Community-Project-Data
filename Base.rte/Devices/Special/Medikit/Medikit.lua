function Create(self)
	self.baseStrength = 20;
end
function Update(self)
	if self.FiredFrame then
		parent = MovableMan:GetMOFromID(self.RootID);
		if parent and IsActor(parent) then
			parent = ToActor(parent);
			local target;
			local extend = parent:GetController():IsState(Controller.AIM_SHARP) and self.Radius or 0;

			for actor in MovableMan.Actors do
				local dist = SceneMan:ShortestDistance(self.MuzzlePos, actor.Pos, SceneMan.SceneWrapsX);
				if dist.Magnitude < (actor.Radius + extend) and actor.Team == self.Team and actor.ID ~= parent.ID then
					target = actor;
					break;
				else
					target = parent;
				end
			end
			if target and (target.Health < target.MaxHealth or target.TotalWoundCount > 0) then
				local strength = self.baseStrength + math.ceil(2000/(1 + math.abs(target.Mass) * 0.5));
				if target.Health < target.MaxHealth then
					target.Health = math.min(target.Health + strength, target.MaxHealth);
				end
				if target.TotalWoundCount > 0 then
					target:RemoveAnyRandomWounds(math.ceil(strength * 0.15));
				end
				target:FlashWhite(50);
				AudioMan:PlaySound("Base.rte/Sounds/GUIs/SlicePicked.wav", self.Pos);

				local targetSize = math.ceil(5 + target.Radius * 0.5);
				for i = 1, targetSize do
					local part = CreateMOPixel("Heal Glow", "Base.rte");
					local vec = Vector(targetSize * 2, 0):RadRotate(6.28/targetSize * i);
					part.Pos = target.Pos + Vector(0, -targetSize * 0.3):RadRotate(target.RotAngle) + vec;
					part.Vel = target.Vel * 0.5 - Vector(vec.X, vec.Y) * 0.25;
					MovableMan:AddParticle(part);
				end
				local cross = CreateMOSParticle("Particle Heal Effect", "Base.rte");
				cross.Pos = target.AboveHUDPos + Vector(0, 5);
				MovableMan:AddParticle(cross);
				
				self.ToDelete = true;
			end
		end
	end
end