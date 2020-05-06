function Create(self)

	self.delayTimer = Timer();
	self.blinkTimer = Timer();
	self.actionPhase = 0;
	self.faceDirection = 0;
	self.detectionAngleTurn = math.random() * math.pi;
	self.detectionAngleDegrees = 50;
	self.detectionTurnSpeed = 25;
	self.tempLaserLength = 0;

	self.laserLength = 80;

	self.alliedTeam = self.Sharpness;
	self.Team = self.alliedTeam;
	self.IgnoresTeamHits = true;
	self.Sharpness = 0;

	self.blink = false;
	self.Frame = (self.alliedTeam+1)*2;

	if coalitionMineTable == nil then
		coalitionMineTable = {};
	end

	self.tableNum = #coalitionMineTable+1;
	coalitionMineTable[self.tableNum] = self;

	self.checkDelay = 100;
	self.checkDelayExtension = 0.1;
	self.detonateThreshold = 10;
	self.detonateDelay = 200;
end

function Update(self)

	self.ToSettle = false;
	if coalitionMineTable == nil then
		coalitionMineTable = {};
		coalitionMineTable[self.tableNum] = self;
	end
	if self.Sharpness ~= 0 then
		self.ToDelete = true;
	end

	if self.actionPhase == 0 then

		local trace = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(self.Radius + self.Vel.Magnitude);
		local rayHitPos = Vector();
		local terrainRaycast = SceneMan:CastStrengthRay(self.Pos, trace, 5, rayHitPos, 0, 0, SceneMan.SceneWrapsX);

		if terrainRaycast == true then

			trace = Vector(trace.X, trace.Y):SetMagnitude(trace.Magnitude + 5);
			local rayHitPosA = Vector();
			local terrainRaycastA = SceneMan:CastStrengthRay(self.Pos + Vector(0, 3):RadRotate(Vector(self.Vel.X,self.Vel.Y).AbsRadAngle), trace, 5, rayHitPosA, 0, 0, SceneMan.SceneWrapsX);

			local rayHitPosB = Vector();
			local terrainRaycastB = SceneMan:CastStrengthRay(self.Pos + Vector(0,-3):RadRotate(Vector(self.Vel.X,self.Vel.Y).AbsRadAngle), trace, 5, rayHitPosB, 0, 0, SceneMan.SceneWrapsX);

			if terrainRaycastA == true and terrainRaycastB == true then
				self.faceDirection = SceneMan:ShortestDistance(rayHitPosA, rayHitPosB, SceneMan.SceneWrapsX).AbsRadAngle + (math.pi /2);
			else
				self.faceDirection = (self.Vel*-1).AbsRadAngle;
			end

			self.Pos = rayHitPos + SceneMan:ShortestDistance(rayHitPos,self.Pos,SceneMan.SceneWrapsX):SetMagnitude(2);
			self.RotAngle = self.faceDirection-(math.pi/2);
			self.PinStrength = self.GibImpulseLimit;
			self.actionPhase = 1;
			AudioMan:PlaySound("Base.rte/Devices/Explosives/AntiPersonnelMine/Sounds/MineActivate.wav", SceneMan:TargetDistanceScalar(self.Pos), false, true, -1);
			self.delayTimer:Reset();
		end

	elseif self.actionPhase == 1 then
	
		self.Vel = self.PinStrength == 0 and self.Vel or Vector();

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
		
		if self.delayTimer:IsPastSimMS(self.checkDelay) then
			self.checkDelay = self.checkDelay + self.checkDelayExtension;
			
			self.detectionAngleTurn = self.detectionAngleTurn + math.rad(self.detectionTurnSpeed);
			local detectionAngle = self.faceDirection + (math.sin(self.detectionAngleTurn) * math.rad(self.detectionAngleDegrees / 2));
			
			self.delayTimer:Reset();

			local rayHitPos = Vector();
			local startPos = self.Pos + Vector(self.Radius, 0):RadRotate(detectionAngle);
			local terrainRaycast = SceneMan:CastStrengthRay(startPos, Vector(self.laserLength, 0):RadRotate(detectionAngle), 10, rayHitPos, 1, 0, SceneMan.SceneWrapsX);

			if terrainRaycast == true then
				self.tempLaserLength = SceneMan:ShortestDistance(startPos,rayHitPos,SceneMan.SceneWrapsX).Magnitude;
			else
				self.tempLaserLength = self.laserLength;
			end
			local raycast = SceneMan:CastMORay(startPos,Vector(self.tempLaserLength,0):RadRotate(detectionAngle),self.ID,self.alliedTeam,0,true,4);
			if raycast ~= rte.NoMOID then
				local targetpart = ToMOSRotating(MovableMan:GetMOFromID(raycast));
				local target = ToMOSRotating(MovableMan:GetMOFromID(targetpart.RootID));
				if not (target.Team == self.alliedTeam and IsActor(target)) and (target.Vel.Magnitude * (1 + math.abs(target.AngularVel) + math.sqrt(target.Radius))) > self.detonateThreshold then
					self.actionPhase = 2;
					self.blink = false;
					self.faceDirection = detectionAngle;
				end
			end
			local effectpar = CreateMOPixel("Mine Laser Beam ".. math.random(3));
			effectpar.Pos = startPos + Vector(math.random() * self.tempLaserLength, 0):RadRotate(detectionAngle);
			effectpar.EffectRotAngle = detectionAngle;
			MovableMan:AddParticle(effectpar);
		end

	elseif self.actionPhase == 2 then

		if self.blink == false then
			self.blink = true;
			self.Frame = ((self.alliedTeam+1)*2)+1;
			self.delayTimer:Reset();
			AudioMan:PlaySound("Base.rte/Devices/Explosives/AntiPersonnelMine/Sounds/MineDetonate.wav", SceneMan:TargetDistanceScalar(self.Pos), false, true, -1);
		end
		if self.delayTimer:IsPastSimMS(self.detonateDelay) then
			self.Vel = Vector(25, 0):RadRotate(self.faceDirection);
			self:GibThis();
		end
	end
end
function Destroy(self)
	coalitionMineTable[self.tableNum] = nil;
end