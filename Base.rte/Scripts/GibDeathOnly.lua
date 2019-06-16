function GibDeathOnlyScript:StartScript()
	--print ("GibDeathOnlyScript:StartScript()")
end

function GibDeathOnlyScript:UpdateScript()
	--print ("GibDeathOnlyScript:UpdateScript()")
	for actor in MovableMan.Actors do
		if actor.Health > 0 then
			if not IsADoor(actor) then
				actor.Health = actor.MaxHealth
			else
				-- Only heal doors if the door itself is still there, 
				-- otherwise door engine won't explode
				local door = ToADoor(actor)
				if door.Door then
					actor.Health = actor.MaxHealth
				end 
			end
		end
		
		if not actor:NumberValueExists("GibDeathOnlyScript") then
			actor:SetNumberValue("GibDeathOnlyScript", 1)

			if IsAHuman(actor) then
				actor.DamageMultiplier = 0
				
				local human = ToAHuman(actor)
				if human then
					if human.Head then
						human.Head.DamageMultiplier = 0
					end
					if human.FGArm then
						human.FGArm.DamageMultiplier = 0
					end
					if human.BGArm then
						human.BGArm.DamageMultiplier = 0
					end
					if human.FGLeg then
						human.FGLeg.DamageMultiplier = 0
					end
					if human.BGLeg then
						human.BGLeg.DamageMultiplier = 0
					end
				end
			end
			
			if IsACrab(actor) then
				actor.DamageMultiplier = 0

				local crab = ToACrab(actor)
				if crab then
					if crab.Turret then
						crab.Turret.DamageMultiplier = 0
					end
					if crab.LFGLeg then
						crab.LFGLeg.DamageMultiplier = 0
					end
					if crab.RFGLeg then
						crab.RFGLeg.DamageMultiplier = 0
					end
					if crab.LBGLeg then
						crab.LBGLeg.DamageMultiplier = 0
					end
					if crab.RBGLeg then
						crab.RBGLeg.DamageMultiplier = 0
					end
				end
			end
			

			if IsACDropShip(actor) then
				local dropship = ToACDropShip(actor)
				if dropship then
					dropship.DamageMultiplier = 0

					if dropship.RThruster then
						dropship.RThruster.DamageMultiplier = 0
					end
					if dropship.LThruster then
						dropship.LThruster.DamageMultiplier = 0
					end
					if dropship.RHatch then
						dropship.RHatch.DamageMultiplier = 0
					end
					if dropship.LHatch then
						dropship.LHatch.DamageMultiplier = 0
					end
				end
			end
		
			if IsACRocket(actor) then
				local rocket = ToACRocket(actor)
				if rocket then
					rocket.DamageMultiplier = 0
				end
			end
		end
	end
end

function GibDeathOnlyScript:EndScript()
	--print ("GibDeathOnlyScript:UpdateScript()")
end

function GibDeathOnlyScript:PauseScript()
	--print ("GibDeathOnlyScript:UpdateScript()")
end

function GibDeathOnlyScript:CraftEnteredOrbit()
	--print ("GibDeathOnlyScript:UpdateScript()")
end
