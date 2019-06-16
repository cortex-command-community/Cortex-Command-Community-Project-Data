function Update(self)
    for actor in MovableMan.Actors do
	--See if a rocket is within 30 pixel range of the docking unit and if it has the AI mode set to "Stay".
	if (actor.ClassName == "ACRocket") and (actor.AIMode == Actor.AIMODE_STAY) and (math.abs(actor.Pos.X - self.Pos.X) < 30) and (math.abs(actor.Pos.Y - self.Pos.Y) < 30) then
	    --Pin the ship and place it nicely in the docking unit.
	    actor.Vel = Vector(0,0);
	    actor.AngularVel = 0;
	    actor.RotAngle = (actor.RotAngle * 2) / 3;
	    actor.Pos = Vector((self.Pos.X + actor.Pos.X * 2) / 3,(actor.Pos.Y * 2 + self.Pos.Y - 28) / 3);  --Replace offsets with values that place the rocket in a nice position, but move it in a gradietn so it doesn't "snap".
	end
    end
end