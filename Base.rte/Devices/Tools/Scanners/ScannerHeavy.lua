function Create(self)

	self.ScanTimer = Timer();
	self.scanDelay = 100;
	self.maxScanRange = 500;
	self.scanDisruption = 300;
	self.scanSpacing = 10;

	self.numberOfScans = 6;
	self.scanSpreadAngle = 30; -- Degrees!

end

function Update(self)

	if self:IsActivated() then
		if self.ScanTimer:IsPastSimMS(self.scanDelay) then
			self.ScanTimer:Reset();
			local actor = MovableMan:GetMOFromID(self.RootID);
			if MovableMan:IsActor(actor) then
				self.parent = ToActor(actor);
				if self.HFlipped == false then
					self.negativeNum = 1;
				else
					self.negativeNum = -1;
				end
				for x = 1, self.numberOfScans do
					local angleVariance = (-self.scanSpreadAngle*0.5) + (math.random()*self.scanSpreadAngle);
					local terrHitCount = 0;
					local dots = math.floor(self.maxScanRange/self.scanSpacing)
					for i = 1, dots do
						local checkPos = self.MuzzlePos + Vector((self.scanSpacing*i)*self.negativeNum,0):RadRotate(self.RotAngle):DegRotate(angleVariance);
						if SceneMan.SceneWrapsX == true then
							if checkPos.X > SceneMan.SceneWidth then
								checkPos = Vector(checkPos.X - SceneMan.SceneWidth,checkPos.Y);
							elseif checkPos.X < 0 then
								checkPos = Vector(SceneMan.SceneWidth + checkPos.X,checkPos.Y);
							end
						end
						local terrCheck = SceneMan:GetTerrMatter(checkPos.X,checkPos.Y);
						if terrCheck ~= 0 then
							terrHitCount = terrHitCount + 1;
						end
					end
					local scanLength = math.floor((self.maxScanRange-(self.scanDisruption*(terrHitCount/dots)))/self.scanSpacing);
					for i = 1, scanLength do
						local checkPos = self.MuzzlePos + Vector((self.scanSpacing*i)*self.negativeNum,0):RadRotate(self.RotAngle):DegRotate(angleVariance);
						if SceneMan.SceneWrapsX == true then
							if checkPos.X > SceneMan.SceneWidth then
								checkPos = Vector(checkPos.X - SceneMan.SceneWidth,checkPos.Y);
							elseif checkPos.X < 0 then
								checkPos = Vector(SceneMan.SceneWidth + checkPos.X,checkPos.Y);
							end
						end
						SceneMan:RevealUnseen(checkPos.X,checkPos.Y,self.parent.Team);
					end
				end
			end
		end
	end

end