function FragileUnitsScript:StartScript()
end
function FragileUnitsScript:UpdateScript()
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("FragileUnitsScript") then
			actor:SetNumberValue("FragileUnitsScript", 1);
			if IsAHuman(actor) then
				actor.GibWoundLimit = 1;
				local human = ToAHuman(actor);
				local parts = {human.Head, human.FGArm, human.BGArm, human.FGLeg, human.BGLeg};
				for i = 1, #parts do
					local part = parts[i];
					if part then
						part.GibWoundLimit = 1;
						part.JointStrength = 1;
					end
				end
			end
			if IsACrab(actor) then
				actor.GibWoundLimit = 1;
				local crab = ToACrab(actor)
				local parts = {crab.Turret, crab.RFGLeg, crab.RBGLeg, crab.LFGLeg, crab.LBGLeg};
				for i = 1, #parts do
					local part = parts[i];
					if part then
						part.GibWoundLimit = 1;
						part.JointStrength = 1;
					end
				end
			end
		end
	end
end