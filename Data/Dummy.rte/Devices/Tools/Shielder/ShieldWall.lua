function Create(self)
	self.glow = CreateMOPixel("Shielder Wall Glow", "Dummy.rte");
	self.glow.Pos = self.Pos;
	self.glow.EffectRotAngle = self.RotAngle;
	MovableMan:AddParticle(self.glow);
	self.glowID = self.glow.UniqueID;
	
	self.soundEffect = CreateSoundContainer("Shielder Wall Sound", "Dummy.rte");
	self.soundEffect.Pos = self.Pos;
	self.soundEffect:Play();
	
	self.AngularVel = 0;
end
function Update(self)
	if self.glow and self.glow.UniqueID == self.glowID then
		self.glow.Pos = self.Pos;
		if self.AngularVel ~= 0 then
			self.glow.EffectRotAngle = self.RotAngle;
		end
		--To-do: add flicker
	else
		self.glow = nil;
	end

	self.AngularVel = 0;

	if self.PinStrength == 0 and self.Vel.Magnitude < 1 then
		self.PinStrength = self.Mass;
	else
		self.Vel = Vector();
	end
	if self.Age > self.Lifetime - 30 * (1 + self.WoundCount) then
		self:GibThis();
	end
end
function Destroy(self)
	if self.glow then
		self.glow.ToDelete = true;
	end
	if self.soundEffect then
		self.soundEffect:Stop();
	end
end