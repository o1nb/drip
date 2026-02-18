--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))
local lighting = cloneref(game:GetService('Lighting'))
local collectionService = cloneref(game:GetService('CollectionService'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer

local vape = shared.vape
local entitylib = vape.Libraries.entity
local color = vape.Libraries.color

local store = {
	matchState = 0,
	currentFloor = 'Unknown',
	entities = {}
}

local doors = {}

-- Detect current floor
local function detectFloor()
	local gameData = replicatedStorage:FindFirstChild('GameData')
	if gameData then
		local floorValue = gameData:FindFirstChild('Floor')
		if floorValue then
			store.currentFloor = floorValue.Value
			return floorValue.Value
		end
	end
	return 'Unknown'
end

store.currentFloor = detectFloor()

-- Initialize Doors API
task.spawn(function()
	local success, err = pcall(function()
		-- Wait for RemotesFolder
		local remotesFolder = replicatedStorage:WaitForChild('RemotesFolder', 10)
		if remotesFolder then
			doors.RemotesFolder = remotesFolder
		end
		
		-- Get various modules if they exist
		pcall(function()
			doors.Modules = replicatedStorage:FindFirstChild('Modules')
		end)
		
		pcall(function()
			doors.Entities = replicatedStorage:FindFirstChild('Entities')
		end)
	end)
	
	if not success then
		warn('[Doors API] Failed to initialize:', err)
	end
end)

-- Entity tracking
local function trackEntity(entityName, displayName)
	local entity = workspace:FindFirstChild(entityName)
	if entity and not store.entities[entityName] then
		store.entities[entityName] = {
			Name = displayName or entityName,
			Model = entity,
			Detected = tick()
		}
		vape:CreateNotification('Entity Detected', displayName or entityName .. ' has spawned!', 5)
	elseif not entity and store.entities[entityName] then
		store.entities[entityName] = nil
	end
	return entity ~= nil
end

task.spawn(function()
	while task.wait(0.5) do
		trackEntity('RushMoving', 'Rush')
		trackEntity('AmbushMoving', 'Ambush')
		trackEntity('Eyes', 'Eyes')
		trackEntity('Halt', 'Halt')
		trackEntity('Screech', 'Screech')
	end
end)

-- Utility Functions
local function getSpeed()
	if entitylib.isAlive then
		return entitylib.character.Humanoid.WalkSpeed
	end
	return 16
end

local function notif(title, text, duration)
	vape:CreateNotification(title, text, duration or 3)
end

-- ESP Utilities
local espHighlights = {}

local function clearESP(espType)
	if espHighlights[espType] then
		for _, item in espHighlights[espType] do
			if item and item.Parent then
				item:Destroy()
			end
		end
		espHighlights[espType] = {}
	end
end

local function addESPToObject(obj, espType, color, outlineColor, labelText)
	if not obj then return end
	if not espHighlights[espType] then
		espHighlights[espType] = {}
	end
	
	local highlight = Instance.new('Highlight')
	highlight.Name = espType .. 'ESP'
	highlight.FillColor = color
	highlight.OutlineColor = outlineColor
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.Parent = obj
	table.insert(espHighlights[espType], highlight)
	
	if labelText then
		local billboard = Instance.new('BillboardGui')
		billboard.Name = espType .. 'ESP'
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.new(0, 100, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 2, 0)
		billboard.Parent = obj
		
		local textLabel = Instance.new('TextLabel')
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = labelText
		textLabel.TextColor3 = color
		textLabel.TextStrokeTransparency = 0
		textLabel.TextScaled = true
		textLabel.Font = Enum.Font.GothamBold
		textLabel.Parent = billboard
		table.insert(espHighlights[espType], billboard)
	end
end

-- MODULES START HERE

run(function()
	local Fullbright
	local originalLighting = {}
	local lightingConnection
	
	Fullbright = vape.Categories.Render:CreateModule({
		Name = 'Fullbright',
		Function = function(callback)
			if callback then
				originalLighting = {
					Brightness = lighting.Brightness,
					ClockTime = lighting.ClockTime,
					FogEnd = lighting.FogEnd,
					GlobalShadows = lighting.GlobalShadows,
					Ambient = lighting.Ambient
				}
				
				lighting.Brightness = 2
				lighting.ClockTime = 14
				lighting.FogEnd = 100000
				lighting.GlobalShadows = false
				lighting.Ambient = Color3.fromRGB(178, 178, 178)
				
				Fullbright:Clean(lighting.Changed:Connect(function(property)
					if not Fullbright.Enabled then return end
					if property == 'Brightness' and lighting.Brightness ~= 2 then
						lighting.Brightness = 2
					end
					if property == 'ClockTime' and lighting.ClockTime ~= 14 then
						lighting.ClockTime = 14
					end
					if property == 'FogEnd' and lighting.FogEnd ~= 100000 then
						lighting.FogEnd = 100000
					end
					if property == 'GlobalShadows' and lighting.GlobalShadows ~= false then
						lighting.GlobalShadows = false
					end
					if property == 'Ambient' and lighting.Ambient ~= Color3.fromRGB(178, 178, 178) then
						lighting.Ambient = Color3.fromRGB(178, 178, 178)
					end
				end))
			else
				if lightingConnection then
					lightingConnection:Disconnect()
					lightingConnection = nil
				end
				for property, value in originalLighting do
					lighting[property] = value
				end
			end
		end,
		Tooltip = 'See clearly in dark areas'
	})
end)

run(function()
	local FOV
	local fovValue = 70
	local fovConnection
	
	FOV = vape.Categories.Render:CreateModule({
		Name = 'FOV',
		Function = function(callback)
			if callback then
				fovConnection = runService.RenderStepped:Connect(function()
					if gameCamera and gameCamera.FieldOfView ~= fovValue then
						gameCamera.FieldOfView = fovValue
					end
				end)
				FOV:Clean(fovConnection)
			end
		end,
		Tooltip = 'Adjust field of view'
	})
	
	vape.Categories.Render:CreateSlider({
		Name = 'FOV Value',
		Min = 70,
		Max = 120,
		Default = 70,
		Function = function(val)
			fovValue = val
		end,
		Suffix = function(val)
			return val == 1 and 'degree' or 'degrees'
		end
	})
end)

run(function()
	local Speed
	local speedValue = 16
	local originalWalkSpeed = 16
	
	Speed = vape.Categories.Blatant:CreateModule({
		Name = 'Speed',
		Function = function(callback)
			if callback then
				if entitylib.isAlive then
					local humanoid = entitylib.character.Humanoid
					if humanoid then
						originalWalkSpeed = humanoid.WalkSpeed
					end
				end
				
				Speed:Clean(runService.Heartbeat:Connect(function()
					if entitylib.isAlive then
						local humanoid = entitylib.character.Humanoid
						if humanoid then
							humanoid.WalkSpeed = speedValue
						end
					end
				end))
			else
				if entitylib.isAlive then
					local humanoid = entitylib.character.Humanoid
					if humanoid then
						humanoid.WalkSpeed = originalWalkSpeed
					end
				end
			end
		end,
		Tooltip = 'Increase walk speed'
	})
	
	vape.Categories.Blatant:CreateSlider({
		Name = 'Speed Value',
		Min = 16,
		Max = 100,
		Default = 50,
		Function = function(val)
			speedValue = val
		end
	})
end)

run(function()
	local NoAccel
	local originalHrpProps
	
	NoAccel = vape.Categories.Blatant:CreateModule({
		Name = 'NoAcceleration',
		Function = function(callback)
			if callback then
				if entitylib.isAlive then
					local hrp = entitylib.character.HumanoidRootPart
					if hrp then
						originalHrpProps = hrp.CustomPhysicalProperties
						hrp.CustomPhysicalProperties = PhysicalProperties.new(100, 0.7, 0, 1, 1)
					end
				end
				
				NoAccel:Clean(runService.Heartbeat:Connect(function()
					if entitylib.isAlive then
						local hrp = entitylib.character.HumanoidRootPart
						if hrp then
							local cpp = hrp.CustomPhysicalProperties
							if not cpp or cpp.Density ~= 100 then
								hrp.CustomPhysicalProperties = PhysicalProperties.new(100, 0.7, 0, 1, 1)
							end
						end
					end
				end))
			else
				if entitylib.isAlive then
					local hrp = entitylib.character.HumanoidRootPart
					if hrp and originalHrpProps then
						hrp.CustomPhysicalProperties = originalHrpProps
					end
				end
				originalHrpProps = nil
			end
		end,
		Tooltip = 'Removes movement acceleration'
	})
end)

run(function()
	local EntityESP
	local espEnabled = false
	local espUpdateLoop
	
	local function createEntityESP()
		local entityMap = {
			RushMoving = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(200, 0, 0), 'RUSH'},
			AmbushMoving = {Color3.fromRGB(255, 100, 0), Color3.fromRGB(200, 80, 0), 'AMBUSH'},
			Eyes = {Color3.fromRGB(150, 0, 255), Color3.fromRGB(120, 0, 200), 'EYES'},
			Halt = {Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 150, 200), 'HALT'},
			Screech = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200), 'SCREECH'}
		}
		
		for entityName, info in entityMap do
			local entity = workspace:FindFirstChild(entityName)
			if entity and entity:IsA('Model') then
				addESPToObject(entity, 'Entity', info[1], info[2], info[3])
			end
		end
		
		-- Check for Figure
		local currentRooms = workspace:FindFirstChild('CurrentRooms')
		if currentRooms then
			for _, room in currentRooms:GetChildren() do
				local figureSetup = room:FindFirstChild('FigureSetup')
				if figureSetup then
					local figureRig = figureSetup:FindFirstChild('FigureRig')
					if figureRig then
						addESPToObject(figureRig, 'Entity', Color3.fromRGB(255, 0, 0), Color3.fromRGB(200, 0, 0), 'FIGURE')
					end
				end
			end
		end
	end
	
	EntityESP = vape.Categories.Render:CreateModule({
		Name = 'EntityESP',
		Function = function(callback)
			espEnabled = callback
			if callback then
				createEntityESP()
				espUpdateLoop = task.spawn(function()
					while espEnabled do
						task.wait(0.5)
						clearESP('Entity')
						createEntityESP()
					end
				end)
			else
				if espUpdateLoop then
					task.cancel(espUpdateLoop)
					espUpdateLoop = nil
				end
				clearESP('Entity')
			end
		end,
		Tooltip = 'See entities through walls'
	})
