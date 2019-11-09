function InfiniteAmmo:StartScript()
	self.Exclude = {}
	self.Exclude["Dihelical Cannon"] = true -- Endless shooting causes endless lag
	self.Exclude["Nucleo"] = true -- Can't shoot for whatever reasons
end

function InfiniteAmmo:UpdateScript()
	for actor in MovableMan.Actors do
		if actor.ClassName == "AHuman" then
			local human = ToAHuman(actor)
			if human then
				if human.EquippedItem and human.EquippedItem.ClassName == "HDFirearm" and self.Exclude[human.EquippedItem.PresetName] == nil then
					local item = ToHDFirearm(human.EquippedItem)
					if item then
						local mag = item.Magazine
						if mag and mag.Capacity > 0 then
							mag.RoundCount = mag.Capacity
						end
					end
				end
			end
		end
	end
end

function InfiniteAmmo:EndScript()
end

function InfiniteAmmo:PauseScript()
end

function InfiniteAmmo:CraftEnteredOrbit()
end
