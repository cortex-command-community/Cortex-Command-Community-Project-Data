--This script is used for actors that have a decapitated state head sprite (see: Browncoat Heavy) in order for them to have proper BuyMenu display.
--The method for this is to have 2 frames for the head sprite:
--Frame 000 being a normal head sprite (non decaptitated/damaged/whatever) to be the one displayed in the BuyMenu.
--Frame 001 being the decapitated/damaged/whatever/null frame that will be used as soon as the actor is created.
--All this script does is set the Frame from 0 to 1 on Create.

function Create(self)
	self.Frame = 1;
end