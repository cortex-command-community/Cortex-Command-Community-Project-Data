function Create(self)

	self.lifeTimer = Timer();
	self.emitTimerA = Timer();
	self.emitTimerB = Timer();

	self.smallAngle = 6.28318/12;

	self.angleList = {};

end

function Update(self)

	if MovableMan:IsParticle(self) and self.lifeTimer:IsPastSimMS(10000) then
		self.ToDelete = true;
	else
		--self.ToDelete = false;
		--self.ToSettle = false;

		if self.emitTimerA:IsPastSimMS(40) then
			self.emitTimerA:Reset();

			self.angleList = {};

			for i = 1, 12 do
				local angleCheck = self.smallAngle*i;

				for i = 1, 5 do
					local checkPos = self.Pos + Vector(i,0):RadRotate(angleCheck);
					if SceneMan.SceneWrapsX == true then
						if checkPos.X > SceneMan.SceneWidth then
							checkPos = Vector(checkPos.X - SceneMan.SceneWidth,checkPos.Y);
						elseif checkPos.X < 0 then
							checkPos = Vector(SceneMan.SceneWidth + checkPos.X,checkPos.Y);
						end
					end
					local terrCheck = SceneMan:GetTerrMatter(checkPos.X,checkPos.Y);
					if terrCheck ~= 0 then
						break;
					end
					if i == 5 then
						self.angleList[#self.angleList+1] = angleCheck;
					end
				end
			end

			if #self.angleList > 0 then
				local listNum = #self.angleList;

				local randomAngleA = self.angleList[math.random(listNum)] + (math.random()*0.4) - 0.2;
				local randomAngleB = self.angleList[math.random(listNum)] + (math.random()*0.4) - 0.2;
				local randomAngleC = self.angleList[math.random(listNum)] + (math.random()*0.4) - 0.2;

				local fireA = CreateMOPixel("Particle Browncoat Incendiary Flame 1");
				fireA.Pos = self.Pos;
				fireA.Vel = Vector((math.random()*5)+10,0):RadRotate(randomAngleA);
				MovableMan:AddParticle(fireA);

				local fireB = CreateMOPixel("Particle Browncoat Incendiary Flame 2");
				fireB.Pos = self.Pos;
				fireB.Vel = Vector((math.random()*5)+5,0):RadRotate(randomAngleB);
				MovableMan:AddParticle(fireB);

				local fireC = CreateMOSParticle("Tiny Smoke Ball Incendiary Flamer 1");
				fireC.Pos = self.Pos;
				fireC.Vel = Vector((math.random()*3)+2,0):RadRotate(randomAngleC);
				MovableMan:AddParticle(fireC);
			else
				local fireA = CreateMOPixel("Particle Browncoat Incendiary Flame 1");
				fireA.Pos = self.Pos;
				fireA.Vel = Vector((math.random()*5)+10,0):RadRotate(math.random()*6.28318);
				MovableMan:AddParticle(fireA);

				local fireB = CreateMOPixel("Particle Browncoat Incendiary Flame 2");
				fireB.Pos = self.Pos;
				fireB.Vel = Vector((math.random()*5)+5,0):RadRotate(math.random()*6.28318);
				MovableMan:AddParticle(fireB);

				local fireC = CreateMOSParticle("Tiny Smoke Ball Incendiary Flamer 1");
				fireC.Pos = self.Pos;
				fireC.Vel = Vector((math.random()*3)+2,0):RadRotate(math.random()*6.28318);
				MovableMan:AddParticle(fireC);
			end

		end

		if self.emitTimerB:IsPastSimMS(60) then
			self.emitTimerB:Reset();

			local listNum = #self.angleList;

			if #self.angleList > 0 then
				local randomAngleA = self.angleList[math.random(listNum)] + (math.random()*0.4) - 0.2;
				local randomAngleB = self.angleList[math.random(listNum)] + (math.random()*0.4) - 0.2;

				local fireD = CreateMOSParticle("Tiny Smoke Ball Incendiary Flamer 2");
				fireD.Pos = self.Pos;
				fireD.Vel = Vector((math.random()*5)+10,0):RadRotate(randomAngleA);
				MovableMan:AddParticle(fireD);

				local fireE = CreateMOSParticle("Tiny Smoke Ball Incendiary Flamer 3");
				fireE.Pos = self.Pos;
				fireE.Vel = Vector((math.random()*5)+5,0):RadRotate(randomAngleB);
				MovableMan:AddParticle(fireE);
			else
				local fireD = CreateMOSParticle("Tiny Smoke Ball Incendiary Flamer 2");
				fireD.Pos = self.Pos;
				fireD.Vel = Vector((math.random()*5)+10,0):RadRotate(math.random()*6.28318);
				MovableMan:AddParticle(fireD);

				local fireE = CreateMOSParticle("Tiny Smoke Ball Incendiary Flamer 3");
				fireE.Pos = self.Pos;
				fireE.Vel = Vector((math.random()*5)+5,0):RadRotate(math.random()*6.28318);
				MovableMan:AddParticle(fireE);
			end

		end

	end

end
