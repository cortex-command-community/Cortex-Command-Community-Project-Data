function Create(self)
	self.glow = CreateMOPixel("Shielder Wall Glow", "Dummy.rte");
	self.glow.Pos = self.Pos;
	self.glow.EffectRotAngle = self.RotAngle;
	MovableMan:AddParticle(self.glow);
	self.glowID = self.glow.UniqueID;
end
function Update(self)
	if self.AngularVel < 1 then
		self.AngularVel = 0;
	else
		self.AngularVel = self.AngularVel * 0.99;
		--self.EffectRotAngle = self.RotAngle;
	end
	if self.glow and self.glow.UniqueID == self.glowID then
		self.glow.Pos = self.Pos;
		if self.AngularVel ~= 0 then
			self.glow.EffectRotAngle = self.RotAngle;
		end
		--To-do: add flicker
	else
		self.glow = nil;
	end
	if self.PinStrength == 0 and self.Vel.Magnitude < 1 then
		self.PinStrength = self.Mass;
	end
	if self.Age > self.Lifetime - 17 * (1 + self.WoundCount) then
		self:GibThis();
	end
end