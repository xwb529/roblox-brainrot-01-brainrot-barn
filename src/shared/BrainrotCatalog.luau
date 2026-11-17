-- Original characters: every shape is constructed locally; no meshes or asset IDs.
local Catalog = {}
Catalog.Rarities = {
	Common = { color = Color3.fromRGB(214, 232, 215), weight = 55, mutationChance = 0.14 },
	Rare = { color = Color3.fromRGB(93, 191, 255), weight = 27, mutationChance = 0.10 },
	Epic = { color = Color3.fromRGB(191, 125, 255), weight = 12, mutationChance = 0.07 },
	Legendary = { color = Color3.fromRGB(255, 190, 66), weight = 5, mutationChance = 0.045 },
	Mythic = { color = Color3.fromRGB(255, 98, 150), weight = 1, mutationChance = 0.025 },
}
Catalog.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic" }
Catalog.Entries = {
	{ id = "sip", name = "Sippuccino Sprout", rarity = "Common", price = 80, income = 3,
		body = "Cup", accessory = "Straw", color = Color3.fromRGB(217, 171, 117) },
	{ id = "spud", name = "Boogie Spudnik", rarity = "Common", price = 140, income = 5,
		body = "Potato", accessory = "Disco", color = Color3.fromRGB(190, 140, 77) },
	{ id = "pea", name = "Peabody Pogo", rarity = "Common", price = 220, income = 8,
		body = "Pea", accessory = "Spring", color = Color3.fromRGB(143, 215, 85) },
	{ id = "toast", name = "Toastie Postie", rarity = "Common", price = 320, income = 11,
		body = "Toast", accessory = "Envelope", color = Color3.fromRGB(246, 210, 137) },
	{ id = "shark", name = "Bananafin Bloop", rarity = "Rare", price = 650, income = 24,
		body = "Shark", accessory = "Peel", color = Color3.fromRGB(250, 217, 67) },
	{ id = "crab", name = "Crumbclaw Courier", rarity = "Rare", price = 1000, income = 36,
		body = "Croissant", accessory = "Claws", color = Color3.fromRGB(223, 146, 67) },
	{ id = "frog", name = "Wobble Wafflehop", rarity = "Rare", price = 1600, income = 58,
		body = "Waffle", accessory = "FrogEyes", color = Color3.fromRGB(223, 172, 84) },
	{ id = "giraffe", name = "Noodleneck Nibbler", rarity = "Epic", price = 3200, income = 115,
		body = "Giraffe", accessory = "Noodles", color = Color3.fromRGB(247, 205, 104) },
	{ id = "jelly", name = "Jamjar Jamboree", rarity = "Epic", price = 5200, income = 185,
		body = "Jar", accessory = "Headphones", color = Color3.fromRGB(210, 96, 170) },
	{ id = "turtle", name = "Shellshot Sputnik", rarity = "Epic", price = 8000, income = 280,
		body = "Turtle", accessory = "Rocket", color = Color3.fromRGB(102, 187, 151) },
	{ id = "panda", name = "Pretzel Pandemonium", rarity = "Legendary", price = 16000, income = 570,
		body = "Panda", accessory = "Pretzel", color = Color3.fromRGB(244, 226, 195) },
	{ id = "duck", name = "Dumpling Duckonaut", rarity = "Legendary", price = 28000, income = 1000,
		body = "Duck", accessory = "Saturn", color = Color3.fromRGB(250, 226, 153) },
	{ id = "dragon", name = "Mochisaurus Moonbeam", rarity = "Mythic", price = 65000, income = 2400,
		body = "Dragon", accessory = "Wings", color = Color3.fromRGB(182, 149, 244) },
	{ id = "cow", name = "Cosmic Curdleking", rarity = "Mythic", price = 95000, income = 3600,
		body = "Cow", accessory = "Crown", color = Color3.fromRGB(154, 226, 246) },
}
Catalog.Mutations = {
	Normal = { multiplier = 1 },
	Gold = { multiplier = 2, color = Color3.fromRGB(255, 204, 55) },
	Diamond = { multiplier = 3, color = Color3.fromRGB(109, 243, 255) },
}
function Catalog.Get(id)
	for _, entry in ipairs(Catalog.Entries) do
		if entry.id == id then return entry end
	end
	return nil
end
function Catalog.Roll(random)
	local roll = random:NextNumber(0, 100)
	local rarity = "Common"
	for _, name in ipairs(Catalog.RarityOrder) do
		roll -= Catalog.Rarities[name].weight
		if roll <= 0 then rarity = name; break end
	end
	local pool = {}
	for _, entry in ipairs(Catalog.Entries) do
		if entry.rarity == rarity then table.insert(pool, entry) end
	end
	local entry = pool[random:NextInteger(1, #pool)]
	local mutation = "Normal"
	if random:NextNumber() < Catalog.Rarities[rarity].mutationChance then
		mutation = if random:NextNumber() < 0.22 then "Diamond" else "Gold"
	end
	return entry, mutation
end
return Catalog
