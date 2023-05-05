if not MovatorData then
	MovatorData = {};
	for team = Activity.NOTEAM, Activity.TEAM_4 do
		MovatorData[team] = {
			energyLevel = 0,
			nodeData = {},
			nodeDataCount = 0,
			teleporterNodes = {},
			teleporterNodesCount = 0,
		};
	end
end

function Movators_AddNode(node)
	local teamMovatorData = MovatorData[node.Team];

	if teamMovatorData.nodeData[node] == nil then
		for nodeKey, nodeInfo in pairs(teamMovatorData.nodeData) do
			if type(nodeKey) ~= "string" then
				if nodeInfo.zoneBox ~= nil then
					local width = node:NumberValueExists("ZoneWidth") and node:GetNumberValue("ZoneWidth") or MovatorDefaultNodeSize;
					local height = node:NumberValueExists("ZoneHeight") and node:GetNumberValue("ZoneHeight") or MovatorDefaultNodeSize;
					local nodeBox = Box(Vector(node.Pos.X - width * 0.5 + 0.5, node.Pos.Y - height * 0.5), Vector(node.Pos.X + width * 0.5, node.Pos.Y + height * 0.5));
					if nodeInfo.zoneBox:IntersectsBox(nodeBox) then
						node.ToDelete = true;
						return false;
					end
				end
			end
		end

		teamMovatorData.nodeData[node] = {
			connectedNodeCount = 0,
			size = Vector(),
			zoneBox,
			zoneInternalBox,
			connectedNodeData = {},
			connectingAreas = {},
		}

		if node.PresetName == "Teleporter Node" then
			teamMovatorData.teleporterNodes[node] = true;
			teamMovatorData.teleporterNodesCount = teamMovatorData.teleporterNodesCount + 1;
		end
		teamMovatorData.nodeDataCount = teamMovatorData.nodeDataCount + 1;

		local width = node:NumberValueExists("ZoneWidth") and node:GetNumberValue("ZoneWidth") or MovatorDefaultNodeSize;
		local height = node:NumberValueExists("ZoneHeight") and node:GetNumberValue("ZoneHeight") or MovatorDefaultNodeSize;

		teamMovatorData.nodeData[node].size = Vector(width, height);
		teamMovatorData.nodeData[node].zoneBox = Box(Vector(node.Pos.X - width * 0.5, node.Pos.Y - height * 0.5), Vector(node.Pos.X + width * 0.5, node.Pos.Y + height * 0.5));
		teamMovatorData.nodeData[node].zoneInternalBox = Box(Vector(node.Pos.X - width * 0.25, node.Pos.Y - height * 0.25), Vector(node.Pos.X + width * 0.25, node.Pos.Y + height * 0.25));

		local nodesAffectedByThisMovator = Movators_CheckConnections(node);
		if nodesAffectedByThisMovator ~= nil then
			for _, affectedNode in pairs(nodesAffectedByThisMovator) do
				Movators_CheckConnections(affectedNode);
			end
		end

		return true;
	end
	return false;
end

function Movators_RemoveNode(node)
	local teamMovatorData = MovatorData[node.Team];

	local removedNodeTable = teamMovatorData.nodeData[node];
	if type(removedNodeTable) ~= "nil" then
		teamMovatorData.nodeData[node] = nil;
		for direction, nodeData in pairs(removedNodeTable.connectedNodeData) do
			teamMovatorData.nodeData[nodeData.node] = nil;
			nodeData.node:SetNumberValue("shouldReaddNode", 1);
		end
		teamMovatorData.nodeDataCount = teamMovatorData.nodeDataCount - 1;
	end

	if node.PresetName == "Teleporter Node" then
		teamMovatorData.teleporterNodes[node] = nil;
		teamMovatorData.teleporterNodesCount = teamMovatorData.teleporterNodesCount - 1;
	end
end

