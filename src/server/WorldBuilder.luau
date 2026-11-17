-- A completely procedural toy-town. No asset service, meshes, textures or decals.
local World = {}
local C = {
	grass = Color3.fromRGB(121, 179, 111), path = Color3.fromRGB(242, 222, 180),
	ink = Color3.fromRGB(36, 53, 58), cream = Color3.fromRGB(255, 245, 220),
	mint = Color3.fromRGB(119, 228, 177), gold = Color3.fromRGB(255, 207, 92),
}

function World.Part(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function World.Text(part, text, color, face)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignText"
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 28
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.94, 0.9)
	label.Position = UDim2.fromScale(0.03, 0.05)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or C.cream
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	return label
end

function World.Sign(parent, name, cf, size, text, color)
	local board = World.Part(parent, name, size, cf, color or C.ink, Enum.Material.Wood)
	local front = World.Text(board, text)
	World.Text(board, text, nil, Enum.NormalId.Back)
	return board, front
end

function World.Prompt(parent, action, object, hold)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = hold or 0.25
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = parent
	return prompt
end

local function tree(parent, x, z, scale)
	local trunk = CFrame.new(x, 2.5 * scale, z)
	World.Part(parent, "TreeTrunk", Vector3.new(1.5, 5, 1.5) * scale, trunk, Color3.fromRGB(127, 90, 65), Enum.Material.Wood)
	for i = 0, 2 do
		World.Part(parent, "RoundCanopy", Vector3.new(7 - i, 6 - i, 7 - i) * scale,
			CFrame.new(x + (i - 1) * 1.6 * scale, (6.4 + i * 1.3) * scale, z),
			Color3.fromRGB(74 + i * 13, 142 + i * 12, 91 + i * 4), nil, Enum.PartType.Ball)
	end
end

local function buildPlot(parent, index, x, z, color)
	local model = Instance.new("Model")
	model.Name = "Barn" .. index
	model:SetAttribute("PlotIndex", index)
	model:SetAttribute("OwnerId", 0)
	model.Parent = parent
	local center = Vector3.new(x, 0, z)
	local facing = if z < 0 then math.pi else 0
	local frame = CFrame.new(center) * CFrame.Angles(0, facing, 0)
	local function p(name, size, pos, tint)
		return World.Part(model, name, size, frame * CFrame.new(pos), tint)
	end
	p("Foundation", Vector3.new(57, 2, 41), Vector3.new(0, 0.7, 0), C.cream)
	p("BarnFloor", Vector3.new(54, 0.2, 38), Vector3.new(0, 1.8, 0), Color3.fromRGB(225, 201, 156))
	-- Open-front barn silhouette, so every pad remains visible from the plaza.
	p("BackWall", Vector3.new(56, 9, 1), Vector3.new(0, 6.2, 20), color)
	for _, side in ipairs({ -1, 1 }) do
		p("SideFence", Vector3.new(1, 2.4, 40), Vector3.new(side * 28, 2.7, 0), color)
		p("BarnPost", Vector3.new(1.5, 13, 1.5), Vector3.new(side * 27, 7.5, -19), color)
		p("BarnPost", Vector3.new(1.5, 13, 1.5), Vector3.new(side * 27, 7.5, 19), color)
	end
	p("Lintel", Vector3.new(57, 2, 2), Vector3.new(0, 13.8, 19), C.cream)
	local nameBoard, nameLabel = World.Sign(model, "OwnerSign", frame * CFrame.new(0, 10, 19.3), Vector3.new(25, 4, 0.8), "BARN " .. index .. "\nOPEN FOR A FARMER", C.ink)
	local panel = p("LockPanel", Vector3.new(4.5, 4, 2), Vector3.new(-23, 4, -18), C.mint)
	local lockLabel = World.Text(panel, "LOCK\nREADY", C.ink)
	local lockPrompt = World.Prompt(panel, "Lock for 60s", "Barn security", 0.35)
	local claimPrompt = World.Prompt(nameBoard, "Claim barn", "Free plot", 0.35)
	claimPrompt.MaxActivationDistance = 24
	local barrier = p("LockBarrier", Vector3.new(52, 6, 0.3), Vector3.new(0, 4.8, -19), C.mint)
	barrier.Material = Enum.Material.ForceField
	barrier.Transparency = 1
	barrier.CanCollide = false
	local pads = {}
	for row = 1, 2 do
		for col = 1, 3 do
			local n = (row - 1) * 3 + col
			local pad = p("Pad" .. n, Vector3.new(12, 0.45, 11), Vector3.new((col - 2) * 16, 2.1, (row - 1) * 15 - 6), Color3.fromRGB(164, 208, 143))
			World.Text(pad, "PAD " .. n, C.ink, Enum.NormalId.Top)
			local prompt = World.Prompt(pad, "Place follower", "Empty pad " .. n, 0.35)
			table.insert(pads, { part = pad, prompt = prompt, occupant = nil, index = n })
		end
	end
	-- A low step makes the raised flood-safe foundations walkable without jumping.
	p("EntryStep", Vector3.new(18, 0.8, 4), Vector3.new(0, 0.4, -22), color)
	return {
		index = index, model = model, center = center, frame = frame, color = color,
		nameLabel = nameLabel, sign = nameBoard, pads = pads, owner = nil,
		panel = panel, lockPrompt = lockPrompt, lockLabel = lockLabel, barrier = barrier,
		claimPrompt = claimPrompt, lockUntil = 0, readyAt = 0,
		spawn = frame * CFrame.new(0, 5, -15), entrance = (frame * CFrame.new(0, 2, -24)).Position,
	}
