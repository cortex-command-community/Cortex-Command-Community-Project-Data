
require("Actors/AI/HumanBehaviors")

NativeHumanAI = {}

function NativeHumanAI:Create(Owner)
	local Members = {}
	
	Members.lateralMoveState = Actor.LAT_STILL
	Members.proneState = AHuman.NOTPRONE
	Members.jumpState = AHuman.NOTJUMPING
	Members.deviceState = AHuman.STILL
	Members.lastAIMode = Actor.AIMODE_NONE
	Members.teamBlockState = Actor.NOTBLOCKED
	Members.SentryFacing = Owner.HFlipped
	Members.fire = false
	Members.groundContact = 5
	
	-- timers
	Members.AirTimer = Timer()
	Members.PickUpTimer = Timer()
	Members.ReloadTimer = Timer()
	Members.BlockedTimer = Timer()
	Members.SquadShootTimer = Timer()
	
	Members.AlarmTimer = Timer()
	Members.AlarmTimer:SetSimTimeLimitMS(400)
	
	Members.TargetLostTimer = Timer()
	Members.TargetLostTimer:SetSimTimeLimitMS(1000)
	
	if Owner:HasObjectInGroup("Brains") or Owner:HasObjectInGroup("Snipers") then
		Members.SpotTargets = HumanBehaviors.CheckEnemyLOS
	else
		Members.SpotTargets = HumanBehaviors.LookForTargets
	end
	
	-- check if this team is controlled by a human
	if ActivityMan:GetActivity():IsPlayerTeam(Owner.Team) then
		Members.isPlayerOwned = true
		Members.PlayerInterferedTimer = Timer()
		Members.PlayerInterferedTimer:SetSimTimeLimitMS(500)
	end
	
	-- set shooting skill
	Members.aimSpeed, Members.aimSkill = HumanBehaviors.GetTeamShootingSkill(Owner.Team)
	
	-- the native AI assume the jetpack cannot be destroyed
	if Owner.Jetpack then
		if not Members.isPlayerOwned then
			Owner.Jetpack.Throttle = 0.15	-- increase jetpack strength slightly to compensate for AI ineptitude
		end
		
		Members.jetImpulseFactor = Owner.Jetpack:EstimateImpulse(false) * FrameMan.PPM / TimerMan.DeltaTimeSecs
		Members.jetBurstFactor = (Owner.Jetpack:EstimateImpulse(true) * FrameMan.PPM / TimerMan.DeltaTimeSecs - Members.jetImpulseFactor) * math.pow(TimerMan.DeltaTimeSecs, 2) * 0.5
		Members.minBurstTime = math.min(Owner.Jetpack.BurstSpacing*2, Owner.JetTimeTotal*0.99)	-- in milliseconds
	end
	
	setmetatable(Members, self)
	self.__index = self
	return Members
end

