function LongDeliveryScript:StartScript()
	local activity = ActivityMan:GetActivity()
	
	if activity then
		local gameactivity = ToGameActivity(activity)
		
		if gameactivity then
			gameactivity.DeliveryDelay = 10000
			self:Deactivate();
		end
	end
end

function LongDeliveryScript:UpdateScript()
end

function LongDeliveryScript:EndScript()
end

function LongDeliveryScript:PauseScript()
end

function LongDeliveryScript:CraftEnteredOrbit()
end
