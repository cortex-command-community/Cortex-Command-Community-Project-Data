function Create(self)
    --Range of the shot.
    self.range = 600;
    
    --Amplitude of the wave.
    self.maxAmplitude = math.floor(1 + math.sqrt(self.Vel.Magnitude) + 0.5);
    
    --Wavelength of the wave.
    self.flaceLength = math.floor(5 + math.sqrt(self.Vel.Magnitude) + 0.5);
	
	--Track intersecting beams
	self.lastAmplitude = 1;
    
    --Speed of the wave (pixels per second).
    self.speed = self.Vel.Magnitude * 10;
	
    --Speed of damage particles.
    self.damageSpeed = 50 + self.Vel.Magnitude * 0.1;

    --Maximum strength for material penetration (both MOs and terrain).
    self.strengthThreshold = 50 + self.Vel.Magnitude * 0.3;
    
    --Direction of the wave.
    self.direction = Vector(self.Vel.X, self.Vel.Y);
    self.direction:SetMagnitude(1);
    self.up = Vector(self.direction.X, self.direction.Y);
    self.up:RadRotate(math.pi * 0.5);
    
    --Interval at which to create damage particles.
    self.damageInterval = 3;
    
    --Timer for the wave.
    self.timer = Timer();
    
    --The last starting position along the line.
    self.lastI = 0;

    --Count MO and terrain hits.
    self.hits = 0;

    --Amount of damage pixels.
    self.damageStrength = math.floor(math.sqrt(self.Vel.Magnitude * 0.1) + 0.5);
	
	--Disintegration strength.
	self.disintegrationStrength = 50;
end

