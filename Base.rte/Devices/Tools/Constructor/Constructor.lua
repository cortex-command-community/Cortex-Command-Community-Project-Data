
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
			checkPos = Vector(checkPos.X - SceneMan.SceneWidth, checkPos.Y);
		elseif checkPos.X < 0 then
			checkPos = Vector(SceneMan.SceneWidth + checkPos.X, checkPos.Y);
		end
	end
	return checkPos;
end

-- recursive flood filling function
function ConstructorFloodFill(x, y, startnum, maxnum, array, realposition, realspacing)
	array[x][y] = startnum;

	if startnum < maxnum then
		if array[x + 1][y] == -1 or array[x + 1][y] > startnum then
			local checkPos = ConstructorWrapPos(realposition + Vector(realspacing, 0));
			if SceneMan:GetTerrMatter(checkPos.X + (realspacing * 0.5), checkPos.Y + (realspacing * 0.5)) == rte.airID then
				ConstructorFloodFill(x + 1, y, startnum + 1, maxnum, array, checkPos, realspacing);
			end
		end
		if array[x - 1][y] == -1 or array[x - 1][y] > startnum then
			local checkPos = ConstructorWrapPos(realposition + Vector(-realspacing, 0));
			if SceneMan:GetTerrMatter(checkPos.X + (realspacing * 0.5), checkPos.Y + (realspacing * 0.5)) == rte.airID then
				ConstructorFloodFill(x - 1, y, startnum + 1, maxnum, array, checkPos, realspacing);
			end
		end
		if array[x][y + 1] == -1 or array[x][y + 1] > startnum then
			local checkPos = ConstructorWrapPos(realposition + Vector(0, realspacing));
			if SceneMan:GetTerrMatter(checkPos.X + (realspacing * 0.5), checkPos.Y + (realspacing * 0.5)) == rte.airID then
				ConstructorFloodFill(x, y + 1, startnum + 1, maxnum, array, checkPos, realspacing);
			end
		end
		if array[x][y - 1] == -1 or array[x][y - 1] > startnum then
			local checkPos = ConstructorWrapPos(realposition + Vector(0, -realspacing));
			if SceneMan:GetTerrMatter(checkPos.X + (realspacing * 0.5), checkPos.Y + (realspacing * 0.5)) == rte.airID then
				ConstructorFloodFill(x, y - 1, startnum + 1, maxnum, array, checkPos, realspacing);
			end
		end
	end
end

function ConstructorSnapPos(checkPos)
	return Vector(math.floor((checkPos.x - 12)/24) * 24 + 12, math.floor((checkPos.y - 12)/24) * 24 + 12);
end

function ConstructorTerrainRay(start, trace, skip)

	local length = trace.Magnitude;
	local angle = trace.AbsRadAngle;

	local density = math.ceil(length/skip);

	local roughLandPos = start + Vector(length, 0):RadRotate(angle);
	for i = 0, density do
		local invector = start + Vector(skip * i, 0):RadRotate(angle);
		local checkPos = ConstructorWrapPos(invector);
		if SceneMan:GetTerrMatter(checkPos.X, checkPos.Y) ~= rte.airID then
			roughLandPos = checkPos;
			break;
		end
	end

	local checkRoughLandPos = roughLandPos + Vector(skip * -1, 0):RadRotate(angle);
	for i = 0, skip do
		local invector = checkRoughLandPos + Vector(i, 0):RadRotate(angle);
		local checkPos = ConstructorWrapPos(invector);
		roughLandPos = checkPos;
		if SceneMan:GetTerrMatter(checkPos.X, checkPos.Y) ~= rte.airID then
			break;
		end
	end

	return roughLandPos;
end

