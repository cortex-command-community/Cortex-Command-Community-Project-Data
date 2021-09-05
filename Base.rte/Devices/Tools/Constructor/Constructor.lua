
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
--TODO: Figure out how to snap different sizes properly
function ConstructorSnapPos(checkPos, blockSize)
	return Vector(math.floor((checkPos.X - blockSize/2)/blockSize) * blockSize + blockSize/2, math.floor((checkPos.Y - blockSize/2)/blockSize) * blockSize + blockSize/2);
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
	
	self.startResource = 2;	--How many blocks of concrete to start with

	self.buildTimer = Timer();
	self.buildList = {};
	self.buildCost = 10;	--How much resource is required per one build 3 x 3 px piece
	self.sprayCost = self.buildCost * 0.5;
							
	self.blockSize = 24;
	self.fullBlock = 64 * self.buildCost;	--One full 24x24 block of concrete requires 64 units of resource
	self.resource = self.startResource * self.fullBlock;
	self.tunnelFillTimer = Timer();

	self.clearer = CreateMOSRotating("Constructor Terrain Clearer");

	self.digStrength = 200;	--The StructuralIntegrity limit of harvestable materials
	
	self.digLength = 50;
	self.digsPerSecond = 100;
	self.spreadRange = math.rad(self.ParticleSpreadRange);
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
		local playerControlled = actor:IsPlayerControlled();
		local screen = ActivityMan:GetActivity():ScreenOfPlayer(ctrl.Player);

		if self.Magazine then
			self.Magazine.RoundCount = self.resource;
			
			self.Magazine.Mass = 1 + 39 * (self.resource/self.maxResource);
			self.Magazine.Scale = 0.5 + (self.resource/self.maxResource) * 0.5;

			local parentWidth = ToMOSprite(actor):GetSpriteWidth();
			local parentHeight = ToMOSprite(actor):GetSpriteHeight();
			self.Magazine.Pos = actor.Pos + Vector(-(self.Magazine.Radius * 0.3 + parentWidth * 0.2 - 0.5) * self.FlipFactor, -(self.Magazine.Radius * 0.15 + parentHeight * 0.2)):RadRotate(actor.RotAngle);
			self.Magazine.RotAngle = actor.RotAngle;
		end
		
		if ctrl:IsState(Controller.PIE_MENU_ACTIVE) then
			PrimitiveMan:DrawTextPrimitive(screen, actor.AboveHUDPos + Vector(0, 26), "Mode: ".. self:GetStringValue("ConstructorMode"), true, 1);
		end
		
		-- constructor actions if the user is in gold dig mode
		if actor.AIMode == Actor.AIMODE_GOLDDIG then
			if self.toAutoBuild == false then
				if not playerControlled then
					if self:GetStringValue("ConstructorMode") == "Spray" then
						self:SetStringValue("ConstructorMode", "Dig");
					end
					self.blockSize = 24;
					if ctrl:IsState(Controller.WEAPON_FIRE) and SceneMan:ShortestDistance(actor.Pos, ConstructorTerrainRay(actor.Pos, Vector(0, 50), 3), SceneMan.SceneWrapsX).Magnitude < 30 then
						self.tunnelFillTimer:Reset();
						self.aiControlled = true;
						self.displayGrid = false;
						self.toAutoBuild = true;
						self.buildList = {};
						local buildscheme = self.autoBuildList;
						if actor:HasObjectInGroup("Brains") then
							buildscheme = self.autoBuildListBrain;
							self.blockSize = 24;
						end
						local snappos = ConstructorSnapPos(actor.Pos, self.blockSize);
						for i = 1, #buildscheme do
							local temppos = snappos + Vector(buildscheme[i].X * self.blockSize, buildscheme[i].Y * self.blockSize);
							local buildThis = {};
							buildThis[1] = temppos.X;
							buildThis[2] = temppos.Y;
							buildThis[3] = 0;
							buildThis[4] = self.blockSize;
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
					ConstructorFloodFill(center, center, 0, self.maxFillDistance, floodFillListX, ConstructorSnapPos(actor.Pos, self.blockSize), self.blockSize);

					-- dump the correctly numbered cells into the build table
					for x = 1, #floodFillListX do
						for y = 1, #floodFillListX do
							if floodFillListX[x][y] >= self.minFillDistance and floodFillListX[x][y] <= self.maxFillDistance then
								local mapX = ConstructorSnapPos(actor.Pos, self.blockSize).X + ((center - x) * -self.blockSize);
								local mapY = ConstructorSnapPos(actor.Pos, self.blockSize).Y + ((center - y) * -self.blockSize);
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
									buildThis[4] = 24;
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
					if self.resource >= self.sprayCost then
						local particleCount = 9;
						for i = 1, particleCount do
							local spray = CreateMOPixel("Particle Concrete " .. math.random(4), "Base.rte");
							spray.Pos = self.MuzzlePos;
							spray.Vel = self.Vel + Vector(math.random(11, 13), 0):RadRotate(angle + RangeRand(-0.5, 0.5) * self.spreadRange);
							spray.Team = self.Team;
							spray.IgnoresTeamHits = true;
							MovableMan:AddParticle(spray);
						end
						self.resource = self.resource - self.sprayCost;
					else
						self:Deactivate();
					end
				else

					local digAmount = (self.fireTimer.ElapsedSimTimeMS * 0.001) * self.digsPerSecond;
					self.fireTimer:Reset();

					for i = 1, digAmount do

						local digPos = ConstructorTerrainRay(self.MuzzlePos, Vector(self.digLength, 0):RadRotate(angle + RangeRand(-1, 1) * self.spreadRange), 1);

						if SceneMan:GetTerrMatter(digPos.X, digPos.Y) ~= rte.airID then

							local digWeight = 0;

							for x = 1, 3 do
								for y = 1, 3 do
									local checkPos = ConstructorWrapPos(Vector(digPos.X - 2 + x, digPos.Y - 2 + y));
									local terrCheck = SceneMan:GetTerrMatter(checkPos.X, checkPos.Y);
									if terrCheck ~= rte.airID then
										if terrCheck == rte.goldID then
											self.clearer.Pos = Vector(checkPos.X, checkPos.Y);
											self.clearer:EraseFromTerrain();
											local collectFX = CreateMOPixel("Particle Constructor Gather Material Gold");
											collectFX.Pos = Vector(checkPos.X, checkPos.Y);
											collectFX.Sharpness = self.ID;
											collectFX.Vel.Y = -RangeRand(2, 3);
											MovableMan:AddParticle(collectFX);
										else
											local material = SceneMan:GetMaterialFromID(terrCheck);
											if material.StructuralIntegrity > 0 and material.StructuralIntegrity <= self.digStrength then
												if math.random() > material.StructuralIntegrity/(self.digStrength * 1.1) then
													self.clearer.Pos = Vector(checkPos.X, checkPos.Y);
													self.clearer:EraseFromTerrain();
													digWeight = digWeight + material.StructuralIntegrity * 0.01;
												end
											else	-- deactivate if material is too strong
												self:Deactivate();
												break;
											end
										end
									end
								end
							end
							if digWeight > 0 then
								self.resource = math.min(self.resource + digWeight, self.maxResource);
								
								local collectFX = CreateMOPixel("Particle Constructor Gather Material" .. (digWeight > 4 and " Big" or ""));
								collectFX.Pos = Vector(digPos.X, digPos.Y);
								collectFX.Sharpness = self.ID;
								collectFX.Vel.Y = 10/(collectFX.Mass + digWeight);
								collectFX.Lifetime = SceneMan:ShortestDistance(digPos, self.Pos, SceneMan.SceneWrapsX).Magnitude/(collectFX.Vel.Magnitude * rte.PxTravelledPerFrame) * TimerMan.DeltaTimeMS;

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
			if playerControlled then
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
			local mouseControlled = ctrl:IsMouseControlled();
			local aiming = false;
			
			if mouseControlled then
				cursorMovement = cursorMovement + ctrl.MouseMovement;
			else
				aiming = ctrl:IsState(Controller.AIM_SHARP);
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
			if ctrl:IsState(Controller.WEAPON_CHANGE_NEXT) then
				self.blockSize = math.min(self.blockSize * 2, 48);
			end
			if ctrl:IsState(Controller.WEAPON_CHANGE_PREV) then
				self.blockSize = math.max(self.blockSize/2, 6);
			end

			if cursorMovement.Magnitude > 0 then
				self.cursor = self.cursor + (mouseControlled and cursorMovement or cursorMovement:SetMagnitude(self.cursorMoveSpeed * (aiming and 0.5 or 1)));
			end
			local precise = not mouseControlled and aiming;
			local map = Vector();
			if precise then
				map = Vector(math.floor(self.cursor.X - self.blockSize/2), math.floor(self.cursor.Y - self.blockSize/2));
				PrimitiveMan:DrawLinePrimitive(screen, self.cursor + Vector(2, 2), self.cursor + Vector(-3, -3), displayColorYellow);
				PrimitiveMan:DrawLinePrimitive(screen, self.cursor + Vector(2, -3), self.cursor + Vector(-3, 2), displayColorYellow);
			else
				map = ConstructorSnapPos(self.cursor, self.blockSize);
				PrimitiveMan:DrawLinePrimitive(screen, self.cursor + Vector(0, 4), self.cursor + Vector(0, -4), displayColorYellow);
				PrimitiveMan:DrawLinePrimitive(screen, self.cursor + Vector(4, 0), self.cursor + Vector(-4, 0), displayColorYellow);
			end
			PrimitiveMan:DrawBoxPrimitive(screen, map, map + Vector(self.blockSize - 1, self.blockSize - 1), displayColorYellow);

			if ctrl:IsState(Controller.PIE_MENU_ACTIVE) or ctrl:IsState(Controller.ACTOR_NEXT_PREP) or ctrl:IsState(Controller.ACTOR_PREV_PREP) then
				self.cursor = nil;
			elseif playerControlled then
				-- add blocks to the build queue if the cursor is firing
				if ctrl:IsState(Controller.WEAPON_FIRE) then
					local freeSlot = true;
					for i = 1, #self.buildList do
						if self.buildList[i] and self.buildList[i][1] == map.X and self.buildList[i][2] == map.Y then
							freeSlot = false;
							break;
						end
					end
					if freeSlot then
						local buildThis = {};
						buildThis[1] = map.X;
						buildThis[2] = map.Y;
						buildThis[3] = 0;
						buildThis[4] = self.blockSize;
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
						PrimitiveMan:DrawBoxPrimitive(screen, Vector(self.buildList[i][1], self.buildList[i][2]), Vector(self.buildList[i][1] + self.buildList[i][4] - 1, self.buildList[i][2] + self.buildList[i][4] - 1), displayColorBlue);
					else
						PrimitiveMan:DrawBoxPrimitive(screen, Vector(self.buildList[i][1], self.buildList[i][2]), Vector(self.buildList[i][1] + self.buildList[i][4] - 1, self.buildList[i][2] + self.buildList[i][4] - 1), displayColorRed);
					end
				end
			end
		end
		self.buildList = tempList;

		-- building up the first block in the build queue
		if self.resource >= self.buildCost and self.buildList[1] then
			if SceneMan:ShortestDistance(actor.Pos, Vector(self.buildList[1][1], self.buildList[1][2]), SceneMan.SceneWrapsX).Magnitude < self.buildDistance then
				--TODO: experiment with different cell sizes?
				local cellSize = 3;
				local oneThirdBlock = self.buildList[1][4]/cellSize;
				local cellsPerBlock = oneThirdBlock^2;
				if self.buildList[1][3] < cellsPerBlock then
					local by = math.floor(self.buildList[1][3]/oneThirdBlock);
					local bx = self.buildList[1][3] - (by * oneThirdBlock);
					by = by * cellSize - 1;
					bx = bx * cellSize - 1;
					
					self.buildList[1][3] = self.buildList[1][3] + 1;
					local totalCost = 0;
					local startPos = ConstructorWrapPos(Vector(bx + self.buildList[1][1], by + self.buildList[1][2]));
					for x = 1, cellSize do
						for y = 1, cellSize do
							local pos = Vector(startPos.X + x, startPos.Y + y);
							local strengthRatio = SceneMan:GetMaterialFromID(SceneMan:GetTerrMatter(pos.X, pos.Y)).StructuralIntegrity/200;
							if strengthRatio < 1 then
								local name = "";
								if bx + x == 0 or bx + x == self.buildList[1][4] - 1 or by + y == 0 or by + y == self.buildList[1][4] - 1 then
									name = "Base.rte/Constructor Border Tile " .. math.random(4);
								else
									name = "Base.rte/Constructor Tile " .. math.random(16);
								end
								local terrainObject = CreateTerrainObject(name); 
								terrainObject.Pos = pos;
								SceneMan:AddTerrainObject(terrainObject);
								
								didBuild = true;
								totalCost = 1 - strengthRatio;
							end
						end
					end
					if didBuild then
						self.resource = self.resource - (self.buildCost * totalCost);
						local buildPos = self.Pos + SceneMan:ShortestDistance(self.Pos, Vector(bx + self.buildList[1][1] + (cellSize - 1), by + self.buildList[1][2] + (cellSize - 1)), SceneMan.SceneWrapsX);
						PrimitiveMan:DrawBoxFillPrimitive(screen, Vector(bx + self.buildList[1][1] + 1, by + self.buildList[1][2] + 1), Vector(bx + self.buildList[1][1] + cellSize, by + self.buildList[1][2] + cellSize), displayColorWhite);
						PrimitiveMan:DrawLinePrimitive(screen, self.Pos, buildPos, displayColorBlue);
						self.buildSound:Play(buildPos);
						if self.buildList[1][3] == cellsPerBlock then
							self.buildList[1] = nil;
						end
					end
				else
					self.buildList[1] = nil;
				end
			else
				self.buildList[#self.buildList + 1] = self.buildList[1];
				self.buildList[1] = nil;
			end
		end
		if display then
			self.displayTimer:Reset();
		end
	elseif self.cursor then
		self.cursor = nil;
	end
end