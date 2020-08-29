--This MOPixel handles the Actor-disintegrating effect of Techion weapons
function Create(self)
	self.effectSpeed = 0.01;
	self.setScale = 1;
	self.minScale = 0.1;
	
	local target;
	local strength = math.random(self.PinStrength * 0.5, self.PinStrength);
	--Get assigned target from Sharpness because MOPixels cannot carry NumberValues
	if self.Sharpness ~= rte.NoMOID and self.Sharpness >= 0 then
		target = MovableMan:GetMOFromID(self.Sharpness);
	--[[Alternative: find suitable target from nearby
	else
		local dist = Vector();
		local actor = MovableMan:GetClosestEnemyActor(self.Team, self.Pos, strength, dist);
		if actor then
			local sizeEstimate = (actor.Height + actor.Diameter)/3;
			if dist.Magnitude < sizeEstimate and sizeEstimate < 50 then
				target = ToActor(actor);
				strength = strength/math.sqrt(dist.Magnitude);
			end
		end]]--
	end
	if target and IsActor(target) and target.ID ~= rte.NoMOID then
		local actor = ToActor(target);
		local size = actor.Radius;
		local parts = {actor};
		for att in actor.Attachables do
			if IsAttachable(att) then
				local newRadius = SceneMan:ShortestDistance(actor.Pos, att.Pos, SceneMan.SceneWrapsX).Magnitude + att.Radius;
				if newRadius > size then
					size = newRadius;
				end
				table.insert(parts, att);
			end
		end
		--Elaborate effect resistance strength calculations based on various Actor values
		local resistance = ((actor.Mass + size + actor.Material.StructuralIntegrity) * 0.3 + (actor.TotalWoundLimit - actor.TotalWoundCount) + actor.Health) * 0.5;
		if resistance - strength < 0 then
			--Leave this Actor alone if it already has a disintegrator particle assigned to it
			if ToActor(target):NumberValueExists("ToDisintegrate") then
				self.ToDelete = true;
			else
				self.target = actor;
				if IsAHuman(target) then
					self.target = ToAHuman(target);
				elseif IsACrab(target) then
					self.target = ToACrab(target);
				end
				self.target.Health = self.target.Health - self.target.MaxHealth;
				self.target:RemoveAnyRandomWounds(self.target.TotalWoundCount + 1);
				self.target.MissionCritical = true;	--This ensures that the target Actor doesn't settle during the effect
				self.target.HitsMOs = false;
				self.target.AngularVel = self.target.AngularVel * 0.5 - self.target.Vel.X + self.target.FlipFactor;
				
				AudioMan:PlaySound("Techion.rte/Devices/Shared/Sounds/Disintegrate".. math.random(3) ..".wav", self.target.Pos);
			end
			--Flag this actor as being hit by a disintegrator particle
			ToActor(target):SetNumberValue("ToDisintegrate", ToActor(target):GetNumberValue("ToDisintegrate") + 1);
			--Additional glow effects
			for _, mo in pairs(parts) do
				local glowDiameter = math.min(math.floor(1 + (mo.Diameter * mo.Scale) * 0.1) * 10, 50);
				local glow = CreateMOPixel("Techion.rte/Disintegration Glow ".. glowDiameter);
				glow.Pos = mo.Pos;
				glow.Vel = mo.Vel;
				MovableMan:AddParticle(glow);
			end
		end
	end