end

function World.Build()
	local root = Instance.new("Folder")
	root.Name = "BrainrotBarn"
	root.Parent = workspace
	local ground = World.Part(root, "Meadow", Vector3.new(360, 6, 330), CFrame.new(0, -3.5, 0), C.grass, Enum.Material.Grass)
	World.Part(root, "Plaza", Vector3.new(250, 1, 49), CFrame.new(0, 0, 0), C.path, Enum.Material.Concrete)
	World.Part(root, "WelcomePath", Vector3.new(22, 0.6, 102), CFrame.new(0, 0, 78), C.path)
	World.Part(root, "NorthPath", Vector3.new(18, 0.5, 76), CFrame.new(0, 0, -69), C.path)
	for _, z in ipairs({ -30, 30 }) do
		World.Part(root, "BarnWalk", Vector3.new(217, 0.5, 10), CFrame.new(0, 0.1, z), C.path)
	end
	local lane = World.Part(root, "Conveyor", Vector3.new(238, 0.6, 12), CFrame.new(0, 0.8, 0), C.ink, Enum.Material.Metal)
	for x = -116, 116, 8 do
		World.Part(root, "BeltSlat", Vector3.new(0.25, 0.08, 11.7), CFrame.new(x, 1.14, 0), Color3.fromRGB(77, 98, 101))
		World.Part(root, "DirectionArrow", Vector3.new(1.5, 0.12, 1.5), CFrame.new(x, 1.18, 0) * CFrame.Angles(0, math.pi / 4, 0), C.gold)
	end
	for _, z in ipairs({ -6.5, 6.5 }) do
		World.Part(root, "ConveyorTrim", Vector3.new(240, 0.8, 0.5), CFrame.new(0, 0.8, z), C.gold)
	end
	for _, x in ipairs({ -120, 120 }) do
		for _, z in ipairs({ -7.5, 7.5 }) do World.Part(root, "PortalPost", Vector3.new(2, 12, 2), CFrame.new(x, 6, z), C.ink) end
		World.Part(root, "PortalLintel", Vector3.new(2.5, 2, 18), CFrame.new(x, 12, 0), C.gold)
		local portal = World.Part(root, "PortalGlow", Vector3.new(0.3, 10, 13), CFrame.new(x, 6, 0), Color3.fromRGB(110, 233, 204), Enum.Material.Neon)
		portal.Transparency = 0.72
		portal.CanCollide = false
	end
	World.Sign(root, "MarketSign", CFrame.new(-98, 14, -10), Vector3.new(34, 5, 1), "THE SILLY EXPRESS\nFresh brainrots every 5 seconds")
	local plots = {}
	local colors = { Color3.fromRGB(209, 104, 96), Color3.fromRGB(99, 158, 181), Color3.fromRGB(173, 133, 188),
		Color3.fromRGB(221, 165, 91), Color3.fromRGB(101, 170, 137), Color3.fromRGB(208, 128, 162) }
	for index = 1, 6 do
		local x = ((index - 1) % 3 - 1) * 70
		local z = if index <= 3 then -58 else 58
		table.insert(plots, buildPlot(root, index, x, z, colors[index]))
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "WelcomeSpawn"
	spawn.Size = Vector3.new(16, 0.6, 12)
	spawn.CFrame = CFrame.new(0, 0.4, 105)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = C.mint
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Parent = root
	-- SpawnLocation's stock decal is never needed; the welcome floor uses SurfaceGui text.
	World.Text(spawn, "WELCOME, FARMER", C.ink, Enum.NormalId.Top)
	World.Sign(root, "Title", CFrame.new(0, 18, 96), Vector3.new(57, 8, 1.5), "BRAINROT BARN\nBUY • BRING HOME • BECOME RIDICULOUS", Color3.fromRGB(57, 100, 83))
	for _, x in ipairs({ -28, 28 }) do World.Part(root, "TitlePost", Vector3.new(1.5, 18, 1.5), CFrame.new(x, 9, 96), C.cream) end
	World.Sign(root, "HowTo", CFrame.new(-41, 6, 104), Vector3.new(24, 10, 1),
		"THE FARMER'S ALMANAC\n1  Buy on the conveyor [E]\n2  Walk onto your barn's pads\n3  Earn cash every second\n4  Lock up before the thief!\nBlue warning? Get off the lane.")
	World.Sign(root, "MutationGuide", CFrame.new(43, 6, 104), Vector3.new(24, 10, 1),
		"SOMETHING SHINY?\nGOLD = 2x income\nDIAMOND = 3x income\nRare critters mutate less often.\nHill + barns are flood-safe.\nRebirth for a lasting +50%!")
	local shops = {}
	for _, spec in ipairs({ { key = "Speed", x = -17, color = C.gold, text = "ZOOM BOOTS\n+5 walk speed\n[E] Buy upgrade" },
		{ key = "Carry", x = 17, color = C.mint, text = "BIGGER PARADE\n+1 carry capacity\n[E] Buy upgrade" } }) do
		local pad = World.Part(root, spec.key .. "Shop", Vector3.new(12, 0.7, 12), CFrame.new(spec.x, 0.5, 120), spec.color)
		World.Text(pad, spec.key:upper(), C.ink, Enum.NormalId.Top)
		World.Sign(root, spec.key .. "ShopSign", CFrame.new(spec.x, 5, 128), Vector3.new(12, 6, 0.8), spec.text, C.ink)
		shops[spec.key] = { part = pad, prompt = World.Prompt(pad, "Buy " .. spec.key .. " upgrade", "Price on HUD", 0.4) }
	end
	local rebirth = World.Part(root, "RebirthAltar", Vector3.new(12, 1, 10), CFrame.new(0, 0.7, 143), Color3.fromRGB(179, 143, 230), Enum.Material.Neon)
	World.Text(rebirth, "REBIRTH", C.ink, Enum.NormalId.Top)
	World.Sign(root, "RebirthSign", CFrame.new(0, 5, 150), Vector3.new(22, 6, 1), "THE FRESH START\n+50% income per rebirth\nCash + collection reset; upgrades stay")
	-- Plateau with eight shallow steps, approachable directly from the plaza.
	World.Part(root, "HighGround", Vector3.new(35, 18, 46), CFrame.new(150, 8.5, 0), Color3.fromRGB(99, 155, 103), Enum.Material.Grass)
	for step = 1, 12 do
		local height = step * 1.5
		World.Part(root, "HillStep", Vector3.new(3, height, 17), CFrame.new(98 + step * 3, height / 2 - 0.5, 15), C.grass, Enum.Material.Grass)
	end
	World.Sign(root, "HillSign", CFrame.new(150, 22, -12), Vector3.new(26, 6, 1), "HIGH GROUND\nWave-free. Worry-free.", Color3.fromRGB(57, 100, 83))
	tree(root, 156, 12, 0.9)
	for _, z in ipairs({ -110, 90 }) do
		for _, x in ipairs({ -139, -111, 110, 139 }) do tree(root, x, z, 0.8 + math.abs(x) % 3 * 0.15) end
	end
	for x = -155, 155, 31 do tree(root, x, -142, 1.2) end
	for _, x in ipairs({ -170, 174 }) do
		World.Part(root, "BoundaryFence", Vector3.new(1, 5, 300), CFrame.new(x, 2, 0), Color3.fromRGB(221, 209, 169), Enum.Material.Wood)
	end
	for _, z in ipairs({ -154, 160 }) do
		World.Part(root, "BoundaryFence", Vector3.new(345, 5, 1), CFrame.new(0, 2, z), Color3.fromRGB(221, 209, 169), Enum.Material.Wood)
	end
	local characters = Instance.new("Folder")
	characters.Name = "Critters"
	characters.Parent = root
	local effects = Instance.new("Folder")
	effects.Name = "Threats"
	effects.Parent = root
	return { root = root, plots = plots, lane = lane, shops = shops, spawn = spawn,
		rebirth = rebirth, rebirthPrompt = World.Prompt(rebirth, "Rebirth…", "Confirmation required", 0.4),
		characters = characters, effects = effects, ground = ground }
end
return World
