HumanFunctions = {};

function HumanFunctions.DoAlternativeGib(actor)
	--Detach limbs instead of regular gibbing
	if actor.detachLimit then
		if actor.WoundCount > actor.detachLimit then
			actor.detachLimit = actor.WoundCount + 1;
			local parts = {actor.BGArm, actor.BGLeg, actor.FGArm, actor.FGLeg, actor.Head};	--Priority order
			local mostWounds = -1;
			local detachLimb;
			--Pick the limb with most wounds and detach it
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
	elseif actor.GibWoundLimit > 0 then
		actor.detachLimit = actor.GibWoundLimit;
		actor.GibWoundLimit = actor.GibWoundLimit * 1.5;
	end
end
	
function HumanFunctions.DoAutomaticEquip(actor)
	--Equip a weapon automatically if the one held by a player is destroyed
	if actor:IsPlayerControlled() and actor.EquippedItem == nil and actor.InventorySize > 0 and not actor.controller:IsState(Controller.WEAPON_FIRE) then
		actor:EquipFirearm(true);
	end
end

function HumanFunctions.DoArmSway(actor, pushStrength)
	--Control arm movements
	local aimAngle = actor:GetAimAngle(false);
	if not actor.lastHandPos then	--Initialize
		actor.lastAngle = aimAngle;
		actor.lastHandPos = {actor.Pos, actor.Pos};
	end
	--Flail around if aiming around too fast
	local angleMovement = actor.lastAngle - aimAngle;
	actor.AngularVel = actor.AngularVel - (2 * angleMovement * actor.FlipFactor)/(math.abs(actor.AngularVel) * 0.1 + 1);
	actor.lastAngle = aimAngle;
	--Shove when unarmed
	if actor:IsInventoryEmpty() and actor.controller:IsState(Controller.WEAPON_FIRE) and (actor.FGArm or actor.BGArm) and not (actor.EquippedItem or actor.EquippedBGItem) and actor.Status == Actor.STABLE then
		actor.AngularVel = actor.AngularVel/(actor.shoved and 1.3 or 3) + (aimAngle - actor.RotAngle * actor.FlipFactor - 1.57) * (actor.shoved and 0.3 or 3) * actor.FlipFactor/(1 + math.abs(actor.RotAngle));
		if not actor.shoved then
			actor.Vel = actor.Vel + Vector(2/(1 + actor.Vel.Magnitude), 0):RadRotate(actor:GetAimAngle(true)) * math.abs(math.cos(actor:GetAimAngle(true)));
			actor.shoved = true;
		end
	else
		actor.shoved = false;
	end
	local armPairs = {{actor.FGArm, actor.FGLeg, actor.BGLeg}, {actor.BGArm, actor.BGLeg, actor.FGLeg}};
	for i = 1, #armPairs do
		local arm = armPairs[i][1];
		if arm then
			arm = ToArm(arm);
			
			local armLength = ToMOSprite(arm):GetSpriteWidth();
			local rotAng = actor.RotAngle - (1.57 * actor.FlipFactor);
			local legMain = armPairs[i][2];
			local legAlt = armPairs[i][3];
			
			if actor.controller:IsState(Controller.MOVE_LEFT) or actor.controller:IsState(Controller.MOVE_RIGHT) then
				rotAng = (legAlt and legAlt.RotAngle) or (legMain and (-legMain.RotAngle + math.pi) or rotAng);
			elseif legMain then
				rotAng = legMain.RotAngle;
			end
			--Flail arms in tandem with leg movement or raise them them up for a push if aiming
			if actor.controller:IsState(Controller.AIM_SHARP) then
				arm.IdleOffset = Vector(0, 1):RadRotate(aimAngle);
			else
				arm.IdleOffset = Vector(0, (armLength + arm.SpriteOffset.X) * 1.1):RadRotate(rotAng * actor.FlipFactor + 1.5 + (i * 0.2));
			end
			if actor.shoved or (actor.EquippedItem and IsTDExplosive(actor.EquippedItem) and actor.controller:IsState(Controller.WEAPON_FIRE)) then
				arm.IdleOffset = Vector(armLength + (pushStrength * armLength), 0):RadRotate(aimAngle);
				local handVector = SceneMan:ShortestDistance(actor.lastHandPos[i], arm.HandPos, SceneMan.SceneWrapsX);
				--Diminish hand relocation vector to potentially prevent post-superhuman pushing powers
				handVector:SetMagnitude(handVector.Magnitude/(1 + handVector.Magnitude * 0.01));
				--Emphasize the first frames that signify contracted arm = highest potential energy
				local dots = math.sqrt(arm.Radius)/(1 + arm.Frame/arm.FrameCount);
				local armStrength = (arm.Mass + arm.Material.StructuralIntegrity) * pushStrength;
				for i = 1, dots do
					local part = CreateMOPixel("Smack Particle Light");
					part.Pos = arm.HandPos - Vector(handVector.X * 0.5, handVector.Y * 0.5);
					part.Vel = Vector(handVector.X, handVector.Y):RadRotate(RangeRand(-0.1, 0.1)) + Vector(0, -0.5);
					part.Mass = armStrength;	part.Sharpness = math.random() * 0.1;
					part.Team = actor.Team;	part.IgnoresTeamHits = true;
					MovableMan:AddParticle(part);
				end
				--Apply some additional forces if the travel vector of the moving hand is half an arms length
				if handVector.Magnitude > (armLength * 0.5) then
					local moCheck = SceneMan:GetMOIDPixel(arm.HandPos.X, arm.HandPos.Y)
					if moCheck ~= rte.NoMOID then
						local mo = MovableMan:GetMOFromID(MovableMan:GetMOFromID(moCheck).RootID);
						if mo and mo.Team ~= actor.Team and IsActor(mo) and actor.Mass > (mo.Mass * 0.5) then
							mo:AddForce(handVector * (actor.Mass * 0.5), Vector());
							ToActor(mo).Status = Actor.UNSTABLE;
						end
					end
				end
			end
			actor.lastHandPos[i] = arm.HandPos;
		end
	end
