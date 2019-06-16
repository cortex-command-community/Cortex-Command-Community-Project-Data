function ToughCraftsScript:StartScript()
	--print ("ToughCraftsScript:StartScript()")
	self.Multiplier = 4
end

function ToughCraftsScript:UpdateScript()
	--print ("ToughCraftsScript:UpdateScript()")
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("ToughCraftsScript") then
			actor:SetNumberValue("ToughCraftsScript", 1)

			if IsACDropShip(actor) then
				local dropship = ToACDropShip(actor)
				if dropship then
					dropship.GibWoundLimit = dropship.GibWoundLimit * self.Multiplier
					dropship.GibImpulseLimit = dropship.GibImpulseLimit * self.Multiplier
					if dropship.RightEngine then
						dropship.RightEngine.GibWoundLimit = dropship.RightEngine.GibWoundLimit * self.Multiplier
						dropship.RightEngine.GibImpulseLimit = dropship.RightEngine.GibImpulseLimit * self.Multiplier
						dropship.RightEngine.JointStrength = dropship.RightEngine.JointStrength * self.Multiplier
					end
					if dropship.LeftEngine then
						dropship.LeftEngine.GibWoundLimit = dropship.LeftEngine.GibWoundLimit * self.Multiplier
						dropship.LeftEngine.GibImpulseLimit = dropship.LeftEngine.GibImpulseLimit * self.Multiplier
						dropship.LeftEngine.JointStrength = dropship.LeftEngine.JointStrength * self.Multiplier
					end
					if dropship.RightThruster then
						dropship.RightThruster.GibWoundLimit = dropship.RightThruster.GibWoundLimit * self.Multiplier
						dropship.RightThruster.GibImpulseLimit = dropship.RightThruster.GibImpulseLimit * self.Multiplier
						dropship.RightThruster.JointStrength = dropship.RightThruster.JointStrength * self.Multiplier
					end
					if dropship.LeftThruster then
						dropship.LeftThruster.GibWoundLimit = dropship.LeftThruster.GibWoundLimit * self.Multiplier
						dropship.LeftThruster.GibImpulseLimit = dropship.LeftThruster.GibImpulseLimit * self.Multiplier
						dropship.LeftThruster.JointStrength = dropship.LeftThruster.JointStrength * self.Multiplier
					end
					if dropship.RightHatch then
						dropship.RightHatch.GibWoundLimit = dropship.RightHatch.GibWoundLimit * self.Multiplier
						dropship.RightHatch.GibImpulseLimit = dropship.RightHatch.GibImpulseLimit * self.Multiplier
						dropship.RightHatch.JointStrength = dropship.RightHatch.JointStrength * self.Multiplier
					end
					if dropship.LeftHatch then
						dropship.LeftHatch.GibWoundLimit = dropship.LeftHatch.GibWoundLimit * self.Multiplier
						dropship.LeftHatch.GibImpulseLimit = dropship.LeftHatch.GibImpulseLimit * self.Multiplier
						dropship.LeftHatch.JointStrength = dropship.LeftHatch.JointStrength * self.Multiplier
					end
				end
			end
		
			if IsACRocket(actor) then
				local rocket = ToACRocket(actor)
				if rocket then
					rocket.GibWoundLimit = rocket.GibWoundLimit * self.Multiplier
					rocket.GibImpulseLimit = rocket.GibImpulseLimit * self.Multiplier
				end
			end
		end
	end
end

function ToughCraftsScript:EndScript()
	--print ("ToughCraftsScript:UpdateScript()")
end

function ToughCraftsScript:PauseScript()
	--print ("ToughCraftsScript:UpdateScript()")
end

function ToughCraftsScript:CraftEnteredOrbit()
	--print ("ToughCraftsScript:UpdateScript()")
end
