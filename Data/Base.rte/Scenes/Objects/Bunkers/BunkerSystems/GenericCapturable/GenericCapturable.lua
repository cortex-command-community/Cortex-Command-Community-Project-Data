function Create(self)
	
	self.Team = 2

	self.messageOnCapture = self:GetStringValue("CaptureMessage");
	
	self.deactivationMessage = self:GetStringValue("DeactivationMessage");
	self.activationMessage = self:GetStringValue("ActivationMessage");
	
	self.actorCheckTimer = Timer();
	self.actorCheckDelay = 250;
	
	self.Activity = ToGameActivity(ActivityMan:GetActivity());
	self.Scene = SceneMan.Scene;
	
	if self:StringValueExists("SceneCaptureArea") then
		if self.Scene:HasArea(self:GetStringValue("SceneCaptureArea")) then
			self.captureArea = self.Scene:GetArea(self:GetStringValue("SceneCaptureArea"));
		end
	end
	
	self.captureProgress = 1;
	self.capturingTeam = self.Team;
	self.dominantTeam = self.Team;
	
	self.instantReset = self:GetNumberValue("InstantReset") == 1 and true or false;
	
	self.secondsToCapture = self:NumberValueExists("SecondsToCapture") and self:GetNumberValue("SecondsToCapture") or 10;
	self.captureSpeed = self.secondsToCapture / 2;
	
	self.actorTeamNumTable = {  [-1] = 0,
								[0] = 0,
								[1] = 0, 
								[2] = 0,
								[3] = 0};
	
end

function Update(self)

	if UInputMan:KeyPressed(Key.Y) then
		self:ReloadScripts();
	end

	if self.actorCheckTimer:IsPastSimMS(self.actorCheckDelay) then
	
		self.actorCheckTimer:Reset();
		
		self.actorTeamNumTable = {  [-1] = 0,
									[0] = 0,
									[1] = 0, 
									[2] = 0,
									[3] = 0};
									
		
		if self.captureArea then
			
			for box in self.captureArea.Boxes do
				for actor in MovableMan:GetMOsInBox(box, -1, true) do
					if IsActor(actor) then
						self.actorTeamNumTable[actor.Team] = self.actorTeamNumTable[actor.Team] + 1
					end
				end
			end
			
		else -- fallback
		
			local actorList = MovableMan:GetMOsInRadius(self.Pos, self.Diameter * 2, -1, true);
			for actor in actorList do
				if IsActor(actor) then
					self.actorTeamNumTable[actor.Team] = self.actorTeamNumTable[actor.Team] + 1
				end
			end
			
		end
		
		local largestNum = 0;
		self.dominantTeam = self.Team;
		
		for i = -1, #self.actorTeamNumTable do
			if self.actorTeamNumTable[i] > largestNum then
				largestNum = self.actorTeamNumTable[i];
				self.dominantTeam = i;
			end
		end
		
	end
	
	if self.dominantTeam ~= self.capturingTeam then
	
		if self.captureProgress > 0 then
			self.captureProgress = math.max(0, self.captureProgress - TimerMan.DeltaTimeSecs / self.captureSpeed);
		else
			self.capturingTeam = self.dominantTeam;
		end
		
	else
	
		if self.captureProgress < 1 then
			self.captureProgress = math.min(1, self.captureProgress + TimerMan.DeltaTimeSecs / self.captureSpeed);
		else
			self.Team = self.dominantTeam;
		end

	end
	
	if self.instantReset and self.dominantTeam == self.Team then
		self.captureProgress = 1;
		self.capturingTeam = self.Team;
	end
	
	PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(0, -20), tostring("Team: " .. self.Team), true, 1);
	PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(0, -30), tostring("Capturing Team: " .. self.capturingTeam), true, 1);
	
	PrimitiveMan:DrawTextPrimitive(self.Pos, tostring(self.captureProgress * 100), true, 1);
				
end