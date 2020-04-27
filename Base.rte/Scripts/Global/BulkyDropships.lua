function BulkyDropshipsScript:UpdateScript()
	for actor in MovableMan.AddedActors do
		if not actor:NumberValueExists("BulkyDropshipsScript") then
			actor:SetNumberValue("BulkyDropshipsScript", 1);
			if IsACDropShip(actor) then
				local dropship = ToACDropShip(actor);
				dropship.MaxEngineAngle = 7;
				dropship.LateralControlSpeed = 1;
			end
		end
	end
end