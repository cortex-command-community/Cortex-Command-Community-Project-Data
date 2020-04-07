function AllUnitsAreBrainsScript:UpdateScript()
	for actor in MovableMan.Actors do
		if IsAHuman(actor) or IsACrab(actor) then
			if not actor:IsInGroup("Brains") then
				actor:AddToGroup("Brains");
			end
		end
	end
end