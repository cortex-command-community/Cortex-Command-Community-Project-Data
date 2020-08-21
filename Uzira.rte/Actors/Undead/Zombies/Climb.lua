require("AI/NativeHumanAI")   -- or NativeCrabAI or NativeTurretAI

function Create(self)
	self.moved = false;
	self.grabfront = false;
	self.stepbottom = false;
end

function Update(self)

	local frontcheck = SceneMan:CastMORay(self.Pos, Vector(10 * self.FlipFactor, 0), self.ID, -2, rte.airID, false, 1);
	if frontcheck ~= rte.NoMOID then
		local mo = MovableMan:GetMOFromID(MovableMan:GetMOFromID(frontcheck).RootID);
		if mo.Team == self.Team and mo.ClassName ~= "AEmitter" and mo.ClassName ~= "MOSRotating" then
			self.grabfront = true;
		end
	end

	local lowercheck = SceneMan:CastMORay(self.Pos+Vector(0, 17), Vector(0, 1), self.ID, -2, rte.airID, false, 1);
	if lowercheck ~= rte.NoMOID then
		local mo = MovableMan:GetMOFromID(MovableMan:GetMOFromID(lowercheck).RootID);
		if mo.Team == self.Team and mo.ClassName ~= "AEmitter" and mo.ClassName ~= "MOSRotating" then
			self.stepbottom = true;
		end
	end

	local groundcheck = SceneMan:CastStrengthRay(self.Pos+Vector(0, 17), Vector(0, 4), 0, Vector(), 0, rte.airID, SceneMan.SceneWrapsX);
	local wallcheck = SceneMan:CastStrengthRay(self.Pos, Vector(8 * self.FlipFactor, 0), 0, Vector(), 0, rte.airID, SceneMan.SceneWrapsX);

	if (self:GetController():IsState(Controller.MOVE_LEFT) or self:GetController():IsState(Controller.MOVE_RIGHT)) then
		self.moved = true;
	end

	if self.moved and self.grabfront and groundcheck and not(wallcheck) then
		self.Vel = Vector(0.5 * self.FlipFactor, -4);
	end

	if self.stepbottom and self.moved then
		self.Vel = Vector(math.floor(self.Vel.X * 0.5), -2);
		if not(wallcheck) then
			self.Vel = Vector(2 * self.FlipFactor, -2);
		end
	end

	self.moved = false;
	self.grabfront = false;
	self.stepbottom = false;
end