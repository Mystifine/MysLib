
return function(character : Model) : boolean
	if not character then return false end;
	if character.Parent == nil then return false end;
	
	local humanoid = character:FindFirstChild("Humanoid");
	if not humanoid then return false end;
	
	if humanoid.Health <= 0 then return false end;
	if humanoid:GetState() == Enum.HumanoidStateType.Dead then return false end;
	
	local primaryPart = character.PrimaryPart;
	if not primaryPart then return false end;
	
	if primaryPart.Parent ~= character then return false end;

	return true;
end
