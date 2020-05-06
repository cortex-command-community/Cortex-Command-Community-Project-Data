function AllUnitsAreBrainsScript:UpdateScript()
	for actor in MovableMan.AddedActors do
		if (IsAHuman(actor) or IsACrab(actor)) and not actor:IsInGroup("Brains") then
			actor:AddToGroup("Brains");
		else
			for i = 1, actor.InventorySize do
				local item = actor:Inventory();
				if (IsAHuman(item) or IsACrab(item)) and not item:IsInGroup("Brains") then
					ToActor(item):AddToGroup("Brains");
				end
				actor:SwapNextInventory(item, true);
			end
		end
	end
end