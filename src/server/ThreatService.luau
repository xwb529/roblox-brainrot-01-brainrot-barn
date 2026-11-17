local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local World = require(script.Parent.WorldBuilder)
local Builder = require(ReplicatedStorage.Shared.BuildCharacter)
local Threats = {}
Threats.__index = Threats
local ink = Color3.fromRGB(34, 40, 51)
local white = Color3.fromRGB(249, 242, 220)

function Threats.new(server)
	return setmetatable({ server = server, wave = nil, thief = nil,
		nextThief = workspace:GetServerTimeNow() + 65, wavePlayers = {}, waveElapsed = 0 }, Threats)
end

function Threats:Broadcast(text, kind)
	for player in pairs(self.server.states) do self.server:Notify(player, text, kind) end
end

function Threats:BeginWave()
	local s = self.server
	s.wavePhase = "Wave"
	s.waveRemaining = 9
	s.floodActive = true
	self.waveElapsed = 0
	table.clear(self.wavePlayers)
	local wave = Instance.new("Model")
	wave.Name = "Tsunami"
	wave.Parent = s.world.effects
	local wall = World.Part(wave, "WaterWall", Vector3.new(12, 17, 53), CFrame.new(-139, 8, 0), Color3.fromRGB(55, 186, 239), Enum.Material.Glass)
	wall.Transparency = 0.4
	wall.CanCollide = false
	wall.CanTouch = false
	wave.PrimaryPart = wall
	for i = -4, 4 do
		local foam = World.Part(wave, "Foam", Vector3.new(15, 3.4, 7), CFrame.new(-138, 16.2 + (i % 2) * 0.7, i * 6), white, nil, Enum.PartType.Ball)
		foam.Transparency = 0.18
		foam.CanCollide = false
		foam.CanTouch = false
	end
	self.wave = wave
	self:Broadcast("TSUNAMI! The Silly Express is taking an unscheduled bath!", "wave")
end

function Threats:StepWave(dt, now)
	local s = self.server
	if s.wavePhase == "Calm" and now >= s.nextWave - 10 then
		s.wavePhase = "Warning"
		self:Broadcast("TSUNAMI IN 10 SECONDS! Leave the lane. Barns and the hill are safe.", "wave")
	end
	if s.wavePhase == "Warning" then
		s.waveRemaining = math.max(0, math.ceil(s.nextWave - now))
		if now >= s.nextWave then self:BeginWave() end
	end
	if not self.wave then return end
	self.waveElapsed += dt
	local x = -139 + math.min(1, self.waveElapsed / 9) * 278
	self.wave:PivotTo(CFrame.new(x, 8, 0))
	s.waveRemaining = math.max(0, math.ceil(9 - self.waveElapsed))
	-- Swept range instead of touch events: fast frames cannot miss lane residents.
	for record in pairs(s.lane) do
		if record.x <= x + 6 then
			s.lane[record] = nil
			record.status = "Washed"
			record.model:Destroy()
		end
	end
	for player in pairs(s.states) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and not self.wavePlayers[player] and root.Position.X <= x + 7 and root.Position.X >= x - 18
			and math.abs(root.Position.Z) < 26.5 and root.Position.Y < 18 then
			self.wavePlayers[player] = true
			character:PivotTo(CFrame.new(0, 5, 105))
			self.server:Notify(player, "SPLASH! Back to the welcome mat. Your purchased friends are safe.", "wave")
		end
	end
	if self.waveElapsed >= 9 then
		self.wave:Destroy()
		self.wave = nil
		s.floodActive = false
		s.wavePhase = "Calm"
		s.waveRemaining = 0
		s.nextWave += 180
		self:Broadcast("The wave passed! Fresh friends are back on the conveyor.", "success")
	end
end

