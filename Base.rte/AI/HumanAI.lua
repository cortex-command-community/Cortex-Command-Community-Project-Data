dofile("Base.rte/Constants.lua")
require("AI/NativeHumanAI")

function Create(self)
	self.AI = NativeHumanAI:Create(self);

	-- You can turn features on and off here
	self.armSway = true;
	self.autoEquip = false;
	self.alternativeGib = true;
	self.visibleInventory = true;

	self.pushStrength = 10;	-- Variable
	self.tilt = 0.3;	-- Visible inventory item angle

	self.lastAngle = self:GetAimAngle(false);

	if self.armSway == true then
		self.lastHandPos = {self.Pos, self.Pos};
	end
	
	if self.alternativeGib == true then
		self.detachLimit = self.GibWoundLimit;
		self.GibWoundLimit = self.GibWoundLimit * 1.5;
	end
end

function Update(self)

	self.ctrl = self:GetController();
	
	-- Detach limbs instead of regular gibbing
	if self.alternativeGib == true then
		if self.WoundCount > self.detachLimit then
			self.detachLimit = self.WoundCount + 1;
			local parts = {self.BGArm, self.BGLeg, self.FGArm, self.FGLeg, self.Head};	-- Piority order
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
	
	-- Equip a weapon automatically if the one held is destroyed
	if self.autoEquip == true then
		if self:IsPlayerControlled() and self.EquippedItem == nil and self.InventorySize > 0 then
			self:EquipFirearm(true);
		end
	end
	
	-- Flail around if moving mouse too fast
	if self.ctrl:IsMouseControlled() then

		local mouseVec = Vector(self.ctrl.MouseMovement.X, self.ctrl.MouseMovement.Y):SetMagnitude(math.sqrt(self.ctrl.MouseMovement.Magnitude));
		local ang = self.lastAngle - self:GetAimAngle(false);

		self.AngularVel = self.AngularVel - (2 * ang * self.FlipFactor + mouseVec.Y * self.FlipFactor / 10) / math.sqrt(math.abs(self.AngularVel) + 1);
	end
	
	-- Shove when unarmed
	if not (self.EquippedItem or self.EquippedBGItem) and self.ctrl:IsState(Controller.WEAPON_FIRE) and self.Status < 1 and (self.FGArm or self.BGArm) then
		if self.shoved ~= true then
			self.AngularVel = self.AngularVel / 3 + (self:GetAimAngle(false) - 1.57) * 3 * self.FlipFactor / (1 + math.abs(self.RotAngle));
			self.Vel = self.Vel + Vector(3 / (1 + self.Vel.Magnitude), 0):RadRotate(self:GetAimAngle(true)) * math.abs(math.cos(self:GetAimAngle(true)));
			self.shoved = true;
		end
	else
		self.shoved = false;
	end
	
	-- Controlling the arm movements
	local arms = {{self.FGArm, self.FGLeg, self.BGLeg}, {self.BGArm, self.BGLeg, self.FGLeg}};
	for i = 1, #arms do
		local arm = arms[i][1];
		if arm then
			local arm = ToArm(arms[i][1]);
			local armLength = ToMOSprite(arm):GetSpriteWidth();
			local rotAng = self.RotAngle - (1.57 * self.FlipFactor);
			local legMain = arms[i][2];
			local legAlt = arms[i][3];
			
			if legMain and not (self.ctrl:IsState(Controller.MOVE_LEFT) or self.ctrl:IsState(Controller.MOVE_RIGHT)) then
				rotAng = legMain.RotAngle;
			elseif legAlt then
				rotAng = legAlt.RotAngle;
			end
			
			-- Flail arms in tandem with leg movement
			ToArm(arm).IdleOffset = Vector(0, armLength * 0.7):RadRotate(rotAng * self.FlipFactor + 1.5 + (i / 5));
			
			if self.shoved == true or (self.EquippedItem and IsTDExplosive(self.EquippedItem) and self.ctrl:IsState(Controller.WEAPON_FIRE)) then
				arm.IdleOffset = Vector(armLength, 0):RadRotate(self:GetAimAngle(false));
				local dist = SceneMan:ShortestDistance(self.lastHandPos[i], arm.HandPos, SceneMan.SceneWrapsX);
		
				local dots = math.sqrt(arm.Radius) * (arm.Frame / arm.FrameCount);
				
				for i = 1, dots do
					local part = CreateMOPixel("Smack Particle Light");
					part.Pos = arm.HandPos;
					part.Vel = (self.Vel + dist):SetMagnitude(math.sqrt(dist.Magnitude * self.pushStrength + math.abs(self.AngularVel) * self.Vel.Magnitude)):RadRotate(0.8 / dots * i);
					part.Mass = (arm.Mass + arm.Material.StructuralIntegrity) * self.pushStrength;	part.Sharpness = math.random() * 0.1;
					part.Team = self.Team;	part.IgnoresTeamHits = true;
					MovableMan:AddParticle(part);
				end
			end
			self.lastHandPos[i] = arm.HandPos;
		end
	end
	
	-- Visualize inventory with primitive bitmaps
	if self.visibleInventory then
		if self.Status < 3 and self:IsInventoryEmpty() == false then
			local heldCount = 0;
			local thrownCount = 0;
			for i = 1, self.InventorySize do
				local item = self:Inventory();
				if item then
					local fixNum = self.HFlipped and -1 or 0;	-- Fix offsets slightly when facing left
					if item.ClassName == "TDExplosive" then
						thrownCount = thrownCount + 1;
					elseif item.ClassName == "HDFirearm" or item.ClassName == "HeldDevice" then
						heldCount = heldCount + 1;

						local isFirearm = item.ClassName == "HeldDevice" and 0 or 1;

						local sRad = math.sqrt(self.Radius);
						local iRad = math.sqrt(item.Radius);
						local iMass = math.sqrt(math.abs(item.Mass));

						fixNum = fixNum + item.Radius * 0.2 + math.sqrt(heldCount);

						-- Bigger actors carry weapons higher up
						-- Smaller weapons are carried lower down
						local pos = self.Pos + Vector((-sRad - fixNum) * self.FlipFactor, -sRad - iMass + 1 + isFirearm * 3):RadRotate(self.RotAngle);

						local itemCount = math.sqrt(math.abs(self.InventorySize - thrownCount));
						
						-- Display tall objects upright
						local tallAng = 1.57;
						if ToMOSprite(item):GetSpriteWidth() < ToMOSprite(item):GetSpriteHeight() then
							tallAng = 0;
						end

						local rotAng = self.RotAngle + tallAng + (heldCount * self.tilt - itemCount * self.tilt + isFirearm / iMass) / itemCount * self.FlipFactor;

						for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
							local screen = ActivityMan:GetActivity():ScreenOfPlayer(self.ctrl.Player);
							if not SceneMan:IsUnseen(pos.X, pos.Y, ActivityMan:GetActivity():GetTeamOfPlayer(player)) then
								FrameMan:DrawBitmapPrimitive(screen, pos, item, rotAng, 0);
							end
						end
					end
					self:SwapNextInventory(item, true);
				end
			end
		end
	end
	self.lastAngle = self:GetAimAngle(false);
end

function UpdateAI(self)
	self.AI:Update(self);
end

function Destroy(self)
	self.AI:Destroy(self);
end
