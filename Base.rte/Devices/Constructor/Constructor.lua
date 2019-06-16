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

-- recursive flood filling function
function ConstructorFloodFill(x, y, startnum, maxnum, array, realposition, realspacing)
	array[x][y] = startnum;

	if startnum < maxnum then
		if array[x+1][y] == -1 or array[x+1][y] > startnum then
			local checkPos = ConstructorWrapPos(realposition + Vector(realspacing,0));
			if SceneMan:GetTerrMatter(checkPos.X+(realspacing*0.5),checkPos.Y+(realspacing*0.5)) == 0 then
				ConstructorFloodFill(x+1, y, startnum+1, maxnum, array, checkPos, realspacing);
			end
		end
		if array[x-1][y] == -1 or array[x-1][y] > startnum then
			local checkPos = ConstructorWrapPos(realposition + Vector(-realspacing,0));
			if SceneMan:GetTerrMatter(checkPos.X+(realspacing*0.5),checkPos.Y+(realspacing*0.5)) == 0 then
				ConstructorFloodFill(x-1, y, startnum+1, maxnum, array, checkPos, realspacing);
			end
		end
		if array[x][y+1] == -1 or array[x][y+1] > startnum then
			local checkPos = ConstructorWrapPos(realposition + Vector(0,realspacing));
			if SceneMan:GetTerrMatter(checkPos.X+(realspacing*0.5),checkPos.Y+(realspacing*0.5)) == 0 then
				ConstructorFloodFill(x, y+1, startnum+1, maxnum, array, checkPos, realspacing);
			end
		end
		if array[x][y-1] == -1 or array[x][y-1] > startnum then
			local checkPos = ConstructorWrapPos(realposition + Vector(0,-realspacing));
			if SceneMan:GetTerrMatter(checkPos.X+(realspacing*0.5),checkPos.Y+(realspacing*0.5)) == 0 then
				ConstructorFloodFill(x, y-1, startnum+1, maxnum, array, checkPos, realspacing);
			end
		end
	end
end

function ConstructorSnapPos(checkPos)
	return Vector(math.floor((checkPos.X-12)/24)*24+12,math.floor((checkPos.Y-12)/24)*24+12);
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

	self.tunnelFillTimer = Timer();

	self.clearer = CreateMOSRotating("Constructor Terrain Clearer");

	self.digstrength = 35;
	self.diglength = 50;
	self.digspersecond = 100;
	self.buildspersecond = 100;

	self.maxresource = 28800; -- 1 block takes 576 pixels
	self.builddistance = 400; -- pixel distance
	self.minfilldistance = 5; -- block distance
	self.maxfilldistance = 6; -- block distance
	self.tunnelfilldelay = 30000;

	-- don't change these
	self.toautobuild = false;
	self.aicontrolled = false;
	self.displaygrid = true;

	-- autobuild for standard units
	self.autobuildlist = {
				Vector(-3,1),
				Vector(-2,1),
				Vector(-1,1),
				Vector(2,1),
				Vector(3,1),
				Vector(4,1),

				Vector(-4,-2),
				Vector(-3,-2),
				Vector(0,-2),
				Vector(1,-2),
				Vector(4,-2),
				Vector(5,-2),

				Vector(-3,-3),
				Vector(4,-3),

				Vector(-3,-4),
				Vector(4,-4),

				Vector(-3,-5),
				Vector(-2,-5),
				Vector(-1,-5),
				Vector(2,-5),
				Vector(3,-5),
				Vector(4,-5),

				Vector(-3,-8),
				Vector(-2,-8),
				Vector(-1,-8),
				Vector(0,-8),
				Vector(1,-8),
				Vector(2,-8),
				Vector(3,-8),
				Vector(4,-8)
			};

	-- autobuild for brain units
	self.autobuildlistbrain = {
				Vector(-2,1),
				Vector(-2,0),
				Vector(-2,-1),
				Vector(-2,-2),
				Vector(-1,-2),
				Vector(0,-2),
				Vector(1,-2),
				Vector(2,1),
				Vector(2,0),
				Vector(2,-1),
				Vector(2,-2),

				Vector(-3,0),
				Vector(-3,-1),
				Vector(-3,-2),

				Vector(-2,-3),
				Vector(-1,-3),
				Vector(0,-3),
				Vector(1,-3),
				Vector(2,-3),

				Vector(3,0),
				Vector(3,-1),
				Vector(3,-2)
			};

