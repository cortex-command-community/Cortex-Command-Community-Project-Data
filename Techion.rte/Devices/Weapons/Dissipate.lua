function Create(self)
    --Speed at which this can dissipate energy.
    self.speedThreshold = 40;
    
    --Strength of material which will dissipate energy.
    self.strengthThreshold = 5;
    
    --Speed of the effect.
    self.effectSpeed = 4;
    
    --The shot effect.
    self.shotEffect = CreateMOSRotating("Techion.rte/Laser Shot Effect");
    self.shotEffect.Pos = self.Pos;
    self.shotEffect.Vel = self.Vel;
    MovableMan:AddParticle(self.shotEffect);
    
    --Check backward.
    local pos = Vector();
    local trace = Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi) * TimerMan.DeltaTimeSecs * 20;
    if SceneMan:CastObstacleRay(self.Pos, trace, pos, Vector(), 0, self.Team, 0, 5) >= 0 then
        --Check that the position is actually strong enough to cause dissipation.
        trace = SceneMan:ShortestDistance(self.Pos, pos, true);
        local strength = SceneMan:CastStrengthRay(self.Pos, trace, self.strengthThreshold, Vector(), 0, 0, true);
        local mo = SceneMan:CastMORay(self.Pos, trace, 0, self.Team, 0, true, 5);
        if strength or (mo ~= 255 and mo ~= 0) then
            local effect = CreateAEmitter("Techion.rte/Laser Dissipate Effect");
            effect.Pos = pos + Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi):SetMagnitude(3);
            effect.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi):SetMagnitude(self.effectSpeed);
            MovableMan:AddParticle(effect);
            effect:GibThis();
        end
    end
end

function Update(self)
    if not self.ToDelete then
        if self.Vel.Magnitude >= self.speedThreshold then
            --Collide with objects and deploy the dissipate effect.
            local pos = Vector();
            local trace = Vector(self.Vel.X, self.Vel.Y) * TimerMan.DeltaTimeSecs * 20;
            if SceneMan:CastObstacleRay(self.Pos, trace, pos, Vector(), 0, self.Team, 0, 5) >= 0 then
                --Check that the position is actually strong enough to cause dissipation.
                trace = SceneMan:ShortestDistance(self.Pos, pos, true);
                local strength = SceneMan:CastStrengthRay(self.Pos, trace, self.strengthThreshold, Vector(), 0, 0, true);
                local mo = SceneMan:CastMORay(self.Pos, trace, 0, self.Team, 0, true, 5);
                if strength or (mo ~= 255 and mo ~= 0) then
                    local effect = CreateAEmitter("Techion.rte/Laser Dissipate Effect");
                    effect.Pos = pos + Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi):SetMagnitude(3);
                    effect.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi):SetMagnitude(self.effectSpeed);
                    MovableMan:AddParticle(effect);
                    effect:GibThis();
                end
            end
        end
    end
    
    --Display the laser shot effect.
    if MovableMan:IsParticle(self.shotEffect) then
        if self.Vel.Magnitude >= self.speedThreshold then
            self.shotEffect.Pos = self.Pos;
            self.shotEffect.Vel = self.Vel;
            self.shotEffect.ToDelete = false;
        else
            self.shotEffect.ToDelete = true;
        end
    end
end

function Destroy(self)
    if MovableMan:IsParticle(self.shotEffect) then
        --Destroy the laser shot effect.
        self.shotEffect.ToDelete = true;
    end
end