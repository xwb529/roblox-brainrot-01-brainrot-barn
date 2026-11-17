local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.BrainrotCatalog)
local Economy = require(Shared.Economy)
local Builder = require(Shared.BuildCharacter)
local World = require(script.Parent.WorldBuilder)
local GameServer = {}
GameServer.__index = GameServer

function GameServer.new(world, remotes)
	return setmetatable({ world = world, remotes = remotes, states = {}, lane = {},
		random = Random.new(), wavePhase = "Calm", nextWave = workspace:GetServerTimeNow() + 180,
		waveRemaining = 0, floodActive = false, tick = 0, placementTick = 0, spawnTick = 0, spawnCount = 0,
	}, GameServer)
end

function GameServer:Notify(player, text, kind)
	if player.Parent == Players then self.remotes.Notice:FireClient(player, text, kind or "info") end
end

function GameServer:Near(player, part, radius)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return root ~= nil and humanoid ~= nil and humanoid.Health > 0 and (root.Position - part.Position).Magnitude <= radius
end

function GameServer:Rate(state, key, delay)
	local now = os.clock()
	if now < (state.rates[key] or 0) then return false end
	state.rates[key] = now + delay
	return true
end

function GameServer:Income(record, state)
	return Economy.Income(record.entry, Catalog.Mutations[record.mutation].multiplier, state.rebirths.Value)
end

function GameServer:TotalIncome(state)
	local income = 0
	if state.plot then
		for _, pad in ipairs(state.plot.pads) do
			if pad.occupant then income += self:Income(pad.occupant, state) end
		end
	end
	return income
end

function GameServer:Snapshot(player)
	local state = self.states[player]
	if not state then return nil end
	local plot = state.plot
	local now = workspace:GetServerTimeNow()
	local occupied = 0
	if plot then for _, pad in ipairs(plot.pads) do if pad.occupant then occupied += 1 end end end
	return {
		cash = state.cash.Value, income = self:TotalIncome(state), rebirths = state.rebirths.Value,
		multiplier = Economy.Multiplier(state.rebirths.Value), rebirthPrice = Economy.RebirthPrice(state.rebirths.Value),
		carry = #state.carry, capacity = state.capacity, speed = 18 + state.speedLevel * 5,
		speedPrice = Economy.SpeedPrice(state.speedLevel), carryPrice = Economy.CarryPrice(state.capacity),
		speedMax = state.speedLevel >= Economy.MaxSpeedLevel, carryMax = state.capacity >= Economy.MaxCarry,
		plot = if plot then plot.index else 0, occupied = occupied,
		lockRemaining = if plot then math.max(0, math.ceil(plot.lockUntil - now)) else 0,
		cooldown = if plot then math.max(0, math.ceil(plot.readyAt - now)) else 0,
		wavePhase = self.wavePhase, nextWave = self.nextWave, waveRemaining = self.waveRemaining,
		collection = state.discovered,
	}
end

function GameServer:Push(player)
	local snapshot = self:Snapshot(player)
	if snapshot and player.Parent == Players then self.remotes.State:FireClient(player, snapshot) end
end

function GameServer:Assign(player, plot)
	local state = self.states[player]
	if not state or state.plot or plot.owner then return false end
	state.plot = plot
	plot.owner = player
	plot.model:SetAttribute("OwnerId", player.UserId)
	plot.nameLabel.Text = player.DisplayName .. "'s BARN\nBARN " .. plot.index .. " • FLOOD SAFE"
	-- Keep both sides of the owner board in sync.
	for _, gui in ipairs(plot.sign:GetChildren()) do
		if gui:IsA("SurfaceGui") then gui:FindFirstChildOfClass("TextLabel").Text = plot.nameLabel.Text end
	end
	plot.claimPrompt.Enabled = false
	self:Push(player)
	return true
end

function GameServer:RefundCarry(state)
	for _, record in ipairs(state.carry) do
		state.cash.Value += record.entry.price
		record.model:Destroy()
	end
	table.clear(state.carry)
end

function GameServer:CharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local state = self.states[player]
	if not state or not humanoid or not root then return end
	humanoid.WalkSpeed = 18 + state.speedLevel * 5
	if state.plot then
		character:PivotTo(state.plot.spawn)
	else
		character:PivotTo(CFrame.new(0, 5, 105))
	end
	humanoid.Died:Connect(function()
		if self.states[player] ~= state then return end
		if #state.carry > 0 then
			self:RefundCarry(state)
			self:Notify(player, "Your followers went home to the shop. Purchase prices refunded.")
			self:Push(player)
		end
	end)
end

