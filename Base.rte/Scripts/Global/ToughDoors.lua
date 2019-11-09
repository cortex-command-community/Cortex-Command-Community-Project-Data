function ToughDoorsScript:StartScript()
	--print ("ToughDoorsScript:StartScript()")
	self.Multiplier = 4
end

function ToughDoorsScript:UpdateScript()
	--print ("ToughDoorsScript:UpdateScript()")
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("ToughDoorsScript") then
			actor:SetNumberValue("ToughDoorsScript", 1)

			if IsADoor(actor) then
				local door = ToADoor(actor)
				if door then
					door.GibWoundLimit = door.GibWoundLimit * self.Multiplier
					door.GibImpulseLimit = door.GibImpulseLimit * self.Multiplier
					if door.Door then
						door.Door.GibWoundLimit = door.Door.GibWoundLimit * self.Multiplier
						door.Door.GibImpulseLimit = door.Door.GibImpulseLimit * self.Multiplier
						door.Door.JointStrength = door.Door.JointStrength * self.Multiplier
					end
				end
			end
		end
	end
end

function ToughDoorsScript:EndScript()
	--print ("ToughDoorsScript:UpdateScript()")
end

function ToughDoorsScript:PauseScript()
	--print ("ToughDoorsScript:UpdateScript()")
end

function ToughDoorsScript:CraftEnteredOrbit()
	--print ("ToughDoorsScript:UpdateScript()")
end
