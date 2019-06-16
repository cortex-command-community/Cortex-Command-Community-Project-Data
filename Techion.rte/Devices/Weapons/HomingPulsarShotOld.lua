function Create(self)
	--Speed at which this can dissipate energy.
	self.speedThreshold = 40;
	
	--Strength of material which will dissipate energy.
	self.strengthThreshold = 5;
	
	--Speed of the effect.
	self.effectSpeed = 4;
	
	--The shot effect.
	self.shotEffect = CreateMOSRotating("Techion.rte/Laser Shot Effect");
	self.shotEffect.Pos = self.Pos;
	self.shotEffect.Vel = self.Vel;
	MovableMan:AddParticle(self.shotEffect);
	
	--Check backward.
	local pos = Vector();
	local trace = Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi) * TimerMan.DeltaTimeSecs * 20;
	if SceneMan:CastObstacleRay(self.Pos, trace, pos, Vector(), 0, self.Team, 0, 5) >= 0 then
		--Check that the position is actually strong enough to cause dissipation.
		trace = SceneMan:ShortestDistance(self.Pos, pos, true);
		local strength = SceneMan:CastStrengthRay(self.Pos, trace, self.strengthThreshold, Vector(), 0, 0, true);
		local mo = SceneMan:CastMORay(self.Pos, trace, 0, self.Team, 0, true, 5);
		if strength or (mo ~= 255 and mo ~= 0) then
			local effect = CreateAEmitter("Techion.rte/Laser Dissipate Effect");
			effect.Pos = pos + Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi):SetMagnitude(3);
			effect.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi):SetMagnitude(self.effectSpeed);
			MovableMan:AddParticle(effect);
			effect:GibThis();
		end
	end

	self.pointCount = 150; -- number of points in the spiral
	self.spiralScale = 8; -- spiral scale
	self.skipPoints = 0; -- skips the first X points

	self.minRecordDist = -1;
	self.detect = false;

	-- radius = spiralScale * squareroot( pountCount )


	self.target = null;

	self.adjustmentAmount = 2;

	self.trailPar = {};
	self.trailParNum = 3;

	for i = 1, self.trailParNum do
		self.trailPar[i] = CreateMOPixel("Particle Micro Pulsar Damage");
		self.trailPar[i].Pos = Vector(self.Pos.X,self.Pos.Y);
		self.trailPar[i].Vel = Vector(self.Vel.X,self.Vel.Y);
		self.trailPar[i].Team = self.Team;
		self.trailPar[i].IgnoresTeamHits = true;
		MovableMan:AddParticle(self.trailPar[i]);
	end


end

function Update(self)

	if self.target == null or self.target.ID == 255 then
		for i = self.skipPoints, self.pointCount - 1 do
			local radius = self.spiralScale*math.sqrt(i);
			local angle = i * 137.508;
			local checkPos = self.Pos + Vector(radius,0):DegRotate(angle);
			if SceneMan.SceneWrapsX == true then
				if checkPos.X > SceneMan.SceneWidth then
					checkPos = Vector(checkPos.X - SceneMan.SceneWidth,checkPos.Y);
				elseif checkPos.X < 0 then
					checkPos = Vector(SceneMan.SceneWidth + checkPos.X,checkPos.Y);
				end
			end
			local moCheck = SceneMan:GetMOIDPixel(checkPos.X,checkPos.Y);
			if moCheck ~= 255 then
				local mo = MovableMan:GetMOFromID(moCheck);
				if mo.Team ~= self.Team or mo.ClassName == "TDExplosive" or mo.ClassName == "MOSRotating" or (mo.ClassName == "AEmitter" and mo.RootID == moCheck) then
					local moDist = SceneMan:ShortestDistance(self.Pos,mo.Pos,SceneMan.SceneWrapsX);
					if SceneMan:CastStrengthRay(self.Pos,moDist:SetMagnitude(moDist.Magnitude-mo.Radius),0,Vector(0,0),3,0,SceneMan.SceneWrapsX) == false then
						if mo.ClassName == "TDExplosive" then
							self.Team = -2;
						end
						self.target = mo;
					end
					break;
				end
			end
		end
	else
		local aimVel = Vector(self.Vel.X,self.Vel.Y):SetMagnitude(1) + SceneMan:ShortestDistance(self.Pos,self.target.Pos,SceneMan.SceneWrapsX):SetMagnitude(self.adjustmentAmount);
		self.Vel = Vector(self.Vel.Magnitude,0):RadRotate(aimVel.AbsRadAngle);
	end

	for i = 1, self.trailParNum do
		if MovableMan:IsParticle(self.trailPar[i]) and self.trailPar[i].PresetName == "Particle Micro Pulsar Damage" then
			self.trailPar[i].Pos = Vector(self.Pos.X,self.Pos.Y);
			self.trailPar[i].Vel = Vector(self.Vel.X,self.Vel.Y);
			self.trailPar[i].Team = self.Team;
		end
	end

	if not self.ToDelete then
		if self.Vel.Magnitude >= self.speedThreshold then
			--Collide with objects and deploy the dissipate effect.
			local pos = Vector();
			local trace = Vector(self.Vel.X, self.Vel.Y) * TimerMan.DeltaTimeSecs * 20;
			if SceneMan:CastObstacleRay(self.Pos, trace, pos, Vector(), 0, self.Team, 0, 5) >= 0 then
				--Check that the position is actually strong enough to cause dissipation.
				trace = SceneMan:ShortestDistance(self.Pos, pos, true);
				local strength = SceneMan:CastStrengthRay(self.Pos, trace, self.strengthThreshold, Vector(), 0, 0, true);
				local mo = SceneMan:CastMORay(self.Pos, trace, 0, self.Team, 0, true, 5);
				if strength or (mo ~= 255 and mo ~= 0) then
					local effect = CreateAEmitter("Techion.rte/Laser Dissipate Effect");
					effect.Pos = pos + Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi):SetMagnitude(3);
					effect.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi):SetMagnitude(self.effectSpeed);
					MovableMan:AddParticle(effect);
					effect:GibThis();
				end
			end
		end
	end
	
	--Display the laser shot effect.
	if MovableMan:IsParticle(self.shotEffect) then
		if self.Vel.Magnitude >= self.speedThreshold then
			self.shotEffect.Pos = self.Pos;
			self.shotEffect.Vel = self.Vel;
			self.shotEffect.ToDelete = false;
		else
			self.shotEffect.ToDelete = true;
		end
	end

end

function Destroy(self)
	if MovableMan:IsParticle(self.shotEffect) then
		--Destroy the laser shot effect.
		self.shotEffect.ToDelete = true;
	end
end