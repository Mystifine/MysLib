return function(input_vector : Vector3)
	local horizontal_vector = Vector3.new(input_vector.X, 0, input_vector.Z);

	if horizontal_vector.Magnitude > 1e-4 then
		return horizontal_vector.Unit;
	else
		return Vector3.new(0,0,0)
	end
end