end

function Update(self)
	
	if self.RootID ~= 255 then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if MovableMan:IsActor(actor) then
			if self.Magazine ~= nil then
				self.Magazine.RoundCount = self.resource;
			end

			-- constructor actions if the user is in gold dig mode
			if ToActor(actor).AIMode == Actor.AIMODE_GOLDDIG then
				if self.toautobuild == false then
					if ToActor(actor):IsPlayerControlled() == false then
						if ToActor(actor):GetController():IsState(Controller.WEAPON_FIRE) and SceneMan:ShortestDistance(actor.Pos, ConstructorTerrainRay(actor.Pos,Vector(0,50),3), SceneMan.SceneWrapsX).Magnitude < 30 then
							self.tunnelFillTimer:Reset();
							self.aicontrolled = true;
							self.displaygrid = false;
							self.toautobuild = true;
							self.buildlist = {};
							local snappos = ConstructorSnapPos(actor.Pos);
							local buildscheme = self.autobuildlist;
							if ToActor(actor):HasObjectInGroup("Brains") then
								buildscheme = self.autobuildlistbrain;
							end
							for i = 1, #buildscheme do
								local temppos = snappos + Vector(buildscheme[i].X*24,buildscheme[i].Y*24);
								local buildthis = {};
								buildthis[1] = temppos.X;
								buildthis[2] = temppos.Y;
								buildthis[3] = 0;
								self.buildlist[#self.buildlist+1] = buildthis;
							end

						end
					else
						self.toautobuild = true;
					end
				end

				-- constructor actions if it's AI controlled
				if self.aicontrolled then
					if self.tunnelFillTimer:IsPastSimMS(self.tunnelfilldelay) and #self.buildlist == 0 then
						self.tunnelFillTimer:Reset();

						-- create an empty 2D array, call cells having -1
						local floodfilllistx = {};
						for x = 1, (self.maxfilldistance*2)+1 do
							floodfilllistx[x] = {};
							for y = 1, (self.maxfilldistance*2)+1 do
								floodfilllistx[x][y] = -1;
							end
						end

						-- figure out the center of the grid
						local center = math.ceil(((self.maxfilldistance*2)+1)/2);

						-- FLOOD FILL!
						ConstructorFloodFill(center, center, 0, self.maxfilldistance, floodfilllistx, ConstructorSnapPos(actor.Pos), 24);

						-- dump the correctly numbered cells into the build table
						for x = 1, #floodfilllistx do
							for y = 1, #floodfilllistx do
								if floodfilllistx[x][y] >= self.minfilldistance and floodfilllistx[x][y] <= self.maxfilldistance then
									local mapx = ConstructorSnapPos(actor.Pos).X + ((center - x) * -24);
									local mapy = ConstructorSnapPos(actor.Pos).Y + ((center - y) * -24);
									local freeslot = true;
									for i = 1, #self.buildlist do
										if self.buildlist[i] ~= nil and self.buildlist[i][1] == mapx and self.buildlist[i][2] == mapy then
											freeslot = false;
											break;
										end
									end
									if freeslot then
										local buildthis = {};
										buildthis[1] = mapx;
										buildthis[2] = mapy;
										buildthis[3] = 0;
										self.buildlist[#self.buildlist+1] = buildthis;
									end
								end
							end
						end

					end
				end
			else
				self.toautobuild = false;
			end

			if self.Sharpness == 0 then

				-- digging
				if ToActor(actor):GetController():IsState(Controller.WEAPON_FIRE) then

					local angle = ToActor(actor):GetAimAngle(true);

					local digamount = (self.fireTimer.ElapsedSimTimeMS/1000)*self.digspersecond;
					self.fireTimer:Reset();

					for i = 1, digamount do

						local digpos = ConstructorTerrainRay(self.MuzzlePos, Vector(self.diglength,0):RadRotate(angle + (math.random()*(math.pi/4)) - (math.pi/8)), 1);

						if SceneMan:GetTerrMatter(digpos.X,digpos.Y) ~= 0 then

							local diddig = false;

							for x = 1, 3 do
								for y = 1, 3 do
									local checkpos = ConstructorWrapPos(Vector(digpos.X-1+x,digpos.Y-1+y));
									if SceneMan:GetTerrMatter(checkpos.X,checkpos.Y) ~= 0 then
										if SceneMan:GetTerrMatter(checkpos.X,checkpos.Y) == 2 then
											self.clearer.Pos = Vector(checkpos.X,checkpos.Y);
											self.clearer:EraseFromTerrain();
											local collectfx2 = CreateMOPixel("Particle Constructor Gather Material Gold");
											collectfx2.Pos = Vector(checkpos.X,checkpos.Y);
											collectfx2.Sharpness = self.UniqueID;
											MovableMan:AddParticle(collectfx2);
										else
											local matstrength = SceneMan:CastStrengthSumRay(Vector(checkpos.X,checkpos.Y-1),Vector(checkpos.X,checkpos.Y),0,0);
											if matstrength > 0 and math.random() < (1/(matstrength/self.digstrength)) then
												self.resource = math.min(self.resource + 1, self.maxresource);
												self.clearer.Pos = Vector(checkpos.X,checkpos.Y);
												self.clearer:EraseFromTerrain();
												diddig = true;
											end
										end
									end
								end
							end

							if diddig then
								local collectfx = CreateMOPixel("Particle Constructor Gather Material");
								collectfx.Pos = Vector(digpos.X,digpos.Y);
								collectfx.Sharpness = self.UniqueID;
								MovableMan:AddParticle(collectfx);
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

				-- constructor build cursor

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

					-- add blocks to the build queue if the cursor is firing
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
								local buildthis = {};
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

			-- clean up the build list of nil slots and draw the squares to show the build layout
			local templist = {};
			for i = 1, #self.buildlist do
				if self.buildlist[i] ~= nil then
					templist[#templist+1] = self.buildlist[i];
					if self.displaygrid then
						if SceneMan:ShortestDistance(actor.Pos, Vector(self.buildlist[i][1],self.buildlist[i][2]), SceneMan.SceneWrapsX).Magnitude < self.builddistance then
							FrameMan:DrawBoxPrimitive(Vector(self.buildlist[i][1],self.buildlist[i][2]), Vector(self.buildlist[i][1]+23,self.buildlist[i][2]+23), 5);
						else
							FrameMan:DrawBoxPrimitive(Vector(self.buildlist[i][1],self.buildlist[i][2]), Vector(self.buildlist[i][1]+23,self.buildlist[i][2]+23), 13);
						end
					end
				end
			end
			self.buildlist = templist;

			-- building up the first block in the build queue
			local buildamount = (self.buildTimer.ElapsedSimTimeMS/1000)*self.buildspersecond;
			self.buildTimer:Reset();
			for i = 1, buildamount do
				if self.resource > 9 then
					if self.buildlist[1] ~= nil then

						if SceneMan:ShortestDistance(actor.Pos, Vector(self.buildlist[1][1],self.buildlist[1][2]), SceneMan.SceneWrapsX).Magnitude < self.builddistance then

							self.resource = self.resource - 9;
							if self.buildlist[1][3] < 64 then
								local by = math.floor(self.buildlist[1][3]/8);
								local bx = self.buildlist[1][3]-(by*8);
								by = by*3-1;
								bx = bx*3-1;

								FrameMan:DrawLinePrimitive(self.Pos, self.Pos + SceneMan:ShortestDistance(self.Pos, Vector(bx+self.buildlist[1][1]+2,by+self.buildlist[1][2]+2), SceneMan.SceneWrapsX ), 5);
								FrameMan:DrawBoxFillPrimitive(Vector(bx+self.buildlist[1][1]+1,by+self.buildlist[1][2]+1),Vector(bx+self.buildlist[1][1]+3,by+self.buildlist[1][2]+3),254);

								for x = 1, 3 do
									for y = 1, 3 do
										local name = "";
										if bx+x == 0 or bx+x == 23 or by+y == 0 or by+y == 23 then
											name = "Particle Constructor Concrete Border "..(math.floor(math.random()*4)+1);
										else
											name = "Particle Constructor Concrete "..(math.floor(math.random()*13)+1);
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

						else
							self.buildlist[#self.buildlist+1] = self.buildlist[1];
							self.buildlist[1] = nil;
						end

					end
				end
			end

		else
			if MovableMan:IsActor(self.cursor) then
				self.cursor.Sharpness = -2;
				self.cursor = nil;
			end
		end

	end

end

function Destroy(self)
	if MovableMan:IsActor(self.cursor) then
		self.cursor.Sharpness = -2;
	end
end