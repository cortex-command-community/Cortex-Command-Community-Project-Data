function AllUnitsAreBrainsScript:StartScript()
end

function AllUnitsAreBrainsScript:UpdateScript()
	for actor in MovableMan.Actors do
		if IsAHuman(actor) or IsACrab(actor) then
			if not actor:IsInGroup("Brains") then
				actor:AddToGroup("Brains")
			end
		end
	end
end

function AllUnitsAreBrainsScript:EndScript()
end

function AllUnitsAreBrainsScript:PauseScript()
end

function AllUnitsAreBrainsScript:CraftEnteredOrbit()
end
