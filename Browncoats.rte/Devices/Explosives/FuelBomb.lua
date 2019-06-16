function Create(self)

	self.explodeTimer = Timer();
	self.partList = {};
	self.burnList = {};

	self.explodeTime = 2000;
	self.numOfParticles = 50;
	self.particlesPerOil = 3;

	self:EraseFromTerrain();
	self.Scale = 0;

	for i = 1, self.numOfParticles do
		self.partList[i] = CreateMOPixel("Browncoat Fuel Bomb Fuel");
		self.partList[i].Pos = self.Pos;
		self.partList[i].Vel = Vector((math.random()*20),0):RadRotate(6.28318*math.random()) + self.Vel;
		MovableMan:AddParticle(self.partList[i]);
		self.burnList[i] = Vector(self.Pos.X,self.Pos.Y);
	end

end

function Update(self)

	self.ToDelete = false;

	if self.explodeTimer:IsPastSimMS(self.explodeTime) then
		local soundCount = 0;
		for i = 1, #self.partList do
			if MovableMan:IsParticle(self.partList[i]) and self.partList[i].PresetName == "Browncoat Fuel Bomb Fuel" then
				soundCount = soundCount + 1;
				if soundCount >= 10 then
					soundCount = 0;
					local sfx = CreateMOSRotating("Browncoat Fuel Bomb Burn Sound");
					sfx.Pos = Vector(self.partList[i].Pos.X,self.partList[i].Pos.Y);
					sfx:GibThis();
					MovableMan:AddParticle(sfx);
				end
				for j = 1, self.particlesPerOil do
					local firePar;
					local randNum = math.random();
					if randNum < 0.2 then
						firePar = CreateMOPixel("Particle Browncoat Incendiary Flame 1");
					elseif randNum < 0.4 then
						firePar = CreateMOPixel("Particle Browncoat Incendiary Flame 2");
					elseif randNum < 0.6 then
						firePar = CreateMOSParticle("Tiny Smoke Ball Incendiary Flamer 1");
					elseif randNum < 0.8 then
						firePar = CreateMOSParticle("Tiny Smoke Ball Incendiary Flamer 2");
					else
						firePar = CreateMOSParticle("Tiny Smoke Ball Incendiary Flamer 3");
					end
					firePar.Pos = Vector(self.partList[i].Pos.X,self.partList[i].Pos.Y);
					firePar.Vel = Vector((math.random()*5)+20,0):RadRotate(math.random()*6.28318);
					MovableMan:AddParticle(firePar);
				end
				self.partList[i].ToDelete = true;
			end
		end
		self.ToDelete = true;
	end

end