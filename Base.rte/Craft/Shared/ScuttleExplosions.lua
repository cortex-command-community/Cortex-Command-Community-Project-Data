function Create(self)
	self.explosionTimer = Timer();
	
	self.height = ToMOSprite(self):GetSpriteHeight();
	self.width = ToMOSprite(self):GetSpriteWidth();
	
	self.explosiondelay = 5000/math.sqrt(self.width + self.height);
end
function Update(self)
	if self.Status > Actor.INACTIVE or self.AIMode == Actor.AIMODE_SCUTTLE then
		if self.explosionTimer:IsPastSimMS(self.explosiondelay) then
			self.explosionTimer:Reset();
			local expl = CreateAEmitter("Scuttle Explosion");
			expl.Pos = self.Pos + Vector(self.width/2 * RangeRand(-0.9, 0.9), self.height/2 * RangeRand(-0.9, 0.9)):RadRotate(self.RotAngle);
			expl.Vel = self.Vel;
			MovableMan:AddParticle(expl);
		end
	end
end