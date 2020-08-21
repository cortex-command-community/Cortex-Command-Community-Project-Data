function Create(self)
	self.lifeTimer = Timer();
	self.lastAngle = self.RotAngle;
	self.firstAngle = self.RotAngle;
	self.AngularVel = 0;
	self.angleCorrectionRatio = 0.8;	-- from old script, idk if this means anything anymore
	self.toGib = false;
	self.toGibCounter = 0;
	
	self.dismemberTimer = Timer();
	self.length = ToMOSprite(self):GetSpriteWidth();
end
function Update(self)
	for i = 1, 2 do
		local part = CreateMOSParticle("Tiny Smoke Ball 1");
		local randomVec = Vector(math.random(3), 0):RadRotate(math.random() * (math.pi * 2));
		if randomVec.Magnitude < 1 then
			part = CreateMOSParticle("Small Smoke Ball 1");
		end
		part.Pos = self.Pos + randomVec;
		part.Vel = self.Vel/i + randomVec;
		MovableMan:AddParticle(part);
	end

	self.AngularVel = self.AngularVel * 0.99;
	self.Vel = self.Vel * 0.99;
	
	if self.lifeTimer:IsPastSimMS(3000) then
		self.angleCorrectionRatio = self.angleCorrectionRatio * 0.9;
	end

	local velFactor = math.sqrt(self.Vel.Magnitude);
	local posVector = Vector((self.length + velFactor) * self.FlipFactor, 0):RadRotate(self.RotAngle);

	local moCheck = SceneMan:CastMORay(self.Pos, posVector, self.ID, self.Team, rte.airID, true, 2);
	if moCheck ~= rte.NoMOID then
		local mo = MovableMan:GetMOFromID(moCheck);
		if mo then
			local moVelFactor = mo.Vel * (0.7 - 0.7/(math.sqrt(mo.Mass/self.Mass + 1)));
			self.Vel = self.Vel/math.sqrt(velFactor + 1) + moVelFactor + Vector(2/(velFactor + 1), 0):RadRotate(self.firstAngle);

			self.AngularVel = self.AngularVel * 0.9 + math.random(-1, 1);
			self.angleCorrectionRatio = self.angleCorrectionRatio - 0.02;
			--Count towards gib counter as well (the -1 revert still applies, making this net + 0.5)
			self.toGibCounter = self.toGibCounter + 1.5;
			for i = 1, velFactor do
				local randVel = Vector(velFactor, 0):RadRotate(math.random() * (math.pi * 2));
				local pix = CreateMOPixel("Ronin Chainsaw Saw Pixel ".. math.random(2));
				pix.Pos = self.Pos;
				pix.Vel = randVel + Vector((50 + velFactor) * self.FlipFactor, 0):RadRotate(self.RotAngle);
				MovableMan:AddParticle(pix);
			end
			if self.dismemberTimer:IsPastSimMS(200) then
				self.dismemberTimer:Reset();
				if IsAttachable(mo) and ToAttachable(mo):IsAttached() and not (IsHeldDevice(mo) or IsThrownDevice(mo)) then
					mo = ToAttachable(mo);
					local chances = 1/(math.sqrt(math.abs(mo.JointStrength) + 1));
					if math.random() < chances then
						mo.JointStrength = -1;
						mo.GetsHitByMOs = false;
					end
				end
			end
		end
	end
	if self.lifeTimer:IsPastSimMS(4000) then
		self.toGib = true;
	end
	if self.Vel.Magnitude < 2 then	--Countdown to explode if too still
		self.toGibCounter = self.toGibCounter + 1;
		local newVel = Vector(-3/(self.Vel.Magnitude + 1) * self.FlipFactor, 0):RadRotate(self.RotAngle + RangeRand(-1.5, 1.5));
		self.Vel = self.Vel + newVel;
	else
		self.toGibCounter = math.abs(self.toGibCounter - 1);	--Revert gib countdown
		if math.random() < self.angleCorrectionRatio then
			--Maintain straighter angle, making it easier to go through lots of objects
			self.AngularVel = self.AngularVel * 0.99 - (self.RotAngle - self.firstAngle);
			self.RotAngle = (self.RotAngle + self.Vel.AbsRadAngle + self.firstAngle)/3;
		end
	end
	if self.toGibCounter == 60 then	-- 60 frames still (or 90 inside a mo)
		self.toGib = true;
	end
	if self.toGib == true then
		local explosion = CreateMOSRotating("Ronin RPC Explosion");
		explosion.Pos = self.Pos;
		explosion:GibThis();
		MovableMan:AddParticle(explosion);
		self.ToDelete = true;
	else
		self.ToDelete = false;
	end
	self.lastAngle = self.RotAngle;
end