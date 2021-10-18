--This script will help the wet concrete fill up gaps in the terrain
function OnCollideWithTerrain(self, materialID)
	if self.PrevVel.Magnitude > 5 then
		local hitPos = Vector();
		local trace = self.PrevVel * rte.PxTravelledPerFrame;
		if SceneMan:CastStrengthRay(self.PrevPos, trace, 10, hitPos, 1, rte.airID, SceneMan.SceneWrapsX) and SceneMan:CastWeaknessRay(hitPos, trace, 10, hitPos, 1, SceneMan.SceneWrapsX) then
			self.Pos = hitPos;
			self.Vel = trace * (-1);
			self.ToSettle = true;
		end
	end
	self:DisableScript("Base.rte/Devices/Tools/ConcreteSprayer/ConcreteFill.lua");
end