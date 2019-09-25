function Create(self)

	self.alliedTeam = -1;
	self.lastAngle = self.RotAngle;
	self.lastVel = Vector(self.Vel.X,self.Vel.Y);

end

function Update(self)

	self.lastAngle = self.RotAngle;
	self.lastVel = Vector(self.Vel.X,self.Vel.Y);

	if self.ID == self.RootID and self.alliedTeam == -1 then
		self.curdist = 500;
		for actor in MovableMan.Actors do
			local dist = SceneMan:ShortestDistance(self.Pos,actor.Pos,SceneMan.SceneWrapsX).Magnitude;
			if dist < self.curdist then
				self.curdist = dist;
				self.alliedTeam = ToActor(actor).Team;
			end
		end
	end

	local rayHitPos = Vector(0,0);
	local terrainRaycast = SceneMan:CastStrengthRay(self.Pos,Vector(self.Vel.X,self.Vel.Y):SetMagnitude(150),0,rayHitPos,0,0,SceneMan.SceneWrapsX);

	if terrainRaycast == true then
		for i = 1, 5 do
			local mine = CreateMOSRotating("Particle Mine");
			mine.Pos = self.Pos;
			mine.Vel = self.Vel + Vector((math.random()*15)+5,0):RadRotate(math.random()*(math.pi*2));
			mine.Sharpness = self.alliedTeam;
			MovableMan:AddParticle(mine);
			self:GibThis();
		end
	end

end

function Destroy(self)

	local gibA = CreateMOSRotating("Cluster Mine Bomb Gib A");
	gibA.Pos = self.Pos;
	gibA.Vel = self.Vel;
	gibA.RotAngle = self.lastAngle;
	MovableMan:AddParticle(gibA);

	local gibB = CreateMOSRotating("Cluster Mine Bomb Gib B");
	gibB.Pos = self.Pos + Vector(1,-3):RadRotate(self.lastAngle);
	gibB.Vel = self.Vel + Vector(0,20):RadRotate(self.lastAngle);
	gibB.AngularVel = 20;
	gibB.RotAngle = self.lastAngle;
	MovableMan:AddParticle(gibB);

	local gibC = CreateMOSRotating("Cluster Mine Bomb Gib C");
	gibC.Pos = self.Pos + Vector(1,4):RadRotate(self.lastAngle);
	gibC.Vel = self.Vel + Vector(0,-20):RadRotate(self.lastAngle);
	gibC.AngularVel = -20;
	gibC.RotAngle = self.lastAngle;
	MovableMan:AddParticle(gibC);

end