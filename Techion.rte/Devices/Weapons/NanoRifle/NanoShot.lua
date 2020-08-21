function Create(self)
   --Collide with objects and deploy the destroy effect.
   self.CheckCollision = function(vel)
      local Trace = vel * rte.PxTravelledPerFrame;
      local moid = SceneMan:CastMORay(self.Pos, Trace, rte.NoMOID, self.Team, rte.airID, true, 1);
      if moid > 0 and moid < rte.NoMOID then
         local hitPos = Vector();
         SceneMan:CastFindMORay(self.Pos, Trace, moid, hitPos, rte.airID, true, 1);
         self.deleteNextFrame = true;
         self.Vel = (SceneMan:ShortestDistance(self.Pos, hitPos, true)/TimerMan.DeltaTimeSecs)/GetPPM();

         local target = MovableMan:GetMOFromID(moid);
         if target then
            local destroy = CreateAEmitter("Nanobot Destroy Effect", "Techion.rte");
            destroy.Sharpness = target.UniqueID;
            destroy.Pos = hitPos + SceneMan:ShortestDistance(hitPos, target.Pos, true):SetMagnitude(3);
            destroy.Vel = target.Vel;
            MovableMan:AddParticle(destroy);
         end
      end
   end
   
   --Speed at which this can actually activate.
   self.speedThreshold = 100;

   self.deleteNextFrame = false;
   --Check backward.
   self.CheckCollision(Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi));
end

function Update(self)
   if self.deleteNextFrame then
      self.ToDelete = true;
   elseif self.Vel.Magnitude >= self.speedThreshold then
      --Check forward.
      self.CheckCollision(self.Vel);
   end
end