function NativeHumanAI:Update(Owner)
	self.Ctrl = Owner:GetController()
	
	if self.isPlayerOwned then
		if self.PlayerInterferedTimer:IsPastSimTimeLimit() then
			-- Tell the coroutines to abort to avoid memory leaks
			if self.Behavior then
				local msg, done = coroutine.resume(self.Behavior, self, Owner, true)
			end			
		
			self.Behavior = nil	-- remove the current behavior
			self.BehaviorName = nil
			if self.BehaviorCleanup then
				self.BehaviorCleanup(self)	-- clean up after the current behavior
				self.BehaviorCleanup = nil
			end

			-- Tell the coroutines to abort to avoid memory leaks
			if self.GoToBehavior then
				local msg, done = coroutine.resume(self.GoToBehavior, self, Owner, true)
			end	
			
			self.GoToBehavior = nil
			self.GoToName = nil
			if self.GoToCleanup then
				self.GoToCleanup(self)
				self.GoToCleanup = nil
			end
			
			self.Target = nil
			self.UnseenTarget = nil
			self.OldTargetPos = nil
			self.PickupHD = nil
			self.BlockingMO = nil
			
			self.fire = false
			self.canHitTarget = false
			self.jump = false
			
			self.proneState = AHuman.NOTPRONE
			self.SentryFacing = Owner.HFlipped
			self.deviceState = AHuman.STILL
			self.lastAIMode = Actor.AIMODE_NONE
			self.teamBlockState = Actor.NOTBLOCKED
			
			if Owner.EquippedItem then
				self.PlayerPreferredHD = Owner.EquippedItem.PresetName
			else
				self.PlayerPreferredHD = nil
			end
		end
		
		self.PlayerInterferedTimer:Reset()
	end
	
	if self.Target and not MovableMan:ValidMO(self.Target) then
		self.Target = nil
	end
	
	if self.UnseenTarget and not MovableMan:ValidMO(self.UnseenTarget) then
		self.UnseenTarget = nil
	end
	
	-- switch to the next behavior, if available
	if self.NextBehavior then
		if self.BehaviorCleanup then
			self.BehaviorCleanup(self)
		end
		
		-- Tell the coroutines to abort to avoid memory leaks
		if self.Behavior then
			local msg, done = coroutine.resume(self.Behavior, self, Owner, true)
		end		
		
		self.Behavior = self.NextBehavior
		self.BehaviorCleanup = self.NextCleanup
		self.BehaviorName = self.NextBehaviorName
		
		self.NextBehavior = nil
		self.NextCleanup = nil
		self.NextBehaviorName = nil
	end
	
	-- switch to the next GoTo behavior, if available
	if self.NextGoTo then
		if self.GoToCleanup then
			self.GoToCleanup(self)
		end
		
		-- Tell the coroutines to abort to avoid memory leaks
		if self.GoToBehavior then
			local msg, done = coroutine.resume(self.GoToBehavior, self, Owner, true)
		end
		
		self.GoToBehavior = self.NextGoTo
		self.GoToCleanup = self.NextGoToCleanup
		self.GoToName = self.NextGoToName
		
		self.NextGoTo = nil
		self.NextGoToCleanup = nil
		self.NextGoToName = nil
	end
	
	-- check if the AI mode has changed or if we need a new behavior
	if Owner.AIMode ~= self.lastAIMode or not(self.Behavior or self.GoToBehavior) then
		-- Tell the coroutines to abort to avoid memory leaks
		if self.Behavior then
			local msg, done = coroutine.resume(self.Behavior, self, Owner, true)
		end		
	
		self.Behavior = nil
		if self.BehaviorCleanup then
			self.BehaviorCleanup(self)	-- stop the current behavior
			self.BehaviorCleanup = nil
		end
		
		-- Tell the coroutines to abort to avoid memory leaks
		if self.GoToBehavior then
			local msg, done = coroutine.resume(self.GoToBehavior, self, Owner, true)
		end			
		
		self.GoToBehavior = nil
		if self.GoToCleanup then
			self.GoToCleanup(self)
			self.GoToCleanup = nil
		end
		
		-- select a new behavior based on AI mode
		if Owner.AIMode == Actor.AIMODE_GOTO or Owner.AIMode == Actor.AIMODE_SQUAD then
			self:CreateGoToBehavior(Owner)
		elseif Owner.AIMode == Actor.AIMODE_BRAINHUNT then
			self:CreateBrainSearchBehavior(Owner)
		elseif Owner.AIMode == Actor.AIMODE_GOLDDIG then
			self:CreateGoldDigBehavior(Owner)
		elseif Owner.AIMode == Actor.AIMODE_PATROL then
			self:CreatePatrolBehavior(Owner)
		else
			if Owner.AIMode ~= self.lastAIMode and Owner.AIMode == Actor.AIMODE_SENTRY then
				self.SentryFacing = Owner.HFlipped	-- store the direction in which we should be looking
				self.SentryPos = Vector(Owner.Pos.X, Owner.Pos.Y)	-- store the pos on which we should be standing
			end
			
			self:CreateSentryBehavior(Owner)
		end
		
		self.lastAIMode = Owner.AIMode
	end
	
	
	-- check if the legs reach the ground
	if self.AirTimer:IsPastSimMS(120) then
		self.AirTimer:Reset()
		
		local Origin
		if Owner.FGLeg then
			Origin = Owner.FGLeg.Pos
		elseif Owner.BGLeg then
			Origin = Owner.BGLeg.Pos
		else
			Origin = Owner.Pos
		end
		
		if -1 < SceneMan:CastObstacleRay(Origin, Vector(RangeRand(-8, 8), Owner.Height*0.17), Vector(), Vector(), Owner.ID, Owner.IgnoresWhichTeam, rte.grassID, 3) then
			self.groundContact = 3
		else
			self.groundContact = self.groundContact - 1
		end
		
		self.flying = false
		if self.groundContact < 0 then
			self.flying = true
		end
		
		Owner:EquipShieldInBGArm()	-- try to equip a shield
	end
	
	-- look for targets
	local FoundMO, HitPoint = self.SpotTargets(self, Owner)	
	if FoundMO then
		if self.Target and MovableMan:ValidMO(self.Target) and FoundMO.ID == self.Target.ID then	-- found the same target
			self.OldTargetPos = Vector(self.Target.Pos.X, self.Target.Pos.Y)
			self.TargetOffset = SceneMan:ShortestDistance(self.Target.Pos, HitPoint, false)
			self.TargetLostTimer:Reset()
			self.ReloadTimer:Reset()
		else
			if FoundMO.Team == Owner.Team then	-- found an ally
				if self.Target then
					if SceneMan:ShortestDistance(Owner.Pos, FoundMO.Pos, false).Magnitude <
						SceneMan:ShortestDistance(Owner.Pos, self.Target.Pos, false).Magnitude
					then
						self.Target = nil	-- stop shooting
					end
				elseif FoundMO.ClassName ~= "ADoor" and
					SceneMan:ShortestDistance(Owner.Pos, FoundMO.Pos, false).Magnitude < Owner.Diameter + FoundMO.Diameter
				then
					self.BlockingMO = FoundMO	-- this MO is blocking our path
				end
			else
				if FoundMO.ClassName == "AHuman" then
					FoundMO = ToAHuman(FoundMO)
				elseif FoundMO.ClassName == "ACrab" then
					FoundMO = ToACrab(FoundMO)
				elseif FoundMO.ClassName == "ACRocket" then
					FoundMO = ToACRocket(FoundMO)
				elseif FoundMO.ClassName == "ACDropShip" then
					FoundMO = ToACDropShip(FoundMO)
				elseif FoundMO.ClassName == "ADoor" then
					FoundMO = ToADoor(FoundMO)
				elseif FoundMO.ClassName == "Actor" then
					FoundMO = ToActor(FoundMO)
				else
					FoundMO = nil
				end
				
				if FoundMO then
					if self.Target then
						-- check if this MO should be targeted instead
						if HumanBehaviors.CalculateThreatLevel(FoundMO, Owner) > 
							HumanBehaviors.CalculateThreatLevel(self.Target, Owner) + 0.5
						then
							self.OldTargetPos = Vector(self.Target.Pos.X, self.Target.Pos.Y)
							self.Target = FoundMO
							self.TargetOffset = SceneMan:ShortestDistance(self.Target.Pos, HitPoint, false)	-- this is the distance vector from the target center to the point we hit with our ray
							if self.NextBehaviorName ~= "ShootTarget" then
								self:CreateAttackBehavior(Owner)
							end
						end
					else
						self.OldTargetPos = nil
						self.Target = FoundMO
						self.TargetOffset = SceneMan:ShortestDistance(self.Target.Pos, HitPoint, false)	-- this is the distance vector from the target center to the point we hit with our ray
						self:CreateAttackBehavior(Owner)
					end
				end
			end
		end
	else -- no target found this frame
		if self.Target and self.TargetLostTimer:IsPastSimTimeLimit() then
			self.Target = nil	-- the target has been out of sight for too long, ignore it
			self:CreatePinBehavior(Owner) -- keep aiming in the direction of the target for a short time
		end

		if self.ReloadTimer:IsPastSimMS(8000) then	-- check if we need to reload
			if Owner.FirearmNeedsReload then
				self.ReloadTimer:Reset()
				Owner:ReloadFirearm()
			elseif not HumanBehaviors.EquipPreferredWeapon(self, Owner) then	-- make sure we equip a preferred or a primary weapon if we have one
				self.ReloadTimer:Reset()
			end
		end
	end
	
	self.squadShoot = false
	if Owner.MOMoveTarget then
		-- make the last waypoint marker stick to the MO we are following
		if MovableMan:ValidMO(Owner.MOMoveTarget) then
			Owner:RemoveMovePathEnd()
			Owner:AddToMovePathEnd(Owner.MOMoveTarget.Pos)
			
			if Owner.AIMode == Actor.AIMODE_SQUAD then
				-- look where the SL looks, if not moving
				if not self.jump and self.lateralMoveState == Actor.LAT_STILL then
					local Leader = MovableMan:GetMOFromID(Owner:GetAIMOWaypointID())
					if Leader then
						if IsAHuman(Leader) then
							Leader = ToAHuman(Leader)
						elseif IsACrab(Leader) then
							Leader = ToACrab(Leader)
						else
							Leader = nil
						end
					end
					
					if Leader and Leader.EquippedItem and IsHDFirearm(Leader.EquippedItem) and
						SceneMan:ShortestDistance(Owner.Pos, Leader.Pos, false).Largest < (Leader.Height + Owner.Height) * 0.5
					then
						local LeaderWeapon = ToHDFirearm(Leader.EquippedItem)
						if LeaderWeapon:IsWeapon() then
							local AimDelta = SceneMan:ShortestDistance(Leader.Pos, Leader.ViewPoint, false)
							self.Ctrl.AnalogAim = SceneMan:ShortestDistance(Owner.Pos, Leader.ViewPoint+AimDelta, false).Normalized
							self.deviceState = AHuman.POINTING
							
							-- check if the SL is shooting and if we have a similar weapon
							if Owner.FirearmIsReady then
								self.deviceState = AHuman.AIMING
								
								if IsHDFirearm(Owner.EquippedItem) and Leader:GetController():IsState(Controller.WEAPON_FIRE) then
									local OwnerWeapon = ToHDFirearm(Owner.EquippedItem)
									if OwnerWeapon:IsTool() then
										-- try equipping a weapon
										if Owner.InventorySize > 0 and not Owner:EquipDeviceInGroup("Primary Weapons", true) then
											Owner:EquipFirearm(true)
										end
									elseif LeaderWeapon:GetAIBlastRadius() >= OwnerWeapon:GetAIBlastRadius() * 0.5 and
										OwnerWeapon:CompareTrajectories(LeaderWeapon) < math.max(100, OwnerWeapon:GetAIBlastRadius())
									then
										self.Target = nil
										self.squadShoot = true
									end
								end
							else
								if Owner.FirearmIsEmpty then
									Owner:ReloadFirearm()
								elseif Owner.InventorySize > 0 and not Owner:EquipDeviceInGroup("Primary Weapons", true) then
									Owner:EquipFirearm(true)
								end
							end
						end
					end
				end
			end
		else
			if self.GoToName == "GoToWpt" then
				self:CreateGoToBehavior(Owner)
			end
			
			-- if we are in AIMODE_SQUAD the leader just got killed
			if Owner.AIMode == Actor.AIMODE_SQUAD then
				Owner.AIMode = Actor.AIMODE_SENTRY
				Owner:ClearMovePath()
			end
		end
	elseif Owner.AIMode == Actor.AIMODE_SQUAD then	-- if we are in AIMODE_SQUAD the leader just got killed
		Owner.AIMode = Actor.AIMODE_SENTRY
		if self.GoToName == "GoToWpt" then
			self:CreateGoToBehavior(Owner)
		end
	end
	
	if self.squadShoot then
		-- cycle semi-auto weapons on and off so the AI will shoot even if the player only press and hold the trigger
		if Owner.FirearmIsSemiAuto and self.SquadShootTimer:IsPastSimMS(Owner.FirearmActivationDelay+50) then
			self.SquadShootTimer:Reset()
			self.squadShoot = false
		end
	else
		-- run the move behavior and delete it if it returns true
		if self.GoToBehavior then
			local msg, done = coroutine.resume(self.GoToBehavior, self, Owner, false)
			if not msg then
				ConsoleMan:PrintString(Owner.PresetName .. " " .. self.GoToName .. " error:\n" .. done)	-- print the error message
				done = true
			end
			
			if done then
				self.GoToBehavior = nil
				self.GoToName = nil
				if self.GoToCleanup then
					self.GoToCleanup(self)
					self.GoToCleanup = nil
				end
			end
		elseif self.flying then	-- avoid falling damage
			if (not self.jump and Owner.Vel.Y > 9) or
				(self.jump and Owner.Vel.Y > 6)
			then
				self.jump = true
				
				-- try falling straight down
				if not self.Target then
					if Owner.Vel.X > 2 then
						self.lateralMoveState = Actor.LAT_LEFT
					elseif Owner.Vel.X < -2 then
						self.lateralMoveState = Actor.LAT_RIGHT
					else
						self.lateralMoveState = Actor.LAT_STILL
					end
				end
			else
				self.jump = false
				self.lateralMoveState = Actor.LAT_STILL
			end
		end
		
		-- run the selected behavior and delete it if it returns true
		if self.Behavior then
			local msg, done = coroutine.resume(self.Behavior, self, Owner, false)
			if not msg then
				ConsoleMan:PrintString(Owner.PresetName .. " behavior " .. self.BehaviorName .. " error:\n" .. done)	-- print the error message
				done = true
			end
			
			if done then
				self.Behavior = nil
				self.BehaviorName = nil
				if self.BehaviorCleanup then
					self.BehaviorCleanup(self)
					self.BehaviorCleanup = nil
				end
				
				if not self.NextBehavior and not self.PickupHD and self.PickUpTimer:IsPastSimMS(10000) then
					self.PickUpTimer:Reset()
					
					if not Owner:EquipFirearm(false) then
						self:CreateGetWeaponBehavior(Owner)
					elseif Owner.AIMode ~= Actor.AIMODE_SENTRY and not Owner:EquipDiggingTool(false) then
						self:CreateGetToolBehavior(Owner)
					end
				end
			end
		end
		
		-- there is a HeldDevice we want to pick up
		if self.PickupHD then
			if not MovableMan:IsDevice(self.PickupHD) or self.PickupHD.ID ~= self.PickupHD.RootID then
				self.PickupHD = nil	-- the HeldDevice has been destroyed or picked up
			elseif SceneMan:ShortestDistance(Owner.Pos, self.PickupHD.Pos, false).Magnitude < Owner.Height then
				self.Ctrl:SetState(Controller.WEAPON_PICKUP, true)
			end
		end
		
		-- listen and react to AlarmEvents and AlarmPoints
		local AlarmPoint = Owner:GetAlarmPoint()
		if AlarmPoint.Largest > 0 then
			if not self.Target and not self.UnseenTarget then	
				self.AlarmPos = Vector(AlarmPoint.X, AlarmPoint.Y)
				self:CreateFaceAlarmBehavior(Owner)
			else
				-- is the alarm generated from behind us?
				local AlarmVector = SceneMan:ShortestDistance(Owner.Pos, AlarmPoint, false)
				if (Owner.HFlipped and AlarmVector.X > 0) or (not Owner.HFlipped and AlarmVector.X < 0)
				then
					self.AlarmPos = Vector(AlarmPoint.X, AlarmPoint.Y)
					self:CreateFaceAlarmBehavior(Owner)
				end
			end
		elseif not self.Target and not self.UnseenTarget then	
			if self.AlarmTimer:IsPastSimTimeLimit() and HumanBehaviors.ProcessAlarmEvent(self, Owner) then
				self.AlarmTimer:Reset()
			end
		end
	end
	
	if self.teamBlockState == Actor.IGNORINGBLOCK then
		if self.BlockedTimer:IsPastSimMS(10000) then
			self.teamBlockState = Actor.NOTBLOCKED
		end
	elseif self.teamBlockState == Actor.BLOCKED then	-- we are blocked by a team-mate, stop
		self.lateralMoveState = Actor.LAT_STILL
		self.jump = false
		if self.BlockedTimer:IsPastSimMS(20000) then
			self.BlockedTimer:Reset()
			self.teamBlockState = Actor.IGNORINGBLOCK
		end
	else
		self.BlockedTimer:Reset()
	end
	
	-- controller states
	self.Ctrl:SetState(Controller.WEAPON_FIRE, (self.fire or self.squadShoot))
	
	if self.deviceState == AHuman.AIMING then
		self.Ctrl:SetState(Controller.AIM_SHARP, true)
	end
	
	if self.jump and Owner.JetTimeLeft > TimerMan.DeltaTimeMS then
		if self.jumpState == AHuman.PREJUMP then
			self.jumpState = AHuman.UPJUMP
		elseif self.jumpState ~= AHuman.UPJUMP then	-- the jetpack is off
			self.jumpState = AHuman.PREJUMP
		end
	else
		self.jumpState = AHuman.NOTJUMPING
	end
	
	if Owner.Jetpack then
		if self.jumpState == AHuman.PREJUMP then
			self.Ctrl:SetState(Controller.BODY_JUMPSTART, true)	-- try to trigger a burst
		elseif self.jumpState == AHuman.UPJUMP then
			self.Ctrl:SetState(Controller.BODY_JUMP, true)	-- trigger normal jetpack emission
		end
	end
	
	if self.proneState == AHuman.GOPRONE then
		self.proneState = AHuman.PRONE
	elseif self.proneState == AHuman.PRONE then
		self.Ctrl:SetState(Controller.BODY_CROUCH, true)
	end
	
	if self.lateralMoveState == Actor.LAT_LEFT then
		self.Ctrl:SetState(Controller.MOVE_LEFT, true)
	elseif self.lateralMoveState == Actor.LAT_RIGHT then
		self.Ctrl:SetState(Controller.MOVE_RIGHT, true)
	end
