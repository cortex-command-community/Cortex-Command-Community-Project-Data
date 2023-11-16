function Create(self)

	self.Activity = ToGameActivity(ActivityMan:GetActivity());
	
end

function Update(self)

	if UInputMan:KeyPressed(Key.P) then	
		self:GibThis();
	end
	
end

function OnDestroy(self)

	self.Activity:SendMessage("RefineryAssault_RefineryConsoleBroken");

end