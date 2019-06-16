function Create(self)
	self.reloadTimer = Timer();
	self.loadedShell = false;
	self.reloadCycle = false;

	self.reloadDelay = 200;

	if self.Magazine then
		self.ammoCounter = self.Magazine.RoundCount;
	else
		self.ammoCounter = 0;
	end
end

function Update(self)

	if self.Magazine ~= nil then
		if self.loadedShell == false then
			self.ammoCounter = self.Magazine.RoundCount;
		else
			self.loadedShell = false;
			self.Magazine.RoundCount = self.ammoCounter + 1;
		end
	else
		self.reloadTimer:Reset();
		self.reloadCycle = true;
		self.loadedShell = true;
	end

	if self:IsActivated() then
		self.reloadCycle = false;
	end

	if self.reloadCycle == true and self.reloadTimer:IsPastSimMS(self.reloadDelay) and self:IsFull() == false then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if MovableMan:IsActor(actor) then
			ToActor(actor):GetController():SetState(Controller.WEAPON_RELOAD,true);
		end
		self.reloadCycle = false;
	end

end