function Create(self)

	self.fireTimer = Timer();
	self.displayTimer = Timer();
	
	self.startResource = 3;	-- how many blocks of concrete to start with

	self.buildTimer = Timer();
	self.buildList = {};
	self.buildCost = 80;	-- how much resource is required per one build 2 x 2 px piece
							
	self.fullBlock = 65 * self.buildCost;	-- one full block of concrete requires 65 units of resource
	self.resource = 1 + self.startResource * self.fullBlock;
	self.tunnelFillTimer = Timer();

	self.clearer = CreateMOSRotating("Constructor Terrain Clearer");

	self.digStrength = 210;	-- the StructualIntegrity limit the device can harvest
	
	self.digLength = 50;
	self.digsPerSecond = 100;
	self.buildsPerSecond = 100;
	self.buildSound = CreateSoundContainer("Geiger Click", "Base.rte");

	self.maxResource = 10 * self.fullBlock;
	self.buildDistance = 400; -- pixel distance
	self.minFillDistance = 5; -- block distance
	self.maxFillDistance = 6; -- block distance
	self.tunnelFillDelay = 30000;

	-- don't change these
	self.toAutoBuild = false;
	self.aiControlled = false;
	self.displayGrid = true;
	self.cursorMoveSpeed = 2;

	-- autobuild for standard units
	self.autoBuildList = {
				Vector(-3, 1), 
				Vector(-2, 1), 
				Vector(-1, 1), 
				Vector(2, 1), 
				Vector(3, 1), 
				Vector(4, 1), 

				Vector(-4, -2), 
				Vector(-3, -2), 
				Vector(0, -2), 
				Vector(1, -2), 
				Vector(4, -2), 
				Vector(5, -2), 

				Vector(-3, -3), 
				Vector(4, -3), 

				Vector(-3, -4), 
				Vector(4, -4), 

				Vector(-3, -5), 
				Vector(-2, -5), 
				Vector(-1, -5), 
				Vector(2, -5), 
				Vector(3, -5), 
				Vector(4, -5), 

				Vector(-3, -8), 
				Vector(-2, -8), 
				Vector(-1, -8), 
				Vector(0, -8), 
				Vector(1, -8), 
				Vector(2, -8), 
				Vector(3, -8), 
				Vector(4, -8)
			};

	-- autobuild for brain units
	self.autoBuildListBrain = {
				Vector(-2, 1), 
				Vector(-2, 0), 
				Vector(-2, -1), 
				Vector(-2, -2), 
				Vector(-1, -2), 
				Vector(0, -2), 
				Vector(1, -2), 
				Vector(2, 1), 
				Vector(2, 0), 
				Vector(2, -1), 
				Vector(2, -2), 

				Vector(-3, 0), 
				Vector(-3, -1), 
				Vector(-3, -2), 

				Vector(-2, -3), 
				Vector(-1, -3), 
				Vector(0, -3), 
				Vector(1, -3), 
				Vector(2, -3), 

				Vector(3, 0), 
				Vector(3, -1), 
				Vector(3, -2)
			};

end

