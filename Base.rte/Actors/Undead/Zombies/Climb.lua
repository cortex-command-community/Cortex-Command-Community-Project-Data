require("Actors/AI/NativeHumanAI")   -- or NativeCrabAI or NativeTurretAI

function Create(self)
	self.moved = false;
	self.grabfront = false;
	self.stepbottom = false;
end

function Update(self)

	if self.HFlipped == false then
		self.reverseNum = 1;
	else
		self.reverseNum = -1;
	end

	local frontcheck = SceneMan:CastMORay(self.Pos,Vector(10*self.reverseNum,0),self.ID,-2,0,false,1);
	if frontcheck ~= 255 then
		local mo = MovableMan:GetMOFromID(MovableMan:GetMOFromID(frontcheck).RootID);
		if mo.Team == self.Team and mo.ClassName ~= "AEmitter" and mo.ClassName ~= "MOSRotating" then
			self.grabfront = true;
		end
	end

	local lowercheck = SceneMan:CastMORay(self.Pos+Vector(0,17),Vector(0,1),self.ID,-2,0,false,1);
	if lowercheck ~= 255 then
		local mo = MovableMan:GetMOFromID(MovableMan:GetMOFromID(lowercheck).RootID);
		if mo.Team == self.Team and mo.ClassName ~= "AEmitter" and mo.ClassName ~= "MOSRotating" then
			self.stepbottom = true;
		end
	end

	local groundcheck = SceneMan:CastStrengthRay(self.Pos+Vector(0,17),Vector(0,4),0,Vector(),0,0,SceneMan.SceneWrapsX);
	local wallcheck = SceneMan:CastStrengthRay(self.Pos,Vector(8*self.reverseNum,0),0,Vector(),0,0,SceneMan.SceneWrapsX);

	if (self:GetController():IsState(Controller.MOVE_LEFT) or self:GetController():IsState(Controller.MOVE_RIGHT)) then
		self.moved = true;
	end

	if self.moved and self.grabfront and groundcheck and not(wallcheck) then
		self.Vel = Vector(0.5*self.reverseNum,-4);
	end

	if self.stepbottom and self.moved then
		self.Vel = Vector(math.floor(self.Vel.X*0.5),-2);
		if not(wallcheck) then
			self.Vel = Vector(2*self.reverseNum,-2);
		end
	end

	self.moved = false;
	self.grabfront = false;
	self.stepbottom = false;

end