end

function NativeHumanAI:Destroy(Owner)
	-- Tell the coroutines to abort to avoid memory leaks
	if self.GoToBehavior then
		local msg, done = coroutine.resume(self.GoToBehavior, self, Owner, true)
	end

	if self.Behavior then
		local msg, done = coroutine.resume(self.Behavior, self, Owner, true)
	end
end


-- functions that create behaviors. the default behaviors are stored in the HumanBehaviors table. store your custom behaviors in a table to avoid name conflicts between mods.
function NativeHumanAI:CreateSentryBehavior(Owner)
	if self.Target then
		self:CreateAttackBehavior(Owner)
	else
		if not Owner:EquipFirearm(true) then
			if self.PickUpTimer:IsPastSimMS(2000) then
				self.PickUpTimer:Reset()
				self:CreateGetWeaponBehavior(Owner)
			end
			
			return
		end
		
		self.NextBehavior = coroutine.create(HumanBehaviors.Sentry)	-- replace "HumanBehaviors.Sentry" with the function name of your own sentry behavior
		self.NextCleanup = nil
		self.NextBehaviorName = "Sentry"
	end
end

function NativeHumanAI:CreatePatrolBehavior(Owner)
	self.NextBehavior = coroutine.create(HumanBehaviors.Patrol)
	self.NextCleanup = nil
	self.NextBehaviorName = "Patrol"
