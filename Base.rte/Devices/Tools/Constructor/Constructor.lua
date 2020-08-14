
function OnPieMenu(item)
	if item and IsHDFirearm(item) and item.PresetName == "Constructor" then
		item = ToHDFirearm(item);
		if item:GetStringValue("ConstructorMode") == "Spray" then
			ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Spray Mode", "ConstructorSprayMode");
		else
			ToGameActivity(ActivityMan:GetActivity()):RemovePieMenuSlice("Dig Mode", "ConstructorDigMode");
		end
	end
end

function ConstructorWrapPos(checkPos)
	if SceneMan.SceneWrapsX then
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
			if SceneMan:GetTerrMatter(checkPos.X+(realspacing*0.5),checkPos.Y+(realspacing*0.5)) == rte.airID then
				ConstructorFloodFill(x+1, y, startnum+1, maxnum, array, checkPos, realspacing);
			end
		end
		if array[x-1][y] == -1 or array[x-1][y] > startnum then
			local checkPos = ConstructorWrapPos(realposition + Vector(-realspacing,0));
			if SceneMan:GetTerrMatter(checkPos.X+(realspacing*0.5),checkPos.Y+(realspacing*0.5)) == rte.airID then
				ConstructorFloodFill(x-1, y, startnum+1, maxnum, array, checkPos, realspacing);
			end
		end
		if array[x][y+1] == -1 or array[x][y+1] > startnum then
			local checkPos = ConstructorWrapPos(realposition + Vector(0,realspacing));
			if SceneMan:GetTerrMatter(checkPos.X+(realspacing*0.5),checkPos.Y+(realspacing*0.5)) == rte.airID then
				ConstructorFloodFill(x, y+1, startnum+1, maxnum, array, checkPos, realspacing);
			end
		end
		if array[x][y-1] == -1 or array[x][y-1] > startnum then
			local checkPos = ConstructorWrapPos(realposition + Vector(0,-realspacing));
			if SceneMan:GetTerrMatter(checkPos.X+(realspacing*0.5),checkPos.Y+(realspacing*0.5)) == rte.airID then
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
		if terrCheck ~= rte.airID then
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
		if terrCheck ~= rte.airID then
			break;
		end
	end

	return roughLandPos;

end

