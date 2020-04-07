function BetterJetpacksScript:StartScript()
	self.multiplier = 1.5;
end
function BetterJetpacksScript:UpdateScript()
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("BetterJetpacksScript") then
			actor:SetNumberValue("BetterJetpacksScript", 1);
			if IsAHuman(actor) then
				actor = ToAHuman(actor);
			elseif IsACrab(actor) then
				actor = ToACrab(actor);
			end
			if actor.Jetpack then
				actor.JetTimeTotal = actor.JetTimeTotal * self.multiplier;
				for em in actor.Jetpack.Emissions do
					em.ParticlesPerMinute = em.ParticlesPerMinute * self.multiplier;
					em.BurstSize = em.BurstSize * self.multiplier;
				end
			end
		end
	end
end