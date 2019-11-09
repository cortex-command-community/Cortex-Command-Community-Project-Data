function BulkyDropshipsScript:StartScript()
end

function BulkyDropshipsScript:UpdateScript()
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("BulkyDropshipsScript") then
			actor:SetNumberValue("BulkyDropshipsScript", 1)

			if IsACDropShip(actor) then
				local dropship = ToACDropShip(actor)
				if dropship then
					dropship.MaxEngineAngle = 7
					dropship.LateralControlSpeed = 1
				end
			end
		end
	end
end

function BulkyDropshipsScript:EndScript()
end

function BulkyDropshipsScript:PauseScript()
end

function BulkyDropshipsScript:CraftEnteredOrbit()
end