function GameServer:AddPlayer(player)
	if self.states[player] then return end
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = Economy.StartCash
	cash.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = stats
	local state = { cash = cash, rebirths = rebirths, capacity = 1, speedLevel = 0,
		carry = {}, rates = {}, plot = nil, discovered = {} }
	self.states[player] = state
	for _, plot in ipairs(self.world.plots) do
		if self:Assign(player, plot) then break end
	end
	player.CharacterAdded:Connect(function(character) self:CharacterAdded(player, character) end)
	if player.Character then task.spawn(function() self:CharacterAdded(player, player.Character) end) end
end

function GameServer:RemovePlayer(player)
	local state = self.states[player]
	if not state then return end
	for _, record in ipairs(state.carry) do record.model:Destroy() end
	if self.threats then self.threats:CancelFor(player) end
	local plot = state.plot
	if plot then
		for _, pad in ipairs(plot.pads) do
			if pad.occupant then pad.occupant.model:Destroy(); pad.occupant = nil end
			self:UpdatePad(pad)
		end
		plot.owner = nil
		plot.lockUntil = 0
		plot.readyAt = 0
		plot.model:SetAttribute("OwnerId", 0)
		for _, gui in ipairs(plot.sign:GetChildren()) do
			if gui:IsA("SurfaceGui") then gui:FindFirstChildOfClass("TextLabel").Text = "BARN " .. plot.index .. "\nOPEN FOR A FARMER" end
		end
		plot.claimPrompt.Enabled = true
	end
	self.states[player] = nil
	-- Waiting spectators receive the first released plot, without reconnecting.
	if plot then
		for waiting, waitingState in pairs(self.states) do
			if not waitingState.plot and self:Assign(waiting, plot) then
				self:Notify(waiting, "A barn opened! Barn " .. plot.index .. " is now yours.")
				break
			end
		end
	end
end

function GameServer:UpdatePad(pad)
	local record = pad.occupant
	if record then
		pad.part.Color = Catalog.Rarities[record.entry.rarity].color
		pad.prompt.ActionText = "Sell for $" .. Economy.Format(math.floor(record.entry.price / 2))
		pad.prompt.ObjectText = record.entry.name
		pad.prompt.HoldDuration = 0.9
	else
		pad.part.Color = Color3.fromRGB(164, 208, 143)
		pad.prompt.ActionText = "Place follower"
		pad.prompt.ObjectText = "Empty pad " .. pad.index
		pad.prompt.HoldDuration = 0.35
	end
end

function GameServer:Place(player, pad)
	local state = self.states[player]
	if not state or not state.plot or pad.occupant or #state.carry == 0 then return end
	if not self:Near(player, pad.part, 12) then return end
	local record = table.remove(state.carry, 1)
	record.status = "Placed"
	record.model:SetAttribute("Status", "Placed")
	record.model:PivotTo(pad.part.CFrame * CFrame.new(0, 0.3, 0))
	pad.occupant = record
	Builder.Label(record.model, record.entry, record.mutation, self:Income(record, state), "BARN " .. state.plot.index .. " • E TO SELL")
	self:UpdatePad(pad)
	self:Notify(player, record.entry.name .. " settled in! +$" .. Economy.Format(self:Income(record, state)) .. "/s", "success")
	self:Push(player)
end

function GameServer:UsePad(player, plot, pad)
	local state = self.states[player]
	if not state or state.plot ~= plot or not self:Near(player, pad.part, 12) then return end
	if not self:Rate(state, "pad", 0.5) then return end
	if pad.occupant then
		local record = pad.occupant
		pad.occupant = nil
		state.cash.Value += math.floor(record.entry.price / 2)
		record.model:Destroy()
		self:UpdatePad(pad)
		self:Notify(player, "Sold " .. record.entry.name .. " for half its purchase price.")
		self:Push(player)
	else
		self:Place(player, pad)
	end
end

function GameServer:Buy(player, record)
	local state = self.states[player]
	if not state or record.status ~= "Lane" or not record.model.Parent then return end
	if not self:Near(player, record.model.PrimaryPart, 14) or not self:Rate(state, "buy", 0.3) then return end
	if not state.plot then self:Notify(player, "All six barns are occupied. Wait for a free barn.", "error"); return end
	if #state.carry >= state.capacity then self:Notify(player, "Your parade is full! Place a follower or upgrade carry capacity.", "error"); return end
	local vacant = 0
	for _, pad in ipairs(state.plot.pads) do if not pad.occupant then vacant += 1 end end
	if vacant <= #state.carry then self:Notify(player, "You need an empty barn pad for each follower.", "error"); return end
	if state.cash.Value < record.entry.price then self:Notify(player, "Need $" .. Economy.Format(record.entry.price) .. " for this silly friend.", "error"); return end
	-- No yields between ownership check and transfer: simultaneous prompts cannot double-buy.
	record.status = "Following"
	record.owner = player
	record.model:SetAttribute("Status", "Following")
	record.model:SetAttribute("OwnerId", player.UserId)
	record.prompt:Destroy()
	self.lane[record] = nil
	state.cash.Value -= record.entry.price
	table.insert(state.carry, record)
	state.discovered[record.entry.id] = true
	Builder.Label(record.model, record.entry, record.mutation, self:Income(record, state), "FOLLOWING • TAKE TO YOUR PAD")
	self:Notify(player, "Bought " .. record.entry.name .. "! Walk onto an empty pad in Barn " .. state.plot.index .. ".", "success")
	self:Push(player)
