function BiggerJetpacksScript:StartScript()
	self.multiplier = 2;
end
function BiggerJetpacksScript:UpdateScript()
	for actor in MovableMan.AddedActors do
		if not actor:NumberValueExists("BiggerJetpacksScript") then
			self:BuffJetpack(actor);
			for i = 1, actor.InventorySize do
				local item = actor:Inventory();
				self:BuffJetpack(item);
				actor:SwapNextInventory(item, true);
			end
		end
	end
end
function BiggerJetpacksScript:BuffJetpack(actor)
	if IsAHuman(actor) then
		actor = ToAHuman(actor);
	elseif IsACrab(actor) then
		actor = ToACrab(actor);
	end
	if actor.Jetpack then
		actor:SetNumberValue("BiggerJetpacksScript", 1);
		print(actor.JetTimeTotal);
		actor.JetTimeTotal = actor.JetTimeTotal * self.multiplier + 100;
	end
end