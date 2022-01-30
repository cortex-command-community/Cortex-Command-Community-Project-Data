function Create(self)
	--[[
	self.startSound = CreateSoundContainer("Heatlance Fire Sound Start", "Browncoats.rte");
	self.endSound = CreateSoundContainer("Heatlance Fire Sound End", "Browncoats.rte");
	--]]
end
function Update(self)
	--[[
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
	--]]
	if self.Magazine then
		local parent = self:GetRootParent();
		if parent and IsActor(parent) then
			parent = ToActor(parent);
			local parentDimensions = Vector(ToMOSprite(parent):GetSpriteWidth(), ToMOSprite(parent):GetSpriteHeight());
			local magDimensions = Vector(self.Magazine:GetSpriteWidth(), self.Magazine:GetSpriteHeight());
			self.Magazine.Pos = parent.Pos + Vector(-(parentDimensions.X + magDimensions.X) * 0.4 * parent.FlipFactor, -(parentDimensions.Y + magDimensions.Y) * 0.2):RadRotate(parent.RotAngle);
			self.Magazine.RotAngle = parent.RotAngle;
		end
	end
end