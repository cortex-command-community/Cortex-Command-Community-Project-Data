require("Scenes/Objects/Bunkers/BunkerSystems/Movators/GlobalMovatorFunctions");

local movatorUtilityFunctions = {};
local movatorActorFunctions = {};
local uiFunctions = {};

function Create(self)
	-------------
	--Constants--
	-------------
	self.currentActivity = ActivityMan:GetActivity();
	self.checkWrapping = SceneMan.SceneWrapsX or SceneMan.SceneWrapsY;
	self.initialPieMenuFullInnerRadius = self.PieMenu.FullInnerRadius;
	self.movementModes = {
		freeze = 0,
		move = 1,
		unstickActor = 2,
		teleporting = 3,
		leaveMovators = 4,
	};
	self.oppositeDirections = {
		[Directions.Up] = Directions.Down,
		[Directions.Down] = Directions.Up,
		[Directions.Left] = Directions.Right,
		[Directions.Right] = Directions.Left,
	};

	self.sceneWaypointThresholdForTreatingTargetAsReached = 12;
	self.movableObjectWaypointThresholdForTreatingTargetAsReached = 48;
	self.movementSpeedMin = 4;
	self.movementSpeedMax = 16;
	self.movementAcceleration = self.movementSpeedMin * 0.1;
	self.massLimitMin = 100;
	self.massLimitMax = 5000;

	self.uiLineHeight = { [true] = 10, [false] = 15 };

	----------------------------------------
	--INI and Pie Menu Configurable Fields--
	----------------------------------------
	self.displayingInfoUI = self:NumberValueExists("DisplayInfoUI");
	self.acceptsAllTeams = self:NumberValueExists("AcceptsAllTeams") and self:GetNumberValue("AcceptsAllTeams") ~= 0 or false;
	self.acceptsCrafts =  self:NumberValueExists("AcceptsCrafts") and self:GetNumberValue("AcceptsCrafts") ~= 0 or false;
	self.humansRemainUpright = self:NumberValueExists("HumansRemainUpright") and self:GetNumberValue("HumansRemainUpright" ~= 0) or false;
	self.movementSpeed = self:NumberValueExists("MovementSpeed") and math.max(self.movementSpeedMin, math.min(self.movementSpeedMax, self:GetNumberValue("MovementSpeed"))) or (self.movementSpeedMin * 2);
	self.massLimit = self:NumberValueExists("MassLimit") and math.max(self.massLimitMin, math.min(self.massLimitMax, self:GetNumberValue("MassLimit"))) or (self.massLimitMin * 5);

	---------------------------
	--INI Configurable Fields--
	---------------------------
	self.infoUIUseSmallText = self:NumberValueExists("InfoUIUseSmallText") and self:GetNumberValue("InfoUIUseSmallText") ~= 0 or false;
	self.infoUIBGColour = self:NumberValueExists("InfoUIBGColour") and self:GetNumberValue("InfoUIBGColour") or 127;
	self.infoUIOutlineWidth = self:NumberValueExists("InfoUIOutlineWidth") and self:GetNumberValue("InfoUIOutlineWidth") or 2;
	self.infoUIOutlineColour = self:NumberValueExists("InfoUIOutlineColour") and self:GetNumberValue("InfoUIOutlineColour") or 71;

	-----------------
	--General Setup--
	-----------------
	for _, functionTable in ipairs({ movatorUtilityFunctions, movatorActorFunctions, uiFunctions }) do
		for functionName, functionReference in pairs(functionTable) do
			self[functionName] = functionReference;
		end
	end

	for actor in MovableMan.Actors do
		if actor.PresetName:find("Movator Controller") and actor.Team == self.Team and actor.UniqueID ~= self.UniqueID then
			ActivityMan:GetActivity():SetTeamFunds(ActivityMan:GetActivity():GetTeamFunds(self.Team) + actor:GetGoldValue(0, 0), self.Team);
			actor.ToDelete = true;
		end
	end

	for _, particleCollection in pairs({ MovableMan.Particles, MovableMan.AddedParticles }) do
		for node in particleCollection do
			if node and IsMOSRotating(node) and node.Team == team and node:IsInGroup("Movator Nodes") then
				ToMOSRotating(node):SetNumberValue("shouldReaddNode", 1);
			end
		end
	end
	--TODO make this an actual power system.
	MovatorData[self.Team].energyLevel = 100;

	self.obstructionCheckCoroutine = coroutine.create(self.checkAllObstructions);
	self.obstructionCheckTimer = Timer(10000);
	self.obstructionsFoundDuringCheck = false;

	self.addAllBoxesCoroutine = coroutine.create(self.addAllBoxes);
	self.addAllPathsCoroutine = coroutine.create(self.addAllPaths);
	self.addAllBoxesAndPathsTimer = Timer(50);
	self.allBoxesAdded = false;
	self.allPathsAdded = false;

	self.combinedMovatorArea = Area();
	self.pathTable = {};

	self.affectedActors = {};
	self.affectedActorsCount = 0;

	self.newActorCheckTimer = Timer(100);
	self.actorMovementUpdateTimer = Timer(15);

	self.heldInputTimer = Timer(50);

	self.leaveMovatorNetworkPieSlice = CreatePieSlice("Leave Movator Network", "Base.rte");
	self.chooseTeleporterPieSlice = CreatePieSlice("Choose Teleporter", "Base.rte");
end

function Update(self)
	self.Frame = 0;

	self:handlePieButtons();

	if self.currentActivity.ActivityState == Activity.EDITING then
		self:updateActivityEditingMode();
	elseif self.currentActivity.ActivityState == Activity.RUNNING then
		if self.obstructionCheckTimer:IsPastSimTimeLimit() then
			self:checkForObstructions();
			self.obstructionCheckTimer:Reset();
		end

		if (not self.allBoxesAdded or not self.allPathsAdded) and self.addAllBoxesAndPathsTimer:IsPastSimTimeLimit() then
			self:addAllBoxesAndPaths();
			self.addAllBoxesAndPathsTimer:Reset();
		end

		if self.allBoxesAdded and self.allPathsAdded then
			if self.newActorCheckTimer:IsPastSimTimeLimit() then
				self:checkForNewActors();
				self.newActorCheckTimer:Reset();
			end

			if self.actorMovementUpdateTimer:IsPastSimTimeLimit() then
				for actorUniqueID, actorData in pairs(self.affectedActors) do
					local actor = actorData.actor;
					if not MovableMan:IsActor(actor) or not self.combinedMovatorArea:IsInside(actor.Pos) then
						self:removeActorFromMovatorTable(actor, actorUniqueID);
					else
						if actor:NumberValueExists("Movator_LeaveMovatorNetwork") then
							self:setActorMovementModeToLeaveMovators(actorData);
							actor:RemoveNumberValue("Movator_LeaveMovatorNetwork");
						end
						if actor:IsPlayerControlled() and actor:NumberValueExists("Movator_ChooseTeleporter") then
							self:setupManualTeleporterData(actorData);
							actor:RemoveNumberValue("Movator_ChooseTeleporter");
						end

						if actor:IsPlayerControlled() then
							local closestNode = self:findClosestNode(actor.Pos, nil, false, false, false);
							if closestNode ~= nil and MovatorData[self.Team].teleporterNodes[closestNode] ~= nil and MovatorData[self.Team].nodeData[closestNode].zoneBox:IsWithinBox(actor.Pos) then
								actor.PieMenu:AddPieSliceIfPresetNameIsUnique(self.chooseTeleporterPieSlice:Clone(), self);
							else
								actor.PieMenu:RemovePieSlicesByPresetName(self.chooseTeleporterPieSlice.PresetName);
							end
							
							if actorData.manualTeleporterData then
								self:chooseTeleporterForPlayerControlledActor(actorData);
								actorData.movementMode = self.movementModes.teleporting;
							else
								actorData.movementMode = self.movementModes.freeze;
							end
							
							if actorData.movementMode ~= self.movementModes.teleporting then -- Note: Teleporting movement mode can be set manually or by waypoints. The point is that you can't move the Actor while it's currently teleporting.
								self:updateDirectionsFromActorControllerInput(actorData);
							end
						elseif actorData.movementMode ~= self.movementModes.leaveMovators then
							self:updateDirectionsFromWaypoints(actorData);
						end
						
						if actorData.movementMode ~= self.movementModes.leaveMovators then
							local actorController = actor:GetController();
							actorController:SetState(Controller.MOVE_LEFT, false);
							actorController:SetState(Controller.MOVE_RIGHT, false);
							actorController:SetState(Controller.MOVE_UP, false);
							actorController:SetState(Controller.MOVE_DOWN, false);
							actorController:SetState(Controller.BODY_JUMP, false);
							actorController:SetState(Controller.BODY_JUMPSTART, false);

							if IsACDropShip(actor) then
								actor = ToACDropShip(actor);
								actor.RightEngine:EnableEmission(false);
								actor.LeftEngine:EnableEmission(false);
								actor.RightThruster:EnableEmission(false);
								actor.LeftThruster:EnableEmission(false);
								actor.RotAngle = 0;
							elseif IsACRocket(actor) then
								actor.RotAngle = 0;
							end

							local actorIsSlowEnoughToUseMovators = self:slowDownFastActorToMovementSpeed(actorData);

							if actorIsSlowEnoughToUseMovators then
								if actorData.direction == Directions.None or actorData.movementMode ~= self.movementModes.move or actor.Vel:MagnitudeIsGreaterThan(self.movementSpeed - 1) then
									actorData.unstickTimer:Reset();
								elseif actorData.unstickTimer:IsPastSimTimeLimit() then
									actorData.movementMode = self.movementModes.unstickActor;
									print("oh no, we're stuck!")
								end

								if actorData.movementMode == self.movementModes.move or actorData.movementMode == self.movementModes.unstickActor then
									self:centreActorToClosestNodeIfMovingInAppropriateDirection(actorData);
								end
								if actorData.movementMode == self.movementModes.freeze then
									self:updateFrozenActor(actorData);
								elseif actorData.movementMode == self.movementModes.move then
									self:updateMovingActor(actorData);
								end
							end
						end
					end
				end
				self.actorMovementUpdateTimer:Reset();
			end

			--self:updateVisualEffects();
		end
	end

	if self.displayingInfoUI then
		self.PieMenu.FullInnerRadius = self:updateInfoUI();
	else
		self.PieMenu.FullInnerRadius = self.initialPieMenuFullInnerRadius;
	end
	self.Frame = 1;
