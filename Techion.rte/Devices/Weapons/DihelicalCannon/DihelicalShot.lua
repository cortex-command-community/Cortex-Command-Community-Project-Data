function Create(self)
    --Range of the shot.
    self.range = 400;
    
    --Amplitude of the wave.
    self.maxAmplitude = 7;
    
    --Wavelength of the wave.
    self.waveLength = 40;
    
    --Speed of the wave (pixels per second).
    self.speed = 400;
    
    --Speed of damage particles.
    self.damageSpeed = 50;

    --Interval at which to create damage particles.
    self.damageInterval = 3;
    
    --Interval at which to create big glows.
    self.bigGlowInterval = 50;
    
    --Maximum strength for material penetration.
    self.strengthThreshold = 70;
    
    --Direction of the wave.
    self.direction = Vector(self.Vel.X, self.Vel.Y);
    self.direction:SetMagnitude(1);
    self.up = Vector(self.direction.X, self.direction.Y);
    self.up:RadRotate(math.pi * 0.5);
    
    --Timer for the wave.
    self.timer = Timer();
    
    --The last starting position along the line.
    self.lastI = 0;
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
        local amplitude = math.sin((i / self.waveLength) * 2 * math.pi) * self.maxAmplitude;
        local waveOffset = Vector(self.up.X, self.up.Y);
        waveOffset:SetMagnitude(amplitude);
        if amplitude < 0 then
            waveOffset = waveOffset:RadRotate(math.pi);
        end
        
        local linePos = self.Pos + Vector(self.direction.X, self.direction.Y):SetMagnitude(i);
        local upPos = linePos + waveOffset;
        local downPos = linePos - waveOffset;
        local fireVector = Vector(self.direction.X, self.direction.Y):SetMagnitude(self.damageSpeed);
        
        --Cancel the beam if there's a terrain collision.
        local trace = Vector(fireVector.X, fireVector.Y):SetMagnitude(5);
        if SceneMan:CastStrengthRay(upPos, trace, self.strengthThreshold, Vector(), 0, 0, true)
        or SceneMan:CastStrengthRay(downPos, trace, self.strengthThreshold, Vector(), 0, 0, true) then
            self.ToDelete = true;
            break;
        end
        
        --Add the upper particles.
        local upperMatter = SceneMan:GetTerrMatter(upPos.X, upPos.Y);
        if upperMatter == 0 then
            --Add the blue wave effect.
            local partA = CreateMOPixel("Techion.rte/Dihelical Cannon Effect Particle");
            partA.Pos = upPos;
            MovableMan:AddParticle(partA);
            
            --Add the wave front effect.
            local frontA = CreateMOPixel("Techion.rte/Dihelical Cannon Front Effect Particle");
            frontA.Pos = upPos;
            MovableMan:AddParticle(frontA);
            
            if i % self.damageInterval == 0 then
                --Check for a target.
                if SceneMan:CastMORay(upPos, fireVector * TimerMan.DeltaTimeSecs * 20, 255, self.Team, 0, true, 3) ~= rte.NoMOID then
                    --Add the damage particle.
                    local damageA = CreateMOPixel("Techion.rte/Dihelical Damage Particle");
                    damageA.Pos = upPos;
                    damageA.Vel = fireVector;
                    damageA.Team = self.Team;
                    MovableMan:AddParticle(damageA);
                    
                    --Add the dissipate effect.
                    local effect = CreateAEmitter("Techion.rte/Laser Dissipate Effect");
                    effect.Pos = upPos;
                    MovableMan:AddParticle(effect);
                    effect:GibThis();
                end
            end
        end
        
        --Add the lower particles.
        local lowerMatter = SceneMan:GetTerrMatter(downPos.X, downPos.Y);
        if lowerMatter == 0 then
            --Add the blue wave effect.
            local partB = CreateMOPixel("Techion.rte/Dihelical Cannon Effect Particle");
            partB.Pos = downPos;
            MovableMan:AddParticle(partB);
            
            --Add the wave front effect.
            local frontB = CreateMOPixel("Techion.rte/Dihelical Cannon Front Effect Particle");
            frontB.Pos = downPos;
            MovableMan:AddParticle(frontB);
            
            if i % self.damageInterval == 0 then
                local fireVector = Vector(self.direction.X, self.direction.Y):SetMagnitude(self.damageSpeed);
                --Check for a target.
                if SceneMan:CastMORay(downPos, fireVector * TimerMan.DeltaTimeSecs * 20, 255, self.Team, 0, true, 3) ~= rte.NoMOID then
                    --Add the damage particle.
                    local damageB = CreateMOPixel("Techion.rte/Dihelical Damage Particle");
                    damageB.Pos = downPos;
                    damageB.Vel = fireVector;
                    damageB.Team = self.Team;
                    MovableMan:AddParticle(damageB);
                    
                    --Add the dissipate effect.
                    local effect = CreateAEmitter("Techion.rte/Laser Dissipate Effect");
                    effect.Pos = downPos;
                    MovableMan:AddParticle(effect);
                    effect:GibThis();
                end
            end
        end
        
        --Add the big glow.
        if i % self.bigGlowInterval == 0 then
            --Add the blue wave effect.
            local glow = CreateMOPixel("Techion.rte/Dihelical Cannon Large Effect Particle");
            glow.Pos = linePos;
            MovableMan:AddParticle(glow);
        end
    end
    
    self.lastI = endPoint;
end