function Update(self)
	
	local actor = self:GetRootParent();
	if actor and IsActor(actor) then

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
			if self.toAutoBuild == false then
				if actor:IsPlayerControlled() == false then
					if self:GetStringValue("ConstructorMode") == "Spray" then
						self:SetStringValue("ConstructorMode", "Dig");
					end
					if ctrl:IsState(Controller.WEAPON_FIRE) and SceneMan:ShortestDistance(actor.Pos, ConstructorTerrainRay(actor.Pos, Vector(0, 50), 3), SceneMan.SceneWrapsX).Magnitude < 30 then
						self.tunnelFillTimer:Reset();
						self.aiControlled = true;
						self.displayGrid = false;
						self.toAutoBuild = true;
						self.buildList = {};
						local snappos = ConstructorSnapPos(actor.Pos);
						local buildscheme = self.autoBuildList;
						if actor:HasObjectInGroup("Brains") then
							buildscheme = self.autoBuildListBrain;
						end
						for i = 1, #buildscheme do
							local temppos = snappos + Vector(buildscheme[i].X * 24, buildscheme[i].Y * 24);
							local buildThis = {};
							buildThis[1] = temppos.X;
							buildThis[2] = temppos.Y;
							buildThis[3] = 0;
							self.buildList[#self.buildList + 1] = buildThis;
						end

					end
				else
					self.toAutoBuild = true;
				end
			end

			-- constructor actions if it's AI controlled
			if self.aiControlled then
				if self.tunnelFillTimer:IsPastSimMS(self.tunnelFillDelay) and #self.buildList == 0 then
					self.tunnelFillTimer:Reset();

					-- create an empty 2D array, call cells having -1
					local floodFillListX = {};
					for x = 1, (self.maxFillDistance * 2) + 1 do
						floodFillListX[x] = {};
						for y = 1, (self.maxFillDistance * 2) + 1 do
							floodFillListX[x][y] = -1;
						end
					end

					-- figure out the center of the grid
					local center = math.ceil(((self.maxFillDistance * 2) + 1) * 0.5);

					-- FLOOD FILL!
					ConstructorFloodFill(center, center, 0, self.maxFillDistance, floodFillListX, ConstructorSnapPos(actor.Pos), 24);

					-- dump the correctly numbered cells into the build table
					for x = 1, #floodFillListX do
						for y = 1, #floodFillListX do
							if floodFillListX[x][y] >= self.minFillDistance and floodFillListX[x][y] <= self.maxFillDistance then
								local mapX = ConstructorSnapPos(actor.Pos).X + ((center - x) * -24);
								local mapY = ConstructorSnapPos(actor.Pos).Y + ((center - y) * -24);
								local freeSlot = true;
								for i = 1, #self.buildList do
									if self.buildList[i] ~= nil and self.buildList[i][1] == mapX and self.buildList[i][2] == mapY then
										freeSlot = false;
										break;
									end
								end
								if freeSlot then
									local buildThis = {};
									buildThis[1] = mapX;
									buildThis[2] = mapY;
									buildThis[3] = 0;
									self.buildList[#self.buildList + 1] = buildThis;
								end
							end
						end
					end
				end
			end
		else
			self.toAutoBuild = false;
		end
		local mode = self:GetNumberValue("BuildMode");
		if mode == 0 and not self.cursor then
			-- activation
			if ctrl:IsState(Controller.WEAPON_FIRE) then

				local angle = actor:GetAimAngle(true);
				
				if self:GetStringValue("ConstructorMode") == "Spray" then
				
					if self.resource > self.buildCost * 0.2 then
						for i = 1, 4 do
							local spray = CreateMOPixel("Particle Concrete " .. (math.random() < 0.5 and "Light" or "Dark"));
							spray.Pos = self.MuzzlePos;
							spray.Vel = self.Vel + Vector(11, 0):RadRotate(angle + RangeRand(-0.1, 0.1));
							spray.Team = self.Team;
							spray.IgnoresTeamHits = true;
							MovableMan:AddParticle(spray);
						end
						self.resource = self.resource - self.buildCost * 0.2;
					else
						self:Deactivate();
					end
				else

					local digAmount = (self.fireTimer.ElapsedSimTimeMS * 0.001) * self.digsPerSecond;
					self.fireTimer:Reset();

					for i = 1, digAmount do

						local digPos = ConstructorTerrainRay(self.MuzzlePos, Vector(self.digLength, 0):RadRotate(angle + (math.random() * (math.pi/4)) - (math.pi/8)), 1);

						if SceneMan:GetTerrMatter(digPos.X, digPos.Y) ~= rte.airID then

							local didDig = false;

							for x = 1, 3 do
								for y = 1, 3 do
									local checkPos = ConstructorWrapPos(Vector(digPos.X - 1 + x, digPos.Y - 1 + y));
									if SceneMan:GetTerrMatter(checkPos.X, checkPos.Y) ~= rte.airID then
										if SceneMan:GetTerrMatter(checkPos.X, checkPos.Y) == rte.goldID then
											self.clearer.Pos = Vector(checkPos.X, checkPos.Y);
											self.clearer:EraseFromTerrain();
											local collectFX = CreateMOPixel("Particle Constructor Gather Material Gold");
											collectFX.Pos = Vector(checkPos.X, checkPos.Y);
											collectFX.Sharpness = self.ID;
											MovableMan:AddParticle(collectFX);
										else
											local matstrength = SceneMan:CastStrengthSumRay(Vector(checkPos.X, checkPos.Y - 1), Vector(checkPos.X, checkPos.Y), 0, 0);
											if matstrength > 0 and matstrength < self.digStrength then
												if math.random() > 1/(self.digStrength/matstrength) then
													self.resource = math.min(self.resource + math.ceil(matstrength * 0.1), self.maxResource);
													self.clearer.Pos = Vector(checkPos.X, checkPos.Y);
													self.clearer:EraseFromTerrain();
													didDig = true;
												end
											else	-- deactivate if material is too strong
												self:Deactivate();
												break;
											end
										end
									end
								end
							end
							if didDig then
								local collectFX = CreateMOPixel("Particle Constructor Gather Material");
								collectFX.Pos = Vector(digPos.X, digPos.Y);
								collectFX.Sharpness = self.ID;
								MovableMan:AddParticle(collectFX);
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

			self.buildList = {};
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
					self.cursor = self.cursor + cursorMovement:SetMagnitude(self.cursorMoveSpeed);
				end
			end

			local mapX = math.floor((self.cursor.X - 12)/24) * 24 + 12;
			local mapY = math.floor((self.cursor.Y - 12)/24) * 24 + 12;

			PrimitiveMan:DrawLinePrimitive(screen, self.cursor + Vector(0, 4), self.cursor + Vector(0, -4), displayColorYellow);
			PrimitiveMan:DrawLinePrimitive(screen, self.cursor + Vector(4, 0), self.cursor + Vector(-4, 0), displayColorYellow);
			PrimitiveMan:DrawBoxPrimitive(screen, Vector(mapX, mapY), Vector(mapX + 23, mapY + 23), displayColorYellow);

			if ctrl:IsState(Controller.PIE_MENU_ACTIVE) or ctrl:IsState(Controller.ACTOR_NEXT_PREP) or ctrl:IsState(Controller.ACTOR_PREV_PREP) then
				self.cursor = nil;
			elseif actor:IsPlayerControlled() then
				-- add blocks to the build queue if the cursor is firing
				if ctrl:IsState(Controller.WEAPON_FIRE) then
					local freeSlot = true;
					for i = 1, #self.buildList do
						if self.buildList[i] ~= nil and self.buildList[i][1] == mapX and self.buildList[i][2] == mapY then
							freeSlot = false;
							break;
						end
					end
					if freeSlot then
						local buildThis = {};
						buildThis[1] = mapX;
						buildThis[2] = mapY;
						buildThis[3] = 0;
						self.buildList[#self.buildList + 1] = buildThis;
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
		local tempList = {};
		for i = 1, #self.buildList do
			if self.buildList[i] ~= nil then
				tempList[#tempList + 1] = self.buildList[i];
				if self.displayGrid then
					if SceneMan:ShortestDistance(actor.Pos, Vector(self.buildList[i][1], self.buildList[i][2]), SceneMan.SceneWrapsX).Magnitude < self.buildDistance then
						PrimitiveMan:DrawBoxPrimitive(screen, Vector(self.buildList[i][1], self.buildList[i][2]), Vector(self.buildList[i][1] + 23, self.buildList[i][2] + 23), displayColorBlue);
					else
						PrimitiveMan:DrawBoxPrimitive(screen, Vector(self.buildList[i][1], self.buildList[i][2]), Vector(self.buildList[i][1] + 23, self.buildList[i][2] + 23), displayColorRed);
					end
				end
			end
		end
		self.buildList = tempList;

		-- building up the first block in the build queue
		if self.resource > self.buildCost then
			if self.buildList[1] then

				if SceneMan:ShortestDistance(actor.Pos, Vector(self.buildList[1][1], self.buildList[1][2]), SceneMan.SceneWrapsX).Magnitude < self.buildDistance then

					if self.buildList[1][3] < 64 then
						local by = math.floor(self.buildList[1][3]/8);
						local bx = self.buildList[1][3] - (by * 8);
						by = by * 3 - 1;
						bx = bx * 3 - 1;

						local bpos = self.Pos + SceneMan:ShortestDistance(self.Pos, Vector(bx + self.buildList[1][1] + 2, by + self.buildList[1][2] + 2), SceneMan.SceneWrapsX);
						PrimitiveMan:DrawLinePrimitive(screen, self.Pos, bpos, displayColorBlue);
						PrimitiveMan:DrawBoxFillPrimitive(screen, Vector(bx + self.buildList[1][1] + 1, by + self.buildList[1][2] + 1), Vector(bx + self.buildList[1][1] + 3, by + self.buildList[1][2] + 3), displayColorWhite);
						
						self.buildList[1][3] = self.buildList[1][3] + 1;
						for x = 1, 3 do
							for y = 1, 3 do
								local pos = ConstructorWrapPos(Vector(bx + self.buildList[1][1] + x, by + self.buildList[1][2] + y));
								if SceneMan:GetTerrMatter(pos.X, pos.Y) == rte.airID then
									local name = "";
									if bx + x == 0 or bx + x == 23 or by + y == 0 or by + y == 23 then
										name = "Base.rte/Particle Constructor Concrete Border " .. math.random(4);
									else
										name = "Base.rte/Particle Constructor Concrete " .. math.random(13);
									end
									local terrainPar = CreateMOPixel(name);
									terrainPar.Pos = pos;
									MovableMan:AddParticle(terrainPar);
									terrainPar.ToSettle = true;
								end
							end
						end
						self.buildSound:Play(bpos);
						self.resource = self.resource - self.buildCost;
					else
						self.buildList[1] = nil;
					end
				else
					self.buildList[#self.buildList + 1] = self.buildList[1];
					self.buildList[1] = nil;
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