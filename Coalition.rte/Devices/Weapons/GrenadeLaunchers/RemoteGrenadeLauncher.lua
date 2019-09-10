function Create(self)

	self.reloaded = false;
	self.ammoCounter = 0;
	self.grenadeTableA = {};
	self.grenadeTableB = {};
	self.maxActiveGrenades = 12;
	self.particleSpread = 6;
	self.particleSpreadSharp = 2;

end

function Update(self)

	if self.Magazine ~= nil then
		if self.reloaded == false then
			self.reloaded = true;
			self.ammoCounter = self.Magazine.RoundCount;
		else
			if self.ammoCounter ~= self.Magazine.RoundCount then

				if self.HFlipped == false then
					self.negativeNum = 1;
				else
					self.negativeNum = -1;
				end

				local bullet = CreateActor("Coalition Remote Grenade Shot");
				bullet.Pos = self.MuzzlePos;
				bullet.Vel = self.Vel + Vector(30*self.negativeNum,0):RadRotate(self.RotAngle):DegRotate((self.particleSpread*-0.5)+(self.particleSpread*math.random()));

				local actor = MovableMan:GetMOFromID(self.RootID);
				if MovableMan:IsActor(actor) then
					if ToActor(actor):GetController():IsState(Controller.AIM_SHARP) then
						bullet.Vel = self.Vel + Vector(30*self.negativeNum,0):RadRotate(self.RotAngle):DegRotate((self.particleSpreadSharp*-0.5)+(self.particleSpreadSharp*math.random()));
					end
					if ToActor(actor):IsPlayerControlled() then
						if self.grenadeTableA[self.maxActiveGrenades] ~= nil then
							self.grenadeTableA[self.maxActiveGrenades].Sharpness = 2;
						end
						for i = 1, self.maxActiveGrenades do
							self.grenadeTableB[i+1] = self.grenadeTableA[i];
						end
						self.grenadeTableA = {};
						for i = 1, self.maxActiveGrenades do
							self.grenadeTableA[i] = self.grenadeTableB[i];
						end
						self.grenadeTableB = {};
						self.grenadeTableA[1] = bullet;
						bullet.Sharpness = 0;
					else
						bullet.Sharpness = 3;
					end

					bullet.Team = ToActor(actor).Team;
					bullet.IgnoresTeamHits = true;

				end

				MovableMan:AddParticle(bullet);

			end
			self.ammoCounter = self.Magazine.RoundCount;
		end
	else
		self.reloaded = false;
	end

	if self.Sharpness == 1 then
		self.Sharpness = 0;
		for i = 1, #self.grenadeTableA do
			if MovableMan:IsParticle(self.grenadeTableA[i]) then
				self.grenadeTableA[i].Sharpness = 2;
			end
		end
		self.grenadeTableA = {};
	elseif self.Sharpness == 2 then
		self.Sharpness = 0;
		for i = 1, #self.grenadeTableA do
			if MovableMan:IsParticle(self.grenadeTableA[i]) then
				self.grenadeTableA[i].Sharpness = 1;
			end
		end
		self.grenadeTableA = {};
	end

end

function Destroy(self)

	for i = 1, #self.grenadeTableA do
		if MovableMan:IsParticle(self.grenadeTableA[i]) then
			self.grenadeTableA[i].Sharpness = 1;
		end
	end

end