end

function Destroy(self)
	for actor in MovableMan.Actors do
		if actor.PresetName:find("Movator Controller") and actor.Team == self.Team and actor.UniqueID ~= self.UniqueID then
			return;
		end
	end
	MovatorData[self.Team].energyLevel = 0;
	MovatorData[self.Team].nodeData = {};
	MovatorData[self.Team].nodeDataCount = 0;
	MovatorData[self.Team].teleporterNodes = {};
	MovatorData[self.Team].teleporterNodesCount = 0;
end

movatorUtilityFunctions.handlePieButtons = function(self)
	self.displayingInfoUI = self:NumberValueExists("DisplayInfoUI");

	if self:NumberValueExists("SwapAcceptsAllTeams") then
		self.acceptsAllTeams = not self.acceptsAllTeams;
		self:RemoveNumberValue("SwapAcceptsAllTeams");
	end
	if self:NumberValueExists("SwapAcceptsCrafts") then
		self.acceptsCrafts = not self.acceptsCrafts;
		self:RemoveNumberValue("SwapAcceptsCrafts");
	end
	if self:NumberValueExists("SwapHumansRemainUpright") then
		self.humansRemainUpright = not self.humansRemainUpright;
		self:RemoveNumberValue("SwapHumansRemainUpright");
	end

	if self:NumberValueExists("ModifyMovementSpeed") and self.heldInputTimer:IsPastSimTimeLimit() then
		if self:GetController():IsState(Controller.SCROLL_UP) or self:GetController():IsState(Controller.HOLD_UP) then
			self.movementSpeed = math.min(self.movementSpeed + 1, self.movementSpeedMax);
		elseif self:GetController():IsState(Controller.SCROLL_DOWN) or self:GetController():IsState(Controller.HOLD_DOWN) then
			self.movementSpeed = math.max(self.movementSpeed - 1, self.movementSpeedMin);
		end
		self.heldInputTimer:Reset()
	end
	if self:NumberValueExists("ModifyMassLimit") and self.heldInputTimer:IsPastSimTimeLimit() then
		if self:GetController():IsState(Controller.SCROLL_UP) or self:GetController():IsState(Controller.HOLD_UP) then
			self.massLimit = math.min(self.massLimit + 25, self.massLimitMax);
		elseif self:GetController():IsState(Controller.SCROLL_DOWN) or self:GetController():IsState(Controller.HOLD_DOWN) then
			self.massLimit = math.max(self.massLimit - 25, self.massLimitMin);
		end
		self.heldInputTimer:Reset();
	end
