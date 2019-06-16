
dofile("Base.rte/Constants.lua")
require("Actors/AI/NativeDropShipAI")	

function Create(self)
	self.AI = NativeDropShipAI:Create(self)
end

function Update(self)
  if self.RightThruster and self.LeftThruster then
    -- use a PD-controller for balance
    local change = 0.6 * self.AngularVel + 0.8 * self.RotAngle
    if change > 0.22 then
      if not self.RightThruster:IsEmitting() then
        self.RightThruster:TriggerBurst()
      end
      self.RightThruster:EnableEmission(true)
    else
      self.RightThruster:EnableEmission(false)
    end
    
    if change < -0.22 then
      if not self.LeftThruster:IsEmitting() then
        self.LeftThruster:TriggerBurst()
      end
      self.LeftThruster:EnableEmission(true)
    else
      self.LeftThruster:EnableEmission(false)
    end
  end
end

function UpdateAI(self)
	self.AI:Update(self)
end
