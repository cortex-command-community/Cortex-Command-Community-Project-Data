function Create(self)

	if g_nucleocommunicationtable == nil then
		g_nucleocommunicationtable = {};
	end

	if g_nucleocommunicationtable[self.Sharpness] == nil then
		g_nucleocommunicationtable[self.Sharpness] = {};
	end

	g_nucleocommunicationtable[self.Sharpness][#g_nucleocommunicationtable[self.Sharpness] + 1] = {self.UniqueID, self};

	self.detTimer = Timer();
	self.boom = false;

	self.detDelay = 4000/math.sqrt(#g_nucleocommunicationtable[self.Sharpness]);
	self.speed = 15;
	self.acceleration = 0.1;
	self.disintegrationStrength = 75;

	self.linkRange = 100 + (FrameMan.PlayerScreenWidth + FrameMan.PlayerScreenHeight) * 0.25;
	self.linkPullRatio = 0.005;
	--Table of colors being used in primitive effects
	self.colors = {5, 186, 198, 196};
end

function Update(self)

	local target;

	if self.detTimer:IsPastSimMS(self.detDelay) then
		self.boom = true;
	else
		local moid = SceneMan:CastMORay(self.Pos, self.Vel * rte.PxTravelledPerFrame, rte.NoMOID, self.Team, rte.airID, true, 1);
		if moid ~= rte.NoMOID then
			local hitPos = Vector();
			SceneMan:CastFindMORay(self.Pos, self.Vel * rte.PxTravelledPerFrame, moid, hitPos, rte.airID, true, 1);
			self.Pos = hitPos;
			self.boom = true;
			self.hitTarget = true;
			target = MovableMan:GetMOFromID(moid);
		end
	end
	
	PrimitiveMan:DrawCirclePrimitive(self.Pos, self.Radius, self.colors[math.random(#self.colors)]);

	if g_nucleocommunicationtable[self.Sharpness] ~= nil then
		for i = 1, #g_nucleocommunicationtable[self.Sharpness] do
			if g_nucleocommunicationtable[self.Sharpness][i][1] == self.UniqueID then
				if g_nucleocommunicationtable[self.Sharpness][i][2].UniqueID ~= self.UniqueID then
					g_nucleocommunicationtable[self.Sharpness][i][2] = self;
				end
			else
				local raydirection = SceneMan:ShortestDistance(self.Pos,g_nucleocommunicationtable[self.Sharpness][i][2].Pos,SceneMan.SceneWrapsX)
				if MovableMan:IsParticle(g_nucleocommunicationtable[self.Sharpness][i][2]) and raydirection.Magnitude < self.linkRange then
				
					local dist = SceneMan:ShortestDistance(self.Pos, g_nucleocommunicationtable[self.Sharpness][i][2].Pos, SceneMan.SceneWrapsX);
					PrimitiveMan:DrawLinePrimitive(self.Pos + Vector(math.random(-1, 1), math.random(-1, 1)), self.Pos + dist + Vector(math.random(-1, 1), math.random(-1, 1)), self.colors[math.random(#self.colors)]);
					--The projectiles are drawn towards each other
					self.Vel = self.Vel + dist * rte.PxTravelledPerFrame * self.linkPullRatio;

					local moid = SceneMan:CastMORay(self.Pos, raydirection, rte.NoMOID, self.Team, rte.airID, true, 1);
					if moid ~= rte.NoMOID then
						local hitPos = Vector();
						SceneMan:CastFindMORay(self.Pos, raydirection, moid, hitPos, rte.airID, true, 1);
						self.Pos = hitPos;
						self.boom = true;
						self.hitTarget = true;
						target = MovableMan:GetMOFromID(moid);
					end
				end
			end
		end
	else
		g_nucleocommunicationtable[self.Sharpness] = {};
		g_nucleocommunicationtable[self.Sharpness][#g_nucleocommunicationtable[self.Sharpness] + 1] = {self.UniqueID,self};
	end
	self.Vel = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(math.min(self.Vel.Magnitude + self.acceleration, self.speed));
	self.AngularVel = self.AngularVel * 0.9;
	self.RotAngle = 0;

	if self.hitTarget then
		for i = 1, #g_nucleocommunicationtable[self.Sharpness] do
			if g_nucleocommunicationtable[self.Sharpness][i][1] ~= self.UniqueID and MovableMan:IsParticle(g_nucleocommunicationtable[self.Sharpness][i][2]) then
				g_nucleocommunicationtable[self.Sharpness][i][2].Pos = self.Pos + Vector(math.random() * 5, 0):RadRotate(math.random() * math.pi * 2);
				g_nucleocommunicationtable[self.Sharpness][i][2]:SetNumberValue("GOBOOM", 1);
			end
		end
	end

	if self.boom or self:NumberValueExists("GOBOOM") then
		local particleCount = 13;
		for i = 1, particleCount do
			local blastpar = i < particleCount * 0.5 and CreateMOPixel("Nucleo Damage Particle") or CreateMOPixel("Nucleo Air Blast");

			local randomDir = Vector(40, 0):RadRotate(math.random() * math.pi * 2);
			blastpar.Pos = self.Pos - Vector(randomDir.X, randomDir.Y);
			blastpar.Vel = Vector(randomDir.X, randomDir.Y);
			blastpar.Team = self.Team;
			blastpar.IgnoresTeamHits = true;
			MovableMan:AddParticle(blastpar);
		end

		if target then
			local parent = MovableMan:GetMOFromID(target.RootID);
			if IsActor(parent) then
				local melt = CreateMOPixel("Disintegrator");
				melt.Pos = self.Pos;
				melt.Team = self.Team;
				melt.Sharpness = ToActor(parent).ID;
				melt.PinStrength = self.disintegrationStrength * math.sqrt(#g_nucleocommunicationtable[self.Sharpness]);
				MovableMan:AddMO(melt);
			end
		end
		
		local blastpar = CreateMOSRotating("Nucleo Explosion");
		blastpar.Pos = self.Pos;
		blastpar:GibThis();
		MovableMan:AddParticle(blastpar);

		self.ToDelete = true;
	end
end

function Destroy(self)
	if g_nucleocommunicationtable and self.Sharpness and g_nucleocommunicationtable[self.Sharpness] then
		for i = 1, #g_nucleocommunicationtable[self.Sharpness] do
			if g_nucleocommunicationtable[self.Sharpness][i][1] == self.UniqueID then
				g_nucleocommunicationtable[self.Sharpness][i] = nil;
			end
		end

		local temptable = {};
		for i = 1, #g_nucleocommunicationtable[self.Sharpness] do
			if g_nucleocommunicationtable[self.Sharpness][i] ~= nil then
				temptable[#temptable + 1] = g_nucleocommunicationtable[self.Sharpness][i];
			end
		end
		g_nucleocommunicationtable[self.Sharpness] = temptable;

		if #g_nucleocommunicationtable[self.Sharpness] == 0 then
			g_nucleocommunicationtable[self.Sharpness] = nil;
		end
	end
end