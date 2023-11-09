function OnGlobalMessage(self, message, object)

	--print("capturablegotglobalmessage")

	if message == self.deactivationMessage then
		self.Deactivated = true;
		self.dominantTeam = self.Team;
		self.capturingTeam = self.Team;
		self.captureProgress = 1;
	elseif message == self.activationMessage then
		self.Deactivated = false;
	end

end

function OnMessage(self, message, object)

	if message == self.deactivationMessage then
		self.Deactivated = true;
		self.dominantTeam = self.Team;
		self.capturingTeam = self.Team;
		self.captureProgress = 1;
	elseif message == self.activationMessage then
		self.Deactivated = false;
	end

end

function Create(self)
	
	self.Team = self:NumberValueExists("StartTeam") and self:GetNumberValue("StartTeam") or 0;

	self.messageOnCapture = self:GetStringValue("CaptureMessage");
	
	self.deactivationMessage = self:GetStringValue("DeactivationMessage");
	self.activationMessage = self:GetStringValue("ActivationMessage");
	
	self.actorCheckTimer = Timer();
	self.actorCheckDelay = 250;
	
	self.Activity = ToGameActivity(ActivityMan:GetActivity());
	self.Scene = SceneMan.Scene;
	print(self:GetStringValue("SceneCaptureArea"))
	if self:StringValueExists("SceneCaptureArea") then
		if self.Scene:HasArea(self:GetStringValue("SceneCaptureArea")) then
			self.captureArea = self.Scene:GetArea(self:GetStringValue("SceneCaptureArea"));
			print("foundarea")
		end
	end
	
	self.captureProgress = 1;
	self.capturingTeam = self.Team;
	self.dominantTeam = self.Team;
	
	self.instantReset = self:GetNumberValue("InstantReset") == 1 and true or false;
	self.neutralIfNotFullyCapped = self:GetNumberValue("NeutralIfNotFullyCapped") == 1 and true or false;
	self.needFullControlToCap = self:GetNumberValue("NeedFullControlToCap") == 1 and true or false;
	
	self.secondsToCapture = self:NumberValueExists("SecondsToCapture") and self:GetNumberValue("SecondsToCapture") or 10;
	self.captureRate = 1/(self.secondsToCapture / 2);
	
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
		local noDominantTeam = true;
		self.Contested = false;
		
		for i = -1, #self.actorTeamNumTable do
			if self.actorTeamNumTable[i] > largestNum then
				largestNum = self.actorTeamNumTable[i];
				noDominantTeam = false;
				if self.dominantTeam ~= i then
					self.dominantTeam = i;
				end
			elseif not noDominantTeam then
				if self.needFullControlToCap then
					if self.actorTeamNumTable[i] > 0 then
						self.Contested = true;
					end
				elseif self.actorTeamNumTable[i] == largestNum then
					self.Contested = true;
				end
			end
			if noDominantTeam then
				self.dominantTeam = self.Team;
			end
		end
		
	end
	
	if self.dominantTeam ~= self.Team then
		if not self.FXcapturing then
			self.FXstartCapture = not self.Deactivated and true or false;
			self.FXcapturing = not self.Deactivated and true or false;
		end
	else
		if self.FXcapturing then
			self.FXstopCapture = true;
		end
		self.FXcapturing = false;
	end
	
	if not self.Contested and not self.Deactivated then
	
		if self.dominantTeam ~= self.capturingTeam then	
		
			if self.captureProgress > 0 then
				self.captureProgress = math.max(0, self.captureProgress - TimerMan.DeltaTimeSecs * self.captureRate);
			else
				self.FXcaptureUncapped = true;
				self.capturingTeam = self.dominantTeam;
				if self.neutralIfNotFullyCapped then
					self.Team = -1;
				end
			end
			
		else
		
			if self.captureProgress < 1 then
				self.captureProgress = math.min(1, self.captureProgress + TimerMan.DeltaTimeSecs * self.captureRate);
				if self.Team == -1 and self.dominantTeam == self.Team then
					self.captureProgress = 0;
				end
					
			else
				if self.dominantTeam ~= self.Team then
					self.Team = self.dominantTeam;
					self.FXcaptureSuccess = true;
					self.Activity:SendMessage(self.messageOnCapture, self.Team);
				end
			end

		end
		
		if self.instantReset and self.dominantTeam == self.Team then
			self.captureProgress = self.Team ~= -1 and 1 or 0;
			self.capturingTeam = self.Team;
		end
		
	end
	
	PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(0, -20), tostring("Team: " .. self.Team), true, 1);
	PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(0, -30), tostring("Capturing Team: " .. self.capturingTeam), true, 1);
	PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(0, -40), tostring("Dominant Team: " .. self.dominantTeam), true, 1);
	
	PrimitiveMan:DrawTextPrimitive(self.Pos, tostring(self.captureProgress * 100), true, 1);
	
	if self.Deactivated then
		PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(0, -60), "DEACTIVATED"	, true, 1);	
	end
end