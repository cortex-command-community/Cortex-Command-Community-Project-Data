HumanFunctions = {};

function HumanFunctions.DoAlternativeGib(actor)
	-- Detach limbs instead of regular gibbing
	if not actor.detachLimit then
		actor.detachLimit = actor.GibWoundLimit;
		actor.GibWoundLimit = actor.GibWoundLimit * 1.5;
	end
	if actor.WoundCount > actor.detachLimit then
		actor.detachLimit = actor.WoundCount + 1;
		local parts = {actor.BGArm, actor.BGLeg, actor.FGArm, actor.FGLeg, actor.Head};	-- Piority order
		local mostWounds = -1;
		local detachLimb;
		-- Pick the limb with most wounds and detach it
		for i = 1, #parts do
			local limb = parts[i];
			if limb and limb.WoundCount > mostWounds then
				detachLimb = limb;
				mostWounds = limb.WoundCount;
			end
		end
		if detachLimb then
			detachLimb.JointStrength = -1;
		end
	end
end
	
function HumanFunctions.DoAutomaticEquip(actor)
	-- Equip a weapon automatically if the one held by a player is destroyed
	if actor:IsPlayerControlled() and actor.EquippedItem == nil and actor.InventorySize > 0 and not actor.controller:IsState(Controller.WEAPON_FIRE) then
		actor:EquipFirearm(true);
	end
end

function HumanFunctions.DoArmSway(actor, pushStrength)
	-- Control arm movements
	if not actor.lastHandPos then
		actor.lastAngle = actor:GetAimAngle(false);
		actor.lastHandPos = {actor.Pos, actor.Pos};
	end
	if actor.controller:IsMouseControlled() then
		-- Flail around if moving mouse too fast
		local mouseVec = Vector(actor.controller.MouseMovement.X, actor.controller.MouseMovement.Y):SetMagnitude(math.sqrt(actor.controller.MouseMovement.Magnitude));
		local ang = actor.lastAngle - actor:GetAimAngle(false);

		actor.AngularVel = actor.AngularVel - (2 * ang * actor.FlipFactor + mouseVec.Y * actor.FlipFactor /10) /math.sqrt(math.abs(actor.AngularVel) + 1);
		
		actor.lastAngle = actor:GetAimAngle(false);
	end
	-- Shove when unarmed
	if actor.controller:IsState(Controller.WEAPON_FIRE) and (actor.FGArm or actor.BGArm) and not (actor.EquippedItem or actor.EquippedBGItem) and actor.Status == Actor.STABLE then
		actor.AngularVel = actor.AngularVel /(actor.shoved and 1.5 or 3) + (actor:GetAimAngle(false) - actor.RotAngle * actor.FlipFactor - 1.57) * (actor.shoved and 0.5 or 3) * actor.FlipFactor /(1 + math.abs(actor.RotAngle));
		if not actor.shoved then
			actor.Vel = actor.Vel + Vector(3 /(1 + actor.Vel.Magnitude), 0):RadRotate(actor:GetAimAngle(true)) * math.abs(math.cos(actor:GetAimAngle(true)));
			actor.shoved = true;
		end
	else
		actor.shoved = false;
	end
	local arms = {{actor.FGArm, actor.FGLeg, actor.BGLeg}, {actor.BGArm, actor.BGLeg, actor.FGLeg}};
	for i = 1, #arms do
		local arm = arms[i][1];
		if arm then
			local arm = ToArm(arms[i][1]);
			local armLength = ToMOSprite(arm):GetSpriteWidth();
			local rotAng = actor.RotAngle - (1.57 * actor.FlipFactor);
			local legMain = arms[i][2];
			local legAlt = arms[i][3];
			
			if actor.controller:IsState(Controller.MOVE_LEFT) or actor.controller:IsState(Controller.MOVE_RIGHT) then
				if legAlt then
					rotAng = legAlt.RotAngle;
				elseif legMain then
					rotAng = -legMain.RotAngle + math.pi;
				end
			elseif legMain then
				rotAng = legMain.RotAngle;
			end
			-- Flail arms in tandem with leg movement
			ToArm(arm).IdleOffset = Vector(0, armLength * 0.7):RadRotate(rotAng * actor.FlipFactor + 1.5 + (i /5));
			
			if actor.shoved or (actor.EquippedItem and IsTDExplosive(actor.EquippedItem) and actor.controller:IsState(Controller.WEAPON_FIRE)) then
				arm.IdleOffset = Vector(armLength, 0):RadRotate(actor:GetAimAngle(false));
				local dist = SceneMan:ShortestDistance(actor.lastHandPos[i], arm.HandPos, SceneMan.SceneWrapsX);
		
				local dots = math.sqrt(arm.Radius) * (arm.Frame /arm.FrameCount);
				
				for i = 1, dots do
					local part = CreateMOPixel("Smack Particle Light");
					part.Pos = arm.HandPos;
					part.Vel = (actor.Vel + dist):SetMagnitude(math.sqrt(dist.Magnitude * pushStrength + math.abs(actor.AngularVel) * actor.Vel.Magnitude)):RadRotate(0.8 /dots * i) + Vector(0, -0.5);
					part.Mass = (arm.Mass + arm.Material.StructuralIntegrity) * pushStrength;	part.Sharpness = math.random() * 0.1;
					part.Team = actor.Team;	part.IgnoresTeamHits = true;
					MovableMan:AddParticle(part);
				end
			end
			actor.lastHandPos[i] = arm.HandPos;
		end
	end
