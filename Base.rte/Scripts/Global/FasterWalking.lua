function FasterWalkingScript:StartScript()
	self.multiplier = 1.6;
	self.pushForceDenominator = 1.2;
end
function FasterWalkingScript:UpdateScript()
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("FasterWalkingScript") then
			actor:SetNumberValue("FasterWalkingScript", 1);
			local walker;
			if IsAHuman(actor) then
				walker = ToAHuman(actor);
			elseif IsACrab(actor) then
				walker = ToACrab(actor);
			end
			if walker then
				walker:SetLimbPathSpeed(0, walker:GetLimbPathSpeed(0) * self.multiplier);
				walker:SetLimbPathSpeed(1, walker:GetLimbPathSpeed(1) * self.multiplier);
				walker:SetLimbPathSpeed(2, walker:GetLimbPathSpeed(2) * self.multiplier);
				walker.LimbPathPushForce = walker.LimbPathPushForce * self.pushForceDenominator;
			end
		end
	end
end