end

function NativeHumanAI:CreateGoldDigBehavior(Owner)
	if not Owner:EquipDiggingTool(false) then
		if self.PickUpTimer:IsPastSimMS(1000) then
			self.PickUpTimer:Reset()
			self:CreateGetToolBehavior(Owner)
		end
		
		return
	end
	
	self.NextBehavior = coroutine.create(HumanBehaviors.GoldDig)
	self.NextCleanup = nil
	self.NextBehaviorName = "GoldDig"
end

function NativeHumanAI:CreateBrainSearchBehavior(Owner)
	self.NextBehavior = coroutine.create(HumanBehaviors.BrainSearch)
	self.NextCleanup = nil
	self.NextBehaviorName = "BrainSearch"
end

function NativeHumanAI:CreateGetToolBehavior(Owner)
	if Owner.AIMode ~= Actor.AIMODE_SQUAD then
		self.NextBehavior = coroutine.create(HumanBehaviors.ToolSearch)
		self.NextCleanup = nil
		self.NextBehaviorName = "ToolSearch"
	end
end

function NativeHumanAI:CreateGetWeaponBehavior(Owner)
	if Owner.AIMode ~= Actor.AIMODE_SQUAD then
		self.NextBehavior = coroutine.create(HumanBehaviors.WeaponSearch)
		self.NextCleanup = nil
		self.NextBehaviorName = "WeaponSearch"
	end
