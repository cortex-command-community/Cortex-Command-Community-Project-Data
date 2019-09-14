function Update(self)
    for actor in MovableMan.Actors do
	--See if a dropship is within 45 pixel range of the docking unit and if it has the AI mode set to "Stay".
	if (actor.ClassName == "ACDropShip") and (actor.AIMode == Actor.AIMODE_STAY) and (math.abs(actor.Pos.X - self.Pos.X) < 45) and (math.abs(actor.Pos.Y - self.Pos.Y) < 45) then
	    --[[ WARNING, AUTOSCUTTLE WILL KICK IN ONCE THE DS NOTICES IT'S NOT MOVING ANYWHERE.
	    --Pin the ship and place it nicely in the docking unit.
	    actor.Vel = Vector(0,0);
	    actor.Pos = Vector(self.Pos.X + 0, self.Pos.Y + 38);  --replace offsets with values that place the dropship in a nice position
	    --]]
	    --TEMPORARY SOLUTION. GRAVITATE AT DOCK PIXELS.
	    local diff = math.sqrt(math.pow((actor.Pos.X-self.Pos.X),2) + math.pow((actor.Pos.Y - (self.Pos.Y + 38)),2))
	    if diff < 5 then
		diff = 5
	    end
	    if diff < 85 then
		local diffx = actor.Pos.X - self.Pos.X;
		local diffy = actor.Pos.Y - (self.Pos.Y + 38);
		local ang = math.atan2(diffy,diffx);
		actor.Vel.Y = actor.Vel.Y - (6 / diff * math.sin(ang));
		actor.Vel.X = actor.Vel.X - (3 / diff * math.cos(ang));
	    end
	end
    end
end