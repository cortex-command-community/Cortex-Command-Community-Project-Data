function Create(self)
	--The number of goo particles available to pick from
	self.gooCount = 6;

	--The range of the tool
	self.range = 30;

	--The arc radius of the tool's beam
	self.beamRadius = math.pi * 0.2;

	--The radial resolution of the beam
	self.resolution = 0.05;

	--The chance of deconstructing a single particle
	self.deconstructChance = 0.1;

	--The base damage output when used on MOs
	self.damageOutput = 25;

	--How many pixels to skip when detecting MOs, for optimization reasons
	self.skipPixels = 1;

	--Sounds
	self.dissipateSound = CreateSoundContainer("Dissipate Sound", "Techion.rte");
	self.disintegrationSound = CreateSoundContainer("Disintegration Sound", "Techion.rte");
end

function OnFire(self)
	local aimAngle = self.HFlipped and self.RotAngle + math.pi or self.RotAngle;

	local aimVec = Vector(self.range, 0):RadRotate(aimAngle);
	local aimUp = Vector(aimVec.X, aimVec.Y):RadRotate(math.pi * 0.5):Normalize();
	local hitPos = Vector();

	--Cast rays in front of the gun
	for i = -self.beamRadius * 0.5, self.beamRadius * 0.5, self.resolution do
		if math.random() < self.deconstructChance then
			if SceneMan:CastStrengthRay(self.MuzzlePos, Vector(aimVec.X, aimVec.Y):RadRotate(i), 1, hitPos, 0, 166, true) then
				local remover = CreateMOSRotating("Techion.rte/Pixel Remover");
				remover.Pos = hitPos;
				MovableMan:AddParticle(remover);
				remover:EraseFromTerrain();

				local piece = CreateMOPixel("Techion.rte/Nanogoo " .. math.random(1, self.gooCount));
				piece.Pos = hitPos;
				MovableMan:AddParticle(piece);
				piece.ToSettle = true;

				local glow = CreateMOPixel("Techion.rte/Pixel Creation Glow");
				glow.Pos = hitPos;
				MovableMan:AddParticle(glow);

				if self.dissipateSound:IsBeingPlayed() then
					self.dissipateSound.Pitch = RangeRand(RangeRand(0.7, 1.3));
					self.dissipateSound:Play(hitPos);
				end
			end
		end
	end

	--Find MOs to disintegrate
	local moCheck = SceneMan:CastMORay(self.MuzzlePos, aimVec * 0.5, self.RootID, self.Team, rte.airID, true, 2);
	if moCheck ~= rte.NoMOID then

		local initMO = MovableMan:GetMOFromID(moCheck);
		if initMO then

			local targetMO = MovableMan:GetMOFromID(ToMOSRotating(initMO).RootID);
			local dustTarget;

			if targetMO then
				local resistance = math.sqrt(targetMO.Radius + math.abs(targetMO.Mass) + targetMO.Material.StructuralIntegrity + 1);
				if IsActor(targetMO) then
					local actor = ToActor(targetMO);
					local damage = self.damageOutput/resistance;
					if math.random() < damage then	--Turns into chance under 1 because Health is an integer in .lua
						if actor.Status > Actor.UNSTABLE then
							dustTarget = actor;
						else
							actor.Health = actor.Health - damage;
							local healthRatio = actor.Health/actor.MaxHealth;
							if math.random() > healthRatio then
								actor:FlashWhite(20/(1 + healthRatio));
								local dots = math.sqrt(actor.Diameter)/(1 + healthRatio);
								for i = 1, dots do
									local piece = CreateMOPixel("Techion.rte/Nanogoo " .. math.random(self.gooCount));
									piece.Pos = actor.Pos;
									piece.Vel = actor.Vel * 0.5 + Vector(dots, 0):RadRotate(6.28 * math.random()) + Vector(0, -1);
									piece.Lifetime = math.random(300, 900);
									piece.GlobalAccScalar = RangeRand(0.2, 0.4);
									piece.AirResistance = RangeRand(0.1, 0.2);
									MovableMan:AddParticle(piece);
								end
								if self.dissipateSound:IsBeingPlayed() then
									self.dissipateSound.Pitch = RangeRand(RangeRand(0.7, 1.3));
									self.dissipateSound:Play(actor.Pos);
								end
							end
						end
					end
				elseif math.random(self.damageOutput) > resistance then
					dustTarget = ToMOSRotating(targetMO);
				end
			end
			if dustTarget then
				local parts = {dustTarget};
				--Measure the corners of a box that the Actor is supposedly inside of
				local topLeft = Vector(-dustTarget.IndividualRadius, -dustTarget.IndividualRadius);
				local bottomRight = Vector(dustTarget.IndividualRadius, dustTarget.IndividualRadius);
				for att in dustTarget.Attachables do
					if IsAttachable(att) then
						local dist = SceneMan:ShortestDistance(dustTarget.Pos, att.Pos, SceneMan.SceneWrapsX);
						local reach = dist:SetMagnitude(dist.Magnitude + att.Radius + 5);
						if reach.X < topLeft.X then
							topLeft.X = reach.X;
						elseif reach.X > bottomRight.X then
							bottomRight.X = reach.X;
						end
						if reach.Y < topLeft.Y then
							topLeft.Y = reach.Y;
						elseif reach.Y > bottomRight.Y then
							bottomRight.Y = reach.Y;
						end
						table.insert(parts, att);
					end
				end
				--Spawn a pixel particle for each pixel of the Actor
				local skip = 1 + self.skipPixels;
				for x = 1, (bottomRight.X - topLeft.X)/skip do
					for y = 1, (bottomRight.Y - topLeft.Y) do
						local checkPos = (dustTarget.Pos + topLeft) + Vector(x * skip, y);
						local terrCheck = SceneMan:GetTerrMatter(checkPos.X, checkPos.Y);
						if terrCheck == rte.airID or terrCheck == rte.grassID then
							local id = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
							if id ~= rte.NoMOID and MovableMan:GetMOFromID(id).RootID == dustTarget.ID then
								for px = 1, skip do
									local piece = CreateMOPixel("Techion.rte/Nanogoo " .. math.random(1, self.gooCount));
									piece.Pos = checkPos + Vector(px - 1, 0);
									piece.Vel = dustTarget.Vel * 0.3 + Vector(0, -1) + SceneMan:ShortestDistance(dustTarget.Pos, piece.Pos, SceneMan.SceneWrapsX):SetMagnitude(math.random());
									piece.Lifetime = math.random(500, 1500);
									piece.GlobalAccScalar = RangeRand(0.2, 0.4);
									piece.AirResistance = RangeRand(0.1, 0.2);
									MovableMan:AddParticle(piece);
								end
							end
						end
					end
				end
				for _, mo in pairs(parts) do
					local glowDiameter = math.min(math.floor(1 + (mo.Diameter * mo.Scale) * 0.1) * 10, 50);
					local glow = CreateMOPixel("Techion.rte/Disintegration Glow ".. glowDiameter);
					glow.Pos = mo.Pos;
					glow.Vel = mo.Vel;
					MovableMan:AddParticle(glow);
				end
				self.disintegrationSound:Play(dustTarget.Pos);
				dustTarget.ToDelete = true;
			end
		end
	end
end