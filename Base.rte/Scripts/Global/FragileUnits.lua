function FragileUnitsScript:UpdateScript()
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("FragileUnitsScript") then
			actor:SetNumberValue("FragileUnitsScript", 1);
			if IsAHuman(actor) or IsACrab(actor) then
				actor.GibWoundLimit = 1;
				for att in actor.Attachables do
					att.GibWoundLimit = 1;
					if not IsAEmitter(att) then
						att.JointStrength = 1;
					end
				end
			end
		end
	end
end