function Create(self)

	self.fireTimer = Timer();
	self.displayTimer = Timer();
	
	self.startresource = 3;	-- how many blocks of concrete to start with

	self.buildTimer = Timer();
	self.buildlist = {};
	self.buildcost = 80;	-- how much resource is required per one build 2 x 2 px piece
							
	self.fullBlock = 65 * self.buildcost;	-- one full block of concrete requires 65 units of resource
	self.resource = 1 + self.startresource * self.fullBlock;
	self.tunnelFillTimer = Timer();

	self.clearer = CreateMOSRotating("Constructor Terrain Clearer");

	self.digstrength = 210;	-- the StructualIntegrity limit the device can harvest
	
	self.diglength = 50;
	self.digspersecond = 100;
	self.buildspersecond = 100;

	self.maxresource = 10 * self.fullBlock;
	self.builddistance = 400; -- pixel distance
	self.minfilldistance = 5; -- block distance
	self.maxfilldistance = 6; -- block distance
	self.tunnelfilldelay = 30000;

	-- don't change these
	self.toautobuild = false;
	self.aicontrolled = false;
	self.displaygrid = true;
	self.cursormovespeed = 2;

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
	
	if self.RootID ~= rte.NoMOID then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if MovableMan:IsActor(actor) then
		
			actor = ToActor(actor);
			local ctrl = actor:GetController();
			local screen = ActivityMan:GetActivity():ScreenOfPlayer(ctrl.Player);
			
			if self.Magazine then
				self.Magazine.RoundCount = self.resource;
			end
			
			if ctrl:IsState(Controller.PIE_MENU_ACTIVE) then
				PrimitiveMan:DrawTextPrimitive(screen, actor.AboveHUDPos + Vector(0, 26), "Mode: ".. self:GetStringValue("ConstructorMode"), true, 1);
			end
			
			-- constructor actions if the user is in gold dig mode
			if actor.AIMode == Actor.AIMODE_GOLDDIG then
				if self.toautobuild == false then
					if actor:IsPlayerControlled() == false then
						if self:GetStringValue("ConstructorMode") == "Spray" then
							self:SetStringValue("ConstructorMode", "Dig");
						end
						if ctrl:IsState(Controller.WEAPON_FIRE) and SceneMan:ShortestDistance(actor.Pos, ConstructorTerrainRay(actor.Pos,Vector(0,50),3), SceneMan.SceneWrapsX).Magnitude < 30 then
							self.tunnelFillTimer:Reset();
							self.aicontrolled = true;
							self.displaygrid = false;
							self.toautobuild = true;
							self.buildlist = {};
							local snappos = ConstructorSnapPos(actor.Pos);
							local buildscheme = self.autobuildlist;
							if actor:HasObjectInGroup("Brains") then
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
			local mode = self:GetNumberValue("BuildMode");
			if mode == 0 then
				-- activation
				if ctrl:IsState(Controller.WEAPON_FIRE) then

					local angle = actor:GetAimAngle(true);
					
					if self:GetStringValue("ConstructorMode") == "Spray" then
					
						if self.resource > self.buildcost / 5 then
							for i = 1, 4 do
								local hue = "Light";
								if math.random() < 0.5 then
									hue = "Dark";
								end
								local spray = CreateMOPixel("Particle Concrete "..hue);
								spray.Pos = self.MuzzlePos;
								spray.Vel = self.Vel + Vector(11, 0):RadRotate(angle + RangeRand(-0.1, 0.1));
								spray.Team = self.Team;
								spray.IgnoresTeamHits = true;
								MovableMan:AddParticle(spray);
							end
							self.resource = self.resource - self.buildcost / 5;
						else
							self:Deactivate();
						end
					else

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
												if matstrength > 0 and matstrength < self.digstrength then
													if math.random() > (1/(self.digstrength/matstrength)) then
														self.resource = math.min(self.resource + math.ceil(matstrength*0.1), self.maxresource);
														self.clearer.Pos = Vector(checkpos.X,checkpos.Y);
														self.clearer:EraseFromTerrain();
														diddig = true;
													end
												else	-- deactivate if material is too strong
													self:Deactivate();
													break;
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
							else	-- deactivate if digging air
								self:Deactivate();
								break;
							end
						end
					end
				else
					self.fireTimer:Reset();
				end

			elseif mode == 1 then	-- cancel
				self:RemoveNumberValue("BuildMode");

				self.buildlist = {};
				self.cursor = nil;

			elseif mode == 2 then	-- build
				self:RemoveNumberValue("BuildMode");

				-- constructor build cursor
				if actor:IsPlayerControlled() then
					self.cursor = Vector(self.MuzzlePos.X, self.MuzzlePos.Y);
				end
			end
			local displayColorBlue = 5;
			local displayColorYellow = 120;
			local displayColorRed = 13;
			local displayColorWhite = 254;
			if self.displayTimer:IsPastSimMS(TimerMan.DeltaTimeMS) then
				self.displayTimer:Reset();
				-- flickering colors
				displayColorBlue = 195;
				displayColorYellow = 116;
				displayColorRed = 12;
				displayColorWhite = 252;
			end

			if self.cursor then
			
				actor.ViewPoint = self.cursor;

				local cursorMovement = Vector();
				
				if ctrl:IsMouseControlled() then
					cursorMovement = cursorMovement + ctrl.MouseMovement;
				else
					if ctrl:IsState(Controller.HOLD_UP) or ctrl:IsState(Controller.BODY_JUMP) then
						cursorMovement = cursorMovement + Vector(0, -1);
					end
					if ctrl:IsState(Controller.HOLD_DOWN) or ctrl:IsState(Controller.BODY_CROUCH) then
						cursorMovement = cursorMovement + Vector(0, 1);
					end
					if ctrl:IsState(Controller.HOLD_LEFT) then
						cursorMovement = cursorMovement + Vector(-1, 0);
					end
					if ctrl:IsState(Controller.HOLD_RIGHT) then
						cursorMovement = cursorMovement + Vector(1, 0);
					end
				end

				if cursorMovement.Magnitude > 0 then
					if ctrl:IsMouseControlled() then
						self.cursor = self.cursor + cursorMovement;
					else
						self.cursor = self.cursor + cursorMovement:SetMagnitude(self.cursormovespeed);
					end
				end

				local mapx = math.floor((self.cursor.X - 12)/24) * 24 + 12;
				local mapy = math.floor((self.cursor.Y - 12)/24) * 24 + 12;

				PrimitiveMan:DrawLinePrimitive(screen, self.cursor + Vector(0, 4), self.cursor + Vector(0, -4), displayColorYellow);
				PrimitiveMan:DrawLinePrimitive(screen, self.cursor + Vector(4, 0), self.cursor + Vector(-4, 0), displayColorYellow);
				PrimitiveMan:DrawBoxPrimitive(screen, Vector(mapx, mapy), Vector(mapx + 23, mapy + 23), displayColorYellow);

				if ctrl:IsState(Controller.PIE_MENU_ACTIVE) then
					self.cursor = nil;
				elseif actor:IsPlayerControlled() then
					-- add blocks to the build queue if the cursor is firing
					if ctrl:IsState(Controller.WEAPON_FIRE) then
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
					for state = 0, 40 do	-- go through and disable all 41 controller states when moving the build cursor
						ctrl:SetState(state, false);
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
							PrimitiveMan:DrawBoxPrimitive(screen, Vector(self.buildlist[i][1],self.buildlist[i][2]), Vector(self.buildlist[i][1]+23,self.buildlist[i][2]+23), displayColorBlue);
						else
							PrimitiveMan:DrawBoxPrimitive(screen, Vector(self.buildlist[i][1],self.buildlist[i][2]), Vector(self.buildlist[i][1]+23,self.buildlist[i][2]+23), displayColorRed);
						end
					end
				end
			end
			self.buildlist = templist;

			-- building up the first block in the build queue
			local buildamount = (self.buildTimer.ElapsedSimTimeMS/1000)*self.buildspersecond;
			self.buildTimer:Reset();
			for i = 1, buildamount do
				if self.resource > self.buildcost then
					if self.buildlist[1] then

						if SceneMan:ShortestDistance(actor.Pos, Vector(self.buildlist[1][1],self.buildlist[1][2]), SceneMan.SceneWrapsX).Magnitude < self.builddistance then

							self.resource = self.resource - self.buildcost;
							if self.buildlist[1][3] < 64 then
								local by = math.floor(self.buildlist[1][3]/8);
								local bx = self.buildlist[1][3]-(by*8);
								by = by*3-1;
								bx = bx*3-1;

								local bpos = self.Pos + SceneMan:ShortestDistance(self.Pos, Vector(bx+self.buildlist[1][1]+2,by+self.buildlist[1][2]+2), SceneMan.SceneWrapsX);
								PrimitiveMan:DrawLinePrimitive(screen, self.Pos, bpos, displayColorBlue);
								PrimitiveMan:DrawBoxFillPrimitive(screen, Vector(bx+self.buildlist[1][1]+1,by+self.buildlist[1][2]+1),Vector(bx+self.buildlist[1][1]+3,by+self.buildlist[1][2]+3), displayColorWhite);
								
								for x = 1, 3 do
									for y = 1, 3 do
										local name = "";
										if bx+x == 0 or bx+x == 23 or by+y == 0 or by+y == 23 then
											name = "Particle Constructor Concrete Border "..math.random(4);
										else
											name = "Particle Constructor Concrete "..math.random(13);
										end
										local terrainpar = CreateMOPixel(name);
										terrainpar.Pos = ConstructorWrapPos(Vector(bx+self.buildlist[1][1]+x,by+self.buildlist[1][2]+y));
										MovableMan:AddParticle(terrainpar);
										terrainpar.ToSettle = true;
									end
								end
								AudioMan:PlaySound("Base.rte/Sounds/Geiger".. math.random(3) ..".wav", bpos);
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
			if display then
				self.displayTimer:Reset();
			end
		elseif self.cursor then
			self.cursor = nil;
		end
	end
end