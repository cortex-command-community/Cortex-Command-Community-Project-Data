function FriendlyFireScript:StartScript()
	--print ("FriendlyFireScript Create")
end

function FriendlyFireScript:UpdateScript()
	for actor in MovableMan.Actors do 
		if not actor:NumberValueExists("FriendlyFireScript") then
			actor:SetNumberValue("FriendlyFireScript", 1)
			actor.IgnoresTeamHits = false 
		end
	end
end

function FriendlyFireScript:EndScript()
	--print ("FriendlyFireScript Destroy")
end

function FriendlyFireScript:PauseScript()
	--print ("FriendlyFireScript Pause")
end

function FriendlyFireScript:CraftEnteredOrbit()
	--print ("FriendlyFireScript Orbited")
end
