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
	self.taskUpdateDelay = 500;
	
	self.teamToCheckNext = 0;
	
	self.teamList = {};
	
	for i = 0, self.Activity.TeamCount do
		self.teamList[i] = {};
		self.teamList[i].squadList = {};
		self.teamList[i].taskList = {};
	end
	--print("activity team count: " .. self.Activity.TeamCount)
	
	-- We cannot account for actors added outside of our system
	
	-- for actor in MovableMan.AddedActors do
		-- if actor.Team ~= -1 then
			-- table.insert(self.teamList[actor.Team].actorList, actor);
		-- end
	-- end
	
end

function TacticsHandler:OnMessage(message, object)

	--print("tacticshandlergotmessage")

	if message == "TacticsHandler_InvalidateActor" then
		self:InvalidateActor(object);
	end
	
end

function TacticsHandler:InvalidateActor(infoTable)

	self.teamList[infoTable.Team].squadList[infoTable.squadIndex].Actors[infoTable.actorIndex] = nil;
	--print("actor invalidated through function")
	
end

function TacticsHandler:PickTask(team)

	if #self.teamList[team].taskList > 0 then
		-- random weighted select
		local totalPriority = 0;
		for t = 1, #self.teamList[team].taskList do
			totalPriority = totalPriority + self.teamList[team].taskList[t].Priority;
		end
		
		local randomSelect = math.random(1, totalPriority);
		local finalSelection = 1;
		for t = 1, #self.teamList[team].taskList do
			randomSelect = randomSelect - self.teamList[team].taskList[t].Priority;
			if randomSelect <= 0 then
				--print("gotfinalselection")
				finalSelection = t;
			end
		end
		
		return self.teamList[team].taskList[finalSelection];
	else
		return false;
	end
	
end

function TacticsHandler:RetaskSquad(squad, team)

	print("retasking squad with task name: " .. squad.taskName)

	local newTask = self:PickTask(team);
	
	if newTask then	
		print("new task is:" .. newTask.Name)
		squad.taskName = newTask.Name;
		for actorIndex = 1, #squad.Actors do
			local actor = squad.Actors[actorIndex];
			-- Todo, due to oddities with how this terrible game is programmed, actor can theoretically point to an actor that shouldn't belong to us anymore
			-- This is due to memory pooling and MOs being reused. In fact, this game somehow managed to survive with a in-built memory corruption any time everything was deleted, for *years*
			-- And it only worked because of memory pooling hiding it. Terrible.
			-- Anyways, we should probably store uniqueIds instead and look those up at point of usage
			if actor then
				if newTask then
					if newTask.Type == "Defend" or newTask.Type == "Attack" then
						actor.AIMode = Actor.AIMODE_GOTO;
						if newTask.Position.PresetName then -- ghetto check if this is an MO
							actor:AddAIMOWaypoint(newTask.Position);
						else
							actor:AddAISceneWaypoint(newTask.Position);
						end
					else
						actor.AIMode = Actor.AIMODE_BRAINHUNT;
					end
				end
			else
				print("during retasking, actor was invalidated")
				actor = nil; -- do some cleanup while we're at it
			end
		end
	else
		--print("couldnotfindttask")
		return false;
	end
	
	return true;

end

function TacticsHandler:RemoveTask(name, team)

	--print("removedttask: " .. name);

	if name and team then
		local task;
		local taskIndex;
		for i = 1, #self.teamList[team].taskList do
			if self.teamList[team].taskList[i].Name == name then
				task = self.teamList[team].taskList[i];
				taskIndex = i;
				break;
			end
		end
		if task then
			table.remove(self.teamList[team].taskList, taskIndex);
			--print("actuallydeletedttask")
			-- retask squads before deleting
			for i = 1, #self.teamList[team].squadList do
				--print(self.teamList[team].squadList[i].taskName)
				--print("task name to del: " .. task.Name);
				if self.teamList[team].squadList[i].taskName == task.Name then
					--print("tried to retask")
					self:RetaskSquad(self.teamList[team].squadList[i], team);
				end
			end
		else
			--print("Tactics Handler was asked to remove a task it didn't have!");
			return false;
		end
	else
		--print("Tactics Handler was asked to remove a task, but not given a name and a team!");
		return false;
	end
	
	return true;
	
