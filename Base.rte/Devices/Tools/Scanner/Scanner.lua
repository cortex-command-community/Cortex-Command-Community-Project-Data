function Create(self)
	self.signalStrength = 1000;
	self.maxScanRange = 400;
	self.scanSpacing = 20;
	self.dotCount = math.floor(self.maxScanRange/self.scanSpacing);
	self.scanSpreadAngle = math.rad(self.ParticleSpreadRange);
end

function OnFire(self)
	local signalStrength = self.signalStrength;
	local angleVariance = self.scanSpreadAngle * 0.5 - (math.random() * self.scanSpreadAngle);
	for i = 1, self.dotCount do
		local checkPos = self.MuzzlePos + Vector((self.scanSpacing * i) * self.FlipFactor, 0):RadRotate(self.RotAngle + angleVariance);
		if SceneMan.SceneWrapsX then
			if checkPos.X > SceneMan.SceneWidth then
				checkPos = Vector(checkPos.X - SceneMan.SceneWidth, checkPos.Y);
			elseif checkPos.X < 0 then
				checkPos = Vector(checkPos.X + SceneMan.SceneWidth, checkPos.Y);
			end
		end
		signalStrength = signalStrength - (40 + SceneMan:GetMaterialFromID(SceneMan:GetTerrMatter(checkPos.X, checkPos.Y)).StructuralIntegrity);
		if signalStrength < 0 then
			break;
		end
		if SceneMan:IsUnseen(checkPos.X, checkPos.Y, self.Team) then
			SceneMan:RevealUnseen(checkPos.X, checkPos.Y, self.Team);
			break;
		end
	end
end