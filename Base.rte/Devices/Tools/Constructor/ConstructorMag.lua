function Create(self)
	self.maxresource = 10 * 65 * 80;
end
function Update(self)

	self.Mass = 1 + self.RoundCount/(self.maxresource * 0.005);	--Full mag is 51kg
	self.Scale = 0.5 + (self.RoundCount/self.maxresource) * 0.5;

	local parent = self:GetRootParent();
	if parent and IsActor(parent) then
		local parentWidth = ToMOSprite(parent):GetSpriteWidth();
		local parentHeight = ToMOSprite(parent):GetSpriteHeight();
		self.Pos = parent.Pos + Vector(-(self.Radius * 0.3 + parentWidth * 0.2 - 0.5) * self.FlipFactor, -(self.Radius * 0.15 + parentHeight * 0.2)):RadRotate(parent.RotAngle);
		self.RotAngle = parent.RotAngle;
	end
end