end

function TacticsHandler:AddTask(name, team, taskPos, taskType, priority)

	if name and team and taskPos then
	
		for i = 1, #self.teamList[team].taskList do
			if self.teamList[team].taskList[i].Name == name then
				--print("Tactics Handler tried to add a task to a specific team with a name that already existed!");
				return false;
			end
		end
	
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
		
		--print("Added new task with name: " .. task.Name)
		
	else
		--print("Tactics Handler tried to add a task with no name, no team, or no task position!");
		return false;
	end
	
	return true;
	
end

function TacticsHandler:AddTaskedSquad(team, squadTable, taskName)
	
	if team and squadTable and taskName then
		local squadEntry = {};
		squadEntry.Actors = squadTable;
		squadEntry.taskName = taskName;
		table.insert(self.teamList[team].squadList, squadEntry); 
		for k, act in ipairs(squadEntry.Actors) do
			local squadInfo = {};
			squadInfo.Team = team;
			squadInfo.squadIndex = #self.teamList[team].squadList;
			squadInfo.actorIndex = k;
			act:AddScript("Base.rte/Activities/Utility/TacticsActorInvalidator.lua");
			act:SendMessage("TacticsHandler_InitSquadInfo", squadInfo);
		end
		--print("addedtaskedsquad: " .. #self.teamList[team].squadList)
		--print("newtaskname: " .. self.teamList[team].squadList[#self.teamList[team].squadList].taskName)
	else
		--print("Tried to add a tasked squad without all required arguments!");
		return false;
	end
	
	return true;
	
end

function TacticsHandler:UpdateTacticsHandler(goldAmountsTable)

	if self.taskUpdateTimer:IsPastSimMS(self.taskUpdateDelay) then
		self.taskUpdateTimer:Reset();
		----print("tactics updated")
		----print(self.teamToCheckNext)

		-- check if we can afford a new tasked squad, tell the activity to send it in
		local team = self.teamToCheckNext;
		self.teamToCheckNext = (self.teamToCheckNext + 1) % self.Activity.TeamCount;
		if goldAmountsTable[team] > 0 then
			----print("team " .. team .. " " .. goldAmountsTable[team]);
			-- TODO replace debug teamcount faker (the modulo)
			local task = self:PickTask(team);
			if task then
				return team, task;
			end
		end
		
		-- check and update all tasked squads
		
		for i = 1, #self.teamList[team].squadList do
			local taskNotActual = true;
			for t = 1, #self.teamList[team].taskList do
				if self.teamList[team].squadList[i].taskName and self.teamList[team].taskList[t].Name == self.teamList[team].squadList[i].taskName then
					--print("matchedttaskname: " .. self.teamList[team].taskList[t].Name)
					taskNotActual = false;
					break;
				end
			end
			if taskNotActual then
				--print("retasking not actual task")
			
				self:RetaskSquad(self.teamList[team].squadList[i], team);
				
			else
				for actorIndex = 1, #self.teamList[team].squadList[i].Actors do
					local actor = self.teamList[team].squadList[i].Actors[actorIndex];
					if #self.teamList[team].squadList[i].Actors > 0 and actor then

						-- all is well

					else
						print("actor invalid")
						self.teamList[team].squadList[i].Actors[actorIndex] = nil; -- actor no longer actual
						if #self.teamList[team].squadList[i].Actors == 0 then
							print("removed wiped squad")
							table.remove(self.teamList[team].squadList, i) -- squad wiped, remove it
							break;
						end
					end
				end
			end
		end
		
	end
	
	return false;
		

end

return TacticsHandler:Create();