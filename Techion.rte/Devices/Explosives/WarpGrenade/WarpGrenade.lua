function Create(self)
	self.fuzeDelay = 3500;
end
function Update(self)
	if self.fuze then
		--Trail effect
		local part = CreateMOPixel("Warp Flicker");
		part.Pos = self.Pos;
		part.Vel = self.Vel;
		part.Lifetime = 10;
		MovableMan:AddParticle(part);
		
		if self.fuze:IsPastSimMS(self.fuzeDelay) then

			local effect = CreateMOSRotating("Warp Grenade Effect", "Techion.rte");
            effect.Pos = self.Pos;
            MovableMan:AddParticle(effect);
            effect:GibThis();
  
            if MovableMan:IsActor(self.holder) then

				local effect = CreateMOSRotating("Warp Grenade Effect", "Techion.rte");
				effect.Pos = self.holder.Pos;
				MovableMan:AddParticle(effect);
				effect:GibThis();

				self.holder.Pos = self.Pos + Vector(0, -self.holder.Radius * 1.5);
				self.holder:FlashWhite(200);
				--Telefrag! Kill actors if you teleport directly on top of them
				for actor in MovableMan.Actors do
					if actor.Team ~= self.holder.Team then
						local dist = SceneMan:ShortestDistance(self.holder.Pos, actor.Pos, SceneMan.SceneWrapsX);
						if dist.Magnitude < 5 + (self.holder.Radius/2) then
							if (self.holder.Mass * 2) > actor.Mass then
								self.holder.Vel = self.holder.Vel + Vector(dist.X, dist.Y):SetMagnitude(1) + Vector(0, -1);
								actor:GibThis();
							end
						end
					end
				end
				if not self.holder:HasObject(self.PresetName) then
					self.holder:AddInventoryItem(CreateTDExplosive(self.PresetName));
				end
				self.ToDelete = true;
            else
				self:GibThis();
			end
		elseif self.ToDelete then
			if MovableMan:IsActor(self.holder) then
				local effect = CreateMOSRotating("Warp Grenade Effect", "Techion.rte");
          		effect.Pos = self.holder.Pos;
				MovableMan:AddParticle(effect);
				effect:GibThis();
				
				self.holder.ToDelete = true;
			end
		end
	elseif self:IsActivated() then
		--Get the holder
		if (self.holder and self.holder.ID == rte.NoMOID) or self.holder == nil then
			local newHolder = MovableMan:GetMOFromID(self.RootID);
			if MovableMan:IsActor(newHolder) then
				self.holder = ToActor(newHolder);
			end
		end
		self.fuze = Timer();
	end
end