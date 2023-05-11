function CommandDisplayInfoUI(self)
	if self:NumberValueExists("DisplayInfoUI") then
		self:RemoveNumberValue("DisplayInfoUI");
	else
		self:SetNumberValue("DisplayInfoUI", 1);
	end
end

function CommandSwapMovatorAcceptsAllTeams(self)
	self:SetNumberValue("SwapAcceptsAllTeams", 1);
end

function CommandSwapMovatorAcceptsCrafts(self)
	self:SetNumberValue("SwapAcceptsCrafts", 1);
end

function CommandSwapMovatorHumansRemainUpright(self)
	self:SetNumberValue("SwapHumansRemainUpright", 1);
end

function CommandModifyMovatorSpeed(self)
	self:RemoveNumberValue("ModifyMassLimit");
	if self:NumberValueExists("ModifyMovementSpeed") then
		self:RemoveNumberValue("ModifyMovementSpeed");
	else
		self:SetNumberValue("ModifyMovementSpeed", 1);
	end
end

function CommandModifyMovatorMassLimit(self)
	self:RemoveNumberValue("ModifyMovementSpeed");
	if self:NumberValueExists("ModifyMassLimit") then
		self:RemoveNumberValue("ModifyMassLimit");
	else
		self:SetNumberValue("ModifyMassLimit", 1);
	end
end

function CommandModifyMovatorVisualEffectsType(self)
	self:SetNumberValue("ModifyVisualEffectsType", 1);
end

function CommandModifyMovatorVisualEffectsSize(self)
	self:SetNumberValue("ModifyVisualEffectsSize", 1);
end

function CommandActorLeaveMovatorNetwork(self)
	self:SetNumberValue("Movator_LeaveMovatorNetwork", 1);
end

function CommandActorChooseTeleporter(self)
	self:SetNumberValue("Movator_ChooseTeleporter", 1);
end