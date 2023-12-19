-- This script incorporates Filipawn Industries code and the vanilla burstfire script together
-- There is likely better ways of doing a lot of this, potentially even standardizing it so it can be easily used more widely

function OnFire(self)

	self.FireTimer:Reset();
	CameraMan:AddScreenShake(5, self.Pos);
	
end

function OnReload(self)

	self.reloadToSmoke = true;
	self.reloadSmokeTimer:Reset();
	
end

function Create(self)

	-- self.servoLoopSound = CreateSoundContainer("Coalition Bunker Cannon Servo Loop", "Coalition.rte");
	-- self.servoLoopSound.Volume = 0;
	-- self.servoLoopSound.Pitch = 1;
	-- self.servoLoopSound:Play(self.Pos);
	
	self.Shot = CreateMOSRotating("Flak Shell Browncoat AA-50", "Browncoats.rte");

	self.FireTimer = Timer();
	
	self.reloadSmokeTimer = Timer();
	
	self.rotationSpeed = 0.10;
	self.smoothedRotAngle = self.RotAngle;
	self.InheritedRotAngleTarget = 0;
	
	if self:NumberValueExists("KeepUnflipped") then
		self.keepFlipped = true;
	else
		self.keepFlipped = false;
	end
	

end

function Update(self)

	--self.servoLoopSound.Pos = self.Pos;

	self.HFlipped = self.keepFlipped;
	
	self.parent = IsActor(self:GetRootParent()) and ToActor(self:GetRootParent()) or nil;
	
	self.playerControlled = (self.parent and self.parent:IsPlayerControlled()) and true or false;
	
	-- reticule of actual aim line so the gun feels cannon-y rather than unresponsive
	
	if self.playerControlled and self.parent.SharpAimProgress > 0.13 then
		for i = 1, 24 do
			if i % 3 == 0 then
				local dotVec = Vector(i*self.FlipFactor, 0):RadRotate(self.RotAngle) + self.Pos + Vector((self.SharpLength + 15) * self.FlipFactor, 0):RadRotate(self.RotAngle)*self.parent.SharpAimProgress;
				PrimitiveMan:DrawLinePrimitive(dotVec, dotVec, 116, 2);
			end
		end
	end
	-- rotation smoothing, for a cannon-y feel:
	
	if self.smoothedRotAngle ~= self.RotAngle then
		self.smoothedRotAngle = self.smoothedRotAngle - (self.rotationSpeed * (self.smoothedRotAngle - self.RotAngle));
	end
	
	-- self.servoLoopSoundVolumeTarget = 0 + math.abs(self.smoothedRotAngle - self.RotAngle)
	-- self.servoLoopSound.Volume = self.servoLoopSound.Volume - (0.5 * (self.servoLoopSound.Volume - self.servoLoopSoundVolumeTarget));
	-- self.servoLoopSoundPitchTarget = 1 + math.abs(self.smoothedRotAngle - self.RotAngle)
	-- self.servoLoopSound.Pitch = self.servoLoopSound.Pitch - (0.1 * (self.servoLoopSound.Pitch - self.servoLoopSoundPitchTarget));
	
	self.InheritedRotAngleOffset = self.smoothedRotAngle - self.RotAngle;
	
	-- Mathemagical firing anim by filipex
	local f = math.max(1 - math.min((self.FireTimer.ElapsedSimTimeMS) / 200, 1), 0)
	self.Frame = math.floor(f * 8 + 0.55);


	if self.FiredFrame then
	
		local shot = self.Shot:Clone();
		shot.Pos = self.MuzzlePos;
		shot.Vel = self.Vel + Vector(160, 0):RadRotate(self.RotAngle);
		shot.Team = self.Team;
		shot.RotAngle = self.RotAngle;
		shot.HFlipped = self.HFlipped;
		MovableMan:AddParticle(shot);

	end
	
	if self:IsReloading() then
		-- manually timed according to sound
		if self.reloadToSmoke and self.reloadSmokeTimer:IsPastSimMS(900) then
			self.reloadToSmoke = false;
			
			for i = 1, 8 do
				local particle = CreateMOSParticle("Small Smoke Ball 1", "Base.rte");
				particle.GlobalAccScalar = 0.005
				particle.Lifetime = math.random(800, 2500);
				particle.Vel = self.Vel + Vector(math.random(-20, 20)/100, -math.random(-40, -30)/100);
				particle.Pos = self.Pos + Vector(-math.random(15, 17)*self.FlipFactor, math.random(-3, 3));
				MovableMan:AddParticle(particle);
			end
			
			for i = 1, 6 do
				local particle = CreateMOSParticle("Small Smoke Ball 1", "Base.rte");
				particle.GlobalAccScalar = 0.005
				particle.Lifetime = math.random(800, 2500);
				particle.Vel = self.Vel + Vector(math.random(-20, 20)/100, -math.random(-100, -30)/100);
				particle.Pos = self.Pos + Vector(-math.random(15, 17)*self.FlipFactor, math.random(-3, 3));
				MovableMan:AddParticle(particle);
			end	
			
		end
	end
	
end

function Destroy(self)

	self.servoLoopSound:Stop(-1);
	
end