-- Bootstrap owns remote creation. Clients never provide prices, income, or ownership.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldBuilder = require(script.WorldBuilder)
local GameServer = require(script.GameServer)
local ThreatService = require(script.ThreatService)

local folder = Instance.new("Folder")
folder.Name = "BarnRemotes"
local remotes = {}
for _, name in ipairs({ "State", "Notice", "Action", "OpenRebirth" }) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	remotes[name] = remote
end
local getState = Instance.new("RemoteFunction")
getState.Name = "GetState"
getState.Parent = folder
remotes.GetState = getState
local world = WorldBuilder.Build()
local server = GameServer.new(world, remotes)
local threats = ThreatService.new(server)
server.threats = threats
server:Start()
threats:Start()
-- Publish only after handlers and the initial world are ready.
folder.Parent = ReplicatedStorage
print("Brainrot Barn open: 6 barns, 36 pads, 14 peculiar friends. No DataStores; enjoy this session!")
