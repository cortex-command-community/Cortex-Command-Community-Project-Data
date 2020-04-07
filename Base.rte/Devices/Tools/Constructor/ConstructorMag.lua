
function Create(self)
	self.maxresource = 10 * 65 * 80;
end

function Update(self)

	self.Mass = 1 + self.RoundCount / (self.maxresource / 100);	-- full mag is 101kg
	self.Scale = 0.5 + (self.RoundCount / self.maxresource) * 0.5;

	local fixNum = self.HFlipped and -1 or 0;

	local parent = MovableMan:GetMOFromID(self:GetParent().RootID);
	if parent and IsActor(parent) then
		local parentWidth = ToMOSprite(parent):GetSpriteWidth();
		local parentHeight = ToMOSprite(parent):GetSpriteHeight();
		self.Pos = parent.Pos + Vector(-(self.Radius * 0.3 + parentWidth * 0.2 + fixNum) * self.FlipFactor, -(self.Radius * 0.15 + parentHeight * 0.2)):RadRotate(parent.RotAngle);
		self.RotAngle = parent.RotAngle;
	end
end