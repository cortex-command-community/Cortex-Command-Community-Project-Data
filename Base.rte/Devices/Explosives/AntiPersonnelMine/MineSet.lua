function Create(self)

	self.delayTimer = Timer();
	self.blinkTimer = Timer();
	self.dustTimer = Timer();
	self.actionPhase = 0;
	self.faceDirection = 0;
	self.dustDelay = 0;
	self.tempLaserLength = 0;

	self.laserLength = 80;
	self.minVisualDelay = 0;
	self.maxVisualDelay = 200;

	self.alliedTeam = self.Sharpness;
	self.Sharpness = 0;

	self.blink = false;
	self.Frame = (self.alliedTeam+1)*2;

	if coalitionMineTable == nil then
		coalitionMineTable = {};
	end

	self.tableNum = #coalitionMineTable+1;
	coalitionMineTable[self.tableNum] = self;

end

function Update(self)

	if self.Sharpness == 0 then
		self.ToDelete = false;
		self.ToSettle = false;
		if coalitionMineTable == nil then
			coalitionMineTable = {};
			coalitionMineTable[self.tableNum] = self;
		end
	else
		self.ToDelete = true;
	end

	if self.actionPhase == 0 then

		local rayHitPos = Vector(0,0);
		local terrainRaycast = SceneMan:CastStrengthRay(self.Pos,Vector(self.Vel.X,self.Vel.Y):SetMagnitude(15),0,rayHitPos,0,0,SceneMan.SceneWrapsX);

		if terrainRaycast == true then

			local rayHitPosA = Vector(0,0);
			local terrainRaycastA = SceneMan:CastStrengthRay(self.Pos+Vector(0,3):RadRotate(Vector(self.Vel.X,self.Vel.Y).AbsRadAngle),Vector(self.Vel.X,self.Vel.Y):SetMagnitude(20),0,rayHitPosA,0,0,SceneMan.SceneWrapsX);

			local rayHitPosB = Vector(0,0);
			local terrainRaycastB = SceneMan:CastStrengthRay(self.Pos+Vector(0,-3):RadRotate(Vector(self.Vel.X,self.Vel.Y).AbsRadAngle),Vector(self.Vel.X,self.Vel.Y):SetMagnitude(20),0,rayHitPosB,0,0,SceneMan.SceneWrapsX);

			if terrainRaycastA == true and terrainRaycastB == true then
				self.faceDirection = SceneMan:ShortestDistance(rayHitPosA,rayHitPosB,SceneMan.SceneWrapsX).AbsRadAngle+(math.pi/2);
			else
				self.faceDirection = (self.Vel*-1).AbsRadAngle;
			end

			self.Pos = rayHitPos + SceneMan:ShortestDistance(rayHitPos,self.Pos,SceneMan.SceneWrapsX):SetMagnitude(3);
			self.RotAngle = self.faceDirection-(math.pi/2);
			self.PinStrength = 1000;
			self.actionPhase = 1;
			self.delayTimer:Reset();
		end

	elseif self.actionPhase == 1 then

		if self.blinkTimer:IsPastSimMS(500) then

			self.blinkTimer:Reset();

			if self.blink == false then
				self.blink = true;
				self.Frame = (self.alliedTeam+1)*2;
			else
				self.blink = false;
				self.Frame = ((self.alliedTeam+1)*2)+1;
			end

		end

		if self.delayTimer:IsPastSimMS(100) then

			self.delayTimer:Reset();

			local rayHitPos = Vector(0,0);
			local terrainRaycast = SceneMan:CastStrengthRay(self.Pos,Vector(self.laserLength,0):RadRotate(self.faceDirection),0,rayHitPos,0,0,SceneMan.SceneWrapsX);

			if terrainRaycast == true then
				self.tempLaserLength = SceneMan:ShortestDistance(self.Pos,rayHitPos,SceneMan.SceneWrapsX).Magnitude;
			else
				self.tempLaserLength = self.laserLength;
			end

			local raycast = SceneMan:CastMORay(self.Pos,Vector(self.tempLaserLength,0):RadRotate(self.faceDirection),self.ID,self.alliedTeam,0,false,4);
			if raycast ~= rte.NoMOID then
				local targetpart = MovableMan:GetMOFromID(raycast);
				local target = MovableMan:GetMOFromID(targetpart.RootID);
				if MovableMan:IsActor(target) then
					if ToActor(target).Team ~= self.alliedTeam then
						self.actionPhase = 2;
						self.blink = false;
					end
				else
					self.actionPhase = 2;
					self.blink = false;
				end
			end

		end

		if self.dustTimer:IsPastSimMS(self.dustDelay) then

			local dustBrightness = math.ceil(math.random()*7);

			if dustBrightness > 0 then

				self.dustTimer:Reset();
				self.dustDelay = (math.random()*(self.maxVisualDelay-self.minVisualDelay))+self.minVisualDelay;

				local dustPos = (math.random()*(self.tempLaserLength-3))+3;

				local effectpar = CreateMOPixel("Mine Laser Particle "..dustBrightness);
				effectpar.Pos = self.Pos + Vector(dustPos,0):RadRotate(self.faceDirection);
				MovableMan:AddParticle(effectpar);

				if dustBrightness >= 3 then
					local effectpar = CreateMOPixel("Mine Laser Particle "..(dustBrightness-2));
					effectpar.Pos = self.Pos + Vector(dustPos+2,0):RadRotate(self.faceDirection);
					MovableMan:AddParticle(effectpar);

					local effectpar = CreateMOPixel("Mine Laser Particle "..(dustBrightness-2));
					effectpar.Pos = self.Pos + Vector(dustPos-2,0):RadRotate(self.faceDirection);
					MovableMan:AddParticle(effectpar);

					if dustBrightness >= 5 then
						local effectpar = CreateMOPixel("Mine Laser Particle "..(dustBrightness-4));
						effectpar.Pos = self.Pos + Vector(dustPos+4,0):RadRotate(self.faceDirection);
						MovableMan:AddParticle(effectpar);

						local effectpar = CreateMOPixel("Mine Laser Particle "..(dustBrightness-4));
						effectpar.Pos = self.Pos + Vector(dustPos-4,0):RadRotate(self.faceDirection);
						MovableMan:AddParticle(effectpar);
					end
				end
			end

		end

	elseif self.actionPhase == 2 then

		if self.blink == false then
			self.blink = true;
			self.Frame = ((self.alliedTeam+1)*2)+1;
			self.delayTimer:Reset();
			local soundfx = CreateAEmitter("Mine Sound Detonate");
			soundfx.Pos = self.Pos;
			MovableMan:AddParticle(soundfx);
		end

		if self.delayTimer:IsPastSimMS(300) then
			self:GibThis();
		end

	end

end

function Destroy(self)

	coalitionMineTable[self.tableNum] = nil;

end