function Update(self)

    local endPoint = self.timer.ElapsedSimTimeS * self.speed;
    if endPoint > self.range then
        endPoint = self.range;
        self.ToDelete = true;
    else
        self.ToDelete = false;
        self.ToSettle = false;
    end
    endPoint = math.floor(endPoint);
	
    --Draw out the path.
    for i = self.lastI, endPoint, 1 do
        local amplitude = math.sin((i/self.flaceLength) * 2 * math.pi) * self.maxAmplitude;
        local waveOffset = Vector(self.up.X, self.up.Y);
        waveOffset:SetMagnitude(amplitude);
        
        local linePos = self.Pos + Vector(self.direction.X, self.direction.Y):SetMagnitude(i * 2);
        local fireVector = Vector(self.direction.X, self.direction.Y):SetMagnitude(self.damageSpeed);
        local upPos = linePos + waveOffset;
        local downPos = linePos - waveOffset * 0.2;
        
        --Cancel the beam if there's a terrain collision.
        local trace = Vector(fireVector.X, fireVector.Y):SetMagnitude(self.damageSpeed * 0.1);

		local strSumRay = SceneMan:CastStrengthSumRay(downPos, downPos + trace, 1, 160);
		self.hits = self.hits + math.sqrt(strSumRay);

		if SceneMan:GetTerrMatter(upPos.X, upPos.Y) == rte.airID then
			--Add the blue wave effect.
			local partA = CreateMOPixel("Techion.rte/Dihelical Cannon Effect Particle");
			partA.Pos = upPos;
			partA.Vel = (fireVector * 0.5 - waveOffset) * 0.2;
			MovableMan:AddParticle(partA);
			
			--Add the wave front effect.
			local frontA = CreateMOPixel("Techion.rte/Dihelical Cannon Front Effect Particle");
			frontA.Pos = upPos;
			frontA.Vel = (fireVector * 0.5 - waveOffset) * 0.2;
			MovableMan:AddParticle(frontA);
		end
		if i % self.damageInterval == 0 then
			--Check for a target.
			local moRay = SceneMan:CastMORay(upPos, fireVector * rte.PxTravelledPerFrame, rte.NoMOID, self.Team, rte.airID, true, 3);
			if moRay ~= rte.NoMOID then
				--Add the damage particle.
				for i = 1, self.damageStrength do
					local damageA = CreateMOPixel("Techion.rte/Dihelical Damage Particle");
					damageA.Pos = upPos;
					damageA.Vel = fireVector;
					damageA.Team = self.Team;
					damageA.IgnoresTeamHits = true;
					MovableMan:AddParticle(damageA);
				end
				--Add the dissipate effect.
				local effect = CreateAEmitter("Techion.rte/Laser Dissipate Effect");
				effect.Pos = upPos;
				MovableMan:AddParticle(effect);
				effect:GibThis();
				
				self.hits = self.hits + 1;
			end
		end
		--Add the blue wave effect.
		local partB = CreateMOPixel("Techion.rte/Dihelical Cannon Effect Particle");
		partB.Pos = downPos;
		partB.Vel = (fireVector + waveOffset) * 0.04;
		MovableMan:AddParticle(partB);
		
		--Add the wave front effect.
		local frontB = CreateMOPixel("Techion.rte/Dihelical Cannon Front Effect Particle");
		frontB.Pos = downPos;
		frontB.Vel = (fireVector + waveOffset) * 0.04;
		MovableMan:AddParticle(frontB);
		
		if i % self.damageInterval == 0 then
			local fireVector = Vector(self.direction.X, self.direction.Y):SetMagnitude(self.damageSpeed);
			--Check for a target.
			local moRay = SceneMan:CastMORay(downPos, fireVector * rte.PxTravelledPerFrame, rte.NoMOID, self.Team, rte.airID, true, 3);
			if moRay ~= rte.NoMOID then
				--Add the damage particles.
				local mo = MovableMan:GetMOFromID(moRay);
				local rootMO = MovableMan:GetMOFromID(mo.RootID);
				if IsActor(rootMO) then
					local melt = CreateMOPixel("Disintegrator");
					melt.Pos = downPos;
					melt.Team = self.Team;
					melt.Sharpness = ToActor(rootMO).ID;
					melt.PinStrength = self.disintegrationStrength;
					MovableMan:AddMO(melt);
				end
				self.hits = self.hits + math.sqrt(mo.Material.StructuralIntegrity) + math.sqrt(mo.Radius + mo.Mass) * 0.1;
				
				for i = 1, self.damageStrength do
					local damageB = CreateMOPixel("Techion.rte/Dihelical Damage Particle");
					damageB.Pos = downPos;
					damageB.Vel = fireVector;
					damageB.Team = self.Team;
					damageB.IgnoresTeamHits = true;
					MovableMan:AddParticle(damageB);
				end
				--Add the dissipate effect.
				local effect = CreateAEmitter("Techion.rte/Laser Dissipate Effect");
				effect.Pos = downPos;
				MovableMan:AddParticle(effect);
				effect:GibThis();
			end
		end
		if (self.lastAmplitude > 0 and amplitude < 0) or (self.lastAmplitude < 0 and amplitude > 0) then

			local part = CreateMOPixel("Techion.rte/Dihelical Cannon Large Effect Particle");
			part.Pos = linePos - Vector(self.direction.X, self.direction.Y):SetMagnitude(2);
			part.Vel = fireVector * 0.1;
			MovableMan:AddParticle(part);
		end
		self.lastAmplitude = amplitude;
		if self.hits > self.strengthThreshold then

            local effect = CreateAEmitter("Techion.rte/Dihelical Cannon Impact Particle");
            effect.Pos = linePos - Vector(self.direction.X, self.direction.Y):SetMagnitude(2);
			effect.Team = self.Team;
			effect.IgnoresTeamHits = true;
            MovableMan:AddParticle(effect);

            self.ToDelete = true;
			break;
		else
			self.hits = self.hits * 0.9;
		end
		self.flaceLength = self.flaceLength * (1 + 0.05/self.flaceLength);
		self.maxAmplitude = self.flaceLength * 0.5;
    end
    self.lastI = endPoint;
end