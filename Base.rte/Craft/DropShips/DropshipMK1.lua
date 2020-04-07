dofile("Base.rte/Constants.lua")
require("AI/NativeDropShipAI")

function Create(self)
	self.AI = NativeDropShipAI:Create(self);
	self.Frame = math.random(0, self.FrameCount - 1);
	
	self.explosionTimer = Timer();
	self.explosiondelay = 3000 / math.sqrt(self.Radius + 1);
	
	self.height = ToMOSprite(self):GetSpriteHeight();
	self.width = ToMOSprite(self):GetSpriteWidth();
end

function UpdateAI(self)
	self.AI:Update(self);
end

function Update(self)
	-- Re-orient the craft at 180 degrees to help rotational AI
	if self.RotAngle > math.pi then
		self.RotAngle = self.RotAngle - (math.pi * 2);
	end
	if self.RotAngle < -math.pi then
		self.RotAngle = self.RotAngle + (math.pi * 2);
	end
	-- Explosion effects on scuttle
	if self.Status > Actor.UNSTABLE or self.AIMode == Actor.AIMODE_SCUTTLE then
		if self.explosionTimer:IsPastSimMS(self.explosiondelay) then
			self.explosionTimer:Reset();
			local expl = CreateAEmitter("Scuttle Explosion");
			expl.Pos = self.Pos + Vector(self.width / 2, self.height / 2):RadRotate(self.RotAngle) * RangeRand(-0.8, 0.8);
			expl.Vel = self.Vel;
			MovableMan:AddParticle(expl);
		end
	end
end