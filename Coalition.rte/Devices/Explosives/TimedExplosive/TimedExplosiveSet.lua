function Create(self)

	self.lifeTimer = Timer();
	self.blinkTimer = Timer();
	self.blipTimer = Timer();

	self.actionPhase = 0;
	self.changeCounter = 0;
	self.stuck = false;
	self.blipdelay = 1000;

	self.minBlipDelay = 100;
	self.medBlipDelay = 250;
	self.maxBlipDelay = 500;
	
	self.detonateDelay = 11000;
	self.Frame = 1;

	self.breachStrength = 100;
end

function Update(self)

	if self.actionPhase == 0 then
		local rayHitPos = Vector();
		local rayHit = false;
		local trace = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(self.Vel.Magnitude * rte.PxTravelledPerFrame + self.Radius);
		local dots = trace.Magnitude/2;
		for i = 1, dots do
			local checkPos = self.Pos + Vector(trace.X, trace.Y) * (i/dots);
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
		if rayHit == true then
			self.actionPhase = 1;
		else
			if SceneMan:CastStrengthRay(self.Pos, trace, 0, rayHitPos, 0, rte.airID, SceneMan.SceneWrapsX) == true then
				self.Pos = rayHitPos + SceneMan:ShortestDistance(rayHitPos, self.Pos, SceneMan.SceneWrapsX):SetMagnitude(3);
				self.PinStrength = 1000;
				self.Vel = Vector();
				self.AngularVel = 0;
				self.stuck = true;
				self.actionPhase = 2;
				AudioMan:PlaySound("Base.rte/Devices/Explosives/RemoteExplosive/Sounds/RemoteExplosiveActivate.wav", self.Pos);
			end
		end
	elseif self.actionPhase == 1 then
		if self.target ~= nil and self.target.ID ~= rte.NoMOID then
			self.Pos = self.target.Pos + Vector(self.stickPosition.X, self.stickPosition.Y):RadRotate(self.target.RotAngle - self.stickRotation);
			self.RotAngle = self.stickDirection + (self.target.RotAngle - self.stickRotation);
			self.PinStrength = 1000;
			self.Vel = Vector();
			self.AngularVel = 0;
		else
			self.PinStrength = 0;
			self.actionPhase = 0;
		end
	end

	if self.stuck == true then

		if self.lifeTimer:IsPastSimMS(self.detonateDelay) then
			--Gib the thing we're attached to if it's fragile enough
			if self.target ~= nil and IsMOSRotating(self.target) then
				local targetStrength = math.sqrt(1 + math.abs(self.target.GibWoundLimit - self.target.WoundCount)) * (self.target.Material.StructuralIntegrity * 0.1 + math.sqrt(self.target.Diameter + self.target.Mass));
				if targetStrength < self.breachStrength then
					self.target:GibThis();
				end
			end
			self:GibThis();
		else
			self.ToDelete = false;
			self.ToSettle = false;
		
			local number = math.ceil((self.detonateDelay - self.lifeTimer.ElapsedSimTimeMS)/100)/10;
			local text = "".. number;
			if number == math.ceil(number) then
				text = text ..".0";
			end
			for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do

				local screen = ActivityMan:GetActivity():ScreenOfPlayer(player);
				if screen ~= -1 and not SceneMan:IsUnseen(self.Pos.X, self.Pos.Y, ActivityMan:GetActivity():GetTeamOfPlayer(player)) then
					PrimitiveMan:DrawTextPrimitive(screen, self.Pos + Vector(-self.Radius/3, -self.Diameter), text, true, 0);
				end
			end
		end

		if self.blipTimer:IsPastSimMS(50) then
			self.Frame = 0;
		else
			self.Frame = 1;
		end

		if self.blipTimer:IsPastSimMS(self.blipdelay) then
			self.blipTimer:Reset();
			self.blinkTimer:Reset();
			AudioMan:PlaySound("Coalition.rte/Devices/Explosives/TimedExplosive/Sounds/TimedExplosiveBlip.wav", self.Pos);

			if self.changeCounter == 0 and self.lifeTimer.ElapsedSimTimeMS > (self.detonateDelay * 0.85 - 5000) then
				self.changeCounter = 1;
				self.blipdelay = self.maxBlipDelay;
			end

			if self.changeCounter == 1 and self.lifeTimer.ElapsedSimTimeMS > (self.detonateDelay * 0.90 - 3000) then
				self.changeCounter = 2;
				self.blipdelay = self.medBlipDelay;
			end

			if self.changeCounter == 2 and self.lifeTimer.ElapsedSimTimeMS > (self.detonateDelay * 0.95 - 1000) then
				self.changeCounter = 3;
				self.blipdelay = self.minBlipDelay;
			end
		end
	end
end