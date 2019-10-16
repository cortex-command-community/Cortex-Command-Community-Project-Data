function Create(self)

	if g_nucleocommunicationtable == nil then
		g_nucleocommunicationtable = {};
	end

	if g_nucleocommunicationtable[self.Sharpness] == null then
		g_nucleocommunicationtable[self.Sharpness] = {};
	end

	g_nucleocommunicationtable[self.Sharpness][#g_nucleocommunicationtable[self.Sharpness]+1] = {self.UniqueID,self};

	self.detTimer = Timer();
	self.boom = false;

	self.detDelay = 5000;
	self.speed = 10;

	self.linkRange = 500;

end

function Update(self)

	self.Vel = Vector(self.Vel.X,self.Vel.Y):SetMagnitude(self.speed);

	if self.detTimer:IsPastSimMS(self.detDelay) then
		self.boom = true;
	else
		local moid = SceneMan:CastMORay(self.Pos, self.Vel * TimerMan.DeltaTimeSecs * 20, 0, self.Team, 0, true, 1);
		if moid ~= 255 then
			local hitPos = Vector();
			SceneMan:CastFindMORay(self.Pos, self.Vel * TimerMan.DeltaTimeSecs * 20, moid, hitPos, 0, true, 1);
			self.Pos = hitPos;
			self.boom = true;
			self.hitTarget = true;
		end
	end

	if g_nucleocommunicationtable[self.Sharpness] ~= null then
		for i = 1, #g_nucleocommunicationtable[self.Sharpness] do
			if g_nucleocommunicationtable[self.Sharpness][i][1] == self.UniqueID then
				if g_nucleocommunicationtable[self.Sharpness][i][2].UniqueID ~= self.UniqueID then
					g_nucleocommunicationtable[self.Sharpness][i][2] = self;
				end
			else
				local raydirection = SceneMan:ShortestDistance(self.Pos,g_nucleocommunicationtable[self.Sharpness][i][2].Pos,SceneMan.SceneWrapsX)
				if MovableMan:IsParticle(g_nucleocommunicationtable[self.Sharpness][i][2]) and raydirection.Magnitude < self.linkRange then
					FrameMan:DrawLinePrimitive(self.Pos, g_nucleocommunicationtable[self.Sharpness][i][2].Pos, 5);
					local moid = SceneMan:CastMORay(self.Pos, raydirection, 0, self.Team, 0, true, 1);
					if moid ~= 255 then
						local hitPos = Vector();
						SceneMan:CastFindMORay(self.Pos, raydirection, moid, hitPos, 0, true, 1);
						self.Pos = hitPos;
						self.boom = true;
						self.hitTarget = true;
					end
				end
			end
		end
	else
		g_nucleocommunicationtable[self.Sharpness] = {};
		g_nucleocommunicationtable[self.Sharpness][#g_nucleocommunicationtable[self.Sharpness]+1] = {self.UniqueID,self};
	end

	if self.hitTarget then
		for i = 1, #g_nucleocommunicationtable[self.Sharpness] do
			if g_nucleocommunicationtable[self.Sharpness][i][1] ~= self.UniqueID and MovableMan:IsParticle(g_nucleocommunicationtable[self.Sharpness][i][2]) then
				g_nucleocommunicationtable[self.Sharpness][i][2].Pos = self.Pos + Vector(math.random()*5,0):RadRotate(math.random()*math.pi*2);
				g_nucleocommunicationtable[self.Sharpness][i][2].PresetName = "GOBOOM";
			end
		end
	end

	if self.boom or self.PresetName == "GOBOOM" then

		for i = 1, 10 do
			local blastpar = CreateMOPixel("Nucleo Damage Particle");
			blastpar.Pos = self.Pos;
			blastpar.Vel = Vector(40,0):RadRotate(math.random()*math.pi*2);
			blastpar.Team = self.Team;
			MovableMan:AddParticle(blastpar);
		end

		for i = 1, 15 do
			local blastpar = CreateMOPixel("Nucleo Air Blast");
			blastpar.Pos = self.Pos;
			blastpar.Vel = Vector(13,0):RadRotate(math.random()*math.pi*2);
			blastpar.Team = self.Team;
			MovableMan:AddParticle(blastpar);
		end

		local blastpar = CreateMOSRotating("Nucleo Explosion");
		blastpar.Pos = self.Pos;
		blastpar:GibThis();
		MovableMan:AddParticle(blastpar);

		self.ToDelete = true;
	end

end

function Destroy(self)
	if g_nucleocommunicationtable and self.Sharpness then
		for i = 1, #g_nucleocommunicationtable[self.Sharpness] do
			if g_nucleocommunicationtable[self.Sharpness][i][1] == self.UniqueID then
				g_nucleocommunicationtable[self.Sharpness][i] = null;
			end
		end

		local temptable = {};
		for i = 1, #g_nucleocommunicationtable[self.Sharpness] do
			if g_nucleocommunicationtable[self.Sharpness][i] ~= null then
				temptable[#temptable+1] = g_nucleocommunicationtable[self.Sharpness][i];
			end
		end
		g_nucleocommunicationtable[self.Sharpness] = temptable;

		if #g_nucleocommunicationtable[self.Sharpness] == 0 then
			g_nucleocommunicationtable[self.Sharpness] = null;
		end
	end
end