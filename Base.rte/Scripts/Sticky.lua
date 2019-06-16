function Create(self)
	local part = nil;
	local dist = 0;
	local curdist = 25;
	local chosenpart = nil;

	--Cycle through all MOs and see which is the closest, and attach to it.
	for i=1,MovableMan:GetMOIDCount()-1 do
		part = MovableMan:GetMOFromID(i)
		if part and
			part = ToMovableObject(part);
			dist = math.sqrt((self.Pos.X - part.Pos.X) ^ 2 + (self.Pos.Y - part.Pos.Y) ^ 2);
			if dist < curdist and part.ID ~= self.ID then
				curdist = dist;
				chosenpart = part;
			end
		end
	end

	--If a part was found, attach to it.  Otherwise, we assume it is a wall, and stay pinned to it.
	if chosenpart ~= nil then
		self.attached = MovableMan:GetMOFromID(chosenpart.RootID);
		self.offset = Vector(chosenpart.Pos.X-self.Pos.X,chosenpart.Pos.Y-self.Pos.Y);
		self.offangle = self.offset.AbsRadAngle - chosenpart.RotAngle;
		self.PinStrength = 0;
		--Make the grenade not collide with the attached object or any of its children so that it doesn't go off on its own.
		for i=1,MovableMan:GetMOIDCount()-1 do
			part = MovableMan:GetMOFromID(i);
			if part and part.RootID == self.attached then
				self:SetWhichMOToNotHit(part,-1);
			end
		end
	end
end

function Update(self)
	--Using trigonometry, move to the right position and update speed and rotation.  Check first if it still exists.
	if self.attached then
		if MovableMan:ValidMO(self.attached) then
			self.Pos.X = self.attached.Pos.X + self.offset.Magnitude * math.cos(self.offangle + self.attached.RotAngle);
			self.Pos.Y = self.attached.Pos.Y + self.offset.Magnitude * math.sin(self.offangle + self.attached.RotAngle);
			self.Vel = self.attached.Vel;
			self.RotAngle = self.attached.RotAngle;
			self.AngularVel = self.attached.AngularVel;
		end
	end
end