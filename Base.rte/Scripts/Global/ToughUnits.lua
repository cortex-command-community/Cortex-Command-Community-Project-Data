function ToughUnitsScript:StartScript()
	self.multiplier = 2;
end
function ToughUnitsScript:UpdateScript()
	for actor in MovableMan.AddedActors do
		if not actor:NumberValueExists("ToughUnitsScript") then
			if IsAHuman(actor) or IsACrab(actor) then
				self:DeployEffect(actor);
			else
				for i = 1, actor.InventorySize do
					local item = actor:Inventory();
					if IsActor(item) then
						self:DeployEffect(ToActor(item));
					end
					actor:SwapNextInventory(item, true);
				end
			end
		end
	end
end
function ToughUnitsScript:DeployEffect(actor)
	actor:SetNumberValue("ToughUnitsScript", 1);
	actor.GibWoundLimit = actor.GibWoundLimit * self.multiplier;
	actor.GibImpulseLimit = actor.GibImpulseLimit * self.multiplier;
	for limb in actor.Attachables do
		limb.GibWoundLimit = limb.GibWoundLimit * self.multiplier;
		limb.JointStrength = limb.JointStrength * self.multiplier;
		for att in limb.Attachables do
			att.GibWoundLimit = att.GibWoundLimit * self.multiplier;
			att.JointStrength = att.JointStrength * self.multiplier;
		end
	end
end