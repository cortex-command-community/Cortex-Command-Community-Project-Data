function Create(self)
	self.TargetingTimer = Timer()
	self.maxDelay = 150
	self.targetingDelay = self.maxDelay
	self.lockActor = 0
	self.lockTerrain = 0
	
	function self:Reset()
		self.TargetingTimer:Reset()
		self.targetingDelay = self.maxDelay
		self.lockActor = 0
		self.lockTerrain = 0
	end
end

function Update(self)
	if self.ID ~= self.RootID then
		if self.RoundInMagCount > 0 then
			if not self:IsActivated() then
				self:Reset()
			elseif self.TargetingTimer:IsPastSimMS(self.targetingDelay) then
				self.TargetingTimer:Reset()
				
				local StartPoint
				local Parent = MovableMan:GetMOFromID(self.RootID)
				if Parent then
					Parent = ToActor(Parent)
					if Parent then
						StartPoint = Parent.ViewPoint	-- trace from the sharp aim location
					end
				else
					StartPoint = self.MuzzlePos
				end
				
				local playSound = false
				local Free = Vector()
				local TargetHitPos = Vector()
				local Trace = self:RotateOffset(Vector(SceneMan.SceneWidth*0.5, 0))
				local pixels = SceneMan:CastObstacleRay(StartPoint, Trace, TargetHitPos, Free, 0, self.Team, rte.grassID, 7)
				
				-- we hit someting
				if pixels > -1 then
					-- did we hit a MO?
					local ID = SceneMan:CastMORay(Free, self:RotateOffset(Vector(-10, 0)), 0, self.Team, rte.grassID, false, 3)
					if ID < rte.NoMOID and ID > 0 then
						self.targetingDelay = self.targetingDelay * 0.8
						self.lockActor = self.lockActor + 30
						self.lockTerrain = math.max(self.lockTerrain-7, 0)
						playSound = true
					else	-- we did not hit any MO
						self.lockActor = math.max(self.lockActor-5, 0)
						
						if self.LastTargetHitPos and SceneMan:ShortestDistance(self.LastTargetHitPos, TargetHitPos, false).Largest < 30 then
							self.targetingDelay = self.targetingDelay * 0.8
							self.lockTerrain = self.lockTerrain + 30
							playSound = true
						else
							self.targetingDelay = math.min(self.targetingDelay*1.6, self.maxDelay)
							self.lockTerrain = math.max(self.lockTerrain-7, 0)
						end
							
						self.LastTargetHitPos = TargetHitPos
					end
					
					if self.lockActor > 150 or self.lockTerrain > 150 then
						self.Magazine.RoundCount = self.RoundInMagCount - 1
						
						local Missile = CreateAEmitter("Direct Attack Missile", "Browncoats.rte")
						if Missile then
							-- Spin the missile so the nose moves upwards
							if self.HFlipped then
								Missile.AngularVel = -1
							else
								Missile.AngularVel = 1
							end
							
							if self.RoundInMagCount > 0 then
								Missile.Pos = self.Pos + self:RotateOffset(Vector(17, -3))
							else
								Missile.Pos = self.Pos + self:RotateOffset(Vector(17, 1))
							end
							
							Missile.Team = self.Team
							Missile.IgnoresTeamHits = true
							Missile.Vel = self:RotateOffset(Vector(9, -4))
							Missile.RotAngle = Missile.Vel.AbsRadAngle
							Missile.Vel = Missile.Vel + self.Vel
							
							-- Ugly hack warning: using Sharpness, Mass and OnlyLinearForces to set the missile's target pos
							if Free.Largest > 0 then
								Missile.Sharpness = math.floor(Free.X)
								Missile.Mass = math.floor(Free.Y)
							else
								Missile.Sharpness = math.floor(TargetHitPos.X)
								Missile.Mass = math.floor(TargetHitPos.Y)
							end
							
							if self.lockActor > self.lockTerrain then
								Missile.OnlyLinearForces = true	-- The target is an actor
							end
							
							MovableMan:AddMO(Missile)
							
							local Blast = CreateAEmitter("Back Blast", "Browncoats.rte")
							if Blast then
								Blast.Pos = self.Pos + self:RotateOffset(Vector(-18, 0))
								Blast.Vel = self.Vel
								Blast.Team = self.Team
								Blast.RotAngle = self:RotateOffset(Vector(-1, 0)).AbsRadAngle
								Blast.IgnoresTeamHits = true
								MovableMan:AddMO(Blast)
							end
							
							Blast = CreateAEmitter("Muzzle Blast", "Browncoats.rte")
							if Blast then
								Blast.Pos = Missile.Pos
								Blast.Vel = self.Vel
								Blast.Team = self.Team
								Blast.RotAngle = self:RotateOffset(Vector(1, 0)).AbsRadAngle
								Blast.IgnoresTeamHits = true
								MovableMan:AddMO(Blast)
							end
						end
						
						self:Reset()
						self.targetingDelay = 600
					elseif playSound then
						local Sound = CreateAEmitter("Rocket Launcher Lock Sound", "Browncoats.rte")
						if Sound then
							Sound.Vel = self.Vel
							Sound.Pos = self.MuzzlePos
							Sound.Team = self.Team
							MovableMan:AddMO(Sound)
						end
						
						local Glow = CreateMOPixel("Rocket Launcher Lock Particle", "Browncoats.rte")
						if Glow then
							if Free.Largest > 0 then
								Glow.Pos = Free
							else
								Glow.Pos = TargetHitPos
							end
							
							Sound.Team = self.Team
							MovableMan:AddMO(Glow)
						end
					end
				else
					self.targetingDelay = math.min(self.targetingDelay*1.6, self.maxDelay)
					self.lockActor = math.max(self.lockActor-5, 0)
					self.lockTerrain = math.max(self.lockTerrain-5, 0)
				end
			end
		else
			self:Reset()
		end
	end
end

--[[
function DirectAttack(Actor)
	local Weapon = ToAHuman(Actor).EquippedItem
	if Weapon then
		Weapon.Sharpness = 1	-- Ugly hack warning: using Sharpness to communicate between pie menu and weapon script
	end
end

function TopAttack(Actor)
	local Weapon = ToAHuman(Actor).EquippedItem
	if Weapon then
		Weapon.Sharpness = 2
	end
end
]]
