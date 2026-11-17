-- Presentation only. All money, rolls, timers and transactions live on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BarnRemotes")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Economy)
local Catalog = require(Shared.BrainrotCatalog)
local palette = {
	ink = Color3.fromRGB(29, 48, 48), panel = Color3.fromRGB(37, 61, 57),
	cream = Color3.fromRGB(255, 243, 216), muted = Color3.fromRGB(180, 206, 187),
	mint = Color3.fromRGB(142, 239, 187), gold = Color3.fromRGB(255, 209, 111),
	pink = Color3.fromRGB(241, 160, 175), blue = Color3.fromRGB(129, 220, 255),
}
local state = nil
local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBarnHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

local function frame(parent, name, size, pos, color)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = color or palette.ink
	f.BorderSizePixel = 0
	f.Parent = parent
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 14)
	return f
end
local function label(parent, name, text, size, pos, textSize, color)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.Size = size
	t.Position = pos
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color or palette.cream
	t.Font = Enum.Font.GothamBold
	t.TextSize = textSize or 18
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = parent
	return t
end
local function button(parent, name, text, size, pos, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = color or palette.mint
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = palette.ink
	b.TextSize = 16
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = true
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	return b
end
local function stroke(parent, color)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Transparency = 0.7
	s.Thickness = 1.2
	s.Parent = parent
end

-- Fixed design canvas scaled to small screens, leaving the centre unobstructed.
local top = frame(gui, "TopBar", UDim2.fromOffset(860, 92), UDim2.new(0.5, 0, 0, 12))
top.AnchorPoint = Vector2.new(0.5, 0)
stroke(top, palette.mint)
local topScale = Instance.new("UIScale", top)
label(top, "Brand", "BRAINROT\nBARN", UDim2.fromOffset(145, 64), UDim2.fromOffset(18, 13), 23, palette.mint)
label(top, "CashTitle", "YOUR CASH", UDim2.fromOffset(166, 20), UDim2.fromOffset(179, 13), 11, palette.muted)
local cashLabel = label(top, "Cash", "$350", UDim2.fromOffset(167, 38), UDim2.fromOffset(178, 31), 31, palette.gold)
label(top, "IncomeTitle", "BARN INCOME", UDim2.fromOffset(155, 20), UDim2.fromOffset(357, 13), 11, palette.muted)
local incomeLabel = label(top, "Income", "+$0 / sec", UDim2.fromOffset(158, 38), UDim2.fromOffset(355, 32), 23, palette.mint)
local rebirthLabel = label(top, "RebirthCount", "0 REBIRTHS  ·  1.0x", UDim2.fromOffset(182, 24), UDim2.fromOffset(523, 15), 14)
local rebirthButton = button(top, "Rebirth", "REBIRTH  [R]", UDim2.fromOffset(162, 33), UDim2.fromOffset(521, 46), palette.pink)
local collectionButton = button(top, "Collection", "FIELD\nGUIDE [B]", UDim2.fromOffset(137, 60), UDim2.fromOffset(704, 17), palette.cream)

local status = frame(gui, "Status", UDim2.fromOffset(480, 77), UDim2.new(0, 12, 1, -91))
local statusScale = Instance.new("UIScale", status)
local barnLabel = label(status, "Barn", "Finding your barn…", UDim2.fromOffset(448, 23), UDim2.fromOffset(15, 8), 16, palette.mint)
local carryLabel = label(status, "Carry", "PARADE 0/1   •   SPEED 18", UDim2.fromOffset(448, 22), UDim2.fromOffset(15, 30), 14)
local shopsLabel = label(status, "Shops", "Boots $350   |   Carry $650   •   Shops at spawn", UDim2.fromOffset(448, 18), UDim2.fromOffset(15, 53), 12, palette.muted)

local mission = frame(gui, "Mission", UDim2.fromOffset(500, 67), UDim2.new(0.5, 0, 1, -170), palette.panel)
mission.AnchorPoint = Vector2.new(0.5, 0)
local missionScale = Instance.new("UIScale", mission)
local missionTitle = label(mission, "Objective", "YOUR FIRST SILLY FRIEND", UDim2.fromOffset(470, 20), UDim2.fromOffset(15, 9), 13, palette.gold)
local missionText = label(mission, "Instruction", "Walk to the conveyor. Hold E to buy a brainrot.", UDim2.fromOffset(470, 25), UDim2.fromOffset(15, 30), 15)
missionText.TextWrapped = true

local wave = frame(gui, "TsunamiWarning", UDim2.fromOffset(660, 64), UDim2.new(0.5, 0, 0, 116), Color3.fromRGB(31, 91, 126))
wave.AnchorPoint = Vector2.new(0.5, 0)
wave.Visible = false
local waveScale = Instance.new("UIScale", wave)
local waveTitle = label(wave, "Warning", "TSUNAMI IN 10s", UDim2.fromOffset(630, 27), UDim2.fromOffset(15, 5), 24, palette.blue)
waveTitle.TextXAlignment = Enum.TextXAlignment.Center
local waveHint = label(wave, "Safety", "GET OFF THE LANE! Barns + high ground are safe.", UDim2.fromOffset(630, 22), UDim2.fromOffset(15, 35), 15)
waveHint.TextXAlignment = Enum.TextXAlignment.Center
local timer = label(gui, "WaveClock", "Next wave 3:00", UDim2.fromOffset(200, 23), UDim2.new(1, -212, 1, -38), 13, palette.cream)
timer.TextXAlignment = Enum.TextXAlignment.Right

local toast = frame(gui, "Toast", UDim2.fromOffset(610, 65), UDim2.new(0.5, 0, 0, 190), palette.panel)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Visible = false
local toastScale = Instance.new("UIScale", toast)
local toastText = label(toast, "Message", "", UDim2.fromOffset(576, 52), UDim2.fromOffset(17, 6), 16)
toastText.TextWrapped = true
toastText.TextXAlignment = Enum.TextXAlignment.Center
local toastId = 0
local function notice(text, kind)
	if type(text) ~= "string" then return end
	toastId += 1
	local id = toastId
	toastText.Text = text
	toastText.TextColor3 = if kind == "error" then palette.pink elseif kind == "success" then palette.mint elseif kind == "wave" then palette.blue else palette.cream
	toast.Visible = true
	toast.BackgroundTransparency = 0.05
	task.delay(5, function()
		if id ~= toastId then return end
		local tween = TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		if id == toastId then toast.Visible = false end
	end)
end

local shade = Instance.new("TextButton")
shade.Name = "ModalBackdrop"
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = palette.ink
shade.BackgroundTransparency = 0.3
shade.BorderSizePixel = 0
shade.Text = ""
shade.AutoButtonColor = false
shade.Visible = false
shade.ZIndex = 10
shade.Parent = gui
local modal = frame(shade, "RebirthConfirm", UDim2.fromOffset(464, 330), UDim2.fromScale(0.5, 0.5), palette.panel)
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.ZIndex = 11
local modalScale = Instance.new("UIScale", modal)
stroke(modal, palette.pink)
local modalTitle = label(modal, "Title", "A FRESH START?", UDim2.fromOffset(416, 40), UDim2.fromOffset(24, 19), 28, palette.pink)
local modalBody = label(modal, "Details", "", UDim2.fromOffset(416, 169), UDim2.fromOffset(24, 67), 18)
modalBody.TextWrapped = true
modalBody.TextYAlignment = Enum.TextYAlignment.Top
local confirm = button(modal, "Confirm", "REBIRTH", UDim2.fromOffset(202, 48), UDim2.fromOffset(238, 254), palette.pink)
local cancel = button(modal, "Cancel", "KEEP FARMING", UDim2.fromOffset(202, 48), UDim2.fromOffset(24, 254), palette.cream)
for _, item in ipairs(modal:GetChildren()) do if item:IsA("GuiObject") then item.ZIndex = 12 end end

local guide = frame(shade, "FieldGuide", UDim2.fromOffset(570, 510), UDim2.fromScale(0.5, 0.5), palette.panel)
guide.AnchorPoint = Vector2.new(0.5, 0.5)
guide.ZIndex = 11
guide.Visible = false
local guideScale = Instance.new("UIScale", guide)
label(guide, "Title", "THE PECULIAR FIELD GUIDE", UDim2.fromOffset(510, 36), UDim2.fromOffset(24, 16), 23, palette.mint)
local discoveredLabel = label(guide, "Discovered", "0 / 14 discovered this session", UDim2.fromOffset(485, 24), UDim2.fromOffset(24, 54), 14, palette.muted)
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Catalog"
scroll.Position = UDim2.fromOffset(20, 94)
scroll.Size = UDim2.fromOffset(530, 340)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.fromOffset(0, #Catalog.Entries * 58)
scroll.ZIndex = 12
scroll.Parent = guide
local guideRows = {}
for i, entry in ipairs(Catalog.Entries) do
	local row = frame(scroll, entry.id, UDim2.new(1, -10, 0, 52), UDim2.fromOffset(0, (i - 1) * 58), palette.ink)
	row.ZIndex = 13
	local title = label(row, "Name", entry.name, UDim2.fromOffset(480, 23), UDim2.fromOffset(12, 3), 15, Catalog.Rarities[entry.rarity].color)
	local details = label(row, "Details", entry.rarity .. "   •   $" .. Economy.Format(entry.price) .. "   •   +$" .. Economy.Format(entry.income) .. "/s", UDim2.fromOffset(480, 22), UDim2.fromOffset(12, 26), 13, palette.muted)
	title.ZIndex = 14
	details.ZIndex = 14
	guideRows[entry.id] = title
end
local guideClose = button(guide, "Close", "BACK TO THE BARN", UDim2.fromOffset(530, 44), UDim2.fromOffset(20, 448), palette.mint)
for _, item in ipairs(guide:GetChildren()) do if item:IsA("GuiObject") then item.ZIndex = 12 end end

local function closeModal()
	shade.Visible = false
	modal.Visible = false
	guide.Visible = false
end
local function updateRebirth()
	if not state then return end
	local nextMultiplier = Economy.Multiplier(state.rebirths + 1)
	local ready = state.cash >= state.rebirthPrice and state.plot > 0 and state.rebirths < 20
	modalBody.Text = "Cost: $" .. Economy.Format(state.rebirthPrice) .. "\n\nResets cash to $350 and clears your collection of placed and carried friends.\n\nIncome becomes " .. string.format("%.1fx", nextMultiplier) .. " forever this session. Boots + carry upgrades stay."
	confirm.Text = if ready then "CONFIRM REBIRTH" elseif state.rebirths >= 20 then "MAX REBIRTHS" else "NEED $" .. Economy.Format(state.rebirthPrice)
	confirm.BackgroundColor3 = if ready then palette.pink else palette.muted
end
local function openRebirth()
	if not state then return end
	shade.Visible = true
	guide.Visible = false
	modal.Visible = true
	updateRebirth()
end
local function toggleGuide()
	local opening = not (shade.Visible and guide.Visible)
	shade.Visible = opening
	guide.Visible = opening
	modal.Visible = false
end
cancel.Activated:Connect(closeModal)
guideClose.Activated:Connect(closeModal)
rebirthButton.Activated:Connect(openRebirth)
collectionButton.Activated:Connect(toggleGuide)
confirm.Activated:Connect(function()
	if not state or state.cash < state.rebirthPrice or state.plot == 0 or state.rebirths >= 20 then return end
	closeModal()
	remotes.Action:FireServer("Rebirth")
end)
remotes.OpenRebirth.OnClientEvent:Connect(openRebirth)
remotes.Notice.OnClientEvent:Connect(notice)

local highlight = Instance.new("Highlight")
highlight.Name = "YourBarnOutline"
highlight.FillTransparency = 1
highlight.OutlineColor = palette.mint
highlight.OutlineTransparency = 0.3
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Parent = workspace
local lastPlot = -1
local function render(snapshot)
	if type(snapshot) ~= "table" then return end
	state = snapshot
	cashLabel.Text = "$" .. Economy.Format(state.cash)
	incomeLabel.Text = "+$" .. Economy.Format(state.income) .. " / sec"
	rebirthLabel.Text = state.rebirths .. " REBIRTHS  ·  " .. string.format("%.1fx", state.multiplier)
	local security = if state.lockRemaining > 0 then "LOCKED " .. state.lockRemaining .. "s" elseif state.cooldown > 0 then "LOCK RECHARGES " .. state.cooldown .. "s" else "LOCK READY [E at panel]"
	barnLabel.Text = if state.plot > 0 then "BARN " .. state.plot .. "   •   " .. state.occupied .. "/6 PADS   •   " .. security else "ALL BARNS BUSY • A free barn will be assigned automatically"
	carryLabel.Text = "PARADE " .. state.carry .. "/" .. state.capacity .. "   •   SPEED " .. state.speed
	shopsLabel.Text = "Boots " .. (if state.speedMax then "MAX" else "$" .. Economy.Format(state.speedPrice)) .. "   |   Carry " .. (if state.carryMax then "MAX" else "$" .. Economy.Format(state.carryPrice)) .. "   •   Shops at spawn"
	if state.plot == 0 then
		missionTitle.Text = "TAKE A LOOK AROUND"
		missionText.Text = "Six farmers can own barns. You are waiting for an open plot."
	elseif state.carry > 0 then
		missionTitle.Text = "BRING YOUR PARADE HOME"
		missionText.Text = "Walk onto an empty green pad in Barn " .. state.plot .. " to place a friend."
	elseif state.occupied == 0 then
		missionTitle.Text = "YOUR FIRST SILLY FRIEND"
		missionText.Text = "Walk to the conveyor. Hold E (or tap the prompt) to buy."
	elseif state.occupied == 6 then
		missionTitle.Text = "A FULL HOUSE OF NONSENSE"
		missionText.Text = "Sell to trade up, lock your barn, or rebirth for a lasting boost."
	else
		missionTitle.Text = "GROW YOUR RIDICULOUS EMPIRE"
		missionText.Text = "Buy more friends. Lock your barn before the striped bandit arrives!"
	end
	wave.Visible = state.wavePhase ~= "Calm"
	waveTitle.Text = if state.wavePhase == "Warning" then "TSUNAMI IN " .. state.waveRemaining .. "s" else "TSUNAMI • TAKE COVER!"
	if state.plot ~= lastPlot then
		lastPlot = state.plot
		local world = workspace:FindFirstChild("BrainrotBarn")
		local plot = world and world:FindFirstChild("Barn" .. state.plot)
		highlight.Adornee = plot
	end
	local found = 0
	for _, entry in ipairs(Catalog.Entries) do
		local discovered = state.collection[entry.id] == true
		if discovered then found += 1 end
		guideRows[entry.id].Text = (if discovered then "✓  " else "○  ") .. entry.name
	end
	discoveredLabel.Text = found .. " / " .. #Catalog.Entries .. " discovered this session   •   Base income shown"
	if shade.Visible and modal.Visible then updateRebirth() end
end
remotes.State.OnClientEvent:Connect(render)
-- Connect before requesting a snapshot, so a join-time update cannot be lost.
task.spawn(function()
	local ok, snapshot = pcall(function() return remotes.GetState:InvokeServer() end)
	if ok and snapshot then render(snapshot) end
end)

ContextActionService:BindAction("BarnRebirth", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		if shade.Visible then closeModal() else openRebirth() end
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.R)
ContextActionService:BindAction("BarnGuide", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then toggleGuide() end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.B)

local function resize()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	local scale = math.min(1, (viewport.X - 24) / 860)
	topScale.Scale = scale
	statusScale.Scale = math.min(1, (viewport.X - 24) / 490)
	missionScale.Scale = math.min(1, (viewport.X - 24) / 510)
	waveScale.Scale = math.min(1, (viewport.X - 24) / 670)
	toastScale.Scale = math.min(1, (viewport.X - 24) / 620)
	modalScale.Scale = math.min(1, (viewport.X - 24) / 464, (viewport.Y - 28) / 330)
	guideScale.Scale = math.min(1, (viewport.X - 24) / 570, (viewport.Y - 28) / 510)
	wave.Position = UDim2.new(0.5, 0, 0, 24 + 92 * scale)
	toast.Position = UDim2.new(0.5, 0, 0, 100 + 92 * scale)
	timer.Visible = viewport.X > 720
end
local cameraConnection = nil
local function bindCamera()
	if cameraConnection then cameraConnection:Disconnect() end
	local camera = workspace.CurrentCamera
	if camera then cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
	resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()
local clockTick = 0
RunService.RenderStepped:Connect(function(dt)
	clockTick += dt
	if clockTick < 0.2 or not state then return end
	clockTick = 0
	local remaining = math.max(0, math.ceil(state.nextWave - workspace:GetServerTimeNow()))
	timer.Text = if state.wavePhase == "Calm" then string.format("NEXT WAVE  %d:%02d", math.floor(remaining / 60), remaining % 60) else "THE PLAZA IS FLOODING!"
end)
notice("Welcome to Brainrot Barn! Your barn glows mint. Buy a friend on the conveyor, then bring it home.", "success")
