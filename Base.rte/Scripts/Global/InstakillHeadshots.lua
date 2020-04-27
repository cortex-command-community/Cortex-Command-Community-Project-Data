function InstakillHeadshotsScript:UpdateScript()
	for actor in MovableMan.AddedActors do
		if not actor:NumberValueExists("InstakillHeadshotsScript") then
			self:DeployEffect(actor);
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
function InstakillHeadshotsScript:DeployEffect(actor)
	actor:SetNumberValue("InstakillHeadshotsScript", 1)
	if IsAHuman(actor) then
		local human = ToAHuman(actor)
		if human.Head then
			human.Head.GibWoundLimit = 1
			human.Head.DamageMultiplier = human.MaxHealth
		end
	elseif IsACrab(actor) then
		local crab = ToACrab(actor)
		if crab.Turret then
			crab.Turret.GibWoundLimit = 1
			crab.Turret.DamageMultiplier = crab.MaxHealth
		end
	end
end