end

function HumanFunctions.DoVisibleInventory(actor, showAll)
	-- Visualize inventory with primitive bitmaps
	if actor.Status < Actor.DYING and not actor:IsInventoryEmpty() then
		local heldCount, thrownCount, largestItem = 0, 0, 0;
		for i = 1, actor.InventorySize do
			local item = actor:Inventory();
			if item then
				local fixNum = actor.HFlipped and -1 or 0;	-- Fix offsets slightly when facing left
				if item.ClassName == "TDExplosive" then
					thrownCount = thrownCount + 1;
				elseif item.ClassName == "HDFirearm" or item.ClassName == "HeldDevice" then
					if showAll or (not showAll and item.Radius > largestItem) then
						largestItem = item.Radius;
						heldCount = heldCount + 1;

						local isFirearm = item.ClassName == "HeldDevice" and 0 or 1;
						local actorSize, itemSize = math.sqrt(actor.Radius), math.sqrt(item.Radius + math.abs(item.Mass));

						fixNum = fixNum + item.Radius * 0.2 + math.sqrt(heldCount);

						-- Bigger actors carry weapons higher up, smaller weapons are carried lower down
						local drawPos = actor.Pos + Vector((-actorSize - fixNum) * actor.FlipFactor, -actorSize - itemSize + 1 + isFirearm * 3):RadRotate(actor.RotAngle);

						local itemCount = math.sqrt(math.abs(actor.InventorySize - thrownCount));
						
						-- Display tall objects upright
						local tallAng = 1.57;
						if ToMOSprite(item):GetSpriteWidth() < ToMOSprite(item):GetSpriteHeight() then
							tallAng = 0;
						end
						local tilt = 0.3;
						local rotAng = actor.RotAngle + tallAng + (heldCount * tilt - itemCount * tilt + isFirearm /itemSize) /itemCount * actor.FlipFactor;

						for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
							local screen = ActivityMan:GetActivity():ScreenOfPlayer(actor.controller.Player);
							if not SceneMan:IsUnseen(drawPos.X, drawPos.Y, ActivityMan:GetActivity():GetTeamOfPlayer(player)) then
								FrameMan:DrawBitmapPrimitive(screen, drawPos, item, rotAng, 0);
							end
						end
					end
				end
				actor:SwapNextInventory(item, true);
			end
		end
	end
end