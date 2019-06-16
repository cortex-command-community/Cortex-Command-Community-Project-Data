function Create(self)
    --The number of goo particles available to pick from.
    self.gooCount = 6;
    
    --The range of the tool.
    self.range = 40;
    
    --The arc radius of the tool's beam.
    self.beamRadius = math.pi * 0.3;
    
    --The radial resolution of the beam.
    self.resolution = 0.05;
    
    --The chance of deconstructing a single particle.
    self.deconstructChance = 0.04;
end

function Update(self)
    if self:IsActivated() and not self:IsReloading() and self.RoundInMagCount > 0 then
        local aimAngle = self.RotAngle;
        if self.HFlipped then
            aimAngle = aimAngle + math.pi;
        end
        local aimVec = Vector(self.range, 0):RadRotate(aimAngle);
        local aimUp = Vector(aimVec.X, aimVec.Y):RadRotate(math.pi * 0.5):Normalize();
        local hitPos = Vector();
        
        --Cast rays in front of the gun.
        for i = -self.beamRadius * 0.5, self.beamRadius * 0.5, self.resolution do
            if math.random() < self.deconstructChance then
                if SceneMan:CastStrengthRay(self.MuzzlePos, Vector(aimVec.X, aimVec.Y):RadRotate(i), 1, hitPos, 0, 166, true) then
                    local remover = CreateMOSRotating("Techion.rte/Pixel Remover");
                    remover.Pos = hitPos;
                    MovableMan:AddParticle(remover);
                    remover:EraseFromTerrain();
                    
                    local piece = CreateMOPixel("Techion.rte/Nanogoo " .. math.random(1, self.gooCount));
                    piece.Pos = hitPos;
                    MovableMan:AddParticle(piece);
                    piece.ToSettle = true;
                    
                    local glow = CreateMOPixel("Pixel Creation Glow","Constructor.rte");
                    glow.Pos = hitPos;
                    MovableMan:AddParticle(glow);
                end
            end
        end
    end
end