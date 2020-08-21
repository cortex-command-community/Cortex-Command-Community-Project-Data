function Create(self)
	self.radius = 200;					-- Range of effective area in px
	self.strength = self.PinStrength;	-- Duration variable
	
	self.actorTable = {};
	local actorCount = 0;	-- This diminishes the effect when multiple actors are affected
	
	for actor in MovableMan.Actors do
		local dist = SceneMan:ShortestDistance(self.Pos, actor.Pos, SceneMan.SceneWrapsX);
		if dist.Magnitude < self.radius then
			local skipPx = 1 + (dist.Magnitude * 0.01);
			local strCheck = SceneMan:CastStrengthSumRay(self.Pos, self.Pos + dist, skipPx, rte.airID);
			if strCheck < (100/skipPx) then
				-- The effect is diminished by target actor mass, material strength and distance
				local resistance = math.sqrt(math.abs(actor.Mass) + actor.Material.StructuralIntegrity + dist.Magnitude + 1) + actorCount;
				actor:SetNumberValue("Ronin Scrambler", math.floor(actor:GetNumberValue("Ronin Scrambler") + self.strength/resistance));
				actor:FlashWhite(20);
				if actor:IsPlayerControlled() then
					local screen = ActivityMan:GetActivity():ScreenOfPlayer(actor:GetController().Player);
					local white, black = 254, 245;
					FrameMan:FlashScreen(screen, white, 1000);
				end
				table.insert(self.actorTable, actor);
				actorCount = actorCount + 1;
			end
		end
	end
	for team = Activity.TEAM_1, Activity.MAXTEAMCOUNT - 1 do
		if SceneMan:AnythingUnseen(team) then
			local size = self.radius/2;
			local dots = 10;
			SceneMan:RestoreUnseenBox(self.Pos.X - (size/2), self.Pos.Y - (size/2), size, size, team);
			for i = 1, dots do
				local vector = Vector(size, 0):RadRotate(6.28 * i/dots);
				local startPos = self.Pos + vector;
				SceneMan:RestoreUnseenBox(startPos.X - (size/2), startPos.Y - (size/2), size, size, team);
			end
		end
	end
end
function Update(self)
	self.ToSettle = false;
	local actorCount = 0;
	for i = 1, #self.actorTable do
		if IsActor(self.actorTable[i]) then
			local actor = ToActor(self.actorTable[i]);
			if actor:NumberValueExists("Ronin Scrambler") and actor.Status < Actor.DYING then
				actorCount = actorCount + 1;
				local numberValue = actor:GetNumberValue("Ronin Scrambler");
				if numberValue > 0 then
					actor.Status = Actor.UNSTABLE;
					local ctrl = actor:GetController();
					if math.random(50) < numberValue then
						for i = 0, 29 do	--Go through and disable the gameplay-related controller states
							ctrl:SetState(i, false);
						end
					end
					local framesPerFlash = 6;
					if (numberValue/framesPerFlash) - math.floor(numberValue/framesPerFlash) == 0 then
						actor:FlashWhite(1);
						if math.random() < 0.5 then
							AudioMan:PlaySound("Ronin.rte/Devices/Special/Scrambler/Sounds/Buzz0".. math.random(6) ..".wav", actor.Pos);
						end
					end
					actor:SetNumberValue("Ronin Scrambler", numberValue - 1);
				else
					actor:RemoveNumberValue("Ronin Scrambler");
				end
			end
		end
	end
	if actorCount == 0 then
		self.ToDelete = true;
	end
end