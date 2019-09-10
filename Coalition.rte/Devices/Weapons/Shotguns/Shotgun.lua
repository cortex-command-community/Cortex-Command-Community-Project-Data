
function Create(self)

	self.reloadTimer = Timer();
	self.loadedShell = false;
	self.reloadCycle = false;

	self.reloadDelay = 200;

	if self.Magazine then
		self.ammoCounter = self.Magazine.RoundCount;
	else
		self.ammoCounter = 0;
	end

	self.parent = nil;
	self.pullTimer = Timer();

	self.newMag = false;
	self.chamber = true;		--
	--self.pullTimer:Reset();	--
	self.num = math.pi;		--
	self.sfx = true;		--

	self.negNum = 0;

	local actor = MovableMan:GetMOFromID(self.RootID);
	if actor and IsAHuman(actor) then
		self.parent = ToAHuman(actor);
	end
end

function Update(self)

	local actor = MovableMan:GetMOFromID(self.RootID);
	if actor and IsAHuman(actor) then
		self.parent = ToAHuman(actor);
	else
		self.parent = nil;
	-- cock and load on pickup
		--self.chamber = true;	--
		--self.pullTimer:Reset();	--
		--self.num = math.pi;	--
		--self.sfx = true;	--
	end

	if self.HFlipped then
		self.negNum = -1;
	else
		self.negNum = 1;
	end
	
	if self.FiredFrame then

		self.chamber = true;
		self.pullTimer:Reset();
		self.num = math.pi;
		self.sfx = true;
		
	end

	if self.parent then

		if self.Magazine then
		
			if self.loadedShell == false then
				self.ammoCounter = self.Magazine.RoundCount;
			else
				self.loadedShell = false;
				self.Magazine.RoundCount = self.ammoCounter + 1;
			end
		else
			self.reloadTimer:Reset();
			self.reloadCycle = true;
			self.loadedShell = true;
		end
	end
	
	if self:IsActivated() then
		self.reloadCycle = false;
	end

	if self.reloadCycle == true and self.reloadTimer:IsPastSimMS(self.reloadDelay) and self:IsFull() == false then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if MovableMan:IsActor(actor) then
			ToActor(actor):GetController():SetState(Controller.WEAPON_RELOAD,true);
		end
		self.reloadCycle = false;
	end
	
	if self.parent then

		if self.chamber == true then

			self:Deactivate();
			--self.parent:GetController():SetState(Controller.WEAPON_FIRE,false);

			if self.pullTimer:IsPastSimMS(500) then
				--self.parent:GetController():SetState(Controller.AIM_SHARP,false);
				--self.Frame = 1;
				

				if self.sfx ~= false then
					sfx = CreateAEmitter("Chamber " .. self.PresetName);
					sfx.Pos = self.Pos;
					MovableMan:AddParticle(sfx);
					self.sfx = false
				end

				if self.unspentCasing == true then
					casing = CreateMOSParticle("Shell");
					casing.Pos = self.Pos+Vector(-4*self.negNum,-1):RadRotate(self.RotAngle);
					casing.Vel = self.Vel+Vector(-math.random(7,9)*self.negNum,-math.random(5,7)):RadRotate(self.RotAngle);
					MovableMan:AddParticle(casing);

					self.unspentCasing = false;
				end
				
				self.RotAngle = self.RotAngle +self.negNum*math.sin(self.num)/4;

				self.num = self.num - math.pi*0.07;
			end

			if self.num <= 0 then
			
				self.num = 0;
				self.chamber = false;
			end
		end
	end				
end