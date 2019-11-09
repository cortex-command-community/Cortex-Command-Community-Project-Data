function ToughBrainsScript:StartScript()
	--print ("ToughBrainsScript:StartScript()")
	self.Multiplier = 3
end

function ToughBrainsScript:UpdateScript()
	--print ("ToughBrainsScript:UpdateScript()")
	for actor in MovableMan.Actors do
		if actor:IsInGroup("Brains") and not actor:NumberValueExists("ToughBrainsScript") then
			actor:SetNumberValue("ToughBrainsScript", 1)
			actor.GibWoundLimit = actor.GibWoundLimit * self.Multiplier
			actor.GibImpulseLimit = actor.GibImpulseLimit * self.Multiplier

			if IsAHuman(actor) then
				local human = ToAHuman(actor)
				if human then
					if human.Head then
						human.Head.GibWoundLimit = human.Head.GibWoundLimit * self.Multiplier
						human.Head.GibImpulseLimit = human.Head.GibImpulseLimit * self.Multiplier
						human.Head.JointStrength = human.Head.JointStrength * self.Multiplier
					end
					if human.FGArm then
						human.FGArm.GibWoundLimit = human.FGArm.GibWoundLimit * self.Multiplier
						human.FGArm.GibImpulseLimit = human.FGArm.GibImpulseLimit * self.Multiplier
						human.FGArm.JointStrength = human.FGArm.JointStrength * self.Multiplier
					end
					if human.BGArm then
						human.BGArm.GibWoundLimit = human.BGArm.GibWoundLimit * self.Multiplier
						human.BGArm.GibImpulseLimit = human.BGArm.GibImpulseLimit * self.Multiplier
						human.BGArm.JointStrength = human.BGArm.JointStrength * self.Multiplier
					end
					if human.FGLeg then
						human.FGLeg.GibWoundLimit = human.FGLeg.GibWoundLimit * self.Multiplier
						human.FGLeg.GibImpulseLimit = human.FGLeg.GibImpulseLimit * self.Multiplier
						human.FGLeg.JointStrength = human.FGLeg.JointStrength * self.Multiplier
					end
					if human.BGLeg then
						human.BGLeg.GibWoundLimit = human.BGLeg.GibWoundLimit * self.Multiplier
						human.BGLeg.GibImpulseLimit = human.BGLeg.GibImpulseLimit * self.Multiplier
						human.BGLeg.JointStrength = human.BGLeg.JointStrength * self.Multiplier
					end
				end
			end
			
			if IsACrab(actor) then
				local crab = ToACrab(actor)
				if crab then
					if crab.Turret then
						crab.Turret.GibWoundLimit = crab.Turret.GibWoundLimit * self.Multiplier
						crab.Turret.GibImpulseLimit = crab.Turret.GibImpulseLimit * self.Multiplier
						crab.Turret.JointStrength = crab.Turret.JointStrength * self.Multiplier
					end
					if crab.LFGLeg then
						crab.LFGLeg.GibWoundLimit = crab.LFGLeg.GibWoundLimit * self.Multiplier
						crab.LFGLeg.GibImpulseLimit = crab.LFGLeg.GibImpulseLimit * self.Multiplier
						crab.LFGLeg.JointStrength = crab.LFGLeg.JointStrength * self.Multiplier
					end
					if crab.RFGLeg then
						crab.RFGLeg.GibWoundLimit = crab.RFGLeg.GibWoundLimit * self.Multiplier
						crab.RFGLeg.GibImpulseLimit = crab.RFGLeg.GibImpulseLimit * self.Multiplier
						crab.RFGLeg.JointStrength = crab.RFGLeg.JointStrength * self.Multiplier
					end
					if crab.LBGLeg then
						crab.LBGLeg.GibWoundLimit = crab.LBGLeg.GibWoundLimit * self.Multiplier
						crab.LBGLeg.GibImpulseLimit = crab.LBGLeg.GibImpulseLimit * self.Multiplier
						crab.LBGLeg.JointStrength = crab.LBGLeg.JointStrength * self.Multiplier
					end
					if crab.RBGLeg then
						crab.RBGLeg.GibWoundLimit = crab.RBGLeg.GibWoundLimit * self.Multiplier
						crab.RBGLeg.GibImpulseLimit = crab.RBGLeg.GibImpulseLimit * self.Multiplier
						crab.RBGLeg.JointStrength = crab.RBGLeg.JointStrength * self.Multiplier
					end
				end
			end
		end
	end
end

function ToughBrainsScript:EndScript()
	--print ("ToughBrainsScript:UpdateScript()")
end

function ToughBrainsScript:PauseScript()
	--print ("ToughBrainsScript:UpdateScript()")
end

function ToughBrainsScript:CraftEnteredOrbit()
	--print ("ToughBrainsScript:UpdateScript()")
end
