function Create(self)
    --Make sure the teleporter list exists.
    if teleporterlista == nil then
	teleporterlista = {};
    end

    --List for storing who can teleport.
    if cantele == nil then
	cantele = {};
    end

    --Add self to teleporter list.
    teleporterlista[#teleporterlista + 1] = self;

    --Stores where on the teleporter list this teleporter is.  Used for assigning a partner.
    self.listnum = #teleporterlista;

    --Initialize delay timer if it doesn't exist yet.
    if cantele[self.listnum] == nil then
	cantele[self.listnum] = Timer();
    else
    --Otherwise, reset it.
	cantele[self.listnum]:Reset();
    end

    --This variable stores which teleporter is this one's "partner", or the one that is linked to it.
    self.partner = nil;

    --How long it takes between teleports.
    self.porttime = 3000;

    --Timer to count how long since the last teleportation.
    self.porttimer = Timer();

    --How long since creation.
    self.creationtimer = Timer();
end

function Update(self)
    --A delay so that all teleporters will have been placed by the time the code activates.
    if self.creationtimer:IsPastSimMS(1000) and ActivityMan:GetActivity().ActivityState ~= Activity.EDITING then
	--Check if the teleporter is linked yet.
	if MovableMan:IsParticle(self.partner) == false then
	    --If not, try to assign a partner.
	    self.partner = teleporterlistb[self.listnum];
	    --Turn on spinning effect.
	    self:EnableEmission(true);
	elseif cantele[self.listnum]:IsPastSimMS(self.porttime) then
	    --Cycle through all actors.
	    for actor in MovableMan.Actors do
		if (actor.Pos.X >= self.Pos.X - 18) and (actor.Pos.X <= self.Pos.X + 18) and (actor.Pos.Y >= self.Pos.Y - 18) and (actor.Pos.Y <= self.Pos.Y + 18) and (actor.PinStrength <= 0) then
		    --Teleport the actor.
		    actor.Pos = self.partner.Pos;
		    --Make the actor glow for a while.
		    actor:FlashWhite(1500);
		    --Create the teleportation effect for both teleporters in the set.
		    local fxa = CreateAEmitter("Teleporter Effect A");
		    fxa.Pos = self.Pos;
		    MovableMan:AddParticle(fxa);
		    local fxb = CreateAEmitter("Teleporter Effect B");
		    fxb.Pos = self.partner.Pos;
		    MovableMan:AddParticle(fxb);
		    --Shut off teleportation on this set until the delay is up.
		    cantele[self.listnum]:Reset();
		end
	    end
	end
    end
end

function Destroy(self)
    --Remove self from teleporter list.
    teleporterlista[self.listnum] = nil;
end