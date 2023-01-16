--Self-healing script complete with animations, for AHuman use only
function Create(self)
	self.baseHealDelay = 500;
	self.PieMenu:AddPieSlice(CreatePieSlice("Self Heal"), self);
end

function Update(self)
	if self.EquippedItem or self.EquippedBGItem then
		self.healing = nil;
		self:RemoveNumberValue("SelfHeal");
	end
	if self.healing and self.healing.part then
		if self.healing.wound then
			if self.healing.timer:IsPastSimMS(self.healing.delay) then
				self.healing.timer:Reset();
				self.Health = math.min(self.Health + self.healing.wound.BurstDamage * math.sqrt(self.healing.part.DamageMultiplier), self.MaxHealth);
				self.healing.wound.ToDelete = true;
				self.healing.wound = nil;
				for wound in self.healing.part.Wounds do
					if not wound.ToDelete then
						self.healing.wound = wound;
						self.healing.delay = self.baseHealDelay * math.sqrt(self.healing.wound.Radius);
					end
				end
			else
				for state = 1, 15 do
					self.controller:SetState(state, false);
				end
				local timerRatio = self.healing.timer.ElapsedSimTimeMS/self.healing.delay;
				local arms = {self.FGArm, self.BGArm};
				for _, arm in pairs(arms) do
					if arm and self.healing.part.ID ~= arm.ID then
						local offset = SceneMan:ShortestDistance(arm.JointPos, self.healing.wound.Pos, SceneMan.SceneWrapsX) + Vector(-math.max(self.healing.wound.Radius - 2, 1), 0):RadRotate(math.pi * 4 * timerRatio);
						arm.HandPos = arm.JointPos + Vector(offset.X, offset.Y):SetMagnitude(math.min(offset.Magnitude, arm.MaxLength));
					end
				end
				self.healing.wound.Scale = math.min(self.healing.wound.Scale, self.healing.wound.Scale * (1 - timerRatio));
			end
		else
			self.healing = nil;
		end
		self.controller:SetState(Controller.BODY_CROUCH, true);
	elseif self:NumberValueExists("SelfHeal") then
		self.healing = {};
		local priority = self:GetWoundCount(false, false, false) * self.DamageMultiplier;
		self.healing.part = self;
		for wound in self.Wounds do
			self.healing.wound = wound;
		end
		for attachable in self.Attachables do
			if attachable.DamageMultiplier > 0 then
				local woundCount = attachable:GetWoundCount(false, false, false) * attachable.DamageMultiplier;
				if woundCount > priority then
					priority = woundCount;
					self.healing.part = attachable;
					for wound in attachable.Wounds do
						self.healing.wound = wound;
						break;
					end
				end
				--Find damage-transferring sub-attachables as well
				for attAttachable in attachable.Attachables do
					if attAttachable.DamageMultiplier > 0 then
						local woundCount = attAttachable:GetWoundCount(false, false, false) * attAttachable.DamageMultiplier;
						if woundCount > priority then
							priority = woundCount * attachable.DamageMultiplier;
							self.healing.part = attAttachable;
							for wound in attAttachable.Wounds do
								self.healing.wound = wound;
								break;
							end
						end
					end
				end
			end
		end
		if self.healing.part and self.healing.wound then
			self.healing.timer = Timer();
			self.healing.delay = self.baseHealDelay * math.sqrt(self.healing.wound.Radius);
			self:UnequipArms();
		else
			self.healing = nil;
			self:EquipFirearm(true);
			self:RemoveNumberValue("SelfHeal");
		end
	end
end

function WhilePieMenuOpen(self, openedPieMenu)
	openedPieMenu:GetFirstPieSliceByPresetName("Self Heal").Enabled = self.WoundCount > 0;
end

function SelfHeal(pieMenu, pieSlice, pieMenuOwner)
	if pieMenuOwner and IsAHuman(pieMenuOwner) then 
		pieMenuOwner = ToAHuman(pieMenuOwner);
		if pieMenuOwner.WoundCount > 0 then
			pieMenuOwner:SetNumberValue("SelfHeal", 1);
		else
			local errorSound = CreateSoundContainer("Error", "Base.rte");
			errorSound:Play(pieMenuOwner.Pos, pieMenuOwner:GetController().Player);
		end
	end
end