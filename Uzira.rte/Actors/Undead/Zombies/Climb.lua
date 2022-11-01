require("AI/NativeHumanAI") -- or NativeCrabAI or NativeTurretAI

function Create(self)
	self.moved = false;
	self.grabFront = false;
	self.stepBottom = false;
end

function Update(self)

	local frontCheck = SceneMan:CastMORay(self.Pos, Vector(10 * self.FlipFactor, 0), self.ID, -2, rte.airID, false, 1);
	if frontCheck ~= rte.NoMOID then
		local mo = MovableMan:GetMOFromID(frontCheck):GetRootParent();
		if mo and mo.Team == self.Team and mo.ClassName ~= "AEmitter" and mo.ClassName ~= "MOSRotating" then
			self.grabFront = true;
		end
	end

	local lowerCheck = SceneMan:CastMORay(self.Pos + Vector(0, 17), Vector(0, 1), self.ID, -2, rte.airID, false, 1);
	if lowerCheck ~= rte.NoMOID then
		local mo = MovableMan:GetMOFromID(lowerCheck):GetRootParent();
		if mo and mo.Team == self.Team and mo.ClassName ~= "AEmitter" and mo.ClassName ~= "MOSRotating" then
			self.stepBottom = true;
		end
	end

	local groundcheck = SceneMan:CastStrengthRay(self.Pos + Vector(0, 17), Vector(0, 4), 0, Vector(), 0, rte.airID, SceneMan.SceneWrapsX);
	local wallcheck = SceneMan:CastStrengthRay(self.Pos, Vector(8 * self.FlipFactor, 0), 0, Vector(), 0, rte.airID, SceneMan.SceneWrapsX);

	if (self:GetController():IsState(Controller.MOVE_LEFT) or self:GetController():IsState(Controller.MOVE_RIGHT)) then
		self.moved = true;
	end

	if self.moved and self.grabFront and groundcheck and not(wallcheck) then
		self.Vel = Vector(0.5 * self.FlipFactor, -4);
	end

	if self.stepBottom and self.moved then
		self.Vel = Vector(math.floor(self.Vel.X * 0.5), -2);
		if not(wallcheck) then
			self.Vel = Vector(2 * self.FlipFactor, -2);
		end
	end

	self.moved = false;
	self.grabFront = false;
	self.stepBottom = false;
end