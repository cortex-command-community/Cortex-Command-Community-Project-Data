function ConstructorWrapPos(checkPos)
	if SceneMan.SceneWrapsX == true then
		if checkPos.X > SceneMan.SceneWidth then
			checkPos = Vector(checkPos.X - SceneMan.SceneWidth,checkPos.Y);
		elseif checkPos.X < 0 then
			checkPos = Vector(SceneMan.SceneWidth + checkPos.X,checkPos.Y);
		end
	end
	return checkPos;
end

function ConstructorTerrainRay(start, trace, skip)

	local length = trace.Magnitude;
	local angle = trace.AbsRadAngle;

	local density = math.ceil(length/skip);

	local roughLandPos = start + Vector(length,0):RadRotate(angle);
	for i = 0, density do
		local invector = start + Vector(skip*i,0):RadRotate(angle);
		local checkPos = ConstructorWrapPos(invector);
		local terrCheck = SceneMan:GetTerrMatter(checkPos.X,checkPos.Y);
		if terrCheck ~= 0 then
			roughLandPos = checkPos;
			break;
		end
	end

	local checkRoughLandPos = roughLandPos + Vector(skip*-1,0):RadRotate(angle);
	for i = 0, skip do
		local invector = checkRoughLandPos + Vector(i,0):RadRotate(angle);
		local checkPos = ConstructorWrapPos(invector);
		local terrCheck = SceneMan:GetTerrMatter(checkPos.X,checkPos.Y);
		roughLandPos = checkPos;
		if terrCheck ~= 0 then
			break;
		end
	end

	return roughLandPos;

end

function Create(self)

	self.fireTimer = Timer();
	self.fired = false;

	self.buildTimer = Timer();
	self.buildlist = {};
	self.resource = 1;

	if g_constructorbuildmetal == nil then
		g_constructorbuildmetal = {};

		for i = 1, 12 do
			for j = 1, 24 do
				local y = {};
				for k = 1, 24 do
					local x = {};
					y[k] = x;
				end
				g_constructorbuildmetal[i] = y;
			end
		end

		for i = 1, 24 do
			g_constructorbuildmetal[2][11][i] = 1;
			g_constructorbuildmetal[2][12][i] = 2;
			g_constructorbuildmetal[2][13][i] = 2;
			g_constructorbuildmetal[2][14][i] = 1;
		end
	end

	self.clearer = CreateMOSRotating("Constructor Terrain Clearer");

	self.diglength = 50;
	self.digspersecond = 100;
	self.buildspersecond = 100;

end