local function buildThief(parent)
	local model = Instance.new("Model")
	model.Name = "The Striped Snack Bandit"
	model.Parent = parent
	local function p(name, size, position, color, shape)
		local part = World.Part(model, name, size, CFrame.new(position), color, nil, shape)
		part.CanCollide = false
		part.CanTouch = false
		return part
	end
	local root = p("Root", Vector3.one, Vector3.zero, ink)
	root.Transparency = 1
	model.PrimaryPart = root
	p("Shirt", Vector3.new(2.5, 2.5, 1.3), Vector3.new(0, 2.8, 0), white)
	for y = 1.8, 3.9, 0.5 do p("ShirtStripe", Vector3.new(2.55, 0.24, 1.35), Vector3.new(0, y, 0), ink) end
	p("Head", Vector3.new(2, 1.8, 1.8), Vector3.new(0, 5, 0), Color3.fromRGB(237, 188, 143), Enum.PartType.Ball)
	p("Mask", Vector3.new(2.02, 0.6, 0.3), Vector3.new(0, 5.1, -0.85), ink)
	for _, x in ipairs({ -0.5, 0.5 }) do
		p("Eye", Vector3.new(0.4, 0.3, 0.16), Vector3.new(x, 5.1, -1.03), white, Enum.PartType.Ball)
		p("Leg", Vector3.new(0.8, 1.5, 1.2), Vector3.new(x * 1.5, 0.8, 0), ink)
		p("Arm", Vector3.new(0.7, 2.3, 0.8), Vector3.new(x * 3, 2.9, 0), ink)
	end
	p("Beanie", Vector3.new(2.2, 0.8, 2), Vector3.new(0, 5.9, 0), ink)
	local sack = p("LootSack", Vector3.new(1.5, 2, 1), Vector3.new(0, 3, 1.1), Color3.fromRGB(158, 123, 80), Enum.PartType.Ball)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BanditLabel"
	gui.Size = UDim2.fromOffset(220, 56)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
	gui.Adornee = root
	gui.AlwaysOnTop = true
	gui.MaxDistance = 150
	gui.Parent = root
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = ink
	label.BackgroundTransparency = 0.2
	label.TextColor3 = Color3.fromRGB(255, 170, 128)
	label.Text = "SNACK BANDIT\nLock your barn!"
	label.TextSize = 17
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)
	return model, sack, label
end

