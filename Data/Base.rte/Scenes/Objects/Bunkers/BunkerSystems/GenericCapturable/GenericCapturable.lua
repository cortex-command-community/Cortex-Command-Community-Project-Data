function Create(self)
	
	self.Team = 2

	self.messageOnCapture = self:GetStringValue("CaptureMessage");
	
	self.deactivationMessage = self:GetStringValue("DeactivationMessage");
	self.activationMessage = self:GetStringValue("ActivationMessage");
	
	self.captureSpeed = self:NumberValueExists("CaptureSpeed") and self:GetNumberValue("CaptureSpeed") or 10;
	
	self.actorCheckTimer = Timer();
	self.actorCheckDelay = 250;
	
	self.Activity = ToGameActivity(ActivityMan:GetActivity());
	self.Scene = SceneMan.Scene;
	
	if self:StringValueExists("SceneCaptureArea") then
		if self.Scene:HasArea(self:GetStringValue("SceneCaptureArea")) then
			self.captureArea = self.Scene:GetArea(self:GetStringValue("SceneCaptureArea"))
		end
	end
	
	-- goes -100 to 100
	self.captureProgress = -100;
	self.dominantTeam = self.Team;
	
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
									
		local actorList
		
		if self.captureArea then
			actorList = MovableMan:GetMOsInBox(self.captureArea, -1, true);
		else
			actorList = MovableMan:GetMOsInRadius(self.Pos, self.Diameter * 2, -1, true);
		end
		
		for actor in actorList do
			if IsActor(actor) then
				self.actorTeamNumTable[actor.Team] = self.actorTeamNumTable[actor.Team] + 1
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
	
	if self.dominantTeam ~= self.Team then
		if self.captureProgress < 100 then
			self.captureProgress = math.min(100, self.captureProgress + TimerMan.DeltaTimeSecs * self.captureSpeed);
		else
			self.Team = self.dominantTeam;
			self.captureProgress = -100;
		end
		
	else
		if self.captureProgress > -100 then
			self.captureProgress = math.max(-100, self.captureProgress - TimerMan.DeltaTimeSecs * self.captureSpeed);	
		end
	end
	
	PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(0, -20), tostring(self.Team), true, 1);
	
	PrimitiveMan:DrawTextPrimitive(self.Pos, tostring(self.captureProgress), true, 1);
				
end