end
function Update(self)
	if self.target and self.target.ID ~= rte.NoMOID then
	
		self.target.ToSettle = false;
		self.target.Vel = (self.target.Vel * 0.9) - (SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs);
		self.target.AngularVel = self.target.AngularVel * 0.5;
		
		self.target.GlobalAccScalar = self.target.GlobalAccScalar * (1 - 1/(math.abs(self.target.Mass) + 1));
		self.target:FlashWhite(10);
		
		self.target:RemoveWounds(self.target.GibWoundLimit);
		
		local flag = self.target:GetNumberValue("ToDisintegrate");
		local parts = {self.target};
		
		if self.target.EquippedItem then
			table.insert(parts, ToMOSRotating(self.target.EquippedItem));
			for att in ToMOSRotating(self.target.EquippedItem).Attachables do
				if IsAttachable(att) then
					att.Scale = self.setScale;
				end
			end
		end
		--Offset several Attachables in a floating fashion
		for mo in self.target.Attachables do
			table.insert(parts, mo);
			local totalAttSize = mo.Radius;
			local inverseScale = 1 - self.setScale;
			mo:RemoveWounds(1);

			for att in mo.Attachables do
				table.insert(parts, att);
				att.Scale = self.setScale;
				totalAttSize = (totalAttSize + att.Radius) * 0.9;
				att.ParentOffset = Vector(att.ParentOffset.X + RangeRand(-0.6, 0.6), att.ParentOffset.Y + RangeRand(-0.6, 0.6)):SetMagnitude(att.ParentOffset.Magnitude + RangeRand(0, 0.6) * inverseScale);
				att.Pos = att.Pos - Vector(0, 100/att.Radius * inverseScale);

				for attAtt in att.Attachables do
					attAtt.Scale = self.setScale;
					totalAttSize = (totalAttSize + attAtt.Radius) * 0.9;
					attAtt.ParentOffset = Vector(attAtt.ParentOffset.X + RangeRand(-0.9, 0.9), attAtt.ParentOffset.Y + RangeRand(-0.9, 0.9)):SetMagnitude(attAtt.ParentOffset.Magnitude + RangeRand(0, 0.9) * inverseScale);
					attAtt.Pos = attAtt.Pos - Vector(0, 100/attAtt.Radius * inverseScale);
				end
			end
			mo.ParentOffset = Vector(mo.ParentOffset.X + RangeRand(-0.3, 0.3), mo.ParentOffset.Y + RangeRand(-0.3, 0.3)):SetMagnitude(mo.ParentOffset.Magnitude + RangeRand(0, 0.3) * inverseScale);
			mo.Pos = mo.Pos - Vector(0, 100/mo.Radius * inverseScale);
			if totalAttSize == mo.Radius then
				mo.RotAngle = mo.RotAngle + (mo.FlipFactor * inverseScale) * 0.5;
			end
			--Induce randomized deletion
			if (totalAttSize * self.setScale) < math.random(3) then
				mo.ToDelete = true;
			end
		end
		--Shrink all found parts and add particle effects
		for _, mo in pairs(parts) do
			mo.Scale = self.setScale;
			local radius = math.sqrt(mo.Radius * mo.Scale) * math.sqrt(flag);
			if mo.WoundCount > 1 then
				mo.ToDelete = true;
				radius = radius * 2;
			end
			for i = 1, radius do
				if math.random(radius) > i then
									
					local piece = CreateMOSParticle("Techion.rte/White Goo Particle");
					if math.random() < 0.3 then
						piece = CreateMOPixel("Techion.rte/Nanogoo " .. math.random(6));
					end
					local offset = Vector(mo.Radius * mo.Scale * RangeRand(0, 0.5), 0):RadRotate(6.28 * math.random());
					piece.Pos = mo.Pos + offset;
					piece.Vel = mo.Vel + offset:SetMagnitude(RangeRand(radius, radius * 2)/math.sqrt(1 + offset.Magnitude));
					piece.Lifetime = (piece.Lifetime * math.sqrt(flag)) * RangeRand(0.1, 1.0);
					piece.AirResistance = piece.AirResistance * RangeRand(0.1, 1.0);
					piece.GlobalAccScalar = piece.GlobalAccScalar * RangeRand(0.1, 1.0);
					MovableMan:AddParticle(piece);
				end
			end
		end
		self.setScale = self.setScale - (self.effectSpeed * flag);
		if self.setScale < self.minScale then

			self.target.ToDelete = true;
		end
	else
		self.ToDelete = true;
	end
end