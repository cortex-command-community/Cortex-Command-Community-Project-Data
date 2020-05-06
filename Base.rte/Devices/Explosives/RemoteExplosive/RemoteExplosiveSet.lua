function Create(self)

	self.blinkTimer = Timer();

	self.actionPhase = 0;
	self.blink = false;
	self.stuck = false;

	self.alliedTeam = self.Sharpness;
	self.Team = self.alliedTeam;
	self.Sharpness = 0;

	if coalitionC4TableA == nil then
		coalitionC4TableA = {};
		coalitionC4TableB = {};
	end

	self.tableNum = #coalitionC4TableA+1;
	coalitionC4TableA[self.tableNum] = self;
	coalitionC4TableB[self.tableNum] = self.alliedTeam;

	self.breachStrength = 100;
end

function Update(self)

	if self.Sharpness == 0 then
		self.ToDelete = false;
		self.ToSettle = false;
	elseif self.Sharpness == 1 then
		self.ToDelete = true;
	elseif self.Sharpness == 2 then	-- Explode
		-- Gib the thing we're attached to if it's fragile enough
		if self.target and IsMOSRotating(self.target) then
			local targetStrength = math.sqrt(1 + math.abs(self.target.GibWoundLimit - self.target.WoundCount)) * (self.target.Material.StructuralIntegrity * 0.1 + math.sqrt(self.target.Diameter + self.target.Mass));
			if targetStrength < self.breachStrength then
				self.target:GibThis();
			end
		end
		self:GibThis();
	end

	if self.actionPhase == 0 then
		local rayHitPos = Vector();
		local rayHit = false;
		local checkVec = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(self.Radius + self.Vel.Magnitude * 0.3);
		for i = 1, 2 do
			local checkPos = self.Pos + (checkVec /i);
			local checkPix = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
			if checkPix ~= rte.NoMOID then
				checkPos = checkPos + SceneMan:ShortestDistance(checkPos, self.Pos, SceneMan.SceneWrapsX):SetMagnitude(3);
				self.target = ToMOSRotating(MovableMan:GetMOFromID(checkPix));
				self.stickPosition = SceneMan:ShortestDistance(self.target.Pos, checkPos, SceneMan.SceneWrapsX);
				self.stickRotation = self.target.RotAngle;
				self.stickDirection = self.RotAngle;
				local soundfx = CreateAEmitter("Remote Explosive Sound Activate");
				soundfx.Pos = self.Pos;
				MovableMan:AddParticle(soundfx);
				self.stuck = true;
				rayHit = true;
				break;
			end
		end
		if rayHit then
			self.actionPhase = 1;
		elseif SceneMan:CastStrengthRay(self.Pos, checkVec, 0, rayHitPos, 1, 0, SceneMan.SceneWrapsX) then
			self.Pos = rayHitPos + SceneMan:ShortestDistance(rayHitPos, self.Pos, SceneMan.SceneWrapsX):SetMagnitude(3);
			self.PinStrength = 1000;
			self.AngularVel = 0;
			self.stuck = true;
			self.actionPhase = 2;
			local soundfx = CreateAEmitter("Remote Explosive Sound Activate");
			soundfx.Pos = self.Pos;
			MovableMan:AddParticle(soundfx);
		end
	elseif self.actionPhase == 1 then
		if self.target and self.target.ID ~= rte.NoMOID then
			self.Pos = self.target.Pos + Vector(self.stickPosition.X, self.stickPosition.Y):RadRotate(self.target.RotAngle - self.stickRotation);
			self.RotAngle = self.stickDirection + (self.target.RotAngle - self.stickRotation);
			self.PinStrength = 1000;
			self.Vel = Vector();
		else
			self.PinStrength = 0;
			self.actionPhase = 0;
		end
	end
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
function Destroy(self)
	coalitionC4TableA[self.tableNum] = nil;
	coalitionC4TableB[self.tableNum] = nil;
end