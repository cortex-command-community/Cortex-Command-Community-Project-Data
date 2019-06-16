function BulkyDropShipsScript:StartScript()
end

function BulkyDropShipsScript:UpdateScript()
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("BulkyDropShipsScript") then
			actor:SetNumberValue("BulkyDropShipsScript", 1)

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

function BulkyDropShipsScript:EndScript()
end

function BulkyDropShipsScript:PauseScript()
end

function BulkyDropShipsScript:CraftEnteredOrbit()
end
