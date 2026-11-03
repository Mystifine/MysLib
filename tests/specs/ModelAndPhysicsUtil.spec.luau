local TestKit = require("../harness/TestKit")
local describe, it, sandbox, eq, ok, near = TestKit.describe, TestKit.it, TestKit.sandbox, TestKit.eq, TestKit.ok, TestKit.near

local function weldsOf(part)
	local welds = {}
	for _, child in part:GetChildren() do
		if child:IsA("WeldConstraint") then
			table.insert(welds, child)
		end
	end
	return welds
end

describe("ModelUtil.getModelLargestPart", function()
	it("finds the largest part", function()
		local sb = sandbox()
		local model = sb.new("Model")
		sb.new("Part", { Size = sb.Vector3.new(1, 1, 1), Parent = model })
		local big = sb.new("Part", { Size = sb.Vector3.new(9, 9, 9), Parent = model })
		sb.new("Part", { Size = sb.Vector3.new(2, 2, 2), Parent = model })

		local largest, size = sb.require("Util.ModelUtil").getModelLargestPart(model)
		eq(largest, big)
		near(size, big.Size.Magnitude)
	end)

	it("is not reset by a non-part sibling", function()
		local sb = sandbox()
		local model = sb.new("Model")
		local big = sb.new("Part", { Size = sb.Vector3.new(9, 9, 9), Parent = model })
		sb.new("Humanoid", { Parent = model })

		eq(sb.require("Util.ModelUtil").getModelLargestPart(model), big)
	end)

	it("keeps the larger of a part and a nested folder's part, in any order", function()
		local sb = sandbox()
		local model = sb.new("Model")
		local big = sb.new("Part", { Size = sb.Vector3.new(9, 9, 9), Parent = model })
		local folder = sb.new("Folder", { Parent = model })
		sb.new("Part", { Size = sb.Vector3.new(1, 1, 1), Parent = folder })
		eq(sb.require("Util.ModelUtil").getModelLargestPart(model), big)

		local deepest = sb.new("Part", { Size = sb.Vector3.new(50, 50, 50), Parent = folder })
		eq(sb.require("Util.ModelUtil").getModelLargestPart(model), deepest)
	end)

	it("returns nil for a model with no parts", function()
		local sb = sandbox()
		local model = sb.new("Model")
		sb.new("Folder", { Parent = model })
		eq(sb.require("Util.ModelUtil").getModelLargestPart(model), nil)
	end)
end)