--[[
	if self:NumberValueExists("ModifyMovatorEffectsType") then
		self:CleanupCurrentMovatorObjectEffectsTableIfPossible();
		local displayTypes = { "" };
		for displayType, _ in pairs(self.EffectsTable.displayTypes) do
			displayTypes[#displayTypes + 1] = displayType;
		end

		for displayTypeIndex, displayType in ipairs(displayTypes) do
			if displayType == self.EffectsTable.selectedType then
				self.EffectsTable.selectedType = displayTypes[((displayTypeIndex % #displayTypes) + 1)];
				break;
			end
		end
		self:RemoveNumberValue("ModifyMovatorEffectsType");
	end
	if self:NumberValueExists("ModifyMovatorEffectsSize") then
		self:CleanupCurrentMovatorObjectEffectsTableIfPossible();
		local largestEffectsSize = 3;
		self.EffectsTable.selectedSize = (self.EffectsTable.selectedSize % largestEffectsSize) + 1;
		self:RemoveNumberValue("ModifyMovatorEffectsSize");
	end
	]]
end

movatorUtilityFunctions.fuzzyPositionMatch = function(self, pos1, pos2, ignoreXMatching, ignoreYMatching, fuzziness, otherDistanceMustBeNegative)
	local distance = SceneMan:ShortestDistance(pos1, pos2, self.checkWrapping);
	local valuesMatch = {X = ignoreXMatching, Y = ignoreYMatching};
	for axis, ignoreMatching in pairs(valuesMatch) do
		if not ignoreMatching then
			if fuzziness >= 0 then
				valuesMatch[axis] = distance[axis] >= 0 and distance[axis] <= fuzziness;
			else
				valuesMatch[axis] = distance[axis] < 0 and distance[axis] >= fuzziness;
			end

			local otherAxis = axis == "X" and "Y" or "X";
			if otherDistanceMustBeNegative then
				valuesMatch[axis] = valuesMatch[axis] and distance[otherAxis] <= 0;
			else
				valuesMatch[axis] = valuesMatch[axis] and distance[otherAxis] >= 0;
			end
		end
	end
	return valuesMatch.X and valuesMatch.Y;
end

movatorUtilityFunctions.updateActivityEditingMode = function(self)
	local teamNodeTable = MovatorData[self.Team].nodeData;
	local teamTeleporterTable = MovatorData[self.Team].teleporterNodes;

	local relevantPlayers = {};
	for player = 0, Activity.PLAYER_4 do
		if self.currentActivity:PlayerHuman(player) and self.currentActivity:GetTeamOfPlayer(player) == self.Team then
			relevantPlayers[#relevantPlayers + 1] = player;
		end
	end

	for _, player in ipairs(relevantPlayers) do
		local selectedEditorObject = ToGameActivity(self.currentActivity):GetEditorGUI(player):GetCurrentObject();
		if selectedEditorObject ~= nil and (selectedEditorObject.PresetName:find("Movator Zone") or selectedEditorObject.PresetName:find("Teleporter Zone")) then
			local selectedEditorObjectPos = selectedEditorObject.Pos;

			local directionMatches = {};
			if not selectedEditorObject.PresetName:find("Vertical Only") then
				directionMatches.left = {};
				directionMatches.right = {};
			end
			if not selectedEditorObject.PresetName:find("Horizontal Only") then
				directionMatches.up = {};
				directionMatches.down = {};
			end

			for direction, matches in pairs(directionMatches) do
				local distanceInDirectionMustBeNegative = direction == "up" or direction == "left";
				for node, nodeData in pairs(teamNodeTable) do
					if selectedEditorObject.PresetName:find("Teleporter Zone") == nil or not teamTeleporterTable[node] then
						local ignoreXMatching = direction == "left" or direction == "right" or (node.PresetName:find("Horizontal Only") ~= nil);
						local ignoreYMatching = direction == "up" or direction == "down" or (node.PresetName:find("Vertical Only") ~= nil);
						if not (ignoreXMatching and ignoreYMatching) then
							if self:fuzzyPositionMatch(selectedEditorObjectPos, node.Pos, ignoreXMatching, ignoreYMatching, 0, distanceInDirectionMustBeNegative) then
								local distance = SceneMan:ShortestDistance(selectedEditorObjectPos, node.Pos, self.checkWrapping);
								if not matches.exact or distance.SqrMagnitude < matches.exact.SqrMagnitude then
									matches.exact = distance;
								end
							elseif self:fuzzyPositionMatch(selectedEditorObjectPos, node.Pos, ignoreXMatching, ignoreYMatching, 12, distanceInDirectionMustBeNegative) then
								local distance = SceneMan:ShortestDistance(selectedEditorObjectPos, node.Pos, self.checkWrapping);
								if not matches.closestFuzzyPositive or distance.SqrMagnitude < matches.closestFuzzyPositive.SqrMagnitude then
									matches.closestFuzzyPositive = distance;
								end
							elseif self:fuzzyPositionMatch(selectedEditorObjectPos, node.Pos, ignoreXMatching, ignoreYMatching, -12, distanceInDirectionMustBeNegative) then
								local distance = SceneMan:ShortestDistance(selectedEditorObjectPos, node.Pos, self.checkWrapping);
								if not matches.closestFuzzyNegative or distance.SqrMagnitude < matches.closestFuzzyNegative.SqrMagnitude then
									matches.closestFuzzyNegative = distance;
								end
							end
						end
					end
				end
				for matchType, distanceToMatch in pairs(matches) do
					if SceneMan:CastStrengthRay(selectedEditorObjectPos, distanceToMatch, 15, Vector(), 4, 0, true) then
						PrimitiveMan:DrawLinePrimitive(selectedEditorObjectPos, selectedEditorObjectPos + distanceToMatch, matchType == "exact" and 12 or 8);
					else
						PrimitiveMan:DrawLinePrimitive(selectedEditorObjectPos, selectedEditorObjectPos + distanceToMatch, matchType == "exact" and 147 or 159);
					end
				end
			end
		end
	end
end

movatorUtilityFunctions.checkForObstructions = function(self)
	local coroutineIsDead, obstructionsFound = coroutine.resume(self.obstructionCheckCoroutine, self);
	if not coroutineIsDead and not obstructionsFound then
		self.obstructionsFound = self.obstructionsFound or obstructionsFound;
		self.obstructionCheckTimer:SetSimTimeLimitMS(100);
	else
		self.obstructionCheckCoroutine = coroutine.create(self.checkAllObstructions);
		self.obstructionCheckTimer:SetSimTimeLimitMS(10000);

		if self.obstructionsFound then
			self.allBoxesAdded = false;
			self.allPathsAdded = false;
			self.obstructionsFound = false;
		end
	end
end

movatorUtilityFunctions.checkAllObstructions = function(self)
	local teamNodeTable = MovatorData[self.Team].nodeData;

	local nodeConnectionsHaveChanged = false;
	local checkedNodeCount = 0;

	local oppositeDirectionTable = {
		[Directions.Up] = Directions.Down,
		[Directions.Down] = Directions.Up,
		[Directions.Left] = Directions.Right,
		[Directions.Right] = Directions.Left,
	};

	for node, nodeData in pairs(teamNodeTable) do
		local previousConnectedNodeCount = nodeData.connectedNodeCount;
		nodeData.connectedNodeCount = 0;
		nodeData.connectedNodeData = {};

		local nodesAffectedByThisMovator = Movators_CheckConnections(node);
		if nodesAffectedByThisMovator then
			for direction, affectedNode in pairs(nodesAffectedByThisMovator) do
				local affectedNodeTable = teamNodeTable[affectedNode];
				affectedNodeTable.connectedNodeCount = affectedNodeTable.connectedNodeCount - 1;
				affectedNodeTable.connectedNodeData[oppositeDirectionTable[direction]] = nil;
				Movators_CheckConnections(affectedNode);
			end
		end

		if previousConnectedNodeCount ~= nodeData.connectedNodeCount then
			nodeConnectionsHaveChanged = true;
		end

		checkedNodeCount = checkedNodeCount + 1;
		if checkedNodeCount % 5 == 0 then
			coroutine.yield(nodeConnectionsHaveChanged);
		end
	end
	return nodeConnectionsHaveChanged;
end

movatorUtilityFunctions.addAllBoxesAndPaths = function(self)
	if not self.allBoxesAdded and coroutine.status(self.addAllBoxesCoroutine) == "dead" then
		self.addAllBoxesCoroutine = coroutine.create(self.addAllBoxes);
	end
	coroutine.resume(self.addAllBoxesCoroutine, self);
	self.allBoxesAdded = self.allBoxesAdded or coroutine.status(self.addAllBoxesCoroutine) == "dead";

	if not self.allPathsAdded and coroutine.status(self.addAllPathsCoroutine) == "dead" then
		self.addAllPathsCoroutine = coroutine.create(self.addAllPaths);
	end
	coroutine.resume(self.addAllPathsCoroutine, self);

	self.allPathsAdded = self.allPathsAdded or coroutine.status(self.addAllPathsCoroutine) == "dead";
end

movatorUtilityFunctions.addAllBoxes = function(self)
	local teamNodeTable = MovatorData[self.Team].nodeData;

	local addedNodeCount = 0;
	for node, nodeData in pairs(teamNodeTable) do
		if nodeData.zoneBox ~= nil then
			self.combinedMovatorArea:AddBox(nodeData.zoneBox);
		else
			print("Movator Error: Movator at position " .. tostring(node.Pos) .. " had no ZoneBox.");
		end

		for _, direction in pairs({Directions.Up, Directions.Left}) do
			if nodeData.connectedNodeData[direction] then
				local connectedNode = nodeData.connectedNodeData[direction].node;
				local connectedNodeData = teamNodeTable[connectedNode];

				local connectingBoxTopLeftCornerOffset;
				local connectingBoxBottomRightCornerOffset;
				if direction == Directions.Up then
					local smallerNodeZoneHalfWidth = math.min(nodeData.size.X, connectedNodeData.size.X) * 0.5;
					connectingBoxTopLeftCornerOffset = Vector(-smallerNodeZoneHalfWidth, connectedNodeData.size.Y * 0.5);
					connectingBoxBottomRightCornerOffset = Vector(smallerNodeZoneHalfWidth, -nodeData.size.Y * 0.5);
				else
					local smallerNodeZoneHalfHeight = math.min(nodeData.size.Y, connectedNodeData.size.Y) * 0.5;
					connectingBoxTopLeftCornerOffset = Vector(connectedNodeData.size.X * 0.5, -smallerNodeZoneHalfHeight);
					connectingBoxBottomRightCornerOffset = Vector(-nodeData.size.X * 0.5, smallerNodeZoneHalfHeight);
				end

				nodeData.connectingAreas[direction] = Area();
				--TODO Area::IsInside wraps things when you check it, so maybe can just store the box, if that's all we're using this for
				for wrappedConnectingBox in SceneMan:WrapBox(Box(connectedNode.Pos + connectingBoxTopLeftCornerOffset, node.Pos + connectingBoxBottomRightCornerOffset)) do
					nodeData.connectingAreas[direction]:AddBox(wrappedConnectingBox);
					self.combinedMovatorArea:AddBox(wrappedConnectingBox);
				end
			end
		end
		addedNodeCount = addedNodeCount + 1;
		if addedNodeCount % 10 == 0 and coroutine.running() then
			coroutine.yield();
		end
	end
	for node, nodeData in pairs(teamNodeTable) do
		for _, direction in pairs({Directions.Down, Directions.Right}) do
			if nodeData.connectedNodeData[direction] then
				nodeData.connectingAreas[direction] = teamNodeTable[nodeData.connectedNodeData[direction].node].connectingAreas[(direction == Directions.Down and Directions.Up or Directions.Left)];
			end
		end
	end
	return true;
end

movatorUtilityFunctions.addAllPaths = function(self)
	local teamNodeTable = MovatorData[self.Team].nodeData;
	local teamTeleporterTable = MovatorData[self.Team].teleporterNodes;

	local possibleConnectionDirections = {Directions.Up, Directions.Down, Directions.Left, Directions.Right};

	for node, nodeData in pairs(teamNodeTable) do
		local tentativeNodes = {};
		local confirmedNodes = {};
		confirmedNodes[node] = { distance = 0, direction = Directions.None };
		local addedPathCount = 0;

		local connectedNodeData = nodeData.connectedNodeData;
		for _, direction in ipairs(possibleConnectionDirections) do
			if connectedNodeData[direction] ~= nil and confirmedNodes[connectedNodeData[direction].node] == nil then
				tentativeNodes[connectedNodeData[direction].node] = { distance = confirmedNodes[node].distance + connectedNodeData[direction].distance.Magnitude, direction = direction };
			end
		end

		if teamTeleporterTable[node] then
			for teleporter, _ in pairs(teamTeleporterTable) do
				if teleporter.UniqueID ~= node.UniqueID then
					tentativeNodes[teleporter] = { distance = 48, direction = Directions.Any }; -- Teleporter extra distance is set as the smallest distance between two nodes, and its direction is set to Any to distinguish it.
				end
			end
		end

		while type(next(tentativeNodes)) ~= "nil" do
			local closestNode;
			local distanceToClosestNode;
			for tentativeNode, tentativeNodeData in pairs(tentativeNodes) do
				if distanceToClosestNode == nil or tentativeNodeData.distance < distanceToClosestNode then
					closestNode = tentativeNode;
					distanceToClosestNode = tentativeNodeData.distance;
				end
			end
			if closestNode == nil then
				break;
			end
			confirmedNodes[closestNode] = { distance = distanceToClosestNode, direction = tentativeNodes[closestNode].direction };
			tentativeNodes[closestNode] = nil;

			local closestNodeConnectedNodeData = teamNodeTable[closestNode].connectedNodeData;
			for _, direction in ipairs(possibleConnectionDirections) do
				if closestNodeConnectedNodeData[direction] ~= nil and confirmedNodes[closestNodeConnectedNodeData[direction].node] == nil then
					local nodeInDirection = closestNodeConnectedNodeData[direction].node;
					if tentativeNodes[nodeInDirection] == nil or tentativeNodes[nodeInDirection].distance > (closestNodeConnectedNodeData[direction].distance.Magnitude + confirmedNodes[closestNode].distance) then
						tentativeNodes[nodeInDirection] = { distance = closestNodeConnectedNodeData[direction].distance.Magnitude + confirmedNodes[closestNode].distance, direction = confirmedNodes[closestNode].direction };
					end
				end
			end

			if teamTeleporterTable[closestNode] then
				for teleporter, _ in pairs(teamTeleporterTable) do
					if teleporter.UniqueID ~= closestNode.UniqueID and confirmedNodes[teleporter] == nil then
						tentativeNodes[teleporter] = { distance = confirmedNodes[closestNode].distance + 48, direction = confirmedNodes[closestNode].direction }; -- Teleporter extra distance is set as the smallest distance between two nodes, and its direction is set to Any to distinguish it.
					end
				end
			end

			addedPathCount = addedPathCount + 1;
			if addedPathCount % 10 == 0 and coroutine.running() then
				coroutine.yield();
			end
		end
		self.pathTable[node] = confirmedNodes;
		if coroutine.running() then
			coroutine.yield();
		end
	end
	return true;
end

movatorUtilityFunctions.findClosestNode = function(self, positionToFindClosestNodeFor, nodeToCheckForPathsFrom, checkForLineOfSight, checkThatPositionIsInsideNodeZoneBoxOrConnectingAreas, checkForShortestPathfinderPath)
	local teamNodeTable = MovatorData[self.Team].nodeData;
	local teamTeleporterTable = MovatorData[self.Team].teleporterNodes;

	local closestNode;
	local distanceToClosestNode;
	local lengthOfScenePathToClosestNode;
	for node, nodeData in pairs(teamNodeTable) do
		if nodeToCheckForPathsFrom == nil or (self.pathTable[nodeToCheckForPathsFrom] ~= nil and self.pathTable[nodeToCheckForPathsFrom][node] ~= nil) then
			local distanceToNode = SceneMan:ShortestDistance(node.Pos, positionToFindClosestNodeFor, self.checkWrapping);
			if distanceToClosestNode == nil or distanceToNode:MagnitudeIsLessThan(distanceToClosestNode) then
				local nodeSatisfiesConditions = true;
				if checkForLineOfSight then
					nodeSatisfiesConditions = not SceneMan:CastStrengthRay(node.Pos, distanceToNode, 15, Vector(), 4, 0, true);
				end
				if nodeSatisfiesConditions and checkThatPositionIsInsideNodeZoneBoxOrConnectingAreas then
					nodeSatisfiesConditions = nodeData.zoneBox:IsWithinBox(positionToFindClosestNodeFor);
					if not nodeSatisfiesConditions then
						local connectingAreaDirectionToCheck = Directions.None;
						if distanceToNode.Y + (nodeData.size.Y * 0.5) < 0 then
							connectingAreaDirectionToCheck = Directions.Up;
						elseif distanceToNode.Y - (nodeData.size.Y * 0.5) > 0 then
							connectingAreaDirectionToCheck = Directions.Down;
						elseif distanceToNode.X + (nodeData.size.X * 0.5) < 0 then
							connectingAreaDirectionToCheck = Directions.Left;
						elseif distanceToNode.X - (nodeData.size.X * 0.5) > 0 then
							connectingAreaDirectionToCheck = Directions.Right;
						end
						if connectingAreaDirectionToCheck ~= Directions.None and nodeData.connectingAreas[connectingAreaDirectionToCheck] ~= nil then
							nodeSatisfiesConditions = nodeData.connectingAreas[connectingAreaDirectionToCheck]:IsInside(positionToFindClosestNodeFor);
						end
					end
				end
				if nodeSatisfiesConditions and checkForShortestPathfinderPath then
					nodeSatisfiesConditions = false;
					local lengthOfScenePathToNode = SceneMan.Scene:CalculatePath(positionToFindClosestNodeFor, node.Pos, false, GetPathFindingDefaultDigStrength());
					if lengthOfScenePathToClosestNode == nil or lengthOfScenePathToNode < lengthOfScenePathToClosestNode then
						nodeSatisfiesConditions = true;
						lengthOfScenePathToClosestNode = lengthOfScenePathToNode;
					end
				end
				if nodeSatisfiesConditions then
					closestNode = node;
					distanceToClosestNode = distanceToNode.Magnitude;
				end
			end
		end
	end
	return closestNode;
end

movatorUtilityFunctions.changeScaleOfMOSRotatingAndAttachables = function(self, mosRotatingToChangeScaleOf, scale)
	mosRotatingToChangeScaleOf.Scale = scale;
	for attachable in mosRotatingToChangeScaleOf.Attachables do
		self:changeScaleOfMOSRotatingAndAttachables(attachable, scale);
	end
end

movatorActorFunctions.checkForNewActors = function(self)
	for box in self.combinedMovatorArea.Boxes do
		for movableObject in MovableMan:GetMOsInBox(box, -1, true) do
			if IsActor(movableObject) and self.affectedActors[movableObject.UniqueID] == nil and movableObject.PinStrength == 0 then
				local actor = ToActor(movableObject);
				if actor.AIMode ~= Actor.AIMODE_GOLDDIG and actor.AIMode ~= Actor.AIMODE_PATROL then
					local teamAccepted = self.acceptsAllTeams or movableObject.Team == self.Team;
					local massAccepted = movableObject.Mass < self.massLimit;
					local typeAccepted = self.acceptsCrafts or (not IsACRocket(movableObject) and not IsACDropShip(movableObject));
					if teamAccepted and massAccepted and typeAccepted then
						self:addActorToMovatorTable(actor);
					end
				end
			end
		end
	end
end

movatorActorFunctions.addActorToMovatorTable = function(self, actor)
	self.affectedActors[actor.UniqueID] = {
		actor = actor,
		movementMode = self.movementModes.freeze,
		direction = Directions.None,
		unstickTimer = Timer(2000),
		waypointData = nil,
	};
	self.affectedActorsCount = self.affectedActorsCount + 1;

	actor.PieMenu:AddPieSliceIfPresetNameIsUnique(self.leaveMovatorNetworkPieSlice:Clone(), self);
	if IsAHuman(actor) then
		ToAHuman(actor).LimbPushForcesAndCollisionsDisabled = true;
	end
end

movatorActorFunctions.removeActorFromMovatorTable = function(self, actor, optionalActorUniqueID)
	if actor.UniqueID ~= 0 and optionalActorUniqueID == nil then
		optionalActorUniqueID = actor.UniqueID;
	end
	if self.affectedActors[optionalActorUniqueID] ~= nil then
		self:convertWaypointDataToActorWaypoints(self.affectedActors[optionalActorUniqueID]);
	end

	self.affectedActors[optionalActorUniqueID] = nil;
	self.affectedActorsCount = self.affectedActorsCount - 1;

	if MovableMan:IsActor(actor) then
		actor.PieMenu:RemovePieSlicesByPresetName(self.leaveMovatorNetworkPieSlice.PresetName);
		actor.PieMenu:RemovePieSlicesByPresetName(self.chooseTeleporterPieSlice.PresetName);
	end
	if IsAHuman(actor) then
		ToAHuman(actor).LimbPushForcesAndCollisionsDisabled = false;
	end
end

movatorActorFunctions.setActorMovementModeToLeaveMovators = function(self, actorData)
	local actor = actorData.actor;

	actor.PieMenu:RemovePieSlicesByPresetName(self.leaveMovatorNetworkPieSlice.PresetName);
	actor.PieMenu:RemovePieSlicesByPresetName(self.chooseTeleporterPieSlice.PresetName);
	self:changeScaleOfMOSRotatingAndAttachables(actor, 1);
	if IsAHuman(actor) then
		ToAHuman(actor).LimbPushForcesAndCollisionsDisabled = false;
	end
	self:convertWaypointDataToActorWaypoints(actorData);

	actorData.movementMode = self.movementModes.leaveMovators;
end

movatorActorFunctions.convertActorWaypointsToWaypointData = function(self, actorData)
	local actor = actorData.actor;
	actorData.waypointData = {};
	local waypointData = actorData.waypointData;

	if actor.MOMoveTarget then
		waypointData.movableObjectTarget = actor.MOMoveTarget;
	else
		waypointData.sceneTargets = {}
		if actor.MovePathEnd ~= actor.Pos then
			waypointData.sceneTargets[#waypointData.sceneTargets + 1] = Vector(actor.MovePathEnd.X, actor.MovePathEnd.Y);
		end
		for actorSceneWaypoint in actor.SceneWaypoints do
			waypointData.sceneTargets[#waypointData.sceneTargets + 1] = Vector(actorSceneWaypoint.X, actorSceneWaypoint.Y);
		end
	end
	waypointData.previousAIMode = actor.AIMode;
	actor.AIMode = Actor.AIMODE_SENTRY;
	actor:ClearAIWaypoints();
end

movatorActorFunctions.convertWaypointDataToActorWaypoints = function(self, actorData)
	local actor = actorData.actor;
	local waypointData = actorData.waypointData;

	if waypointData then
		actor.AIMode = waypointData.previousAIMode;
		if waypointData.movableObjectTarget then
			actor:AddAIMOWaypoint(waypointData.movableObjectTarget);
		elseif waypointData.sceneTargets then
			for _, sceneTarget in ipairs(waypointData.sceneTargets) do
				actor:AddAISceneWaypoint(sceneTarget);
			end
		end
		actor:UpdateMovePath();

		actorData.waypointData = nil;
	end
end

movatorActorFunctions.setupManualTeleporterData = function(self, actorData)
	local teamTeleporterTable = MovatorData[self.Team].teleporterNodes;
	
	local actor = actorData.actor;
	
	actorData.waypointData = nil;
	actorData.manualTeleporterData = {};
	manualTeleporterData = actorData.manualTeleporterData;
	
	manualTeleporterData.actorTeleportationStage = 0;
	manualTeleporterData.teleporterVisualsTimer = Timer(1000);
	
	local startingTeleporter = self:findClosestNode(actor.Pos, nil, false, false, false);
	manualTeleporterData.sortedTeleporters = {{ node = startingTeleporter, distance = 0 }};
	
	for teleporterNode, _ in pairs(teamTeleporterTable) do
		if teleporterNode.UniqueID ~= startingTeleporter.UniqueID then
			local xDistanceToTeleporter = SceneMan:ShortestDistance(startingTeleporter.Pos, teleporterNode.Pos, self.checkWrapping).X;
			
			local teleporterNodeAddedToSortedTable = false;
			for index, sortedTeleporterData in ipairs(manualTeleporterData.sortedTeleporters) do
				if xDistanceToTeleporter <= sortedTeleporterData.distance then
					table.insert(manualTeleporterData.sortedTeleporters, index, { node = teleporterNode, distance = xDistanceToTeleporter });
					teleporterNodeAddedToSortedTable = true;
					break;
				end
			end
			if not teleporterNodeAddedToSortedTable then
				table.insert(manualTeleporterData.sortedTeleporters, #manualTeleporterData.sortedTeleporters + 1, { node = teleporterNode, distance = xDistanceToTeleporter });
			end
		end
	end
	for index, sortedTeleporterData in pairs(manualTeleporterData.sortedTeleporters) do
		if sortedTeleporterData.node.UniqueID == startingTeleporter.UniqueID then
			manualTeleporterData.currentChosenTeleporter = index;
			print("Current teleporter found!")
		--	break;
		end
		print(tostring(index).. ". " ..tostring(sortedTeleporterData.node.Pos))
	end
	
	self.heldInputTimer:Reset(); -- Note: Because manual teleporting is done with Fire and Pie Menu, we need to reset this timer when we set things up, so we don't instantly trigger teleporting or canceling.
end

movatorActorFunctions.chooseTeleporterForPlayerControlledActor = function(self, actorData)
	local actor = actorData.actor;
	local actorController = actor:GetController();
	local manualTeleporterData = actorData.manualTeleporterData;
	
	if manualTeleporterData.actorTeleportationStage == 0 then
		if actorController:IsState(Controller.PRESS_LEFT) or (actorController:IsState(Controller.HOLD_LEFT) and self.heldInputTimer:IsPastSimMS(250)) then
			manualTeleporterData.currentChosenTeleporter = manualTeleporterData.currentChosenTeleporter - 1;
			if manualTeleporterData.currentChosenTeleporter <= 0 then
				manualTeleporterData.currentChosenTeleporter = #manualTeleporterData.sortedTeleporters;
			end
			print(manualTeleporterData.currentChosenTeleporter)
			self.heldInputTimer:Reset();
		elseif actorController:IsState(Controller.PRESS_RIGHT) or (actorController:IsState(Controller.HOLD_RIGHT) and self.heldInputTimer:IsPastSimMS(250)) then
			manualTeleporterData.currentChosenTeleporter = manualTeleporterData.currentChosenTeleporter + 1;
			if manualTeleporterData.currentChosenTeleporter > #manualTeleporterData.sortedTeleporters then
				manualTeleporterData.currentChosenTeleporter = 1;
			end
			print(manualTeleporterData.currentChosenTeleporter)
			self.heldInputTimer:Reset();
		elseif actorController:IsState(Controller.PRESS_PRIMARY) and self.heldInputTimer:IsPastSimTimeLimit() then
			manualTeleporterData.actorTeleportationStage = 1;
			manualTeleporterData.teleporterVisualsTimer:Reset();
		elseif actorController:IsState(Controller.PRESS_SECONDARY) and self.heldInputTimer:IsPastSimTimeLimit() then
			actorData.manualTeleporterData = nil;
			return;
		end
		
		local player = actorController.Player;
		CameraMan:SetScrollTarget(manualTeleporterData.sortedTeleporters[manualTeleporterData.currentChosenTeleporter].node.Pos, 1, false, player);
		FrameMan:ClearScreenText(player);
		FrameMan:SetScreenText("CHOOSING TELEPORTER: Move Left or Right to change teleporter. Press Fire to teleport. Open the Pie Menu to cancel.", player, 0, 100, false);
	else
		self:changeScaleOfMOSRotatingAndAttachables(actor, (manualTeleporterData.actorTeleportationStage == 2 and manualTeleporterData.teleporterVisualsTimer.SimTimeLimitProgress or 1 - manualTeleporterData.teleporterVisualsTimer.SimTimeLimitProgress));
		self:centreActorToClosestNodeIfMovingInAppropriateDirection(actorData, true);
		if manualTeleporterData.teleporterVisualsTimer.SimTimeLimitProgress >= 1 then
			if manualTeleporterData.actorTeleportationStage == 1 then
				actor.Pos = manualTeleporterData.sortedTeleporters[manualTeleporterData.currentChosenTeleporter].node.Pos;
				manualTeleporterData.actorTeleportationStage = manualTeleporterData.actorTeleportationStage + 1;
				manualTeleporterData.teleporterVisualsTimer:Reset();
			else
				actorData.manualTeleporterData = nil;
				return;
			end
		end
	end
	actor:FlashWhite(100);
	self:updateFrozenActor(actorData);
	return;
end

movatorActorFunctions.updateDirectionsFromActorControllerInput = function(self, actorData)
	local actor = actorData.actor;
	local actorController = actor:GetController();

	actorData.direction = Directions.None;

	if not actorController:IsState(Controller.PIE_MENU_ACTIVE) then
		if actorController:IsState(Controller.PRESS_UP) or actorController:IsState(Controller.HOLD_UP) then
			actorData.direction = Directions.Up;
		elseif actorController:IsState(Controller.PRESS_DOWN) or actorController:IsState(Controller.HOLD_DOWN) then
			actorData.direction = Directions.Down;
		elseif actorController:IsState(Controller.PRESS_LEFT) or actorController:IsState(Controller.HOLD_LEFT) then
			actorData.direction = Directions.Left;
		elseif actorController:IsState(Controller.PRESS_RIGHT) or actorController:IsState(Controller.HOLD_RIGHT) then
			actorData.direction = Directions.Right;
		end
	end
	if actorData.movementMode ~= self.movementModes.unstickActor then
		if actorData.direction == Directions.None and actorData.movementMode ~= self.movementModes.leaveMovators then
			actorData.movementMode = self.movementModes.freeze;
		elseif actorData.direction ~= Directions.None then
			actor.PieMenu:AddPieSliceIfPresetNameIsUnique(self.leaveMovatorNetworkPieSlice:Clone(), self);
			actorData.movementMode = self.movementModes.move;
			self:convertWaypointDataToActorWaypoints(actorData);
		end
	end
end

movatorActorFunctions.updateDirectionsFromWaypoints = function(self, actorData)
	local teamNodeTable = MovatorData[self.Team].nodeData;

	local actor = actorData.actor;

	if actorData.waypointData == nil and (actor.AIMode == Actor.AIMODE_GOTO or actor.AIMode == Actor.AIMODE_BRAINHUNT or actor.AIMode == Actor.AIMODE_SQUAD) and (actor.MovePathSize > 0 or actor:GetWaypointListSize() > 0) then
		self:convertActorWaypointsToWaypointData(actorData);
	end

	local waypointData = actorData.waypointData;
	if waypointData ~= nil then
		if waypointData.previousNode == nil or waypointData.nextNode == nil or waypointData.endNode == nil then
			actorData.movementMode = self.movementModes.freeze;
			self:setupActorWaypointData(actorData);
		else
			if actorData.movementMode == self.movementModes.freeze then
				actorData.movementMode = self.movementModes.move;
			end
			if actorData.movementMode == self.movementModes.teleporting then
				self:handleTeleportingActorToAppropriateTeleporterForWaypoint(actorData);
			elseif waypointData.previousNode.UniqueID ~= waypointData.endNode.UniqueID and not actorData.waypointData.targetIsBetweenPreviousAndNextNode then
				if teamNodeTable[waypointData.nextNode].zoneInternalBox:IsWithinBox(actor.Pos) then
					self:handleActorInNextNodeZoneInternalBox(actorData);
				end
			else
				self:handleActorThatHasReachedItsEndNode(actorData);
			end
		end
	end
end

movatorActorFunctions.setupActorWaypointData = function(self, actorData)
	local teamNodeTable = MovatorData[self.Team].nodeData;
	local teamTeleporterTable = MovatorData[self.Team].teleporterNodes;

	local actor = actorData.actor;
	local waypointData = actorData.waypointData;

	--TODO probably rename this to previousNode
	waypointData.previousNode = self:findClosestNode(actor.Pos, nil, true, true, false);
	if not waypointData.previousNode then
		self:removeActorFromMovatorTable(actor);
		print("Couldn't find previous node, give up")
		return;
	end
	local targetPosition = waypointData.movableObjectTarget ~= nil and waypointData.movableObjectTarget.Pos or waypointData.sceneTargets[1];
	waypointData.targetPosition = Vector(targetPosition.X, targetPosition.Y);
	waypointData.targetIsInsideMovatorArea = self.combinedMovatorArea:IsInside(waypointData.targetPosition);
	waypointData.actorReachedTargetInsideMovatorArea = false;
	waypointData.targetIsBetweenPreviousAndNextNode = false;
	waypointData.teleporterVisualsTimer = Timer(1000);

	waypointData.endNode = self:findClosestNode(waypointData.targetPosition, waypointData.previousNode, false, waypointData.targetIsInsideMovatorArea, true);
	if not waypointData.endNode then
		print("no end node 1")
		waypointData.endNode = self:findClosestNode(waypointData.targetPosition, waypointData.previousNode, false, false, true);
		if not waypointData.endNode then
			print("no end node 2")
			waypointData.endNode = self:findClosestNode(waypointData.targetPosition, waypointData.previousNode, false, false, false);
		end

		if waypointData.targetIsInsideMovatorArea then
			local closestPotentiallyNonConnectedNode = self:findClosestNode(waypointData.targetPosition, nil, false, true, true);
			local nonConnectedNodeThatEncompassesTargetExists = closestPotentiallyNonConnectedNode ~= nil and self.pathTable[waypointData.previousNode][closestPotentiallyNonConnectedNode] == nil;
			if nonConnectedNodeThatEncompassesTargetExists then
				waypointData.targetIsInsideMovatorArea = false;
				print("There's a closer node that's not connected to the starting node. Treat the target as outside the area and go to our closest viable node")
			end
		end
	end

	if waypointData.previousNode.UniqueID == waypointData.endNode.UniqueID then
		self:accountForSameStartingAndEndingNodeWhenSettingUpActorWaypointData(actorData);
		return;
	end

	actorData.direction = self.pathTable[waypointData.previousNode][waypointData.endNode].direction;
	if actorData.direction == Directions.Any then
		waypointData.nextNode = waypointData.previousNode;
		if not self:makeActorMoveToStartingNodeIfAppropriateWhenSettingUpActorWaypointData(actorData) then
			actorData.movementMode = self.movementModes.teleporting;
		end
	else
		waypointData.nextNode = teamNodeTable[waypointData.previousNode].connectedNodeData[actorData.direction].node;
		self:makeActorMoveToStartingNodeIfAppropriateWhenSettingUpActorWaypointData(actorData);
	end

	if waypointData.nextNode.UniqueID == waypointData.endNode.UniqueID and waypointData.targetIsInsideMovatorArea then
		local areaToCheckForTargetPos = teamNodeTable[waypointData.previousNode].connectingAreas[actorData.direction];
		waypointData.targetIsBetweenPreviousAndNextNode = areaToCheckForTargetPos ~= nil and areaToCheckForTargetPos:IsInside(waypointData.targetPosition);
	end
end

movatorActorFunctions.accountForSameStartingAndEndingNodeWhenSettingUpActorWaypointData = function(self, actorData)
	local teamNodeTable = MovatorData[self.Team].nodeData;

	local actor = actorData.actor;
	local waypointData = actorData.waypointData;

	if waypointData.targetIsInsideMovatorArea then
		local zoneBox = teamNodeTable[waypointData.previousNode].zoneBox;
		local actorAndTargetAreInSameArea = zoneBox:IsWithinBox(actor.Pos) or zoneBox:IsWithinBox(waypointData.targetPosition);
		local directionOfConnectingAreaActorIsIn = Directions.None;
		local directionOfConnectingAreaTargetIsIn = Directions.None;
		if not actorAndTargetAreInSameArea then
			for direction, connectingArea in pairs(teamNodeTable[waypointData.previousNode].connectingAreas) do
				if connectingArea:IsInside(actor.Pos) then
					directionOfConnectingAreaActorIsIn = direction;
				end
				if connectingArea:IsInside(waypointData.targetPosition) then
					directionOfConnectingAreaTargetIsIn = direction;
				end
			end
			actorAndTargetAreInSameArea = directionOfConnectingAreaActorIsIn == directionOfConnectingAreaTargetIsIn;
		end

		if actorAndTargetAreInSameArea then
			local distanceFromActorToTargetPosition = SceneMan:ShortestDistance(waypointData.targetPosition, actor.Pos, self.checkWrapping);
			local relevantAxis = math.abs(distanceFromActorToTargetPosition.X) > math.abs(distanceFromActorToTargetPosition.Y) and "X" or "Y";
			if relevantAxis == "X" then
				actorData.direction = distanceFromActorToTargetPosition[relevantAxis] > 0 and Directions.Left or Directions.Right;
			else
				actorData.direction = distanceFromActorToTargetPosition[relevantAxis] > 0 and Directions.Up or Directions.Down;
			end
			print("Target is close to start and in same area as actor, direction set to "..tostring(actorData.direction))
			waypointData.nextNode = waypointData.previousNode;
			actorData.targetIsBetweenPreviousAndNextNode = true;
		else
			actorData.direction = self.oppositeDirections[directionOfConnectingAreaActorIsIn];
			waypointData.nextNode = waypointData.previousNode;
			print(directionOfConnectingAreaTargetIsIn)
			waypointData.endNode = teamNodeTable[waypointData.previousNode].connectedNodeData[directionOfConnectingAreaTargetIsIn].node;
			print("Target in different area than actor, moving to starting node in direction "..tostring(actorData.direction)..", next node set to node in direction "..tostring(directionOfConnectingAreaTargetIsIn).. " from that");
		end
	else
		print("Starting and end node are the same, and target is outside movators, move to starting node")
		self:makeActorMoveToStartingNodeIfAppropriateWhenSettingUpActorWaypointData(actorData);
	end
end

movatorActorFunctions.makeActorMoveToStartingNodeIfAppropriateWhenSettingUpActorWaypointData = function(self, actorData)
	local actor = actorData.actor;
	local waypointData = actorData.waypointData;

	local distanceFromActorToPreviousNode = SceneMan:ShortestDistance(waypointData.previousNode.Pos, actor.Pos, self.checkWrapping);
	local relevantAxis;
	local distanceThreshold;
	if actorData.direction == Directions.Any or actorData.direction == Directions.None then
		relevantAxis = (math.abs(distanceFromActorToPreviousNode.X) > math.abs(distanceFromActorToPreviousNode.Y)) and "X" or "Y";
		distanceThreshold = 0;
	else
		relevantAxis = (actorData.direction == Directions.Up or actorData.direction == Directions.Down) and "X" or "Y";
		distanceThreshold = 24;
	end
	print("Distance is "..tostring(distanceFromActorToPreviousNode) .." , relevant axis is " .. relevantAxis .. ", direction is currently " ..tostring(actorData.direction) .. " but need to move to start node first");
	if math.abs(distanceFromActorToPreviousNode[relevantAxis]) > distanceThreshold then
		if relevantAxis == "X" then
			actorData.direction = distanceFromActorToPreviousNode[relevantAxis] > 0 and Directions.Left or Directions.Right;
		else
			actorData.direction = distanceFromActorToPreviousNode[relevantAxis] > 0 and Directions.Up or Directions.Down;
		end
		waypointData.nextNode = waypointData.previousNode;
		print("Direction has changed to "..tostring(actorData.direction) .. " and next node has been set to starting node so things work")
		return true;
	end
	return false;
end

movatorActorFunctions.handleTeleportingActorToAppropriateTeleporterForWaypoint = function(self, actorData)
	local teamTeleporterTable = MovatorData[self.Team].teleporterNodes;

	local actor = actorData.actor;
	local waypointData = actorData.waypointData;

	local actorHasTeleported = waypointData.previousNode.UniqueID ~= waypointData.nextNode.UniqueID
	if waypointData.teleporterVisualsTimer:IsPastSimTimeLimit() then
		if not actorHasTeleported then
			if teamTeleporterTable[waypointData.endNode] then
				waypointData.nextNode = waypointData.endNode;
			else
				local closestTeleporterDistance;
				for teleporterNode, _ in pairs(teamTeleporterTable) do
					if self.pathTable[teleporterNode][waypointData.endNode] ~= nil and (closestTeleporterDistance == nil or self.pathTable[teleporterNode][waypointData.endNode].distance < closestTeleporterDistance) then
						closestTeleporterDistance = self.pathTable[teleporterNode][waypointData.endNode].distance;
						waypointData.nextNode = teleporterNode;
					end
				end
			end
			actor.Pos = waypointData.nextNode.Pos;
			waypointData.teleporterVisualsTimer:Reset();
		else
			actorData.movementMode = self.movementModes.freeze;
			self:changeScaleOfMOSRotatingAndAttachables(actor, 1);
		end
	else
		self:changeScaleOfMOSRotatingAndAttachables(actor, (actorHasTeleported and waypointData.teleporterVisualsTimer.SimTimeLimitProgress or 1 - waypointData.teleporterVisualsTimer.SimTimeLimitProgress));
		if not actorHasTeleported then
			self:centreActorToClosestNodeIfMovingInAppropriateDirection(actorData, true);
		end
		self:updateFrozenActor(actorData);
		actor:FlashWhite(100);
	end
end

movatorActorFunctions.handleActorInNextNodeZoneInternalBox = function(self, actorData)
	local teamNodeTable = MovatorData[self.Team].nodeData;
	local teamTeleporterTable = MovatorData[self.Team].teleporterNodes;

	local actor = actorData.actor;
	local waypointData = actorData.waypointData;

	waypointData.previousNode = waypointData.nextNode;
	if waypointData.previousNode.UniqueID == waypointData.endNode.UniqueID then
		return;
	end

	if teamTeleporterTable[waypointData.previousNode] then
		actor.Pos = waypointData.nextNode.Pos;
	end

	actorData.direction = self.pathTable[waypointData.previousNode][waypointData.endNode].direction;
	if actorData.direction == Directions.Any then
		actorData.movementMode = self.movementModes.teleporting;
		waypointData.teleporterVisualsTimer:Reset();
		return;
	else
		waypointData.nextNode = teamNodeTable[waypointData.previousNode].connectedNodeData[actorData.direction].node;
	end

	waypointData.nextNode = teamNodeTable[waypointData.previousNode].connectedNodeData[actorData.direction].node;
	if waypointData.movableObjectTarget then
		waypointData.targetPosition = Vector(waypointData.movableObjectTarget.Pos.X, waypointData.movableObjectTarget.Pos.Y);
	end
	print("Change Direction")

	if waypointData.nextNode.UniqueID == waypointData.endNode.UniqueID and waypointData.targetIsInsideMovatorArea then
		local areaToCheckForTargetPos = teamNodeTable[waypointData.previousNode].connectingAreas[actorData.direction];
		waypointData.targetIsBetweenPreviousAndNextNode = areaToCheckForTargetPos ~= nil and areaToCheckForTargetPos:IsInside(waypointData.targetPosition);
	end
end

movatorActorFunctions.handleActorThatHasReachedItsEndNode = function(self, actorData)
	local teamNodeTable = MovatorData[self.Team].nodeData;

	local actor = actorData.actor;
	local waypointData = actorData.waypointData;

	local function getDirectionForDistanceLargerAxis(distanceVector, minimumDistanceThreshold)
		local direction = Directions.None;

		local largerDistanceAxis = (math.abs(distanceVector.X) > math.abs(distanceVector.Y)) and "X" or "Y";
		if distanceVector[largerDistanceAxis] > minimumDistanceThreshold then
			direction = largerDistanceAxis == "Y" and Directions.Up or Directions.Left;
			--print("Not close to target yet, moving in direction "..tostring(direction))
		elseif distanceVector[largerDistanceAxis] < -minimumDistanceThreshold then
			direction = largerDistanceAxis == "Y" and Directions.Down or Directions.Right;
			--print("Not close to target yet, moving in direction "..tostring(direction))
		end
		return direction;
	end

	if waypointData.targetIsInsideMovatorArea then
		if not waypointData.actorReachedTargetInsideMovatorArea then
			local distanceFromActorToTargetPosition = SceneMan:ShortestDistance(waypointData.targetPosition, actor.Pos, self.checkWrapping);
			local thresholdForTreatingTargetAsReached = waypointData.movableObjectTarget == nil and self.sceneWaypointThresholdForTreatingTargetAsReached or self.movableObjectWaypointThresholdForTreatingTargetAsReached;
			actorData.direction = getDirectionForDistanceLargerAxis(distanceFromActorToTargetPosition, thresholdForTreatingTargetAsReached);
			if actorData.direction == Directions.None then
				print("Reached target inside movators!")
				waypointData.actorReachedTargetInsideMovatorArea = true;
				actorData.movementMode = self.movementModes.freeze;
			end
		elseif waypointData.actorReachedTargetInsideMovatorArea then
			actorData.movementMode = self.movementModes.freeze;
			if waypointData.movableObjectTarget ~= nil then
				if SceneMan:ShortestDistance(actor.Pos, waypointData.movableObjectTarget.Pos, self.checkWrapping):MagnitudeIsGreaterThan(self.movableObjectWaypointThresholdForTreatingTargetAsReached * 2) then
					print("Target has moved away, let's find it!")
					self:setupActorWaypointData(actorData);
				end
			else
				if #waypointData.sceneTargets > 1 then
					table.remove(waypointData.sceneTargets, 1);
					self:setupActorWaypointData(actorData);
				else
					actorData.waypointData = nil;
				end
			end
		end
	elseif teamNodeTable[waypointData.endNode].zoneBox:IsWithinBox(actor.Pos) then
		local scenePathSize = SceneMan.Scene:CalculatePath(waypointData.targetPosition, actor.Pos, false, GetPathFindingDefaultDigStrength());
		local secondLastScenePathEntryPosition;
		local scenePathEntryIndex = 0;
		for scenePathEntryPosition in SceneMan.Scene.ScenePath do
			if scenePathEntryIndex == scenePathSize - 2 then
				secondLastScenePathEntryPosition = scenePathEntryPosition;
				break;
			end
			scenePathEntryIndex = scenePathEntryIndex + 1;
		end
		actorData.direction = getDirectionForDistanceLargerAxis(SceneMan:ShortestDistance(secondLastScenePathEntryPosition, actor.Pos, self.checkWrapping), 0);
	end
end

movatorActorFunctions.slowDownFastActorToMovementSpeed = function(self, actorData)
	local actor = actorData.actor;

	if actor.Vel:MagnitudeIsGreaterThan(self.movementSpeed * 1.1) then
		actor.Vel = actor.Vel / 1.3;
		return false;
	end

	if actor.AngularVel > self.movementSpeed then
		actor.AngularVel = actor.AngularVel - (self.movementAcceleration);
		return false;
	elseif actor.AngularVel < -self.movementSpeed then
		actor.AngularVel = actor.AngularVel + (self.movementAcceleration);
		return false;
	end

	return true;
end

movatorActorFunctions.centreActorToClosestNodeIfMovingInAppropriateDirection = function(self, actorData, forceCentring)
	local teamNodeTable = MovatorData[self.Team].nodeData;

	local actor = actorData.actor;
	local actorDirection = actorData.direction;

	local closestNode = self:findClosestNode(actor.Pos, nil, true, true, false);
	if not closestNode then
		actor:FlashWhite(100);
		actor:MoveOutOfTerrain(0);
		self:setActorMovementModeToLeaveMovators(actorData);
		return;
	end

	local isStuck = actorData.movementMode == self.movementModes.unstickActor;
	forceCentring = forceCentring or isStuck;
	local directionToUseForCentering;
	if not forceCentring and not teamNodeTable[closestNode].zoneBox:IsWithinBox(actor.Pos) then
		for direction, connectingArea in pairs(teamNodeTable[closestNode].connectingAreas) do
			if connectingArea:IsInside(actor.Pos) then
				directionToUseForCentering = direction;
				break;
			end
		end
	end

	if forceCentring or actorDirection == directionToUseForCentering or actorDirection == self.oppositeDirections[directionToUseForCentering] then
		local actorSizeCenteringAdjustment = Vector(0, math.min(24, math.max(0, actor.Radius - 24)));
		if IsACRocket(actor) or IsACDropShip(actor) then
			actorSizeCenteringAdjustment.Y = 0;
		end
		local distanceToClosestNode = SceneMan:ShortestDistance(closestNode.Pos + actorSizeCenteringAdjustment, actor.Pos, self.checkWrapping);
		local centeringAxes;
		if forceCentring then
			centeringAxes = { "X", "Y" };
		else
			centeringAxes = { (directionToUseForCentering == Directions.Up or directionToUseForCentering == Directions.Down) and "X" or "Y"; }
		end
		local gravityAdjustment = SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs * -1;
		local centeringSpeedAndDistance = self.movementAcceleration * 5;

		for _, centeringAxis in pairs(centeringAxes) do
			if distanceToClosestNode[centeringAxis] > centeringSpeedAndDistance then
				actor.Vel[centeringAxis] = -centeringSpeedAndDistance + gravityAdjustment[centeringAxis];
				if isStuck then
				print("Centering " ..(centeringAxis == "X" and "Leftward" or "Upward"));
				end
			elseif distanceToClosestNode[centeringAxis] < -centeringSpeedAndDistance then
				actor.Vel[centeringAxis] = centeringSpeedAndDistance + gravityAdjustment[centeringAxis];
				if isStuck then
				print("Centering " ..(centeringAxis == "X" and "Rightward" or "Downward"));
				end
			else
				if isStuck then
					actorData.movementMode = self.movementModes.move;
					actorData.unstickTimer:Reset();
				print("We're centered!")
				end
				actor.Vel[centeringAxis] = gravityAdjustment[centeringAxis];
				actor.Pos[centeringAxis] = closestNode.Pos[centeringAxis] + actorSizeCenteringAdjustment[centeringAxis];
			end
		end
	end
end

movatorActorFunctions.updateFrozenActor = function(self, actorData)
	local actor = actorData.actor;

	local gravityAdjustment = SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs * -1;
	for _, axis in pairs({"X", "Y"}) do
		if math.abs(actor.Vel[axis]) > self.movementAcceleration * 2 then
			actor.Vel[axis] = actor.Vel[axis] + ((actor.Vel[axis] > self.movementAcceleration and -self.movementAcceleration or self.movementAcceleration) * 2) + gravityAdjustment[axis];
		end
		if math.abs(actor.Vel[axis]) <= self.movementAcceleration * 2 then
			actor.Vel[axis] = gravityAdjustment[axis];
			if IsAHuman(actor) then
				ToAHuman(actor).ProneState = AHuman.NOTPRONE;
				actor:GetController():SetState(Controller.BODY_CROUCH, false);
			end
		end
	end
end

movatorActorFunctions.updateMovingActor = function(self, actorData)
	local actor = actorData.actor;
	local actorDirection = actorData.direction;

	local directionMovementTable = {
		[Directions.Up] = { acceleration = Vector(0, -self.movementAcceleration), aHumanRotAngle = 0, aHumanProneState = AHuman.NOTPRONE, aHumanCrouchState = false },
		[Directions.Down] = { acceleration = Vector(0, self.movementAcceleration), aHumanRotAngle = math.pi, aHumanProneState = AHuman.GOPRONE, aHumanCrouchState = true },
		[Directions.Left] = { acceleration = Vector(-self.movementAcceleration, 0), aHumanRotAngle = math.pi * 0.5, aHumanProneState = AHuman.GOPRONE, aHumanCrouchState = true },
		[Directions.Right] = { acceleration = Vector(self.movementAcceleration, 0), aHumanRotAngle = math.pi * -0.5, aHumanProneState = AHuman.GOPRONE, aHumanCrouchState = true },
	};

	local gravityAdjustment = SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs * -1;
	for direction, movementTable in pairs(directionMovementTable) do
		if actorDirection == direction then
			actor.Vel = (actor.Vel + movementTable.acceleration):CapMagnitude(self.movementSpeed);
			actor.Vel = actor.Vel + gravityAdjustment;
			if IsAHuman(actor) then
				if not self.humansRemainUpright then
					local verticalRotationAdjustment = (direction == Directions.Down) and -actor.FlipFactor or 1;
					if actor.RotAngle > movementTable.aHumanRotAngle + self.movementAcceleration then
						actor.RotAngle = actor.RotAngle - (self.movementAcceleration * 0.25 * verticalRotationAdjustment);
					elseif actor.RotAngle < movementTable.aHumanRotAngle - self.movementAcceleration then
						actor.RotAngle = actor.RotAngle + (self.movementAcceleration * 0.25 * verticalRotationAdjustment);
					else
						actor.RotAngle = movementTable.aHumanRotAngle;
					end
					ToAHuman(actor).ProneState = movementTable.aHumanProneState;
				end
				actor:GetController():SetState(Controller.BODY_CROUCH, movementTable.aHumanCrouchState);
			end
		end
	end
end

uiFunctions.updateInfoUI = function(self)
	local desiredPieMenuFullInnerRadius = 128;

	local formattedEffectsNameTable = {
		displayTypes = { [""] = "None", line = "Line", chevron = "Pulse", chevron_narrow = "Tight Pulse" },
		sizes = { "Small", "Medium", "Large" },
	};
	local textDataTable = {
		"Controlled Movators: " .. tostring(MovatorData[self.Team].nodeDataCount - MovatorData[self.Team].teleporterNodesCount),
		"Controlled Teleporters: " .. tostring(MovatorData[self.Team].teleporterNodesCount),
		"Number of Affected Actors: " .. tostring(self.affectedActorsCount),
		"All Teams Accepted: " .. (self.acceptsAllTeams and "True" or "False"),
		"Crafts Accepted: " .. (self.acceptsCrafts and "True" or "False"),
		"Humans Remain Upright: " .. (self.humansRemainUpright and "True" or "False");
		"Movement Speed: " .. tostring(self.movementSpeed),
		"Mass Limit: " .. tostring(self.massLimit),
		--"Selected Effects Type: " .. formattedEffectsNameTable.displayTypes[self.EffectsTable.selectedType],
	};
	--if self.EffectsTable.selectedType ~= "" then
	--	textDataTable[#textDataTable + 1] = "Selected Effects Size: " .. formattedEffectsNameTable.sizes[self.EffectsTable.selectedSize];
	--end

	if self:GetNumberValue("ModifyMovementSpeed") > 0 then
		table.insert(textDataTable, 1, "---------------------------");
		table.insert(textDataTable, 1, "Change the Movement Speed");
		table.insert(textDataTable, 1, "Move or Scroll Up or Down to");
		table.insert(textDataTable, 1, "---------------------------");
		desiredPieMenuFullInnerRadius = 160;
	elseif self:GetNumberValue("ModifyMassLimit") > 0 then
		table.insert(textDataTable, 1, "--------------------------");
		table.insert(textDataTable, 1, "Change the Mass Limit");
		table.insert(textDataTable, 1, "Move or Scroll Up or Down to");
		table.insert(textDataTable, 1, "--------------------------");
		desiredPieMenuFullInnerRadius = 160;
	end
	local centerPoint = Vector(self.Pos.X, self.Pos.Y);
	local config = { useSmallText = self.infoUIUseSmallText, bgColour = self.infoUIBGColour, outlineWidth = self.infoUIOutlineWidth, outlineColour = self.infoUIOutlineColour };

	self:drawTextBox(textDataTable, centerPoint, config);

	return desiredPieMenuFullInnerRadius;
end

uiFunctions.drawTextBox = function(self, textDataTable, maxSizeBoxOrCenterPoint, config)
	config = self:setupTextBoxConfigIfNeeded(config, maxSizeBoxOrCenterPoint);
	local centerPoint, maxSize = self:setupCenterPointAndMaxSizeAndFixTextDataTableIfNecessary(textDataTable, maxSizeBoxOrCenterPoint, config);
	local topLeft = Vector(centerPoint.X - maxSize.X * 0.5, centerPoint.Y - maxSize.Y * 0.5);
	PrimitiveMan:DrawBoxFillPrimitive(Vector(topLeft.X - config.padding, topLeft.Y - config.padding), Vector(topLeft.X + maxSize.X + config.padding, topLeft.Y + maxSize.Y + config.padding), config.outlineColour);
	PrimitiveMan:DrawBoxFillPrimitive(Vector(topLeft.X - config.padding + config.outlineWidth, topLeft.Y - config.padding + config.outlineWidth), Vector(topLeft.X + maxSize.X + config.padding - config.outlineWidth, topLeft.Y + maxSize.Y + config.padding - config.outlineWidth), config.bgColour);

	for textIndex, textDataEntry in ipairs(textDataTable) do
		local linePos = Vector(topLeft.X, topLeft.Y + (textIndex - 1) * self.uiLineHeight[config.useSmallText]);
		local alignment = type(textDataEntry.alignment) ~= "nil" and textDataEntry.alignment or 1;
		if alignment == 1 then
			linePos.X = linePos.X + maxSize.X * 0.5;
		elseif alignment == 2 then
			linePos.X = linePos.X + maxSize.X;
		end
		PrimitiveMan:DrawTextPrimitive(linePos, textDataEntry.text, config.useSmallText, alignment);
	end
end

uiFunctions.setupTextBoxConfigIfNeeded = function(self, config, maxSizeBoxOrCenterPoint)
	if type(config) == "nil" then
		config = {};
	end
	if type(config.useSmallText) == "nil" then
		config.useSmallText = false;
	end
	if type(config.scaleBoxToFitText) == "nil" or maxSizeBoxOrCenterPoint.ClassName == "Vector" then
		config.scaleBoxToFitText = (maxSizeBoxOrCenterPoint.ClassName == "Vector");
	end
	if type(config.snapSize) == "nil" then
		config.snapSize = config.useSmallText and 2 or 4;
	end
	if type(config.padding) == "nil" then
		config.padding = config.useSmallText and 3 or 6;
	end
	if type(config.bgColour) == "nil" then
		config.bgColour = 127;
	end
	if type(config.outlineWidth) == "nil" then
		config.outlineWidth = 2;
	end
	if type(config.outlineColour) == "nil" then
		config.outlineColour = 71;
	end
	return config;
end

uiFunctions.setupCenterPointAndMaxSizeAndFixTextDataTableIfNecessary = function(self, textDataTable, maxSizeBoxOrCenterPoint, config)
	local centerPoint = maxSizeBoxOrCenterPoint;
	local maxSize = Vector(math.huge, math.huge);
	if maxSizeBoxOrCenterPoint.ClassName == "Box" then
		centerPoint = maxSizeBoxOrCenterPoint.Center;
		maxSize = Vector(maxSizeBoxOrCenterPoint.Width - config.padding * 2, maxSizeBoxOrCenterPoint.Height - config.padding * 2);
	end
	maxSize = self:getScaledMaxSizeAndFixTextDataTableIfNecessary(textDataTable, maxSize, config);
	return centerPoint, maxSize;
end

uiFunctions.getScaledMaxSizeAndFixTextDataTableIfNecessary = function(self, textDataTable, maxSize, config)
	local numberOfLines = 0;
	local maxSizeIfScalingBoxToFitText = Vector(0, 0);
	for i = 1, #textDataTable do
		if type(textDataTable[i]) == "string" then
			textDataTable[i] = { text = textDataTable[i] };
		end
		numberOfLines = numberOfLines + self:getNumberOfLinesForText(textDataTable[i].text, maxSize.X, config.useSmallText);
		if config.scaleBoxToFitText then
			local textWidth = FrameMan:CalculateTextWidth(textDataTable[i].text, config.useSmallText);
			maxSizeIfScalingBoxToFitText.X = math.max(maxSizeIfScalingBoxToFitText.X, textWidth);
		end
	end
	local totalHeight = numberOfLines * self.uiLineHeight[config.useSmallText];
	for i = #textDataTable, 1, -1 do
		if totalHeight > maxSize.Y then
			totalHeight = totalHeight - self.uiLineHeight[config.useSmallText] * self:getNumberOfLinesForText(textDataTable[i].text, maxSize.X, config.useSmallText);
			table.remove(textDataTable, i);
		else
			break;
		end
	end
	maxSizeIfScalingBoxToFitText.Y = totalHeight;

	if config.scaleBoxToFitText then
		maxSizeIfScalingBoxToFitText.X = maxSizeIfScalingBoxToFitText.X + config.snapSize - maxSizeIfScalingBoxToFitText.X % config.snapSize;
		maxSizeIfScalingBoxToFitText.Y = maxSizeIfScalingBoxToFitText.Y + config.snapSize - maxSizeIfScalingBoxToFitText.Y % config.snapSize;
		maxSize = Vector(math.min(maxSize.X, maxSizeIfScalingBoxToFitText.X), math.min(maxSize.Y, maxSizeIfScalingBoxToFitText.Y));
	end
	return maxSize;
end

uiFunctions.getNumberOfLinesForText = function(self, textString, maxWidth, useSmallText)
	local numberOfLines = 1;
	local stringWidth = FrameMan:CalculateTextWidth(textString, useSmallText);
	if stringWidth > maxWidth then
		numberOfLines = numberOfLines + math.modf(stringWidth / maxWidth);
	end
	return numberOfLines;
end
