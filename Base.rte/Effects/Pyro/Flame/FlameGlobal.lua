--Global handler for flame particles - this eliminates the need to run a script on each of the particles
function Create(self)
	self.shortFlame = CreatePEmitter("Flame Hurt Short Float", "Base.rte");
	print("GlobalFlameHandler:Create()");
end
--To-do: multiple flames close to each other should form a bigger flame
function Update(self)
	self.PinStrength = 900001;
	local flameCount = 0;
	local nearbyFlame = {};
	if #Flames ~= 0 then
		for i = 1, #Flames do
			if Flames[i] and Flames[i].particle and MovableMan:ValidMO(Flames[i].particle) then
			
				flameCount = flameCount + 1;
		
				local flame = Flames[i].particle;
				local ageRatio = flame.Age/flame.Lifetime;
				flame.ToSettle = false;
				flame.Throttle = flame.Throttle - TimerMan.DeltaTimeMS/flame.Lifetime;
				
				if Flames[i].target and Flames[i].target.ID ~= rte.NoMOID and not Flames[i].target.ToDelete then
					flame.Vel = Flames[i].target.Vel;
					flame.Pos = Flames[i].target.Pos + Vector(Flames[i].stickOffset.X, Flames[i].stickOffset.Y):RadRotate(Flames[i].target.RotAngle - Flames[i].targetStickAngle);
					local actor = Flames[i].target:GetRootParent();
					if MovableMan:IsActor(actor) then
						actor = ToActor(actor);
						actor.Health = actor.Health - (Flames[i].target.DamageMultiplier + flame.Throttle)/(actor.Mass * 0.5 + Flames[i].target.Material.StructuralIntegrity * 0.75);
						--Stop, drop and roll!
						flame.Lifetime = flame.Lifetime - math.abs(actor.AngularVel);
					end
				else
					Flames[i].target = nil;
					if math.random() > ageRatio then
						if flame.Vel.Magnitude > 1 then
							local checkPos = Vector(flame.Pos.X, flame.Pos.Y - 1) + flame.Vel * rte.PxTravelledPerFrame * math.random();
							local moCheck = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
							if moCheck ~= rte.NoMOID then
								local mo = MovableMan:GetMOFromID(moCheck);
								if mo and (flame.Team == Activity.NOTEAM or mo.Team ~= flame.Team) then
									Flames[i].target = ToMOSRotating(mo);
									
									Flames[i].isShort = true;
									Flames[i].deleteDelay = math.random(flame.Lifetime);
									
									Flames[i].targetStickAngle = mo.RotAngle;	
									Flames[i].stickOffset = SceneMan:ShortestDistance(mo.Pos, flame.Pos, SceneMan.SceneWrapsX) * 0.8;
									
									flame.GlobalAccScalar = 0.9;
								end
							elseif flame.GlobalAccScalar < 0.5 and Flames[i].isShort and math.random() < 0.2 and SceneMan:GetTerrMatter(checkPos.X, checkPos.Y) ~= rte.airID then
								Flames[i].deleteDelay = math.random(flame.Lifetime);
								flame.GlobalAccScalar = 0.9;
							end
						end
						if not Flames[i].isShort then
							--Combine two flames into one
							if flame.Throttle < 0 then
								for n = 1, #nearbyFlame do
									local dist = SceneMan:ShortestDistance(flame.Pos + flame.Vel * rte.PxTravelledPerFrame, nearbyFlame[n].Pos, SceneMan.SceneWrapsX);
									if dist.Magnitude < 2 then
										flame.Lifetime = flame.Lifetime + nearbyFlame[n].Lifetime * 0.5;
										flame.Throttle = flame.Throttle + nearbyFlame[n].Throttle + 1;
										flame.Pos = flame.Pos + dist * 0.5;
										nearbyFlame[n].ToDelete = true;
										--[[To-do: spawn a new, bigger flame particle altogether?
										local newFlame = CreatePEmitter("Big Flame", "Base.rte");
										newFlame.Lifetime = flame.Lifetime;
										newFlame.Pos = flame.Pos;
										newFlame.Vel = flame.Vel;
										MovableMan:AddParticle(newFlame);
										Flames[i].particle = newFlame;
										Flames[i].isShort = true;
										flame.ToDelete = true;
										flame = newFlame;
										]]--
										break;
									end
								end
								table.insert(nearbyFlame, flame);
							end
							if math.random() < (1 + flame.Throttle) * 0.1 then
								--Spawn another, shorter flame particle occasionally
								local particle = self.shortFlame:Clone();
								particle.Lifetime = particle.Lifetime * RangeRand(0.6, 0.9);
								particle.Vel = flame.Vel + Vector(0, -3) + Vector(math.random(), 0):RadRotate(math.random() * math.pi * 2);
								particle.Pos = Vector(flame.Pos.X, flame.Pos.Y - 1);
								MovableMan:AddParticle(particle);
							end
						end
						if Flames[i].deleteDelay and flame.Age > Flames[i].deleteDelay then
							flame.ToDelete = true;
						end
					end
				end
			else
				Flames[i] = {};
			end
		end
		if flameCount == 0 then
			--Clear the global table
			Flames = {};
		end
	end
end
function Destroy(self)
	GlobalFlameHandler = nil;
	print("GlobalFlameHandler:Destroy()");
end