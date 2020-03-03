function Create(self)
	self.turnSpeed = 0.015;	-- Speed of the turret turning, in rad per frame
	self.searchRange = 250;	-- Detection area diameter or max ray distance to search enemies from, in px
	-- Whether turret searches for enemies in a larger area. Default mode is a narrower ray detection
	self.areaMode = true;
	-- Toggle visibility of the aim area / trace to see how the detection works
	self.showAim = false;
	-- Angle alteration variables (do not touch)
	self.rotNum = 0;	-- Left / Right
	self.vertiNum = 0;	-- Up / Down
end

function Update(self)

	local mo = self:GetParent();
	if mo and IsActor(mo) then
	
		local parent = ToActor(mo);

		local ctrl = parent:GetController();
	
		if ctrl:IsState(Controller.MOVE_RIGHT) then
			self.rotNum = self.rotNum + self.turnSpeed;
		end
		if ctrl:IsState(Controller.MOVE_LEFT) then
			self.rotNum = self.rotNum - self.turnSpeed;
		end
		-- Spread / tighten aim when moving up / down
		if ctrl:IsState(Controller.MOVE_DOWN) then
			self.vertiNum = self.vertiNum - self.turnSpeed;
		end
		if math.abs(self.rotNum) > 0.001 then
			self.rotNum = self.rotNum / (1 + self.turnSpeed * 2);
		else
			self.rotNum = 0;
		end
		if math.abs(self.vertiNum) > 0.001 then
			self.vertiNum = self.vertiNum / (1 + self.turnSpeed * 4);
		else
			self.vertiNum = 0;
		end
		-- Aim directly away from parent ship
		local posTrace = SceneMan:ShortestDistance(parent.Pos, self.Pos, SceneMan.SceneWrapsX):SetMagnitude(self.searchRange / 2);
		self.RotAngle = (1.57 * self.vertiNum + posTrace.AbsRadAngle) / (1 + self.vertiNum) - self.rotNum;
		if self.areaMode then	-- Area Mode
			local aimPos = self.Pos + Vector((self.searchRange / 2), 0):RadRotate(self.RotAngle);
		
			-- Debug: visualize aim area
			if self.showAim then
				FrameMan:DrawCirclePrimitive(self.Team, aimPos, (self.searchRange / 2), 13);
			end
			
			local aimTarget = MovableMan:GetClosestEnemyActor(self.Team, aimPos, (self.searchRange / 2), Vector());
			if aimTarget then
			
				-- Debug: visualize search trace
				if self.showAim then
					FrameMan:DrawLinePrimitive(self.Team, aimPos, aimTarget.Pos, 13);
				end
			
				-- Check that the target isn't obscured by terrain
				local aimTrace = SceneMan:ShortestDistance(self.Pos, aimTarget.Pos, SceneMan.SceneWrapsX);
				local terrCheck = SceneMan:CastStrengthRay(self.Pos, aimTrace, 30, Vector(), 5, 0, SceneMan.SceneWrapsX);

				if terrCheck == false then
					self.RotAngle = aimTrace.AbsRadAngle;
					-- Debug: visualize aim trace
					if self.showAim then
						FrameMan:DrawLinePrimitive(self.Team, self.Pos, aimTarget.Pos, 254);
					end
					self:EnableEmission(true);
					self:TriggerBurst();	-- Fire!
				end
			end
		else	-- Default Mode
			local target;
			local aimTrace = Vector(self.searchRange, 0):RadRotate(self.RotAngle);
			-- Search for MOs directly in line of sight of two rays
			local mocheck1 = SceneMan:CastMORay(self.Pos, aimTrace:RadRotate(1 / math.sqrt(self.searchRange)), parent.ID, self.Team, 0, false, 5);
			if mocheck1 ~= 255 then
				target = MovableMan:GetMOFromID(MovableMan:GetMOFromID(mocheck1).RootID);
			else
				local mocheck2 = SceneMan:CastMORay(self.Pos, aimTrace:RadRotate(-1 / math.sqrt(self.searchRange)), parent.ID, self.Team, 0, false, 5);
				if mocheck2 ~= 255 then
					target = MovableMan:GetMOFromID(MovableMan:GetMOFromID(mocheck2).RootID);
				end
			end
			local color = 13;	-- Debug trace color: red
			if target and IsActor(target) then
				self:EnableEmission(true);
				self:TriggerBurst();	-- Fire!
				
				if self:IsSetToBurst() then
					color = 254;	-- Debug trace color: white
				end
			end
			-- Debug: visualize aim traces
			if self.showAim then
				FrameMan:DrawLinePrimitive(self.Team, self.Pos, self.Pos + aimTrace:RadRotate(1 / math.sqrt(self.searchRange)), color);
				FrameMan:DrawLinePrimitive(self.Team, self.Pos, self.Pos + aimTrace:RadRotate(-1 / math.sqrt(self.searchRange)), color);
			end
		end
	end
end