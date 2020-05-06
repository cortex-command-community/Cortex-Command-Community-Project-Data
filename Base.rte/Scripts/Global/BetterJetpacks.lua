function BetterJetpacksScript:StartScript()
	self.multiplier = 1.5;
end
function BetterJetpacksScript:UpdateScript()
	for actor in MovableMan.AddedActors do
		if not actor:NumberValueExists("BetterJetpacksScript") then
			self:BuffJetpack(actor);
			for i = 1, actor.InventorySize do
				local item = actor:Inventory();
				self:BuffJetpack(item);
				actor:SwapNextInventory(item, true);
			end
		end
	end
end
function BetterJetpacksScript:BuffJetpack(actor)
	if IsAHuman(actor) then
		actor = ToAHuman(actor);
	elseif IsACrab(actor) then
		actor = ToACrab(actor);
	end
	if actor.Jetpack then
		actor:SetNumberValue("BetterJetpacksScript", 1);
		actor.JetTimeTotal = actor.JetTimeTotal * self.multiplier;
		for em in actor.Jetpack.Emissions do
			em.ParticlesPerMinute = em.ParticlesPerMinute * self.multiplier;
			em.BurstSize = em.BurstSize * self.multiplier;
		end
	end
end