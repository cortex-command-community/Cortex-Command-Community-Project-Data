function BetterJetpacksScript:StartScript()
	self.multiplier = 1.5;
end

function BetterJetpacksScript:UpdateScript()
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("BetterJetpacksScript") then
			actor:SetNumberValue("BetterJetpacksScript", 1);
			if IsAHuman(actor) then
				local human = ToAHuman(actor);
				human.JetTimeTotal = human.JetTimeTotal * self.multiplier;
				local jetpack = human.Jetpack;
				if jetpack then
					for em in jetpack.Emissions do
						em.ParticlesPerMinute = em.ParticlesPerMinute * self.multiplier;
						em.BurstSize = em.BurstSize * self.multiplier;
					end
				end
			end
		end
	end
end

function BetterJetpacksScript:EndScript()
end

function BetterJetpacksScript:PauseScript()
end

function BetterJetpacksScript:CraftEnteredOrbit()
end
