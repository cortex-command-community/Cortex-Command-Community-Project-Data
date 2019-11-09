function HugeJetpacksScript:StartScript()
	--print ("HugeJetpacksScript:StartScript()")
end

function HugeJetpacksScript:UpdateScript()
	--print ("HugeJetpacksScript:UpdateScript()")
	
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("HugeJetpacksScript") then
			actor:SetNumberValue("HugeJetpacksScript", 1)

			if IsAHuman(actor) then
				local human = ToAHuman(actor)
				if human then
					human.JetTimeTotal = human.JetTimeTotal * 2
				end
			end
		end
	end
end

function HugeJetpacksScript:EndScript()
	--print ("HugeJetpacksScript:UpdateScript()")
end

function HugeJetpacksScript:PauseScript()
	--print ("HugeJetpacksScript:UpdateScript()")
end

function HugeJetpacksScript:CraftEnteredOrbit()
	--print ("HugeJetpacksScript:UpdateScript()")
end
