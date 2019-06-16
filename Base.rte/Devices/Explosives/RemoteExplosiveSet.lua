function Create(self)

	self.blinkTimer = Timer();

	self.actionPhase = 0;
	self.blink = false;
	self.stuck = false;

	self.alliedTeam = self.Sharpness;
	self.Sharpness = 0;

	if coalitionC4TableA == nil then
		coalitionC4TableA = {};
		coalitionC4TableB = {};
	end

	self.tableNum = #coalitionC4TableA+1;
	coalitionC4TableA[self.tableNum] = self;
	coalitionC4TableB[self.tableNum] = self.alliedTeam;

end

function Update(self)

	if self.Sharpness == 0 then
		self.ToDelete = false;
		self.ToSettle = false;
	elseif self.Sharpness == 1 then
		self.ToDelete = true;
	elseif self.Sharpness == 2 then
		self:GibThis();
	end

	if self.actionPhase == 0 then
		local rayHitPos = Vector(0,0);
		local rayHit = false;
		for i = 1, 15 do
			local checkPos = self.Pos + Vector(self.Vel.X,self.Vel.Y):SetMagnitude(i);
			local checkPix = SceneMan:GetMOIDPixel(checkPos.X,checkPos.Y);
			if checkPix ~= rte.NoMOID then
				checkPos = checkPos + SceneMan:ShortestDistance(checkPos,self.Pos,SceneMan.SceneWrapsX):SetMagnitude(3);
				self.target = MovableMan:GetMOFromID(checkPix);
				self.stickpositionX = checkPos.X-self.target.Pos.X;
				self.stickpositionY = checkPos.Y-self.target.Pos.Y;
				self.stickrotation = self.target.RotAngle;
				self.stickdirection = self.RotAngle;
				local soundfx = CreateAEmitter("Remote Explosive Sound Activate");
				soundfx.Pos = self.Pos;
				MovableMan:AddParticle(soundfx);
				self.stuck = true;
				rayHit = true;
				break;
			end
		end
		if rayHit == true then
			self.actionPhase = 1;
		else
			if SceneMan:CastStrengthRay(self.Pos,Vector(self.Vel.X,self.Vel.Y):SetMagnitude(15),0,rayHitPos,0,0,SceneMan.SceneWrapsX) == true then
				self.Pos = rayHitPos + SceneMan:ShortestDistance(rayHitPos,self.Pos,SceneMan.SceneWrapsX):SetMagnitude(3);
				self.PinStrength = 1000;
				self.AngularVel = 0;
				self.stuck = true;
				self.actionPhase = 2;
				local soundfx = CreateAEmitter("Remote Explosive Sound Activate");
				soundfx.Pos = self.Pos;
				MovableMan:AddParticle(soundfx);
			end
		end
	elseif self.actionPhase == 1 then
		if self.target ~= nil and self.target.ID ~= 255 then
			self.Pos = self.target.Pos + Vector(self.stickpositionX,self.stickpositionY):RadRotate(self.target.RotAngle-self.stickrotation);
			self.RotAngle = self.stickdirection+(self.target.RotAngle-self.stickrotation);
			self.PinStrength = 1000;
			self.Vel = Vector(0,0);
		else
			self.PinStrength = 0;
			self.actionPhase = 0;
		end
	end

	if self.stuck == true then
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
	end

end

function Destroy(self)

	coalitionC4TableA[self.tableNum] = nil;
	coalitionC4TableB[self.tableNum] = nil;

end