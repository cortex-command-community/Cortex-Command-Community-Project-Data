function OnFire(self)

	self.mechSound:Play(self.Pos);

end

function Create(self
)
	self.mechSound = CreateSoundContainer("Mech Browncoat AR-25", "Browncoats.rte");
	
end