function Update(self)
	
	if self.RootID ~= 255 then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if MovableMan:IsActor(actor) then
			if self.Magazine ~= nil then
				self.Magazine.RoundCount = self.resource;
			end

			if self.Sharpness == 0 then

				if ToActor(actor):GetController():IsState(Controller.WEAPON_FIRE) then

					local angle = ToActor(actor):GetAimAngle(true);

					local digamount = (self.fireTimer.ElapsedSimTimeMS/1000)*self.digspersecond;
					self.fireTimer:Reset();

					for i = 1, digamount do

						local digpos = ConstructorTerrainRay(self.MuzzlePos, Vector(self.diglength,0):RadRotate(angle + (math.random()*(math.pi/4)) - (math.pi/8)), 1);

						if SceneMan:GetTerrMatter(digpos.X,digpos.Y) ~= 0 then

							local collectfx = CreateMOPixel("Particle Constructor Gather Material");
							collectfx.Pos = Vector(digpos.X,digpos.Y);
							collectfx.Sharpness = self.UniqueID;
							MovableMan:AddParticle(collectfx);

							for x = 1, 3 do
								for y = 1, 3 do
									local checkpos = ConstructorWrapPos(Vector(digpos.X-1+x,digpos.Y-1+y));
									if SceneMan:GetTerrMatter(checkpos.X,checkpos.Y) ~= 0 then
										if SceneMan:GetTerrMatter(checkpos.X,checkpos.Y) == 2 then
											local collectfx2 = CreateMOPixel("Particle Constructor Gather Material Gold");
											collectfx2.Pos = Vector(checkpos.X,checkpos.Y);
											collectfx2.Sharpness = self.UniqueID;
											MovableMan:AddParticle(collectfx2);
										else
											self.resource = self.resource + 1;
										end
										self.clearer.Pos = Vector(checkpos.X,checkpos.Y);
										self.clearer:EraseFromTerrain();
									end
								end
							end

						end

					end

				else
					self.fireTimer:Reset();
				end

			elseif self.Sharpness == 1 then
				self.Sharpness = 0;

				self.buildlist = {};

			elseif self.Sharpness == 2 then
				self.Sharpness = 0;

				if MovableMan:IsActor(self.cursor) then
					self.cursor.Sharpness = -2;
				end

				if ToActor(actor):IsPlayerControlled() then
					self.cursor = CreateActor("Constructor Cursor");
					self.cursor.Pos = self.MuzzlePos;
					self.cursor.Team = actor.Team;
					self.cursor.Sharpness = self.UniqueID;
					MovableMan:AddActor(self.cursor);
					ActivityMan:GetActivity():SwitchToActor(self.cursor, ToActor(actor):GetController().Player, actor.Team);
				end
			end

			if MovableMan:IsActor(self.cursor) then
				if self.cursor.Sharpness == self.UniqueID then
					local mapx = math.floor((self.cursor.Pos.X-12)/24)*24+12;
					local mapy = math.floor((self.cursor.Pos.Y-12)/24)*24+12;
					FrameMan:DrawBoxPrimitive(Vector(mapx, mapy), Vector(mapx+23, mapy+23), 120);
					if self.cursor:IsPlayerControlled() then
						if self.cursor:GetController():IsState(Controller.WEAPON_FIRE) then
							local freeslot = true;
							for i = 1, #self.buildlist do
								if self.buildlist[i] ~= nil and self.buildlist[i][1] == mapx and self.buildlist[i][2] == mapy then
									freeslot = false;
									break;
								end
							end
							if freeslot then
								buildthis = {};
								buildthis[1] = mapx;
								buildthis[2] = mapy;
								buildthis[3] = 0;
								self.buildlist[#self.buildlist+1] = buildthis;
							end
						end
					else
						self.cursor.Sharpness = -2;
					end
				else
					self.cursor = nil;
				end
			end

			local templist = {};
			for i = 1, #self.buildlist do
				if self.buildlist[i] ~= nil then
					templist[#templist+1] = self.buildlist[i];
					FrameMan:DrawBoxPrimitive(Vector(self.buildlist[i][1],self.buildlist[i][2]), Vector(self.buildlist[i][1]+23,self.buildlist[i][2]+23), 5);
				end
			end
			self.buildlist = templist;

			local buildamount = (self.buildTimer.ElapsedSimTimeMS/1000)*self.buildspersecond;
			self.buildTimer:Reset();
			for i = 1, buildamount do
				if self.resource > 9 then
					if self.buildlist[1] ~= nil then
						self.resource = self.resource - 9;
						if self.buildlist[1][3] < 64 then
							local by = math.floor(self.buildlist[1][3]/8);
							local bx = self.buildlist[1][3]-(by*8);
							by = by*3-1;
							bx = bx*3-1;

							FrameMan:DrawLinePrimitive(self.Pos, Vector(bx+self.buildlist[1][1]+2,by+self.buildlist[1][2]+2), 5);
							FrameMan:DrawBoxFillPrimitive(Vector(bx+self.buildlist[1][1]+1,by+self.buildlist[1][2]+1),Vector(bx+self.buildlist[1][1]+3,by+self.buildlist[1][2]+3),254);

							for x = 1, 3 do
								for y = 1, 3 do
									local name = "";
									if bx+x == 0 or bx+x == 23 or by+y == 0 or by+y == 23 then
										name = "Particle Constructor Concrete Border "..math.ceil(math.random()*4);
									else
										name = "Particle Constructor Concrete "..math.ceil(math.random()*13);
									end
									local terrainpar = CreateMOPixel(name);
									terrainpar.Pos = ConstructorWrapPos(Vector(bx+self.buildlist[1][1]+x,by+self.buildlist[1][2]+y));
									MovableMan:AddParticle(terrainpar);
									terrainpar.ToSettle = true;
								end
							end
							self.buildlist[1][3] = self.buildlist[1][3] + 1;
						else
							self.buildlist[1] = nil;
						end
					end
				end
			end

		else
			if MovableMan:IsActor(self.cursor) then
				self.cursor.Sharpness = 666;
				self.cursor = nil;
			end
		end

	end

end