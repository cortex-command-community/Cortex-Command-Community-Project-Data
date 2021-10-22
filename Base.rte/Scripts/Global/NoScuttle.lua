function NoScuttleScript:UpdateScript()
	for actor in MovableMan.AddedActors do
		if IsACDropShip(actor) or IsACRocket(actor) then
			ToACraft(actor).ScuttleOnDeath = false;
			actor:DisableScript("Base.rte/Craft/Shared/ScuttleExplosions.lua");
		end
	end
end