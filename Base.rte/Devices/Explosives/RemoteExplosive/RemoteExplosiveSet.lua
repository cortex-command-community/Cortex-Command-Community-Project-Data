function Create(self)

	self.blinkTimer = Timer();

	self.actionPhase = 0;
	self.blink = false;
	self.stuck = false;

	self.alliedTeam = self.Sharpness;
	self.Team = self.alliedTeam;
	self.Sharpness = 0;

	if RemoteExplosiveTableA == nil then
		RemoteExplosiveTableA = {};
		RemoteExplosiveTableB = {};
	end

	self.tableNum = #RemoteExplosiveTableA + 1;
	RemoteExplosiveTableA[self.tableNum] = self;
	RemoteExplosiveTableB[self.tableNum] = self.alliedTeam;

	RemoteExplosiveStick(self);
end

function Update(self)

	if self.Sharpness == 0 then
		self.ToDelete = false;
		self.ToSettle = false;
	elseif self.Sharpness == 1 then
		self.ToDelete = true;
	elseif self.Sharpness == 2 then	--Explode
		self.Vel = Vector(10, 0):RadRotate(self.RotAngle);
		self:GibThis();
	end

	RemoteExplosiveStick(self);

	if self.stuck then
		if self.blinkTimer:IsPastSimMS(500) then
			self.blinkTimer:Reset();
			if self.blink == false then
				self.blink = true;
				self.Frame = (self.alliedTeam + 1) * 2;
			else
				self.blink = false;
				self.Frame = ((self.alliedTeam + 1) * 2) + 1;
			end
		end
	end
end
function RemoteExplosiveStick(self)

	if self.actionPhase == 0 then
		local rayHitPos = Vector();
		local rayHit = false;
		local checkVec = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(math.max(self.Vel.Magnitude * rte.PxTravelledPerFrame, ToMOSprite(self):GetSpriteWidth()));
		for i = 1, 2 do
			local checkPos = self.Pos + (checkVec/i);
			local checkPix = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
			if checkPix ~= rte.NoMOID then
				checkPos = checkPos + SceneMan:ShortestDistance(checkPos, self.Pos, SceneMan.SceneWrapsX):SetMagnitude(3);
				self.target = ToMOSRotating(MovableMan:GetMOFromID(checkPix));
				self.stickPosition = SceneMan:ShortestDistance(self.target.Pos, checkPos, SceneMan.SceneWrapsX);
				self.stickRotation = self.target.RotAngle;
				self.stickDirection = self.RotAngle;

				AudioMan:PlaySound("Base.rte/Devices/Explosives/RemoteExplosive/Sounds/RemoteExplosiveActivate.wav", self.Pos);
				self.stuck = true;
				rayHit = true;
				break;
			end
		end
		if rayHit then
			self.actionPhase = 1;
		elseif SceneMan:CastStrengthRay(self.Pos, checkVec, 0, rayHitPos, 1, rte.airID, SceneMan.SceneWrapsX) then
			self.Pos = rayHitPos + SceneMan:ShortestDistance(rayHitPos, self.Pos, SceneMan.SceneWrapsX):SetMagnitude(3);
			self.PinStrength = 1000;
			self.AngularVel = 0;
			self.stuck = true;
			self.actionPhase = 2;

			AudioMan:PlaySound("Base.rte/Devices/Explosives/RemoteExplosive/Sounds/RemoteExplosiveActivate.wav", self.Pos);
		end
	else
		self.Vel = Vector();
		self.AngularVel = 0;
		if self.actionPhase == 1 then
			if self.target and self.target.ID ~= rte.NoMOID and not self.target.ToDelete then
				self.Pos = self.target.Pos + Vector(self.stickPosition.X, self.stickPosition.Y):RadRotate(self.target.RotAngle - self.stickRotation);
				self.RotAngle = self.stickDirection + (self.target.RotAngle - self.stickRotation);
				self.PinStrength = 1000;
				self.Vel = Vector();
			else
				self.PinStrength = 0;
				self.actionPhase = 0;
			end
		end
	end
end
function Destroy(self)
	RemoteExplosiveTableA[self.tableNum] = nil;
	RemoteExplosiveTableB[self.tableNum] = nil;
end