end

function GameServer:SpawnCritter()
	if self.floodActive then return end
	self.spawnCount += 1
	local entry, mutation = Catalog.Roll(self.random)
	-- The first four arrivals and every fourth afterward keep an affordable entry point.
	if self.spawnCount <= 4 then entry = Catalog.Entries[self.spawnCount]; mutation = "Normal"
	elseif self.spawnCount % 4 == 0 then entry = Catalog.Entries[self.random:NextInteger(1, 4)] end
	local model = Builder.Build(entry, mutation)
	model:PivotTo(CFrame.new(-116, 1.2, 0) * CFrame.Angles(0, -math.pi / 2, 0))
	model.Parent = self.world.characters
	local prompt = World.Prompt(model.PrimaryPart, "Buy $" .. Economy.Format(entry.price), entry.name, 0.3)
	local record = { model = model, prompt = prompt, entry = entry, mutation = mutation, x = -116, status = "Lane" }
	model:SetAttribute("Status", "Lane")
	self.lane[record] = true
	prompt.Triggered:Connect(function(player) self:Buy(player, record) end)
end

function GameServer:Upgrade(player, kind)
	local state = self.states[player]
	local shop = self.world.shops[kind]
	if not state or not shop or not self:Near(player, shop.part, 14) or not self:Rate(state, "upgrade", 0.5) then return end
	local speed = kind == "Speed"
	if (speed and state.speedLevel >= Economy.MaxSpeedLevel) or (not speed and state.capacity >= Economy.MaxCarry) then
		self:Notify(player, "That upgrade is maxed!", "error"); return
	end
	local price = if speed then Economy.SpeedPrice(state.speedLevel) else Economy.CarryPrice(state.capacity)
	if state.cash.Value < price then self:Notify(player, "This upgrade costs $" .. Economy.Format(price) .. ".", "error"); return end
	state.cash.Value -= price
	if speed then
		state.speedLevel += 1
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.WalkSpeed = 18 + state.speedLevel * 5 end
	else
		state.capacity += 1
	end
	self:Notify(player, if speed then "Zoom boots upgraded! +5 walk speed." else "Your parade can carry one more friend!", "success")
	self:Push(player)
end

function GameServer:ToggleLock(player, plot)
	local state = self.states[player]
	if not state or plot.owner ~= player or not self:Near(player, plot.panel, 14) or not self:Rate(state, "lock", 0.5) then return end
	local now = workspace:GetServerTimeNow()
	if plot.lockUntil > now then
		plot.lockUntil = 0
		self:Notify(player, "Barn unlocked early. The original cooldown still applies.")
	elseif now >= plot.readyAt then
		plot.lockUntil = now + 60
		plot.readyAt = now + 120
		self:Notify(player, "Barn locked for 60 seconds. The striped snack bandit cannot enter.", "success")
	else self:Notify(player, "Lock recharging: " .. math.ceil(plot.readyAt - now) .. "s.", "error") end
	self:UpdateLock(plot)
	self:Push(player)
end

function GameServer:UpdateLock(plot)
	local now = workspace:GetServerTimeNow()
	local locked = plot.lockUntil > now
	plot.barrier.Transparency = if locked then 0.65 else 1
	plot.panel.Color = if locked then Color3.fromRGB(116, 230, 177) else Color3.fromRGB(255, 206, 111)
	plot.model:SetAttribute("Locked", locked)
	if locked then
		plot.lockLabel.Text = "LOCKED\n" .. math.ceil(plot.lockUntil - now) .. "s"
		plot.lockPrompt.ActionText = "Unlock early"
	elseif plot.readyAt > now then
		plot.lockLabel.Text = "RECHARGE\n" .. math.ceil(plot.readyAt - now) .. "s"
		plot.lockPrompt.ActionText = "Recharging…"
	else
		plot.lockLabel.Text = "LOCK\nREADY"
		plot.lockPrompt.ActionText = "Lock for 60s"
	end
end

