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
		self.teamList[i].actorList = {};
		self.teamList[i].taskList = {};
	end
	
	for actor in MovableMan.AddedActors do
		if actor.Team ~= -1 then
			table.insert(self.teamList[actor.Team].actorList, actor);
		end
	end
	
end

function TacticsHandler:AddTask(name, team, taskType, priority)

	if name and team then
		if not taskType then
			taskType = "Attack";
		end
		if not priority then
			priority = 5;
		end
		
		local task = {};
		task.Name = name;
		task.Type = taskType;
		task.Priority = priority;
		
		table.insert(self.teamList[team].taskList, task);
		
	else
		print("Tried to add a task with no name or no team!");
		return false;
	end
	
	return true;
	
end

function TacticsHandler:UpdateTasks()

end

return TacticsHandler:Create();