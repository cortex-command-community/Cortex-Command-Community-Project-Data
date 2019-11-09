function LowerGravityScript:StartScript()
	SceneMan.Scene.GlobalAcc = Vector(SceneMan.Scene.GlobalAcc.X, SceneMan.Scene.GlobalAcc.Y * 0.65);
end

function LowerGravityScript:UpdateScript()

end

function LowerGravityScript:EndScript()
	--print ("LowerGravity Destroy")
end

function LowerGravityScript:PauseScript()
	--print ("LowerGravity Pause")
end

function LowerGravityScript:CraftEnteredOrbit()
	--print ("LowerGravity Orbited")
end