describe("ModelUtil welding", function()
	it("weldConstraint links two parts", function()
		local sb = sandbox()
		local a, b = sb.new("Part", { Name = "A" }), sb.new("Part", { Name = "B" })
		local weld = sb.require("Util.ModelUtil").weldConstraint(a, b)
		eq(weld.Part0, a)
		eq(weld.Part1, b)
		eq(weld.Parent, b)
		eq(weld.Name, "B")
	end)

	it("weldModel welds parts to the PrimaryPart and sets physics properties", function()
		local sb = sandbox()
		local model = sb.new("Model")
		local primary = sb.new("Part", { Anchored = true, Parent = model })
		local other = sb.new("Part", { Anchored = true, Parent = model })
		model.PrimaryPart = primary

		sb.require("Util.ModelUtil").weldModel(model)

		eq(#weldsOf(primary), 0)
		eq(#weldsOf(other), 1)
		eq(weldsOf(other)[1].Part0, primary)
		for _, part in { primary, other } do
			eq(part.Anchored, false)
			eq(part.CanCollide, false)
			eq(part.CanTouch, false)
			eq(part.Massless, true)
		end
	end)

	it("weldModel warns and does nothing without a PrimaryPart", function()
		local sb = sandbox()
		local model = sb.new("Model")
		local part = sb.new("Part", { Anchored = true, Parent = model })
		sb.require("Util.ModelUtil").weldModel(model)
		ok(sb.hasWarning("no PrimaryPart"))
		eq(part.Anchored, true)
	end)

	-- Pins existing behaviour: a nested model becomes its own assembly, so it can still be
	-- jointed to the outer model (e.g. a hinged door). Changing this would break such setups.
	it("welds a nested model to its own PrimaryPart only", function()
		local sb = sandbox()
		local model = sb.new("Model")
		local primary = sb.new("Part", { Parent = model })
		model.PrimaryPart = primary

		local nested = sb.new("Model", { Parent = model })
		local nestedPrimary = sb.new("Part", { Parent = nested })
		local nestedOther = sb.new("Part", { Parent = nested })
		nested.PrimaryPart = nestedPrimary

		sb.require("Util.ModelUtil").weldModel(model)

		eq(weldsOf(nestedOther)[1].Part0, nestedPrimary)
		eq(#weldsOf(nestedPrimary), 0)
	end)
end)

describe("PhysicsUtil.Velocity", function()
	local function constraints(part)
		local found = {}
		for _, child in part:GetChildren() do
			if child:IsA("Attachment") then
				table.insert(found, child)
			end
		end
		return found
	end

	it("creates the constraint, updates it, and expires after its duration", function()
		local sb = sandbox()
		local Velocity = sb.require("Util.PhysicsUtil").Velocity
		local part = sb.new("Part", { Parent = sb.workspace })
		local force, vel = sb.Vector3.new(1, 1, 1), sb.Vector3.new(5, 0, 0)
		local velocity = Velocity.new(part, force, vel, 1)

		eq(#constraints(part), 1)
		eq(velocity.linearVelocity.VectorVelocity, vel)
		velocity:SetVelocity(sb.Vector3.new(9, 0, 0))
		eq(velocity.linearVelocity.VectorVelocity, sb.Vector3.new(9, 0, 0))
		velocity:SetMaxForce(sb.Vector3.new(2, 2, 2))
		eq(velocity.linearVelocity.MaxAxesForce, sb.Vector3.new(2, 2, 2))

		sb.advance(1.1)
		eq(#constraints(part), 0)
		velocity:SetVelocity(vel)
		velocity:Destroy()
	end)

	it("keeps an infinite velocity alive and cleans up with the part", function()
		local sb = sandbox()
		local part = sb.new("Part", { Parent = sb.workspace })
		local velocity = sb.require("Util.PhysicsUtil").Velocity.new(part, sb.Vector3.new(), sb.Vector3.new(), -1)
		sb.advance(5)
		eq(#constraints(part), 1)
		part:Destroy()
		eq(velocity.basePart, nil)
	end)

	it("replaces equal or lower priority velocities and leaves higher ones", function()
		local sb = sandbox()
		local Velocity = sb.require("Util.PhysicsUtil").Velocity
		local part = sb.new("Part", { Parent = sb.workspace })

		local low = Velocity.new(part, sb.Vector3.new(), sb.Vector3.new(), -1, 1)
		local high = Velocity.new(part, sb.Vector3.new(), sb.Vector3.new(), -1, 5)
		eq(low.basePart, nil, "lower priority replaced")
		eq(#constraints(part), 1)

		Velocity.new(part, sb.Vector3.new(), sb.Vector3.new(), -1, 2)
		ok(high.basePart, "higher priority kept")
		eq(#constraints(part), 2)
	end)

	it("sets the priority before the attachment becomes visible to others", function()
		local sb = sandbox()
		local part = sb.new("Part", { Parent = sb.workspace })
		local priorityWhenAdded = "unset"
		part.ChildAdded:Connect(function(child)
			priorityWhenAdded = child:GetAttribute("velocityPriority")
		end)
		sb.require("Util.PhysicsUtil").Velocity.new(part, sb.Vector3.new(), sb.Vector3.new(), -1, 3)
		eq(priorityWhenAdded, 3)
	end)

	it("does not throw on a same-named attachment with no priority", function()
		local sb = sandbox()
		local part = sb.new("Part", { Parent = sb.workspace })
		sb.new("Attachment", { Name = "MysLibVelocityAttachment", Parent = part })
		sb.require("Util.PhysicsUtil").Velocity.new(part, sb.Vector3.new(), sb.Vector3.new(), -1)
		eq(#constraints(part), 1)
	end)
end)

describe("PhysicsUtil.Orientation", function()
	local function attachments(part)
		local found = {}
		for _, child in part:GetChildren() do
			if child:IsA("Attachment") then
				table.insert(found, child)
			end
		end
		return found
	end

	it("creates the constraint, updates it, and expires after its duration", function()
		local sb = sandbox()
		local Orientation = sb.require("Util.PhysicsUtil").Orientation
		local part = sb.new("Part", { Parent = sb.workspace })
		local orientation = Orientation.new(part, 1000, sb.CFrame.new(), 1)

		eq(#attachments(part), 1)
		orientation:SetCFrame(sb.CFrame.new(1, 0, 0))
		eq(orientation.align_orientation.CFrame, sb.CFrame.new(1, 0, 0))
		orientation:SetMaxTorque(5)
		eq(orientation.align_orientation.MaxTorque, 5)

		sb.advance(1.1)
		eq(#attachments(part), 0)
		orientation:SetMaxTorque(5)
		orientation:Destroy()
	end)

	it("replaces equal or lower priority orientations instead of stacking them", function()
		local sb = sandbox()
		local Orientation = sb.require("Util.PhysicsUtil").Orientation
		local part = sb.new("Part", { Parent = sb.workspace })

		local low = Orientation.new(part, 1000, sb.CFrame.new(), -1, 1)
		Orientation.new(part, 1000, sb.CFrame.new(), -1, 1)
		eq(low.base_part, nil, "equal priority replaced")
		eq(#attachments(part), 1)

		local high = Orientation.new(part, 1000, sb.CFrame.new(), -1, 5)
		eq(#attachments(part), 1)

		Orientation.new(part, 1000, sb.CFrame.new(), -1, 2)
		ok(high.base_part, "higher priority kept")
		eq(#attachments(part), 2)
	end)

	it("does not throw on a same-named attachment with no priority", function()
		local sb = sandbox()
		local part = sb.new("Part", { Parent = sb.workspace })
		sb.new("Attachment", { Name = "mysLibAlignOrientationAttachment", Parent = part })
		sb.require("Util.PhysicsUtil").Orientation.new(part, 1000, sb.CFrame.new(), -1)
		eq(#attachments(part), 1)
	end)
end)

describe("PhysicsUtil vectors", function()
	it("measures and normalises on the XZ plane", function()
		local sb = sandbox()
		local PhysicsUtil = sb.require("Util.PhysicsUtil")
		near(PhysicsUtil.getHorizontalDistance(sb.Vector3.new(0, 100, 0), sb.Vector3.new(3, -100, 4)), 5)

		local unit = PhysicsUtil.getHorizontalNormalizedVector(sb.Vector3.new(3, 50, 4))
		near(unit.Magnitude, 1)
		eq(unit.Y, 0)
		eq(PhysicsUtil.getHorizontalNormalizedVector(sb.Vector3.new(0, 5, 0)), sb.Vector3.new())
	end)
end)