end)

run(function()
	local DoorESP
	local doorESPEnabled = false
	local doorUpdateLoop
	
	local function createDoorESP()
		local currentRooms = workspace:FindFirstChild('CurrentRooms')
		if not currentRooms then return end
		
		for _, room in currentRooms:GetChildren() do
			local door = room:FindFirstChild('Door')
			if door and door:IsA('Model') then
				addESPToObject(door, 'Door', Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 200, 0), 'DOOR')
			end
		end
	end
	
	vape.Categories.Render:CreateModule({
		Name = 'DoorESP',
		Function = function(callback)
			doorESPEnabled = callback
			if callback then
				createDoorESP()
				doorUpdateLoop = task.spawn(function()
					while doorESPEnabled do
						task.wait(1)
						clearESP('Door')
						createDoorESP()
					end
				end)
			else
				if doorUpdateLoop then
					task.cancel(doorUpdateLoop)
					doorUpdateLoop = nil
				end
				clearESP('Door')
			end
		end,
		Tooltip = 'See doors through walls'
	})
end)

run(function()
	local ItemESP
	local itemESPEnabled = false
	local itemUpdateLoop
	
	local function createItemESP()
		local currentRooms = workspace:FindFirstChild('CurrentRooms')
		if not currentRooms then return end
		
		local itemMap = {
			KeyObtain = 'Key',
			FuseObtain = 'Fuse',
			LiveHintBook = 'Book',
			LeverForGate = 'Lever'
		}
		
		for _, room in currentRooms:GetChildren() do
			for _, obj in room:GetDescendants() do
				local label = itemMap[obj.Name]
				if label then
					addESPToObject(obj, 'Item', Color3.fromRGB(255, 255, 0), Color3.fromRGB(200, 200, 0), label)
				end
			end
		end
	end
	
	vape.Categories.Render:CreateModule({
		Name = 'ItemESP',
		Function = function(callback)
			itemESPEnabled = callback
			if callback then
				createItemESP()
				itemUpdateLoop = task.spawn(function()
					while itemESPEnabled do
						task.wait(1)
						clearESP('Item')
						createItemESP()
					end
				end)
			else
				if itemUpdateLoop then
					task.cancel(itemUpdateLoop)
					itemUpdateLoop = nil
				end
				clearESP('Item')
			end
		end,
		Tooltip = 'See important items through walls'
	})
end)

