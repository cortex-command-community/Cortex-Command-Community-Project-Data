function Create(self)
	self.startSound = CreateSoundContainer("Heatlance Fire Sound Start", "Browncoats.rte");
	self.endSound = CreateSoundContainer("Heatlance Fire Sound End", "Browncoats.rte");
end
function Update(self)
	if self:IsActivated() and self.RoundInMagCount ~= 0 then
		if not self.triggerPulled then
			self.startSound:Play(self.MuzzlePos);
		end
		self.triggerPulled = true;
	else
		if self.triggerPulled then
			self.endSound:Play(self.MuzzlePos);
		end
		self.triggerPulled = false;
	end
	if self.Magazine then
		local parent = self:GetRootParent();
		if parent and IsActor(parent) then
			parent = ToActor(parent);
			local parentDimensions = Vector(ToMOSprite(parent):GetSpriteWidth(), ToMOSprite(parent):GetSpriteHeight());
			self.Magazine.Pos = parent.Pos + Vector(-(parentDimensions.X - ToMOSprite(self.Magazine):GetSpriteWidth()) * 0.7 * parent.FlipFactor, - parentDimensions.Y * 0.3);
			self.Magazine.RotAngle = parent.RotAngle;
		end
	end
end