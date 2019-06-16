function InstantDeliveryScript:StartScript()
	local activity = ActivityMan:GetActivity()
	
	if activity then
		local gameactivity = ToGameActivity(activity)
		
		if gameactivity then
			gameactivity.DeliveryDelay = 1
			self:Deactivate();
		end
	end
end

function InstantDeliveryScript:UpdateScript()
end

function InstantDeliveryScript:EndScript()
end

function InstantDeliveryScript:PauseScript()
end

function InstantDeliveryScript:CraftEnteredOrbit()
end