run(function()
	local EntityNotifier
	local notifierEnabled = false
	local notifiedEntities = {}
	
	EntityNotifier = vape.Categories.Utility:CreateModule({
		Name = 'EntityNotifier',
		Function = function(callback)
			notifierEnabled = callback
			if not callback then
				notifiedEntities = {}
			end
		end,
		Tooltip = 'Get notifications when entities spawn'
	})
	
	task.spawn(function()
		local entityNotifyList = {
			{name = 'RushMoving', text = 'Rush is coming!', type = 'Error'},
			{name = 'AmbushMoving', text = 'Ambush is coming!', type = 'Error'},
			{name = 'Eyes', text = 'Eyes has appeared!', type = 'Error'},
			{name = 'Halt', text = 'Halt has appeared!', type = 'Warning'}
		}
		
		while true do
			task.wait(0.5)
			if notifierEnabled then
				for _, e in entityNotifyList do
					local model = workspace:FindFirstChild(e.name)
					if model and not notifiedEntities[e.name] then
						notifiedEntities[e.name] = true
						notif('Entity Alert', e.text, 5)
					elseif not model and notifiedEntities[e.name] then
						notifiedEntities[e.name] = nil
					end
				end
			end
		end
	end)
end)

run(function()
	local InstantProximity
	
	InstantProximity = vape.Categories.Utility:CreateModule({
		Name = 'InstantProximity',
		Function = function(callback)
			if callback then
				InstantProximity:Clean(runService.Heartbeat:Connect(function()
					local currentRooms = workspace:FindFirstChild('CurrentRooms')
					if not currentRooms then return end
					
					for _, prompt in currentRooms:GetDescendants() do
						if prompt:IsA('ProximityPrompt') and prompt.Enabled then
							local actionText = (prompt.ActionText or ''):lower()
							-- Don't auto-interact with hide/close prompts
							if not actionText:find('hide') and not actionText:find('close') then
								if prompt.HoldDuration > 0 then
									local originalHold = prompt.HoldDuration
									prompt.HoldDuration = 0
									fireproximityprompt(prompt)
									task.delay(0.05, function()
										if prompt and prompt.Parent then
											prompt.HoldDuration = originalHold
										end
									end)
								else
									fireproximityprompt(prompt)
								end
							end
						end
					end
				end))
			end
		end,
		Tooltip = 'Instantly complete proximity prompts'
	})
end)

-- Session Info
local games = vape.Libraries.sessioninfo:AddItem('Games Played')
local currentFloorInfo = vape.Libraries.sessioninfo:AddItem('Floor', 0, function()
	return store.currentFloor
end, false)

task.delay(1, function()
	games:Increment()
end)

-- Cleanup
vape:Clean(function()
	for _, v in espHighlights do
		for _, item in v do
			if item and item.Parent then
				item:Destroy()
			end
		end
	end
	table.clear(espHighlights)
	table.clear(store)
	table.clear(doors)
end)

notif('Vape', 'Doors modules loaded! Floor: ' .. store.currentFloor, 3)
