function Create(self)	
	--Get the target from Sharpness.
	for id = 1, MovableMan:GetMOIDCount() - 1 do
		local mo = MovableMan:GetMOFromID(id);
		if mo and mo.UniqueID == self.Sharpness then
			self.target = mo;
			break;
		end
	end
	
	if self.target then
		--Current number of damage pulses.
		self.pulses = 0;
		
		--Maximum number of damage pulses to go through before stopping.
		self.maxPulses = 15;
		
		--Chance of flickering each frame.
		self.flickerChance = 0.9;
		
		--Length of time between pulses of damage.
		self.damageTime = 300;
		
		--Timer for damage.
		self.damageTimer = Timer();
		
		--Offset information.
		self.Pos = self.Pos + self.Vel * rte.PxTravelledPerFrame;
		
		if self.target then
			self.targetOffset = SceneMan:ShortestDistance(self.target.Pos, self.Pos, true);
			self.hitAngle = self.target.RotAngle;
		else
			self.targetOffset = Vector();
			self.hitAngle = 0;
		end

		self:EnableEmission(true);
	end
end

function Update(self)
	if self.target and IsMOSRotating(self.target) and not self.target.ToDelete then
		self.Pos = self.target.Pos + Vector(self.targetOffset.X, self.targetOffset.Y):RadRotate(self.target.RotAngle - self.hitAngle);

		--Flicker.
		if math.random() <= self.flickerChance then
			local flicker = CreateMOPixel("Techion.rte/Nanobot Flicker");
			local offset = Vector(ToMOSprite(self.target):GetSpriteWidth() * RangeRand(-0.5, 0.5), ToMOSprite(self.target):GetSpriteHeight() * RangeRand(-0.5, 0.5)):RadRotate(self.target.RotAngle);
			flicker.Pos = self.target.Pos + offset;
			flicker.Vel = offset * (-0.1);
			MovableMan:AddParticle(flicker);
		end
		
		--Cause damage.
		if self.damageTimer:IsPastSimMS(self.damageTime + self.target.Material.StructuralIntegrity * 2) then

			if IsAttachable(self.target) then
				self.nextTarget = ToAttachable(self.target):GetParent();
				self.nextTargetOffset = ToAttachable(self.target).ParentOffset;
			end

			local woundName = ToMOSRotating(self.target):GetEntryWoundPresetName();
			if woundName ~= "" then
				local wound = CreateAEmitter(woundName);
				wound.EmitAngle = self.targetOffset.AbsRadAngle + RangeRand(-0.1, 0.1);
				ToMOSRotating(self.target):AddWound(wound, self.targetOffset + Vector(math.random(-1, 1), math.random(-1, 1)), true);
			end
			self.pulses = self.pulses + 1;
			self.damageTimer:Reset();
		end
		if self.pulses > self.maxPulses then
			self.ToDelete = true;
		end
	elseif self.nextTarget then
		self.target = self.nextTarget;
		self.targetOffset = self.nextTargetOffset;
		self.hitAngle = 0;

		self.nextTarget = nil;
	else
		self:GibThis();
	end
end