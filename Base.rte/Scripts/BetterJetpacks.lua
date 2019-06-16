function BetterJetpacksScript:StartScript()
	self.Multiplier = 1.75
end

function BetterJetpacksScript:UpdateScript()
	--print ("BetterJetpacksScript:UpdateScript()")
	
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("BetterJetpacksScript") then
			actor:SetNumberValue("BetterJetpacksScript", 1)

			if IsAHuman(actor) then
				local human = ToAHuman(actor)
				if human then
					local jetpack = human.Jetpack
					if jetpack then
						for em in jetpack.Emissions do
							em.ParticlesPerMinute = em.ParticlesPerMinute * self.Multiplier
						end
					end
				end
			end
		end
	end
end

function BetterJetpacksScript:EndScript()
	--print ("BetterJetpacksScript:UpdateScript()")
end

function BetterJetpacksScript:PauseScript()
	--print ("BetterJetpacksScript:UpdateScript()")
end

function BetterJetpacksScript:CraftEnteredOrbit()
	--print ("BetterJetpacksScript:UpdateScript()")
end
