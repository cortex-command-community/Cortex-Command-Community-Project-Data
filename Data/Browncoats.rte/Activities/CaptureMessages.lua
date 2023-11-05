function OnMessage(self, message, object)

	if string.find(message, "Captured") then
	
		if message == "Captured_RefineryTestCapturable1" then
			MovableMan:SendGlobalMessage("DeactivateCapturable_RefineryTestCapturable1");
			MovableMan:SendGlobalMessage("ActivateCapturable_RefineryTestCapturable2");
		elseif message == "Captured_RefineryTestCapturable2" then
			MovableMan:SendGlobalMessage("DeactivateCapturable_RefineryTestCapturable2");
			self.Activity:GetBanner(GUIBanner.YELLOW, 0):ShowText("oh wow you did it that is capturable 2 good job", GUIBanner.FLYBYLEFTWARD, 1500, Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), 0.4, 4000, 0)
		end
	end
	
end
		