end

function NativeHumanAI:CreateGoToBehavior(Owner)
	self.NextGoTo = coroutine.create(HumanBehaviors.GoToWpt)
	self.NextGoToCleanup = function(AI)
		AI.lateralMoveState = Actor.LAT_STILL
		AI.deviceState = AHuman.STILL
		AI.proneState = AHuman.NOTPRONE
		AI.jump = false
		AI.fire = false
	end
	self.NextGoToName = "GoToWpt"
end

function NativeHumanAI:CreateAttackBehavior(Owner)
	self.ReloadTimer:Reset()
	self.TargetLostTimer:Reset()
	if Owner:EquipFirearm(true) then
		self.NextBehavior = coroutine.create(HumanBehaviors.ShootTarget)
		self.NextBehaviorName = "ShootTarget"
	elseif Owner.AIMode ~= Actor.AIMODE_SQUAD and Owner:EquipThrowable(true) then
		self.NextBehavior = coroutine.create(HumanBehaviors.ThrowTarget)
		self.NextBehaviorName = "ThrowTarget"
	elseif Owner.AIMode ~= Actor.AIMODE_SQUAD and Owner:EquipDiggingTool(true) and
		SceneMan:ShortestDistance(Owner.Pos, self.Target.Pos, false).Magnitude < 150
	then
		self.NextBehavior = coroutine.create(HumanBehaviors.AttackTarget)
		self.NextBehaviorName = "AttackTarget"
	else	-- unarmed or far away
		if self.PickUpTimer:IsPastSimMS(2500) then
			self.PickUpTimer:Reset()
			self.NextBehavior = coroutine.create(HumanBehaviors.WeaponSearch)
			self.NextBehaviorName = "WeaponSearch"
			self.NextCleanup = nil
			
			return
		else -- there are probably no weapons around here (in the vicinity of an area adjacent to a location)
			if self.Target and MovableMan:ValidMO(self.Target) and 
				not (self.isPlayerOwned and Owner.AIMode == Actor.AIMODE_SENTRY) and
				(self.Target.ClassName == "AHuman" or self.Target.ClassName == "ACrab")
			then
				self.NextBehavior = coroutine.create(HumanBehaviors.AttackTarget)
				self.NextBehaviorName = "AttackTarget"
			else
				self.Target = nil
				return
			end
		end
	end
	
	self.NextCleanup = function(AI)
		AI.fire = false
		AI.canHitTarget = false
		AI.deviceState = AHuman.STILL
		AI.proneState = AHuman.NOTPRONE
		AI.TargetLostTimer:SetSimTimeLimitMS(2000)
	end
