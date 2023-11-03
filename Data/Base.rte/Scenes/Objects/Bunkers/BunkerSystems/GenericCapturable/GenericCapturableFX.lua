function Create(self)
	
	self.startCaptureSound = CreateSoundContainer("Capturable Start Capture", "Base.rte");
	self.capturingSound = CreateSoundContainer("Capturable Capturing", "Base.rte");
	self.stopCaptureSound = CreateSoundContainer("Capturable Stop Capture", "Base.rte");
	self.captureSuccessSound = CreateSoundContainer("Capturable Capture Success", "Base.rte");
	
end

function Update(self)

	if self.FXstartCapture then
		self.startCaptureSound:Play(self.Pos);
	end
	if self.FXcapturing and not self.capturingSound:IsBeingPlayed() then
		self.capturingSound:Play(self.Pos);
	end
	if self.FXstopCapture then
		self.stopCaptureSound:Play(self.Pos);
	end
	if self.FXcaptureSuccess then
		self.captureSuccessSound:Play(self.Pos);
	end

	self.FXstartCapture = false;
	self.FXstopCapture = false;
	self.FXcaptureSuccess = false;
				
end