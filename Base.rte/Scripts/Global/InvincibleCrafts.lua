function InvincibleCraftsScript:StartScript()
end

function InvincibleCraftsScript:UpdateScript()
	--print ("InvincibleCraftsScript:UpdateScript()")
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("InvincibleCraftsScript") then
			actor:SetNumberValue("InvincibleCraftsScript", 1)

			if IsACDropShip(actor) then
				local dropship = ToACDropShip(actor)
				if dropship then
					dropship.HitsMOs = false
					dropship.GetsHitByMOs = false
					if dropship.RightEngine then
						dropship.RightEngine.HitsMOs = false
						dropship.RightEngine.GetsHitByMOs = false
						dropship.RightEngine.JointStrength = 1000000
					end
					if dropship.LeftEngine then
						dropship.LeftEngine.HitsMOs = false
						dropship.LeftEngine.GetsHitByMOs = false
						dropship.LeftEngine.JointStrength = 1000000
					end
					if dropship.RightThruster then
						dropship.RightThruster.HitsMOs = false
						dropship.RightThruster.GetsHitByMOs = false
						dropship.RightThruster.JointStrength = 1000000
					end
					if dropship.LeftThruster then
						dropship.LeftThruster.HitsMOs = false
						dropship.LeftThruster.GetsHitByMOs = false
						dropship.LeftThruster.JointStrength = 1000000
					end
					if dropship.RightHatch then
						dropship.RightHatch.HitsMOs = false
						dropship.RightHatch.GetsHitByMOs = false
						dropship.RightHatch.JointStrength = 1000000
					end
					if dropship.LeftHatch then
						dropship.LeftHatch.HitsMOs = false
						dropship.LeftHatch.GetsHitByMOs = false
						dropship.LeftHatch.JointStrength = 1000000
					end
				end
			end
		
			if IsACRocket(actor) then
				local rocket = ToACRocket(actor)
				if rocket then
					rocket.HitsMOs = false
					rocket.GetsHitByMOs = false
				end
			end
		end
	end
end

function InvincibleCraftsScript:EndScript()
	--print ("InvincibleCraftsScript:UpdateScript()")
end

function InvincibleCraftsScript:PauseScript()
	--print ("InvincibleCraftsScript:UpdateScript()")
end

function InvincibleCraftsScript:CraftEnteredOrbit()
	--print ("InvincibleCraftsScript:UpdateScript()")
end
