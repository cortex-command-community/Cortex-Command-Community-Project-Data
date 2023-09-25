function Create(self)

	self.quickThrowTimer = Timer();
	self.quickThrowDelay = 5000;
	self.quickThrowExplosive = CreateTDExplosive("Fire Bomb", "Browncoats.rte");
	
end

function Update(self)

	if self.AI.Target then
		if self.quickThrowTimer:IsPastSimMS(self.quickThrowDelay) then
			local explosive = self.quickThrowExplosive:Clone();
			explosive.MinThrowVel = 30;
			explosive.MaxThrowVel = 30;
			self:AddInventoryItem(explosive);
			self:EquipThrowable(true);
			self.quickThrowing = true;
			self.quickThrowTimer:Reset();
			
		elseif self.quickThrowing then
		
			self:GetController():SetState(Controller.PRIMARY_ACTION, true);

			self:GetController():SetState(Controller.WEAPON_CHANGE_NEXT, false);
			self:GetController():SetState(Controller.WEAPON_CHANGE_PREV, false);
			
			if not self.EquippedItem then
				self.quickThrowing = false;
			else
				self.EquippedItem:Activate();
			end
		end
	else
		self.quickThrowTimer:Reset();
	end

end
