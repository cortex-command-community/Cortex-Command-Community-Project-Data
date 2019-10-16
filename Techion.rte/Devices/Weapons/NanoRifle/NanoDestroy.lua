function Create(self)	
	--Get the target from Sharpness.
	for id = 1, MovableMan:GetMOIDCount()-1 do
		local MO = MovableMan:GetMOFromID(id);
		if MO and MO.UniqueID == self.Sharpness then
			self.target = MO;
			break;
		end
	end
	
	if self.target then
		--Current number of damage pulses.
		self.pulses = 0;
		
		--Number of damage pulses to go through before stopping.
		self.maxPulses = 10;
		
		--Chance of flickering each frame.
		self.flickerChance = 0.9;
		
		--Length of time between pulses of damage.
		self.damageTime = 300;
		
		--Speed of a damage particle.
		self.damageSpeed = 100;
		
		--Timer for damage.
		self.damageTimer = Timer();
		
		--Offset information.
		self.Pos = self.Pos + self.Vel * TimerMan.DeltaTimeSecs * 20;
		
		if self.target then
			self.targetOffset = SceneMan:ShortestDistance(self.target.Pos, self.Pos, true);
			self.hitAngle = self.target.RotAngle;
		else
			self.targetOffset = Vector()
			self.hitAngle = 0;
		end
		
		self:EnableEmission(true);
	end
end

function Update(self)
	if self.target and self.target.ID ~= rte.NoMOID then
		self.Pos = self.target.Pos + Vector(self.targetOffset.X, self.targetOffset.Y):RadRotate(self.target.RotAngle - self.hitAngle);
		
		--Flicker.
		if math.random() <= self.flickerChance then
			local flicker = CreateMOPixel("Techion.rte/Nanobot Flicker");
			flicker.Pos = self.Pos + Vector(self.target.Radius * 0.7, 0):RadRotate(2 * math.pi * math.random());
			flicker.Vel = Vector(1, 0):RadRotate(2 * math.pi * math.random());
			MovableMan:AddParticle(flicker);
		end
		
		--Cause damage.
		if self.damageTimer:IsPastSimMS(self.damageTime) then
			local damage = CreateMOPixel("Techion.rte/Nanobot Damage");
			damage.Pos = self.Pos;
			damage.Vel = Vector(self.damageSpeed, 0):RadRotate(2 * math.pi * math.random());
			MovableMan:AddParticle(damage);
			
			self.pulses = self.pulses + 1;
			self.damageTimer:Reset();
		end
		
		if self.pulses > self.maxPulses then
			self.ToDelete = true;
		end
	else
		self:GibThis();
	end
end