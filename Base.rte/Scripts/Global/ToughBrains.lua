function ToughBrainsScript:StartScript()
	self.multiplier = 3;
end
function ToughBrainsScript:UpdateScript()
	for actor in MovableMan.Actors do
		if actor:IsInGroup("Brains") and not actor:NumberValueExists("ToughBrainsScript") then
			actor:SetNumberValue("ToughBrainsScript", 1);
			actor.GibWoundLimit = actor.GibWoundLimit * self.multiplier;
			actor.GibImpulseLimit = actor.GibImpulseLimit * self.multiplier;
			local parts = {};
			if IsAHuman(actor) then
				local human = ToAHuman(actor);
				human.GibWoundLimit = human.GibWoundLimit * self.multiplier;
				human.GibImpulseLimit = human.GibImpulseLimit * self.multiplier;
				parts = {human.Head, human.FGArm, human.BGArm, human.FGLeg, human.BGLeg};
			end
			if IsACrab(actor) then
				local crab = ToACrab(actor);
				crab.GibWoundLimit = crab.GibWoundLimit * self.multiplier;
				crab.GibImpulseLimit = crab.GibImpulseLimit * self.multiplier;
				parts = {crab.Turret, crab.RFGLeg, crab.RBGLeg, crab.LFGLeg, crab.LBGLeg, crab.EquippedItem};
			end
			for i = 1, #parts do
				local part = parts[i];
				if part and IsAttachable(part) then
					part = ToAttachable(part);
					part.GibWoundLimit = part.GibWoundLimit * self.multiplier;
					part.JointStrength = part.JointStrength * self.multiplier;
					for att in part.Attachables do
						att.GibWoundLimit = att.GibWoundLimit * self.multiplier;
						att.JointStrength = att.JointStrength * self.multiplier;
					end
				end
			end
		end
	end
end