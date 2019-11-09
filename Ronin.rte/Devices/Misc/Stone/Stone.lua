dofile ("Base.rte/Scripts/Shared/RandomFrame.lua")

function Update(self)
	if self.Vel.Magnitude > 2 then
		self.HUDVisible = false;
	else
		self.HUDVisible = true;
	end
end