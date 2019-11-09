function FragileUnitsScript:StartScript()
	--print ("FragileUnitsScript:StartScript()")
end

function FragileUnitsScript:UpdateScript()
	--print ("FragileUnitsScript:UpdateScript()")
	
	for actor in MovableMan.Actors do
		if not actor:NumberValueExists("FragileUnitsScript") then
			actor:SetNumberValue("FragileUnitsScript", 1)

			if IsAHuman(actor) then
				actor.GibWoundLimit = 1
				local human = ToAHuman(actor)
				if human then
					if human.Head then
						human.Head.GibWoundLimit = 1
					end
					if human.FGArm then
						human.FGArm.GibWoundLimit = 1
					end
					if human.BGArm then
						human.BGArm.GibWoundLimit = 1
					end
					if human.FGLeg then
						human.FGLeg.GibWoundLimit = 1
					end
					if human.BGLeg then
						human.BGLeg.GibWoundLimit = 1
					end
				end
			end
			
			if IsACrab(actor) then
				actor.GibWoundLimit = 1
				local crab = ToACrab(actor)
				if crab then
					if crab.Turret then
						crab.Turret.GibWoundLimit = 1
					end
					if crab.LFGLeg then
						crab.LFGLeg.GibWoundLimit = 1
					end
					if crab.RFGLeg then
						crab.RFGLeg.GibWoundLimit = 1
					end
					if crab.LBGLeg then
						crab.LBGLeg.GibWoundLimit = 1
					end
					if crab.RBGLeg then
						crab.RBGLeg.GibWoundLimit = 1
					end
				end
			end
		end
	end
end

function FragileUnitsScript:EndScript()
	--print ("FragileUnitsScript:UpdateScript()")
end

function FragileUnitsScript:PauseScript()
	--print ("FragileUnitsScript:UpdateScript()")
end

function FragileUnitsScript:CraftEnteredOrbit()
	--print ("FragileUnitsScript:UpdateScript()")
end
