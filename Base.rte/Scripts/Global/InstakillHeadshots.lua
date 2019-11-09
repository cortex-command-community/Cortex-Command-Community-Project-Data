function InstakillHeadshotsScript:StartScript()
	--print ("InstakillHeadshotsScript:StartScript()")
end

function InstakillHeadshotsScript:UpdateScript()
	--print ("InstakillHeadshotsScript:UpdateScript()")
	-- Traverse only added actors as this way we can cover all actors added
	-- and don't have to check any others which already exist in the simulation
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("InstakillHeadshotsScript") then
			actor:SetNumberValue("InstakillHeadshotsScript", 1)
			if IsAHuman(actor) then
				local human = ToAHuman(actor)
				if human then
					if human.Head then
						human.Head.GibWoundLimit = 1
						human.Head.DamageMultiplier = 100
					end
				end
			end
			
			if IsACrab(actor) then
				local crab = ToACrab(actor)
				if crab then
					if crab.Turret then
						crab.Turret.GibWoundLimit = 1
						crab.Turret.DamageMultiplier = 100
					end
				end
			end
		end
	end
end

function InstakillHeadshotsScript:EndScript()
	--print ("InstakillHeadshotsScript:UpdateScript()")
end

function InstakillHeadshotsScript:PauseScript()
	--print ("InstakillHeadshotsScript:UpdateScript()")
end

function InstakillHeadshotsScript:CraftEnteredOrbit()
	--print ("InstakillHeadshotsScript:UpdateScript()")
end
