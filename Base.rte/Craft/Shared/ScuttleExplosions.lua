function Create(self)
	self.explosionTimer = Timer();
	
	self.height = ToMOSprite(self):GetSpriteHeight();
	self.width = ToMOSprite(self):GetSpriteWidth();
	
	if self:NumberValueExists("ScuttleExplosionDelay") then
		self.explosionDelay = self:GetNumberValue("ScuttleExplosionDelay");
	else
		self.explosionDelay = 5000/math.sqrt(self.width + self.height);
	end
end
function Update(self)
	if self.Status > Actor.INACTIVE or self.AIMode == Actor.AIMODE_SCUTTLE then
		if self.explosionTimer:IsPastSimMS(self.explosionDelay) then
			self.explosionTimer:Reset();
			local explosion = CreateAEmitter("Scuttle Explosion");
			explosion.Pos = self.Pos + Vector(self.width/2 * RangeRand(-0.9, 0.9), self.height * 0.5 * RangeRand(-0.9, 0.9)):RadRotate(self.RotAngle);
			explosion.Vel = self.Vel;
			MovableMan:AddParticle(explosion);
		end
	end
end