local function targetNodeIsNotObstructed(startNode, targetNode, direction, nodeZoneSize)
	local checkWrapping = SceneMan.SceneWrapsX or SceneMan.SceneWrapsY;

	local spreadRaysHorizontally = direction == Directions.Up or direction == Directions.Down;
	local rayOffsets = {
		spreadRaysHorizontally and Vector(-nodeZoneSize.X * 0.25, 0) or Vector(0, -nodeZoneSize.Y * 0.25),
		Vector(),
		spreadRaysHorizontally and Vector(nodeZoneSize.X * 0.25, 0) or Vector(0, nodeZoneSize.Y * 0.25),
	};

	local rayVector = SceneMan:ShortestDistance(startNode.Pos, targetNode.Pos, checkWrapping);
	for _, rayOffset in ipairs(rayOffsets) do
		if SceneMan:CastStrengthRay(startNode.Pos + rayOffset, rayVector, 15, Vector(), 4, 0, true) then
			return false;
		end
	end
	return true;
end

function Movators_CheckConnections(node)
	local teamMovatorData = MovatorData[node.Team];

	local nodeData = teamMovatorData.nodeData[node];
	local nodesInDirections = { [Directions.Up] = {}, [Directions.Down] = {}, [Directions.Left] = {}, [Directions.Right] = {} };
	local affectedNodes = {};

	local thisNodeIsHorizontalOnly = node.PresetName:find("Horizontal Only");
	local thisNodeIsVerticalOnly = node.PresetName:find("Vertical Only");

	local checkWrapping = SceneMan.SceneWrapsX or SceneMan.SceneWrapsY;

	for otherNode, otherNodeData in pairs(teamMovatorData.nodeData) do
		if type(otherNode) ~= "string" and MovableMan:IsParticle(otherNode) and (not teamMovatorData.teleporterNodes[node] or not teamMovatorData.teleporterNodes[otherNode]) then
			local otherNodeIsHorizontalOnly = otherNode.PresetName:find("Horizontal Only");
			local otherNodeIsVerticalOnly = otherNode.PresetName:find("Vertical Only");
			local distanceToOtherNode = SceneMan:ShortestDistance(node.Pos, otherNode.Pos, checkWrapping);
			local width = nodeData.size.X * 0.5 + nodeData.size.X * 0.5;
			local height = nodeData.size.Y * 0.5 + nodeData.size.Y * 0.5;
			if not thisNodeIsHorizontalOnly and not otherNodeIsHorizontalOnly and distanceToOtherNode.Y <= -height and distanceToOtherNode.X == 0 then
				table.insert(nodesInDirections[Directions.Up], otherNode);
			elseif not thisNodeIsHorizontalOnly and not otherNodeIsHorizontalOnly and distanceToOtherNode.Y >= height and distanceToOtherNode.X == 0 then
				table.insert(nodesInDirections[Directions.Down], otherNode);
			elseif not thisNodeIsVerticalOnly and not otherNodeIsVerticalOnly and distanceToOtherNode.X <= -width and distanceToOtherNode.Y == 0 then
				table.insert(nodesInDirections[Directions.Left], otherNode);
			elseif not thisNodeIsVerticalOnly and not otherNodeIsVerticalOnly and distanceToOtherNode.X >= width and distanceToOtherNode.Y == 0 then
				table.insert(nodesInDirections[Directions.Right], otherNode);
			end
		end
	end

	for direction, nodesInDirection in pairs(nodesInDirections) do
		local closestNode;
		local distanceToClosestNode;
		for _, nodeInDirection in pairs(nodesInDirection) do
			local distanceToNode = SceneMan:ShortestDistance(node.Pos, nodeInDirection.Pos, checkWrapping);
			if (distanceToClosestNode == nil or distanceToNode.SqrMagnitude < distanceToClosestNode.SqrMagnitude) and targetNodeIsNotObstructed(node, nodeInDirection, direction, nodeData.size) then
				closestNode = nodeInDirection;
				distanceToClosestNode = distanceToNode;
			end
		end

		if closestNode ~= nil then
			if not nodeData.connectedNodeData[direction] then
				nodeData.connectedNodeCount = nodeData.connectedNodeCount + 1;
			end
			nodeData.connectedNodeData[direction] = { node = closestNode, distance = distanceToClosestNode };
			if nodeData.connectingAreas[direction] == nil then
				nodeData.connectingAreas[direction] = Area();
			end

			affectedNodes[direction] = closestNode;
		end
	end
	return affectedNodes;
end