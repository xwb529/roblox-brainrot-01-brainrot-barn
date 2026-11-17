local Catalog = require(script.Parent.BrainrotCatalog)
local Economy = require(script.Parent.Economy)
local Builder = {}
local cream = Color3.fromRGB(255, 243, 212)
local ink = Color3.fromRGB(36, 39, 55)
local pink = Color3.fromRGB(249, 137, 157)

function Builder.Build(entry, mutationName)
	local model = Instance.new("Model")
	model.Name = entry.name
	model:SetAttribute("CatalogId", entry.id)
	model:SetAttribute("Mutation", mutationName)
	local mutation = Catalog.Mutations[mutationName] or Catalog.Mutations.Normal
	local color = mutation.color or entry.color
	local function part(name, size, position, tint, shape, rotation)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
		p.Color = tint or color
		p.Shape = shape or Enum.PartType.Block
		p.Material = if mutationName == "Diamond" then Enum.Material.Glass else Enum.Material.SmoothPlastic
		if mutationName == "Gold" then p.Material = Enum.Material.Metal end
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local function ball(name, size, position, tint)
		return part(name, size, position, tint, Enum.PartType.Ball)
	end
	local function rod(name, size, position, tint, rotation)
		return part(name, size, position, tint, Enum.PartType.Cylinder, rotation or CFrame.Angles(0, 0, math.pi / 2))
	end
	local root = part("Root", Vector3.one, Vector3.zero)
	root.Transparency = 1
	model.PrimaryPart = root
	local body = entry.body
	if body == "Cup" or body == "Jar" then
		rod("Vessel", Vector3.new(2.7, 2.5, 2.5), Vector3.new(0, 2, 0))
		rod("Rim", Vector3.new(0.22, 2.8, 2.8), Vector3.new(0, 3.4, 0), cream)
		rod("Contents", Vector3.new(0.1, 2.3, 2.3), Vector3.new(0, 3.55, 0), if body == "Cup" then Color3.fromRGB(100, 61, 45) else pink)
	elseif body == "Giraffe" then
		ball("Body", Vector3.new(2.5, 2, 2), Vector3.new(0, 1.7, 0))
		part("NoodleNeck", Vector3.new(0.8, 3.3, 0.8), Vector3.new(0, 3, -0.4))
		ball("Head", Vector3.new(2.2, 1.4, 1.8), Vector3.new(0, 4.5, -0.6))
	elseif body == "Shark" then
		ball("BananaBody", Vector3.new(2, 2.3, 3.6), Vector3.new(0, 2, 0))
		part("DorsalFin", Vector3.new(0.25, 1.6, 1.4), Vector3.new(0, 3.3, 0.6), color, Enum.PartType.Wedge)
		part("TailFin", Vector3.new(1.8, 1.8, 0.3), Vector3.new(0, 2.1, 2), color, Enum.PartType.Wedge)
	elseif body == "Croissant" then
		for i = -2, 2 do
			ball("PastrySegment", Vector3.new(1.2, 1.7 - math.abs(i) * 0.2, 1.9), Vector3.new(i * 0.65, 2, math.abs(i) * 0.3))
		end
	elseif body == "Toast" or body == "Waffle" then
		part("Crust", Vector3.new(2.8, 2.8, 1.3), Vector3.new(0, 2, 0))
		part("SoftMiddle", Vector3.new(2.3, 2.25, 1.4), Vector3.new(0, 2.1, 0), cream)
		if body == "Waffle" then
			for i = -1, 1 do
				part("WaffleGrid", Vector3.new(0.12, 2.1, 0.12), Vector3.new(i * 0.65, 2.1, -0.76), color)
				part("WaffleGrid", Vector3.new(2.1, 0.12, 0.12), Vector3.new(0, 2.1 + i * 0.65, -0.76), color)
			end
		end
	elseif body == "Turtle" then
		ball("Shell", Vector3.new(3.5, 2.3, 3), Vector3.new(0, 1.8, 0))
		ball("Head", Vector3.new(1.9, 1.7, 1.8), Vector3.new(0, 2, -1.7), cream)
		for _, x in ipairs({ -1.4, 1.4 }) do
			for _, z in ipairs({ -1, 1 }) do ball("Flipper", Vector3.new(1, 0.5, 1.4), Vector3.new(x, 0.7, z)) end
		end
	elseif body == "Panda" or body == "Cow" then
		ball("Body", Vector3.new(2.8, 2.5, 2.3), Vector3.new(0, 1.7, 0))
		ball("Head", Vector3.new(2.7, 2, 2.2), Vector3.new(0, 3.1, -0.4), cream)
		for _, x in ipairs({ -1.2, 1.2 }) do ball("Ears", Vector3.new(0.8, 0.8, 0.6), Vector3.new(x, 4, -0.4), ink) end
		ball("Muzzle", Vector3.new(1.4, 0.8, 0.4), Vector3.new(0, 2.8, -1.55), pink)
	elseif body == "Duck" then
		ball("Dumpling", Vector3.new(3, 2.4, 2.7), Vector3.new(0, 1.7, 0))
		ball("Head", Vector3.new(2, 2, 2), Vector3.new(0, 3, -0.6))
		part("Beak", Vector3.new(1.5, 0.4, 1), Vector3.new(0, 2.9, -1.8), Color3.fromRGB(255, 149, 58))
	elseif body == "Dragon" then
		ball("MochiBody", Vector3.new(2.7, 3, 2.4), Vector3.new(0, 2, 0))
		ball("Head", Vector3.new(2.5, 2.1, 2.1), Vector3.new(0, 3.4, -0.7))
		for i = 1, 3 do ball("Tail", Vector3.one * (1.3 - i * 0.2), Vector3.new(0, 1.5, 1 + i * 0.6)) end
	else
		ball("Body", Vector3.new(2.5, 3, 2.3), Vector3.new(0, 2, 0))
	end
	local eyeY = if body == "Giraffe" then 4.6 elseif body == "Panda" or body == "Cow" or body == "Duck" or body == "Dragon" then 3.4 else 2.5
	local eyeZ = if body == "Turtle" then -2.5 elseif body == "Shark" then -1.65 elseif body == "Toast" or body == "Waffle" then -0.83 else -1.3
	for _, x in ipairs({ -0.52, 0.52 }) do
		ball("EyeWhite", Vector3.new(0.7, 0.8, 0.36), Vector3.new(x, eyeY, eyeZ), Color3.new(1, 1, 1))
		ball("Pupil", Vector3.new(0.29, 0.4, 0.16), Vector3.new(x + 0.06, eyeY, eyeZ - 0.2), ink)
	end
	part("Smile", Vector3.new(0.5, 0.12, 0.16), Vector3.new(0, eyeY - 0.6, eyeZ - 0.05), ink)
	for _, x in ipairs({ -0.75, 0.75 }) do
		ball("Shoe", Vector3.new(0.85, 0.55, 1.1), Vector3.new(x, 0.3, -0.2), ink)
	end
	local accessory = entry.accessory
	if accessory == "Straw" then
		part("StripedStraw", Vector3.new(0.25, 2.3, 0.25), Vector3.new(0.6, 4.2, 0), pink, nil, CFrame.Angles(0, 0, -0.2))
		ball("Sprout", Vector3.new(1, 0.3, 0.5), Vector3.new(-0.3, 4, 0), Color3.fromRGB(106, 194, 97))
	elseif accessory == "Disco" then
		local disco = ball("DiscoBall", Vector3.one * 1.5, Vector3.new(0, 4.1, 0), Color3.fromRGB(165, 227, 255))
		disco.Material = Enum.Material.Metal
		for i = -1, 1 do part("MirrorStripe", Vector3.new(1.4, 0.1, 0.1), Vector3.new(0, 4.1 + i * 0.35, -0.65), cream) end
	elseif accessory == "Spring" then
		for i = 1, 5 do rod("PogoSpring", Vector3.new(0.1, 0.8, 0.8), Vector3.new(0, 3.4 + i * 0.17, 0), cream) end
	elseif accessory == "Envelope" then
		part("Mailbag", Vector3.new(1.3, 0.9, 0.4), Vector3.new(1.5, 1.9, 0), Color3.fromRGB(102, 179, 219))
		part("Letter", Vector3.new(0.8, 0.6, 0.15), Vector3.new(1.5, 2.4, 0), cream)
	elseif accessory == "Peel" then
		for _, x in ipairs({ -1, 1 }) do part("BananaPeel", Vector3.new(0.6, 2, 0.5), Vector3.new(x, 2.2, 1.5), cream, nil, CFrame.Angles(0, 0, x * 0.7)) end
	elseif accessory == "Claws" then
		for _, x in ipairs({ -1, 1 }) do
			part("Arm", Vector3.new(1.4, 0.35, 0.35), Vector3.new(x * 2, 1.6, -0.6), pink)
			ball("CrabClaw", Vector3.new(1.1, 1.3, 0.8), Vector3.new(x * 2.7, 2, -0.6), pink)
		end
	elseif accessory == "FrogEyes" then
		for _, x in ipairs({ -0.9, 0.9 }) do ball("FrogKnob", Vector3.one * 0.9, Vector3.new(x, 3.7, 0), Color3.fromRGB(137, 205, 101)) end
	elseif accessory == "Noodles" then
		for i = -2, 2 do part("NoodleHair", Vector3.new(0.2, 1 + (i % 2) * 0.3, 0.2), Vector3.new(i * 0.3, 5.3, 0), cream, nil, CFrame.Angles(0, 0, i * 0.15)) end
	elseif accessory == "Headphones" then
		part("Headband", Vector3.new(3.2, 0.35, 0.5), Vector3.new(0, 3.9, 0), ink)
		for _, x in ipairs({ -1.5, 1.5 }) do ball("EarCup", Vector3.new(0.7, 1.2, 1.1), Vector3.new(x, 3.3, 0), Color3.fromRGB(119, 240, 218)) end
	elseif accessory == "Rocket" then
		for _, x in ipairs({ -0.85, 0.85 }) do
			rod("Booster", Vector3.new(2.7, 0.8, 0.8), Vector3.new(x, 3, 0.4), cream, CFrame.Angles(0, math.pi / 2, 0))
			ball("Flame", Vector3.new(0.6, 0.6, 1.1), Vector3.new(x, 3, 2), Color3.fromRGB(255, 142, 64))
		end
	elseif accessory == "Pretzel" then
		for _, x in ipairs({ -0.55, 0.55 }) do
			for i = 0, 7 do
				local angle = i * math.pi / 4
				ball("PretzelLoop", Vector3.one * 0.4, Vector3.new(x + math.cos(angle) * 0.6, 4.8 + math.sin(angle) * 0.5, 0), Color3.fromRGB(189, 118, 59))
			end
		end
	elseif accessory == "Saturn" then
		ball("PlanetHat", Vector3.one * 1.1, Vector3.new(0, 4.5, 0), pink)
		rod("SaturnRing", Vector3.new(0.12, 2, 2), Vector3.new(0, 4.5, 0), Color3.fromRGB(136, 202, 255))
	elseif accessory == "Wings" then
		for _, x in ipairs({ -1, 1 }) do part("MoonWing", Vector3.new(2.3, 2, 0.3), Vector3.new(x * 2, 3, 0.6), pink, Enum.PartType.Wedge, CFrame.Angles(0, 0, x * 0.3)) end
	elseif accessory == "Crown" then
		part("CrownBand", Vector3.new(2.4, 0.45, 1.7), Vector3.new(0, 4.3, -0.4), Color3.fromRGB(255, 205, 60))
		for i = -1, 1 do part("CrownPoint", Vector3.new(0.45, 0.9, 0.5), Vector3.new(i * 0.8, 4.85, -0.8), Color3.fromRGB(255, 205, 60), Enum.PartType.Wedge) end
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Identity"
	billboard.Size = UDim2.fromOffset(232, 92)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 7.1, 0)
	billboard.MaxDistance = 90
	billboard.AlwaysOnTop = true
	billboard.Adornee = root
	billboard.Parent = root
	local text = Instance.new("TextLabel")
	text.Name = "Info"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundColor3 = Color3.fromRGB(25, 35, 44)
	text.BackgroundTransparency = 0.18
	text.TextColor3 = Catalog.Rarities[entry.rarity].color
	text.Font = Enum.Font.GothamBold
	text.TextSize = 15
	text.TextStrokeTransparency = 0.65
	text.Parent = billboard
	Instance.new("UICorner", text).CornerRadius = UDim.new(0, 10)
	Builder.Label(model, entry, mutationName, entry.income * mutation.multiplier, "BUY $" .. Economy.Format(entry.price))
	return model
end

function Builder.Label(model, entry, mutation, income, status)
	local root = model.PrimaryPart
	if not root then return end
	local label = root:FindFirstChild("Identity")
	if not label then return end
	local prefix = if mutation == "Normal" then "" else mutation .. " "
	label.Info.Text = prefix .. entry.name .. "\n" .. entry.rarity .. "  •  +$" .. Economy.Format(income) .. "/s\n" .. status
end
return Builder
