function FasterWalkingScript:StartScript()
	self.Multiplier = 1.75
	self.PushForceDenominator = 1.25
end

function FasterWalkingScript:UpdateScript()
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("FasterWalkingScript") then
			actor:SetNumberValue("FasterWalkingScript", 1)

			if IsAHuman(actor) then
				local human = ToAHuman(actor)
				if human then
					human:SetLimbPathSpeed(0, human:GetLimbPathSpeed(0) * self.Multiplier)
					human:SetLimbPathSpeed(1, human:GetLimbPathSpeed(1) * self.Multiplier)
					human:SetLimbPathSpeed(2, human:GetLimbPathSpeed(2) * self.Multiplier)
					
					human.LimbPathPushForce = human.LimbPathPushForce * self.PushForceDenominator
				end
			end
			
			if IsACrab(actor) then
				local crab = ToACrab(actor)
				if crab then
					crab:SetLimbPathSpeed(0, crab:GetLimbPathSpeed(0) * self.Multiplier)
					crab:SetLimbPathSpeed(1, crab:GetLimbPathSpeed(1) * self.Multiplier)
					crab:SetLimbPathSpeed(2, crab:GetLimbPathSpeed(2) * self.Multiplier)
					
					crab.LimbPathPushForce = crab.LimbPathPushForce * self.PushForceDenominator
				end
			end
		end
	end
end

function FasterWalkingScript:EndScript()
end

function FasterWalkingScript:PauseScript()
end

function FasterWalkingScript:CraftEnteredOrbit()
end
