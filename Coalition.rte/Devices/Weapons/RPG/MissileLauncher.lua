
function Create(self)
	self.checkTimer = Timer()
	self.homingTimer = Timer()
end

function Update(self)
	if self.ID == self.RootID then
		return
	end
	
	if self.missile then
		if MovableMan:ValidMO(self.missile) and MovableMan:ValidMO(self.parent) then
			if self.checkTimer:IsPastRealMS(83) then
				self.checkTimer:Reset()
				
				self.lastTarget = self.targetPos
				self.targetPos = self.MuzzlePos + Vector(SceneMan:ShortestDistance(self.missile.Pos,self.MuzzlePos,SceneMan.SceneWrapsX).Magnitude+200,0):RadRotate(self.parent:GetAimAngle(true))
				if SceneMan.SceneWrapsX == true then
					if self.targetPos.X > SceneMan.SceneWidth then
						self.targetPos = Vector(self.targetPos.X - SceneMan.SceneWidth,self.targetPos.Y)
					elseif self.targetPos.X < 0 then
						self.targetPos = Vector(SceneMan.SceneWidth + self.targetPos.X,self.targetPos.Y)
					end
				end

				-- Search our LOS both for terrain and actors
				for i = 1, 100 do
					local checkPos = self.MuzzlePos + Vector((i/100)*1000,0):RadRotate(self.parent:GetAimAngle(true))
					if SceneMan.SceneWrapsX == true then
						if checkPos.X > SceneMan.SceneWidth then
							checkPos = Vector(checkPos.X - SceneMan.SceneWidth,checkPos.Y)
						elseif checkPos.X < 0 then
							checkPos = Vector(SceneMan.SceneWidth + checkPos.X,checkPos.Y)
						end
					end
					local terrCheck = SceneMan:GetTerrMatter(checkPos.X,checkPos.Y)
					if terrCheck == 0 then
						local moCheck = SceneMan:GetMOIDPixel(checkPos.X,checkPos.Y)
						if moCheck ~= rte.NoMOID then
							self.targetPos = checkPos
							break
						end
					else
						self.targetPos = checkPos
						break
					end
				end

				local laserPar = CreateMOPixel("Coalition RPG Laser Particle", "Coalition.rte")
				laserPar.Pos = self.targetPos
				MovableMan:AddParticle(laserPar)

				local drawVector = SceneMan:ShortestDistance(self.lastTarget,self.targetPos,false)
				local drawLine = math.ceil(drawVector.Magnitude/5)
				for i = 1, drawLine do
					local laserPar = CreateMOPixel("Coalition RPG Laser Particle 2", "Coalition.rte")
					laserPar.Pos = self.lastTarget + Vector(i*5,0):RadRotate(drawVector.AbsRadAngle)
					MovableMan:AddParticle(laserPar)
				end
			end
			
			-- Find the velocity vector that will take the missile to the target
			if self.homingTimer:IsPastSimMS(250) then
				local FutureVel = self.missile.Vel + (self.missile.Vel-self.missileLastVel) * 4
				local OptimalVel = SceneMan:ShortestDistance(self.missile.Pos, self.targetPos, false).Normalized
				local angError = math.asin(OptimalVel:Cross(FutureVel.Normalized))	-- The angle between FutureVel and OptimalVel
				
				self.missile.RotAngle = self.missile.RotAngle + math.min(math.max(angError, -0.14), 0.14)	-- Gradually turn towards the optimal velocity vector
				if not self.Magazine or (self.Magazine and self.Magazine.RoundCount < 1) then
					self.parent:GetController():SetState(Controller.WEAPON_RELOAD, true)
				else
					self:Deactivate()	-- Stop the user from shooting again
				end
			end
			
			self.missileLastVel = self.missileLastVel * 0.3 + self.missile.Vel * 0.7	-- Filter the velocity to reduce noise
		else
			self.missile = nil
		end
	end
	
	if not self.missile and self:IsActivated() and self.Magazine then
		if self.Magazine.RoundCount > 0 and self.Magazine.PresetName == "Magazine Coalition Missile Launcher" then
			self.missile = CreateAEmitter("Particle Coalition Missile Launcher", "Coalition.rte")
			if self.missile then
				self.parent = MovableMan:GetMOFromID(self.RootID)
				if MovableMan:IsActor(self.parent) then
					self.parent = ToActor(self.parent)
					self.missile.Team = self.parent.Team
					self.missile.IgnoresTeamHits = true
					self.targetPos = self.parent.ViewPoint
					
					-- Launch the missile slightly upwards, but a bit more for the AI
					self.missile.Vel = self:RotateOffset(Vector(15, 0))
					if self.parent:IsPlayerControlled() then
						self.missile.Vel.Y = self.missile.Vel.Y - 4
					else
						self.missile.Vel.Y = self.missile.Vel.Y - 6
					end
					
					self.missile.Vel = self.missile.Vel + self.Vel
				else
					self.parent = nil
				end
				
				self.missile.RotAngle = self.missile.Vel.AbsRadAngle
				self.missile.Pos = self.MuzzlePos
				MovableMan:AddParticle(self.missile)
				
				self.missileLastVel = Vector(self.missile.Vel.X, self.missile.Vel.Y)
			end
		end
	end
end