end

function HumanFunctions.DoVisibleInventory(actor, showAll)
	--Visualize inventory with primitive bitmaps
	if actor.Status < Actor.DYING and not actor:IsInventoryEmpty() then
		local heldCount, thrownCount, largestItem = 0, 0, 0;
		for i = 1, actor.InventorySize do
			local item = actor:Inventory();
			if item then
				if item.ClassName == "TDExplosive" then
					thrownCount = thrownCount + 1;
				elseif item.ClassName == "HDFirearm" or item.ClassName == "HeldDevice" then
					if showAll or item.Radius + item.Mass > largestItem then
						largestItem = item.Radius + item.Mass;
						heldCount = heldCount + 1;
						local itemCount = math.sqrt(heldCount);

						local actorBack = Vector(ToMOSprite(actor):GetSpriteWidth() + actor.SpriteOffset.X, ToMOSprite(actor):GetSpriteHeight() + actor.SpriteOffset.Y);
						local stackX = item.Radius * 0.2 + itemCount - 0.5;
						--Bigger actors carry weapons higher up, smaller weapons are carried lower down
						local drawPos = actor.Pos + Vector((-actorBack.X * 0.5 - stackX) * actor.FlipFactor, -actorBack.Y * 0.75):RadRotate(actor.RotAngle);
						--Display tall objects upright
						local widthToHeightRatio = ToMOSprite(item):GetSpriteWidth()/ToMOSprite(item):GetSpriteHeight();
						local tallAng = widthToHeightRatio > 1 and 1.57 or 0;

						local tilt = (itemCount/item.Radius) * widthToHeightRatio * actor.FlipFactor;
						local rotAng = actor.RotAngle + tallAng + (tilt * 2) - tilt * (itemCount - 1);

						for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
							local screen = ActivityMan:GetActivity():ScreenOfPlayer(player);
							if screen ~= -1 and not SceneMan:IsUnseen(drawPos.X, drawPos.Y, ActivityMan:GetActivity():GetTeamOfPlayer(player)) then
								PrimitiveMan:DrawBitmapPrimitive(screen, drawPos, item, rotAng, 0);
							end
						end
					end
				end
				actor:SwapNextInventory(item, true);
			end
		end
	end
end