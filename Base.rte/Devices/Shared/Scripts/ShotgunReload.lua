function Create(self)
	self.reloadTimer = Timer();
	self.loadedShell = false;
	self.reloadCycle = false;

	self.reloadDelay = 75;

	self.ammoCounter = self.RoundInMagCount;
end

function Update(self)
	if self.Magazine then
		if self.loadedShell then
			self.loadedShell = false;
			self.Magazine.RoundCount = self.ammoCounter + 1;
		else
			self.ammoCounter = self.Magazine.RoundCount;
		end
		if self.Magazine.RoundCount == self.Magazine.Capacity then
			self.reloadCycle = false;
		end
	else
		self.reloadTimer:Reset();
		self.reloadCycle = true;
		self.loadedShell = true;
	end
	if self:IsActivated() then
		self.reloadCycle = false;
	end
	if self.reloadCycle and self.reloadTimer:IsPastSimMS(self.reloadDelay) and self:IsFull() == false then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if MovableMan:IsActor(actor) then
			self:Reload();
		end
		self.reloadCycle = false;
	end
end