--Global handler for flame particles - this eliminates the need to run a script on each of the particles
GlobalFlameManagement = {FlameHandler = nil, Flames = {}};

function Create(self)
	self.shortFlame = CreatePEmitter("Flame Hurt Short Float", "Base.rte");
end

--To-do: multiple flames close to each other should form a bigger flame
function Update(self)
	self.PinStrength = 900001;
	local flameCount = 0;
	if #GlobalFlameManagement.Flames ~= 0 then
		--TODO: use 'pairs' instead?
		for i = 1, #GlobalFlameManagement.Flames do
			if GlobalFlameManagement.Flames[i] and GlobalFlameManagement.Flames[i].particle and MovableMan:ValidMO(GlobalFlameManagement.Flames[i].particle) then

				flameCount = flameCount + 1;

				local flame = GlobalFlameManagement.Flames[i].particle;
				local ageRatio = flame.Age/flame.Lifetime;
				flame.ToSettle = false;
				flame.Throttle = flame.Throttle - TimerMan.DeltaTimeMS/flame.Lifetime;

				if GlobalFlameManagement.Flames[i].target and MovableMan:ValidMO(GlobalFlameManagement.Flames[i].target) and GlobalFlameManagement.Flames[i].target.ID ~= rte.NoMOID and not GlobalFlameManagement.Flames[i].target.ToDelete then
					flame.Vel = GlobalFlameManagement.Flames[i].target.Vel;
					flame.Pos = GlobalFlameManagement.Flames[i].target.Pos + Vector(GlobalFlameManagement.Flames[i].stickOffset.X, GlobalFlameManagement.Flames[i].stickOffset.Y):RadRotate(GlobalFlameManagement.Flames[i].target.RotAngle - GlobalFlameManagement.Flames[i].targetStickAngle);
					local actor = GlobalFlameManagement.Flames[i].target:GetRootParent();
					if MovableMan:IsActor(actor) then
						actor = ToActor(actor);
						actor.Health = actor.Health - math.max(GlobalFlameManagement.Flames[i].target.DamageMultiplier * (flame.Throttle + 1), 0.1)/(actor.Mass * 0.7 + GlobalFlameManagement.Flames[i].target.Material.StructuralIntegrity);
						--Stop, drop and roll!
						flame.Lifetime = flame.Lifetime - math.abs(actor.AngularVel);
					end
				else
					GlobalFlameManagement.Flames[i].target = nil;
					if math.random() > ageRatio then
						if flame.Vel:MagnitudeIsGreaterThan(1) then
							local checkPos = Vector(flame.Pos.X, flame.Pos.Y - 1) + flame.Vel * rte.PxTravelledPerFrame * math.random();
							local moCheck = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
							if moCheck ~= rte.NoMOID then
								local mo = MovableMan:GetMOFromID(moCheck);
								if mo and (flame.Team == Activity.NOTEAM or mo.Team ~= flame.Team) then
									GlobalFlameManagement.Flames[i].target = ToMOSRotating(mo);

									GlobalFlameManagement.Flames[i].isShort = true;
									GlobalFlameManagement.Flames[i].deleteDelay = math.random(flame.Lifetime);

									GlobalFlameManagement.Flames[i].targetStickAngle = mo.RotAngle;
									GlobalFlameManagement.Flames[i].stickOffset = SceneMan:ShortestDistance(mo.Pos, flame.Pos, SceneMan.SceneWrapsX) * 0.8;

									flame.GlobalAccScalar = 0.9;
								end
							elseif flame.GlobalAccScalar < 0.5 and GlobalFlameManagement.Flames[i].isShort and math.random() < 0.2 and SceneMan:GetTerrMatter(checkPos.X, checkPos.Y) ~= rte.airID then
								GlobalFlameManagement.Flames[i].deleteDelay = math.random(flame.Lifetime);
								flame.GlobalAccScalar = 0.9;
							end
						end
						
						--Spawn another, shorter flame particle occasionally
						if not GlobalFlameManagement.Flames[i].isShort and math.random() < (1 + flame.Throttle) * 0.1 then
							local particle = self.shortFlame:Clone();
							particle.Lifetime = particle.Lifetime * RangeRand(0.6, 0.9);
							particle.Vel = flame.Vel + Vector(0, -3) + Vector(math.random(), 0):RadRotate(math.random() * math.pi * 2);
							particle.Pos = Vector(flame.Pos.X, flame.Pos.Y - 1);
							MovableMan:AddParticle(particle);
						end
					end
					if GlobalFlameManagement.Flames[i].deleteDelay and flame.Age > GlobalFlameManagement.Flames[i].deleteDelay then
						flame.ToDelete = true;
					end
				end
			else
				GlobalFlameManagement.Flames[i] = {};
			end
		end
		if flameCount == 0 then
			GlobalFlameManagement.Flames = {};
		end
	end
end

function Destroy(self)
	GlobalFlameManagement.FlameHandler = nil;
end