function Threats:SpawnThief()
	local s = self.server
	local candidates = {}
	local now = workspace:GetServerTimeNow()
	for _, plot in ipairs(s.world.plots) do
		if plot.owner and plot.lockUntil <= now then
			local occupied = {}
			for _, pad in ipairs(plot.pads) do if pad.occupant then table.insert(occupied, pad) end end
			if #occupied > 0 then table.insert(candidates, { plot = plot, pads = occupied }) end
		end
	end
	if #candidates == 0 then return end
	local target = candidates[s.random:NextInteger(1, #candidates)]
	local pad = target.pads[s.random:NextInteger(1, #target.pads)]
	local model, sack, label = buildThief(s.world.effects)
	local entrance = target.plot.entrance
	local position = Vector3.new(-142, 0.5, 0)
	model:PivotTo(CFrame.new(position))
	local thief = { model = model, sack = sack, label = label, plot = target.plot, pad = pad,
		owner = target.plot.owner, record = nil, position = position, index = 1, escaping = false,
		waypoints = { Vector3.new(entrance.X, 0.5, 0), Vector3.new(entrance.X, 0.5, entrance.Z),
			Vector3.new(entrance.X, 2.4, entrance.Z + (if entrance.Z > 0 then 5 else -5)), pad.part.Position + Vector3.new(0, 0.3, 0) },
	}
	self.thief = thief
	local prompt = World.Prompt(model.PrimaryPart, "Rescue stolen friend", "Catch the snack bandit!", 0.15)
	prompt.Enabled = false
	thief.prompt = prompt
	prompt.Triggered:Connect(function(player)
		if self.thief ~= thief or not thief.record or thief.owner ~= player then return end
		if not s:Near(player, thief.model.PrimaryPart, 14) then return end
		local state = s.states[player]
		if not state or state.plot ~= thief.plot then return end
		local freePad
		for _, candidate in ipairs(state.plot.pads) do if not candidate.occupant then freePad = candidate; break end end
		if not freePad then s:Notify(player, "Make room in your barn to rescue this friend!", "error"); return end
		local record = thief.record
		thief.record = nil
		record.status = "Placed"
		record.model:SetAttribute("Status", "Placed")
		record.model:PivotTo(freePad.part.CFrame * CFrame.new(0, 0.3, 0))
		freePad.occupant = record
		Builder.Label(record.model, record.entry, record.mutation, s:Income(record, state), "RESCUED • E TO SELL")
		s:UpdatePad(freePad)
		s:Notify(player, "Rescued " .. record.entry.name .. "! Back in your barn.", "success")
		s:Push(player)
		self:FinishThief()
	end)
	self:Broadcast("The snack bandit is sneaking toward Barn " .. target.plot.index .. "! Lock up!", "error")
end

function Threats:Flee(thief)
	if thief.escaping then return end
	thief.escaping = true
	thief.index = 1
	local entrance = thief.plot.entrance
	thief.waypoints = { Vector3.new(entrance.X, 2.4, entrance.Z), Vector3.new(entrance.X, 0.5, 0), Vector3.new(-148, 0.5, 0) }
end

function Threats:FinishThief()
	local thief = self.thief
	if not thief then return end
	if thief.record then
		thief.record.model:Destroy()
		self.server:Notify(thief.owner, "The snack bandit escaped with " .. thief.record.entry.name .. ". Lock up next time!", "error")
	end
	thief.model:Destroy()
	self.thief = nil
end

function Threats:CancelFor(player)
	if self.thief and self.thief.owner == player then self:FinishThief() end
end

function Threats:StepThief(dt, now)
	if not self.thief then
		if now >= self.nextThief then
			self.nextThief = now + self.server.random:NextInteger(75, 110)
			self:SpawnThief()
		end
		return
	end
	local thief = self.thief
	if not thief.escaping and (thief.plot.owner ~= thief.owner or thief.plot.lockUntil > now) then
		thief.label.Text = "FOILED!\nThis barn is locked!"
		self.server:Notify(thief.owner, "Your lock scared off the snack bandit!", "success")
		self:Flee(thief)
	end
	local goal = thief.waypoints[thief.index]
	if not goal then
		if thief.escaping then self:FinishThief(); return end
		local record = thief.pad.occupant
		if record and thief.plot.lockUntil <= now and thief.plot.owner == thief.owner then
			thief.pad.occupant = nil
			thief.record = record
			record.status = "Stolen"
			record.model:SetAttribute("Status", "Stolen")
			self.server:UpdatePad(thief.pad)
			local state = self.server.states[thief.owner]
			if state then
				Builder.Label(record.model, record.entry, record.mutation, 0, "STOLEN! OWNER: E TO RESCUE")
				self.server:Push(thief.owner)
			end
			thief.prompt.Enabled = true
			thief.label.Text = "STOP THAT BANDIT!\nOwner: catch + E to rescue"
			self.server:Notify(thief.owner, "THIEF! Catch the bandit and press E to rescue " .. record.entry.name .. "!", "error")
		end
		self:Flee(thief)
		return
	end
	local delta = goal - thief.position
	local step = (if thief.escaping then 20 else 11) * dt
	if delta.Magnitude <= step then
		thief.position = goal
		thief.index += 1
	else thief.position += delta.Unit * step end
	local flat = Vector3.new(delta.X, 0, delta.Z)
	local cf = if flat.Magnitude > 0.01 then CFrame.lookAt(thief.position, thief.position + flat) else CFrame.new(thief.position)
	thief.model:PivotTo(cf * CFrame.Angles(0, 0, math.sin(os.clock() * 12) * 0.05))
	if thief.record then thief.record.model:PivotTo(cf * CFrame.new(0, 1.2, 3.2)) end
end

function Threats:Start()
	RunService.Heartbeat:Connect(function(dt)
		local now = workspace:GetServerTimeNow()
		self:StepWave(dt, now)
		self:StepThief(dt, now)
	end)
end
return Threats
