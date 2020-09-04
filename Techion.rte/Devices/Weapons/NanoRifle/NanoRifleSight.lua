function Create(self)

	self.laserTimer = Timer();
	self.laserCheckDelay = 50;
	self.laserLength = self.SharpLength + FrameMan.PlayerScreenWidth/3;
	self.laserSpaceCheck = 8; --For optimization purposes. Smaller value means a more accurate but slower check.

	self.laserDensity = math.ceil(self.laserLength/self.laserSpaceCheck);
end

function Update(self)

	if self.laserTimer:IsPastSimMS(self.laserCheckDelay) then
		self.laserTimer:Reset();

		if self.RootID ~= self.ID then
			local actor = MovableMan:GetMOFromID(self.RootID);
			if MovableMan:IsActor(actor) and ToActor(actor):GetController():IsState(Controller.AIM_SHARP) then
				local roughLandPos = self.MuzzlePos + Vector(self.laserLength, 0):RadRotate(ToActor(actor):GetAimAngle(true));
				for i = 0, self.laserDensity do
					local checkPos = self.MuzzlePos + Vector(self.laserSpaceCheck * i, 0):RadRotate(ToActor(actor):GetAimAngle(true));
					if SceneMan.SceneWrapsX == true then
						if checkPos.X > SceneMan.SceneWidth then
							checkPos = Vector(checkPos.X - SceneMan.SceneWidth, checkPos.Y);
						elseif checkPos.X < 0 then
							checkPos = Vector(SceneMan.SceneWidth + checkPos.X, checkPos.Y);
						end
					end
					local terrCheck = SceneMan:GetTerrMatter(checkPos.X, checkPos.Y);
					if terrCheck == rte.airID then
						local moCheck = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
						if moCheck ~= rte.NoMOID and MovableMan:GetMOFromID(moCheck).Team ~= actor.Team then
							roughLandPos = checkPos;
							break;
						end
					else
						roughLandPos = checkPos;
						break;
					end
				end

				local checkRoughLandPos = roughLandPos + Vector(self.laserSpaceCheck * -1, 0):RadRotate(ToActor(actor):GetAimAngle(true));
				for i = 0, self.laserSpaceCheck do
					local checkPos = checkRoughLandPos + Vector(i, 0):RadRotate(ToActor(actor):GetAimAngle(true));
					if SceneMan.SceneWrapsX == true then
						if checkPos.X > SceneMan.SceneWidth then
							checkPos = Vector(checkPos.X - SceneMan.SceneWidth,checkPos.Y);
						elseif checkPos.X < 0 then
							checkPos = Vector(SceneMan.SceneWidth + checkPos.X,  checkPos.Y);
						end
					end
					local terrCheck = SceneMan:GetTerrMatter(checkPos.X, checkPos.Y);
					if terrCheck == rte.airID then
						local moCheck = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
						if moCheck ~= rte.NoMOID then
							break;
						end
					else
						break;
					end
					roughLandPos = checkPos;
				end

				local laserPar = CreateMOPixel("Nanorifle Laser Sight Glow");
				laserPar.Pos = roughLandPos;
				laserPar.Lifetime = self.laserCheckDelay * 2;
				MovableMan:AddParticle(laserPar);
			end
		end
	end
end