end

-- force the use of a digger when attacking
function NativeHumanAI:CreateHtHBehavior(Owner)
	if Owner.AIMode ~= Actor.AIMODE_SQUAD and self.Target and Owner:EquipDiggingTool(true) then
		self.NextBehavior = coroutine.create(HumanBehaviors.AttackTarget)
		self.NextBehaviorName = "AttackTarget"
		self.NextCleanup = function(AI)
			AI.fire = false
			AI.Target = nil
			AI.deviceState = AHuman.STILL
			AI.proneState = AHuman.NOTPRONE
		end
	end
end

function NativeHumanAI:CreateSuppressBehavior(Owner)
	if Owner:EquipFirearm(true) then
		self.NextBehavior = coroutine.create(HumanBehaviors.ShootArea)
		self.NextBehaviorName = "ShootArea"
	else
		if Owner.FirearmIsEmpty then
			Owner:ReloadFirearm()
		end
		
		return
	end
	
	self.NextCleanup = function(AI)
		AI.fire = false
		AI.UnseenTarget = nil
		AI.deviceState = AHuman.STILL
		AI.proneState = AHuman.NOTPRONE
	end
end

function NativeHumanAI:CreateMoveAroundBehavior(Owner)
	self.NextGoTo = coroutine.create(HumanBehaviors.MoveAroundActor)
	self.NextGoToName = "MoveAroundActor"
	self.NextGoToCleanup = function(AI)
		AI.lateralMoveState = Actor.LAT_STILL
		AI.jump = false
	end
end

function NativeHumanAI:CreateFaceAlarmBehavior(Owner)
	self.NextBehavior = coroutine.create(HumanBehaviors.FaceAlarm)
	self.NextBehaviorName = "FaceAlarm"
	self.NextCleanup = nil
end

function NativeHumanAI:CreatePinBehavior(Owner)
	if self.OldTargetPos and Owner:EquipFirearm(true) then
		self.NextBehavior = coroutine.create(HumanBehaviors.PinArea)
		self.NextBehaviorName = "PinArea"
	else
		return
	end
	
	self.NextCleanup = function(AI)
		self.OldTargetPos = nil
	end
end