function GameServer:Rebirth(player)
	local state = self.states[player]
	if not state or not self:Rate(state, "rebirth", 1) then return end
	local price = Economy.RebirthPrice(state.rebirths.Value)
	if not state.plot then return end
	if state.cash.Value < price then self:Notify(player, "Rebirth requires $" .. Economy.Format(price) .. ".", "error"); return end
	if state.rebirths.Value >= 20 then self:Notify(player, "You reached the rebirth limit. Legendary farming!", "success"); return end
	if self.threats then self.threats:CancelFor(player) end
	for _, record in ipairs(state.carry) do record.model:Destroy() end
	table.clear(state.carry)
	for _, pad in ipairs(state.plot.pads) do
		if pad.occupant then pad.occupant.model:Destroy(); pad.occupant = nil end
		self:UpdatePad(pad)
	end
	state.cash.Value = Economy.StartCash
	state.rebirths.Value += 1
	self:Notify(player, "Fresh start! Permanent income is now " .. Economy.Multiplier(state.rebirths.Value) .. "x. Upgrades kept.", "success")
	self:Push(player)
end

function GameServer:Step(dt)
	self.tick += dt
	self.placementTick += dt
	self.spawnTick += dt
	if self.spawnTick >= 5 then self.spawnTick %= 5; self:SpawnCritter() end
	local time = os.clock()
	for record in pairs(self.lane) do
		record.x += dt * 4.8
		if record.x > 117 then
			self.lane[record] = nil
			record.status = "Gone"
			record.model:Destroy()
		else
			record.model:PivotTo(CFrame.new(record.x, 1.2 + math.abs(math.sin(time * 5)) * 0.18, 0) * CFrame.Angles(0, -math.pi / 2, math.sin(time * 5) * 0.04))
		end
	end
	local checkPads = self.placementTick >= 0.15
	if checkPads then self.placementTick = 0 end
	for player, state in pairs(self.states) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			for index, record in ipairs(state.carry) do
				local offset = Vector3.new(((index - 1) % 3 - 1) * 3.5, 0, 5 + math.floor((index - 1) / 3) * 3.8)
				if #state.carry == 1 then offset = Vector3.new(0, 0, 5) end
				local target = root.CFrame * CFrame.new(offset)
				local facing = target - target.Position
				local cf = CFrame.new(target.Position.X, root.Position.Y - 3 + math.abs(math.sin(time * 6 + index)) * 0.16, target.Position.Z) * facing
				record.model:PivotTo(record.model:GetPivot():Lerp(cf, math.min(1, dt * 12)))
			end
			if checkPads and state.plot and #state.carry > 0 then
				for _, pad in ipairs(state.plot.pads) do
					local relative = pad.part.CFrame:PointToObjectSpace(root.Position)
					if not pad.occupant and math.abs(relative.X) < 6 and math.abs(relative.Z) < 5.5 and relative.Y > 0 and relative.Y < 7 then
						self:Place(player, pad)
						break
					end
				end
			end
		end
	end
	if self.tick >= 1 then
		local seconds = math.floor(self.tick)
		self.tick -= seconds
		for player, state in pairs(self.states) do
			state.cash.Value += self:TotalIncome(state) * seconds
			self:Push(player)
		end
		for _, plot in ipairs(self.world.plots) do self:UpdateLock(plot) end
	end
end

function GameServer:Start()
	for _, plot in ipairs(self.world.plots) do
		plot.claimPrompt.Triggered:Connect(function(player)
			if self:Near(player, plot.sign, 26) then self:Assign(player, plot) end
		end)
		plot.lockPrompt.Triggered:Connect(function(player) self:ToggleLock(player, plot) end)
		for _, pad in ipairs(plot.pads) do
			pad.prompt.Triggered:Connect(function(player) self:UsePad(player, plot, pad) end)
		end
	end
	for kind, shop in pairs(self.world.shops) do
		shop.prompt.Triggered:Connect(function(player) self:Upgrade(player, kind) end)
	end
	self.world.rebirthPrompt.Triggered:Connect(function(player)
		if self:Near(player, self.world.rebirth, 14) then self.remotes.OpenRebirth:FireClient(player) end
	end)
	self.remotes.GetState.OnServerInvoke = function(player)
		local state = self.states[player]
		if state and self:Rate(state, "snapshot", 0.25) then return self:Snapshot(player) end
		return nil
	end
	self.remotes.Action.OnServerEvent:Connect(function(player, action)
		if action == "Rebirth" then self:Rebirth(player) end
	end)
	Players.PlayerAdded:Connect(function(player) self:AddPlayer(player) end)
	Players.PlayerRemoving:Connect(function(player) self:RemovePlayer(player) end)
	for _, player in ipairs(Players:GetPlayers()) do self:AddPlayer(player) end
	self:SpawnCritter()
	RunService.Heartbeat:Connect(function(dt) self:Step(dt) end)
end
return GameServer
