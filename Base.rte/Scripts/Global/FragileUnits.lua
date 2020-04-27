function FragileUnitsScript:UpdateScript()
	for actor in MovableMan.AddedActors do
		if not actor:NumberValueExists("FragileUnitsScript") then
			self:DeployEffect(actor);
			for i = 1, actor.InventorySize do
				local item = actor:Inventory();
				self:DeployEffect(item);
				actor:SwapNextInventory(item, true);
			end
		end
	end
end
function FragileUnitsScript:DeployEffect(actor)
	if IsAHuman(actor) or IsACrab(actor) then
		actor = ToActor(actor);
		actor.MaxHealth = 1000;
		actor.Health = actor.MaxHealth;
		actor:SetNumberValue("FragileUnitsScript", 1);
		actor.GibWoundLimit = 1;
		for att in actor.Attachables do
			att.GibWoundLimit = 1;
			if not IsAEmitter(att) then
				att.JointStrength = 1;
			end
		end
	end
end