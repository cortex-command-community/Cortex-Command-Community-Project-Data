--------------------------------------- Instructions ---------------------------------------

--

--------------------------------------- Misc. Information ---------------------------------------

--




local TacticsHandler = {};

function TacticsHandler:Create()
	local Members = {};

	setmetatable(Members, self);
	self.__index = self;

	return Members;
end

function TacticsHandler:Initialize(activity)
	
	print("TacticsHandlerinited")
	
	self.Activity = activity;
	
	self.taskUpdateTimer = Timer();
	self.taskUpdateDelay = 1000;
	
	self.teamList = {};
	
	for i = 0, self.Activity.TeamCount do
		self.teamList[i] = {};
		self.teamList[i].squadList = {};
		self.teamList[i].taskList = {};
	end
	
	-- We cannot account for actors added outside of our system
	
	-- for actor in MovableMan.AddedActors do
		-- if actor.Team ~= -1 then
			-- table.insert(self.teamList[actor.Team].actorList, actor);
		-- end
	-- end
	
end

function TacticsHandler:AddTask(name, team, taskPos, taskType, priority)

	if name and team and taskPos then
		if not taskType then
			taskType = "Attack";
		end
		if not priority then
			priority = 5;
		end
		
		local task = {};
		task.Name = name;
		task.Type = taskType;
		task.Position = taskPos;
		task.Priority = priority;
		
		table.insert(self.teamList[team].taskList, task);
		
	else
		print("Tactics Handler tried to add a task with no name, no team, or no task position!");
		return false;
	end
	
	return true;
	
end

function TacticsHandler:AddTaskedSquad(team, squadTable, taskName)
	
	if team and squadTable and taskName then
		local squadEntry = {squadTable, taskName};
		table.insert(self.teamList[team].squadList, squadEntry); 
	else
		print("Tried to add a tasked squad without all required arguments!");
		return false;
	end
	
	return true;
	
end

function TacticsHandler:UpdateTacticsHandler(goldAmountsTable)

	if self.taskUpdateTimer:IsPastSimMS(self.taskUpdateDelay) then
		self.taskUpdateTimer:Reset();

		for i = 0, #goldAmountsTable do
			if goldAmountsTable[i] > 0 then
				-- random weighted select
				local totalPriority = 0;
				for t = 1, #self.teamList[i].taskList do
					totalPriority = totalPriority + self.teamList[i].taskList[t].Priority;
				end
				
				local randomSelect = math.random(1, totalPriority);
				local finalSelection = 1;
				for t = 1, #self.teamList[i].taskList do
					randomSelect = randomSelect - self.teamList[i].taskList[t].Priority;
					if randomSelect < 0 then
						finalSelection = t;
					end
				end
				
				return i, self.teamList[i].taskList[finalSelection];
			end
		end
	end
	
	return nil;
		

end

return TacticsHandler:Create();