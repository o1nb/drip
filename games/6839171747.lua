-- Doors Vape Modules
-- Place ID: 6839171747
-- Game ID: 2440500124

local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local lightingService = cloneref(game:GetService('Lighting'))
local tweenService = cloneref(game:GetService('TweenService'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vape = shared.vape

local store = {
	currentFloor = 'Unknown',
	hookSupported = false
}

-- Detect Floor
run(function()
	local gameData = replicatedStorage:FindFirstChild('GameData')
	if gameData then
		local floorValue = gameData:FindFirstChild('Floor')
		if floorValue then
			store.currentFloor = floorValue.Value
		end
	end
end)

-- Check hook support
run(function()
	pcall(function()
		local mt = getrawmetatable(game)
		if mt and mt.__namecall and hookmetamethod then
			store.hookSupported = true
		end
	end)
end)

-- Fullbright
run(function()
	local Fullbright
	local originalLighting = {}
	local lightingConnection
	
	Fullbright = vape.Categories.Render:CreateModule({
		Name = 'Fullbright',
		Function = function(callback)
			if callback then
				originalLighting = {
					Brightness = lightingService.Brightness,
					ClockTime = lightingService.ClockTime,
					FogEnd = lightingService.FogEnd,
					GlobalShadows = lightingService.GlobalShadows,
					Ambient = lightingService.Ambient
				}
				
				lightingService.Brightness = 2
				lightingService.ClockTime = 14
				lightingService.FogEnd = 100000
				lightingService.GlobalShadows = false
				lightingService.Ambient = Color3.fromRGB(178, 178, 178)
				
				Fullbright:Clean(lightingService.Changed:Connect(function(property)
					if not Fullbright.Enabled then return end
					if property == 'Brightness' and lightingService.Brightness ~= 2 then
						lightingService.Brightness = 2
					end
					if property == 'ClockTime' and lightingService.ClockTime ~= 14 then
						lightingService.ClockTime = 14
					end
					if property == 'FogEnd' and lightingService.FogEnd ~= 100000 then
						lightingService.FogEnd = 100000
					end
					if property == 'GlobalShadows' and lightingService.GlobalShadows ~= false then
						lightingService.GlobalShadows = false
					end
					if property == 'Ambient' and lightingService.Ambient ~= Color3.fromRGB(178, 178, 178) then
						lightingService.Ambient = Color3.fromRGB(178, 178, 178)
					end
				end))
			else
				if lightingConnection then 
					lightingConnection:Disconnect() 
				end
				for property, value in pairs(originalLighting) do 
					lightingService[property] = value 
				end
			end
		end,
		Tooltip = 'See clearly in dark areas'
	})
end)

-- FOV Changer
run(function()
	local FOVChanger
	local FOVValue
	local desiredFOV = 70
	
	FOVChanger = vape.Categories.Render:CreateModule({
		Name = 'FOVChanger',
		Function = function(callback)
			if callback then
				FOVChanger:Clean(runService.RenderStepped:Connect(function()
					if gameCamera and gameCamera.FieldOfView ~= desiredFOV then
						gameCamera.FieldOfView = desiredFOV
					end
				end))
			else
				if gameCamera then
					gameCamera.FieldOfView = 70
				end
			end
		end,
		Tooltip = 'Adjust field of view'
	})
	
	FOVValue = FOVChanger:CreateSlider({
		Name = 'FOV',
		Min = 70,
		Max = 120,
		Default = 70,
		Function = function(val)
			desiredFOV = val
		end
	})
end)

-- No Acceleration
run(function()
	local NoAcceleration
	local originalHrpProps
	
	NoAcceleration = vape.Categories.Blatant:CreateModule({
		Name = 'NoAcceleration',
		Function = function(callback)
			if callback then
				local char = lplr.Character or lplr.CharacterAdded:Wait()
				local hrp = char:WaitForChild('HumanoidRootPart')
				if hrp then
					originalHrpProps = hrp.CustomPhysicalProperties
					hrp.CustomPhysicalProperties = PhysicalProperties.new(100, 0.7, 0, 1, 1)
				end
				
				NoAcceleration:Clean(runService.Heartbeat:Connect(function()
					local character = lplr.Character
					if character then
						local h = character:FindFirstChild('HumanoidRootPart')
						if h then
							local cpp = h.CustomPhysicalProperties
							if not cpp or cpp.Density ~= 100 then
								h.CustomPhysicalProperties = PhysicalProperties.new(100, 0.7, 0, 1, 1)
							end
						end
					end
				end))
			else
				local char = lplr.Character
				if char then
					local h = char:FindFirstChild('HumanoidRootPart')
					if h then 
						h.CustomPhysicalProperties = originalHrpProps 
					end
				end
				originalHrpProps = nil
			end
		end,
		Tooltip = 'Removes movement acceleration'
	})
end)

-- Speed
run(function()
	local Speed
	local SpeedValue
	local AntiSpeedBypass
	local speedValue = 16
	local originalWalkSpeed = 16
	local clonedCollision
	
	Speed = vape.Categories.Blatant:CreateModule({
		Name = 'Speed',
		Function = function(callback)
			if callback then
				if not AntiSpeedBypass.Enabled then
					Speed:Toggle()
					vape:CreateNotification('Speed', 'Enable AntiSpeed Bypass first!', 3)
					return
				end
				
				local char = lplr.Character
				if char then
					local hum = char:FindFirstChild('Humanoid')
					if hum then 
						originalWalkSpeed = hum.WalkSpeed 
					end
				end
				
				Speed:Clean(runService.Heartbeat:Connect(function()
					local character = lplr.Character
					if character then
						local humanoid = character:FindFirstChild('Humanoid')
						if humanoid then
							humanoid.WalkSpeed = speedValue
						end
					end
				end))
			else
				local char = lplr.Character
				if char then
					local hum = char:FindFirstChild('Humanoid')
					if hum then 
						hum.WalkSpeed = originalWalkSpeed 
					end
				end
			end
		end,
		Tooltip = 'Increase walk speed'
	})
	
	SpeedValue = Speed:CreateSlider({
		Name = 'Speed',
		Min = 2,
		Max = store.currentFloor == 'Mines' and 75 or 250,
		Default = 16,
		Function = function(val)
			speedValue = val
		end
	})
	
	AntiSpeedBypass = Speed:CreateToggle({
		Name = 'AntiSpeed Bypass',
		Function = function(callback)
			if callback then
				local char = lplr.Character or lplr.CharacterAdded:Wait()
				local collisionPart = char:WaitForChild('CollisionPart')
				clonedCollision = collisionPart:Clone()
				clonedCollision.Name = '_CollisionClone'
				clonedCollision.Massless = true
				clonedCollision.Parent = char
				clonedCollision.CanCollide = false
				clonedCollision.CanQuery = false
				clonedCollision.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.7, 0, 1, 1)
				
				task.spawn(function()
					while AntiSpeedBypass.Enabled do
						task.wait(0.23)
						if clonedCollision then
							clonedCollision.Massless = false
							task.wait(0.23)
							local root = char:FindFirstChild('HumanoidRootPart')
							if root and root.Anchored then
								clonedCollision.Massless = true
								task.wait(1)
							end
							clonedCollision.Massless = true
						end
					end
				end)
			else
				if clonedCollision then 
					clonedCollision:Destroy() 
					clonedCollision = nil 
				end
			end
		end,
		Default = true
	})
end)

-- Door Reach
run(function()
	local DoorReach
	local ReachDistance
	local reachDistance = 25
	
	DoorReach = vape.Categories.Blatant:CreateModule({
		Name = 'DoorReach',
		Function = function(callback)
			if callback then
				DoorReach:Clean(runService.Heartbeat:Connect(function()
					local char = lplr.Character
					if not char then return end
					local hrp = char:FindFirstChild('HumanoidRootPart')
					if not hrp then return end
					
					local currentRooms = workspace:FindFirstChild('CurrentRooms')
					if not currentRooms then return end
					
					local rooms = currentRooms:GetChildren()
					table.sort(rooms, function(a, b)
						return (tonumber(a.Name) or 0) > (tonumber(b.Name) or 0)
					end)
					
					for i = 1, math.min(3, #rooms) do
						local targetRoom = rooms[i]
						if not targetRoom then continue end
						local door = targetRoom:FindFirstChild('Door')
						if not door then continue end
						local remote = door:FindFirstChild('ClientOpen')
						if not remote then continue end
						local doorPart = door:IsA('BasePart') and door or door:FindFirstChildWhichIsA('BasePart')
						if doorPart then
							local distance = (hrp.Position - doorPart.Position).Magnitude
							if distance <= reachDistance then 
								remote:FireServer() 
							end
						end
					end
				end))
			end
		end,
		Tooltip = 'Open doors from further away'
	})
	
	ReachDistance = DoorReach:CreateSlider({
		Name = 'Distance',
		Min = 10,
		Max = 75,
		Default = 25,
		Function = function(val)
			reachDistance = val
		end
	})
end)

-- Auto GodMode (Rush/Ambush Detection)
run(function()
	local AutoGodMode
	local godModeEnabled = false
	local godModeSaved = {}
	local GOD_COLLISION_SIZE = Vector3.new(1.01, 0.5, 0.5)
	local GODMODE_ENTITY_RANGE = 250
	
	local function applyGodMode(character)
		pcall(function()
			local humanoid = character:WaitForChild('Humanoid', 5)
			if not humanoid then return end
			
			local collision = character:FindFirstChild('Collision', true)
			if not collision or not collision:IsA('BasePart') then return end
			
			local collisionCrouch = collision:FindFirstChild('CollisionCrouch', true)
			
			godModeSaved = { hipHeight = humanoid.HipHeight, parts = {} }
			
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA('BasePart') then
					godModeSaved.parts[part] = {
						Size = part.Size,
						CanCollide = part.CanCollide,
					}
				end
			end
			
			humanoid.HipHeight = 0.05
			collision.Size = GOD_COLLISION_SIZE
			collision.CanCollide = true
			if collisionCrouch and collisionCrouch:IsA('BasePart') then
				collisionCrouch.Size = GOD_COLLISION_SIZE
				collisionCrouch.CanCollide = true
			end
			
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA('BasePart') and part ~= collision and part ~= collisionCrouch then
					part.CanCollide = false
				end
			end
		end)
	end
	
	local function restoreGodMode(character)
		pcall(function()
			if not godModeSaved.parts then return end
			
			local humanoid = character:FindFirstChild('Humanoid')
			if humanoid and godModeSaved.hipHeight then
				humanoid.HipHeight = godModeSaved.hipHeight
			end
			
			for part, saved in pairs(godModeSaved.parts) do
				if part and part.Parent then
					part.Size = saved.Size
					part.CanCollide = saved.CanCollide
				end
			end
			
			godModeSaved = {}
		end)
	end
	
	local function enableGodMode()
		local character = lplr.Character
		if not character or godModeEnabled then return end
		godModeEnabled = true
		applyGodMode(character)
	end
	
	local function disableGodMode()
		local character = lplr.Character
		if not character or not godModeEnabled then return end
		godModeEnabled = false
		restoreGodMode(character)
	end
	
	AutoGodMode = vape.Categories.Blatant:CreateModule({
		Name = 'AutoGodMode',
		Function = function(callback)
			if callback then
				lplr.CharacterAdded:Connect(function(character)
					if godModeEnabled then
						godModeEnabled = false
						task.wait(0.5)
						enableGodMode()
					end
				end)
				
				AutoGodMode:Clean(runService.Heartbeat:Connect(function()
					local character = lplr.Character
					if not character then return end
					local hrp = character:FindFirstChild('HumanoidRootPart')
					if not hrp then return end
					
					local shouldEnable = false
					for _, name in ipairs({'RushMoving', 'AmbushMoving', 'BackdoorRush'}) do
						local model = workspace:FindFirstChild(name)
						if model then
							local part = model:FindFirstChildWhichIsA('BasePart')
							if part and (hrp.Position - part.Position).Magnitude <= GODMODE_ENTITY_RANGE then
								shouldEnable = true
								break
							end
						end
					end
					
					if shouldEnable and not godModeEnabled then
						enableGodMode()
					elseif not shouldEnable and godModeEnabled then
						disableGodMode()
					end
				end))
			else
				if godModeEnabled then 
					disableGodMode() 
				end
			end
		end,
		Tooltip = 'Auto-enables GodMode when Rush/Ambush is within 250 studs'
	})
end)

-- Object Bypass
run(function()
	local ObjectBypass
	local disabledObjects = {}
	
	local function processRoom(room)
		pcall(function()
			local assets = room:FindFirstChild('Assets')
			if not assets then return end
			
			for _, chandelier in pairs(assets:GetChildren()) do
				if chandelier.Name == 'ChandelierObstruction' then
					local collision = chandelier:FindFirstChild('Collision')
					if collision and collision.CanTouch then
						collision.CanTouch = false
						collision.CanQuery = false
						if not table.find(disabledObjects, collision) then
							table.insert(disabledObjects, collision)
						end
					end
				end
			end
			
			for _, object in pairs(assets:GetDescendants()) do
				if object:IsA('Model') and object:GetAttribute('LoadModule') == 'AnimatedObstacleKill' then
					for _, part in pairs(object:GetDescendants()) do
						if part:IsA('BasePart') and part.CanTouch then
							part.CanTouch = false
							part.CanQuery = false
							if not table.find(disabledObjects, part) then
								table.insert(disabledObjects, part)
							end
						end
					end
				end
			end
		end)
	end
	
	ObjectBypass = vape.Categories.Blatant:CreateModule({
		Name = 'ObjectBypass',
		Function = function(callback)
			if callback then
				local currentRooms = workspace:FindFirstChild('CurrentRooms')
				if currentRooms then
					for _, room in pairs(currentRooms:GetChildren()) do 
						processRoom(room) 
					end
				end
				
				task.spawn(function()
					while ObjectBypass.Enabled do
						task.wait(0.5)
						if currentRooms then
							for _, room in pairs(currentRooms:GetChildren()) do 
								processRoom(room) 
							end
						end
					end
				end)
			else
				for _, part in pairs(disabledObjects) do
					pcall(function()
						if part and part.Parent then 
							part.CanTouch = true 
							part.CanQuery = true 
						end
					end)
				end
				table.clear(disabledObjects)
			end
		end,
		Tooltip = 'Disables chandeliers and animated obstacles'
	})
end)

-- Anti-Dupe
run(function()
	local AntiDupe
	local disabledDupeCollisions = {}
	
	local function processRoom(room)
		pcall(function()
			local sideroomSpace = room:FindFirstChild('SideroomSpace')
			if sideroomSpace then
				local collision = sideroomSpace:FindFirstChild('Collision')
				if collision and collision:IsA('BasePart') and collision.CanCollide then
					collision.CanCollide = false
					collision.CanQuery = false
					collision.CanTouch = false
					if not table.find(disabledDupeCollisions, collision) then
						table.insert(disabledDupeCollisions, collision)
					end
				end
			end
			
			local sideroomDupe = room:FindFirstChild('SideroomDupe')
			if sideroomDupe then
				local doorFake = sideroomDupe:FindFirstChild('DoorFake')
				if doorFake then
					local hidden = doorFake:FindFirstChild('Hidden')
					if hidden and hidden:IsA('BasePart') and hidden.CanCollide then
						hidden.CanCollide = false
						hidden.CanQuery = false
						hidden.CanTouch = false
						if not table.find(disabledDupeCollisions, hidden) then
							table.insert(disabledDupeCollisions, hidden)
						end
					end
				end
				
				for _, part in pairs(sideroomDupe:GetDescendants()) do
					if part:IsA('BasePart') and part.Name:lower():find('collision') then
						part:Destroy()
					end
				end
			end
		end)
	end
	
	AntiDupe = vape.Categories.Blatant:CreateModule({
		Name = 'AntiDupe',
		Function = function(callback)
			if callback then
				local currentRooms = workspace:FindFirstChild('CurrentRooms')
				if currentRooms then
					for _, room in pairs(currentRooms:GetChildren()) do 
						processRoom(room) 
					end
				end
				
				task.spawn(function()
					while AntiDupe.Enabled do
						task.wait(0.5)
						if currentRooms then
							for _, room in pairs(currentRooms:GetChildren()) do 
								processRoom(room) 
							end
						end
					end
				end)
			else
				for _, part in pairs(disabledDupeCollisions) do
					pcall(function()
						if part and part.Parent then
							part.CanCollide = true
							part.CanQuery = true
							part.CanTouch = true
						end
					end)
				end
				table.clear(disabledDupeCollisions)
			end
		end,
		Tooltip = 'Disables dupe room collisions'
	})
end)

-- Spoof Crouch
run(function()
	local SpoofCrouch
	
	SpoofCrouch = vape.Categories.Blatant:CreateModule({
		Name = 'SpoofCrouch',
		Function = function(callback)
			if callback then
				task.spawn(function()
					while SpoofCrouch.Enabled do
						pcall(function()
							replicatedStorage.RemotesFolder.Crouch:FireServer(true, true)
						end)
						task.wait(0.32)
					end
				end)
			end
		end,
		Tooltip = 'Tricks the game into thinking you are always crouching'
	})
end)

-- Anti Eyes
run(function()
	local AntiEyes
	
	AntiEyes = vape.Categories.Blatant:CreateModule({
		Name = 'AntiEyes',
		Function = function(callback)
			if callback then
				AntiEyes:Clean(runService.Heartbeat:Connect(function()
					pcall(function()
						for _, v in pairs(workspace:GetChildren()) do
							if v.Name == 'Eyes' and v:FindFirstChild('Core') then
								local core = v.Core
								if core:FindFirstChild('Ambience') and core.Ambience.Playing then
									replicatedStorage.RemotesFolder.MotorReplication:FireServer(-650)
									break
								end
							end
						end
					end)
				end))
			end
		end,
		Tooltip = 'Automatically looks away from Eyes'
	})
end)

-- Disable Screech
run(function()
	local DisableScreech
	local screechOriginalParent
	
	DisableScreech = vape.Categories.Blatant:CreateModule({
		Name = 'DisableScreech',
		Function = function(callback)
			pcall(function()
				local screech = replicatedStorage.Entities:FindFirstChild('Screech')
				if callback and screech then
					local zeScriptStuff = replicatedStorage:FindFirstChild('ZeScript_Stuff')
					if not zeScriptStuff then
						zeScriptStuff = Instance.new('Folder')
						zeScriptStuff.Name = 'ZeScript_Stuff'
						zeScriptStuff.Parent = replicatedStorage
					end
					local disabledEntity = zeScriptStuff:FindFirstChild('DisabledEntity')
					if not disabledEntity then
						disabledEntity = Instance.new('Folder')
						disabledEntity.Name = 'DisabledEntity'
						disabledEntity.Parent = zeScriptStuff
					end
					screechOriginalParent = screech.Parent
					screech.Parent = disabledEntity
				elseif not callback and screech and screechOriginalParent then
					screech.Parent = screechOriginalParent
				end
			end)
		end,
		Tooltip = 'Prevents Screech from spawning'
	})
end)

-- Disable Snare
run(function()
	local DisableSnare
	local snareHitboxes = {}
	
	DisableSnare = vape.Categories.Blatant:CreateModule({
		Name = 'DisableSnare',
		Function = function(callback)
			if callback then
				local currentRooms = workspace:FindFirstChild('CurrentRooms')
				if currentRooms then
					for _, room in pairs(currentRooms:GetChildren()) do
						pcall(function()
							local assets = room:FindFirstChild('Assets')
							if assets then
								for _, snare in pairs(assets:GetChildren()) do
									if snare.Name == 'Snare' then
										local hitbox = snare:FindFirstChild('Hitbox')
										if hitbox then
											hitbox.CanTouch = false
											table.insert(snareHitboxes, hitbox)
										end
									end
								end
							end
						end)
					end
				end
				
				task.spawn(function()
					while DisableSnare.Enabled do
						task.wait(0.5)
						if currentRooms then
							for _, room in pairs(currentRooms:GetChildren()) do
								pcall(function()
									local assets = room:FindFirstChild('Assets')
									if assets then
										for _, snare in pairs(assets:GetChildren()) do
											if snare.Name == 'Snare' then
												local hitbox = snare:FindFirstChild('Hitbox')
												if hitbox and hitbox.CanTouch then
													hitbox.CanTouch = false
													if not table.find(snareHitboxes, hitbox) then
														table.insert(snareHitboxes, hitbox)
													end
												end
											end
										end
									end
								end)
							end
						end
					end
				end)
			else
				for _, hitbox in pairs(snareHitboxes) do
					pcall(function()
						if hitbox and hitbox.Parent then 
							hitbox.CanTouch = true 
						end
					end)
				end
				table.clear(snareHitboxes)
			end
		end,
		Tooltip = 'Disables Snare traps'
	})
end)

-- Auto Proximity Interact
run(function()
	local AutoProxi
	local InstantInteract
	local isAutoProxiKeyHeld = false
	local autoProxiCooldowns = {}
	local autoProxiKey = Enum.KeyCode.R
	
	inputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == autoProxiKey and not gameProcessed then
			isAutoProxiKeyHeld = true
		end
	end)
	
	inputService.InputEnded:Connect(function(input)
		if input.KeyCode == autoProxiKey then
			isAutoProxiKeyHeld = false
		end
	end)
	
	local function shouldInteract(prompt)
		if not prompt or not prompt.Enabled then return false end
		local actionText = (prompt.ActionText or ''):lower()
		if actionText:find('close') then return false end
		if actionText:find('leave') then return false end
		if actionText:find('exit') and not actionText:find('door') then return false end
		if actionText:find('hide') then return false end
		return true
	end
	
	local function getAllProximityPrompts()
		local prompts = {}
		pcall(function()
			local currentRooms = workspace:FindFirstChild('CurrentRooms')
			if currentRooms then
				for _, prompt in pairs(currentRooms:GetDescendants()) do
					if prompt:IsA('ProximityPrompt') then 
						table.insert(prompts, prompt) 
					end
				end
			end
			local playerGui = lplr:FindFirstChild('PlayerGui')
			if playerGui then
				for _, prompt in pairs(playerGui:GetDescendants()) do
					if prompt:IsA('ProximityPrompt') then 
						table.insert(prompts, prompt) 
					end
				end
			end
		end)
		return prompts
	end
	
	local function runAutoProxi()
		pcall(function()
			local prompts = getAllProximityPrompts()
			for _, prompt in pairs(prompts) do
				if shouldInteract(prompt) then
					local promptId = tostring(prompt:GetFullName())
					local now = tick()
					if autoProxiCooldowns[promptId] and (now - autoProxiCooldowns[promptId]) < 0.1 then 
						continue 
					end
					autoProxiCooldowns[promptId] = now
					
					task.spawn(function()
						pcall(function()
							if InstantInteract.Enabled and prompt.HoldDuration > 0 then
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
						end)
					end)
				end
			end
			
			for id, time in pairs(autoProxiCooldowns) do
				if tick() - time > 5 then 
					autoProxiCooldowns[id] = nil 
				end
			end
		end)
	end
	
	AutoProxi = vape.Categories.Utility:CreateModule({
		Name = 'AutoProxi',
		Function = function(callback)
			if callback then
				task.spawn(function()
					while AutoProxi.Enabled do
						if isAutoProxiKeyHeld then 
							runAutoProxi() 
						end
						task.wait(0.05)
					end
				end)
			else
				table.clear(autoProxiCooldowns)
			end
		end,
		Tooltip = 'Hold R to auto-interact with proximity prompts'
	})
	
	InstantInteract = AutoProxi:CreateToggle({
		Name = 'Instant',
		Default = true
	})
end)

-- Entity Notifier
run(function()
	local EntityNotifier
	local notifiedEntities = {}
	
	EntityNotifier = vape.Categories.Render:CreateModule({
		Name = 'EntityNotifier',
		Function = function(callback)
			if callback then
				task.spawn(function()
					local entityNotifyList = {
						{ name = 'RushMoving', text = 'Rush is coming!' },
						{ name = 'AmbushMoving', text = 'Ambush is coming!' },
						{ name = 'Eyes', text = 'Eyes has appeared!' },
						{ name = 'Halt', text = 'Halt has appeared!' },
					}
					
					while EntityNotifier.Enabled do
						task.wait(0.5)
						pcall(function()
							for _, e in ipairs(entityNotifyList) do
								local model = workspace:FindFirstChild(e.name)
								if model and not notifiedEntities[e.name] then
									notifiedEntities[e.name] = true
									vape:CreateNotification('Entity', e.text, 5)
								elseif not model and notifiedEntities[e.name] then
									notifiedEntities[e.name] = nil
								end
							end
						end)
					end
				end)
			else
				table.clear(notifiedEntities)
			end
		end,
		Tooltip = 'Get notifications when entities spawn'
	})
end)

-- Mines Anticheat Bypass
if store.currentFloor == 'Mines' or store.currentFloor == 'Unknown' then
	run(function()
		local MinesBypass
		local ladderESP = {}
		
		MinesBypass = vape.Categories.Minigames:CreateModule({
			Name = 'MinesBypass',
			Function = function(callback)
				if callback then
					local currentRooms = workspace:FindFirstChild('CurrentRooms')
					if currentRooms then
						for _, room in pairs(currentRooms:GetChildren()) do
							pcall(function()
								local ladder = room:FindFirstChild('Ladder', true)
								if ladder then
									local highlight = Instance.new('Highlight')
									highlight.FillColor = Color3.fromRGB(0, 100, 255)
									highlight.OutlineColor = Color3.fromRGB(0, 150, 255)
									highlight.FillTransparency = 0.5
									highlight.OutlineTransparency = 0
									highlight.Parent = ladder
									table.insert(ladderESP, highlight)
								end
							end)
						end
					end
					
					task.spawn(function()
						while MinesBypass.Enabled do
							task.wait(0.1)
							pcall(function()
								local character = lplr.Character
								if character then
									local climbingAttr = character:GetAttribute('Climbing')
									if climbingAttr == true then
										task.wait(0.5)
										character:SetAttribute('Climbing', false)
									end
								end
							end)
						end
					end)
				else
					for _, highlight in pairs(ladderESP) do
						pcall(function()
							if highlight and highlight.Parent then 
								highlight:Destroy() 
							end
						end)
					end
					table.clear(ladderESP)
				end
			end,
			Tooltip = 'Prevents ladder detection in Mines'
		})
	end)
end

-- Figure GodMode
run(function()
	local FigureGodMode
	local isFigureGodModeActive = false
	local fakeCameraConnection
	
	local function getFigurePosition(figureRig)
		if not figureRig then return nil end
		local ok, pivot = pcall(function() return figureRig:GetPivot() end)
		if ok and pivot then return pivot.Position end
		local part = figureRig:FindFirstChildWhichIsA('BasePart', true)
		return part and part.Position or nil
	end
	
	local function enableFakeCamera(character)
		if fakeCameraConnection then return end
		local head = character:FindFirstChild('Head')
		if not head then return end
		gameCamera.CameraType = Enum.CameraType.Scriptable
		fakeCameraConnection = runService.RenderStepped:Connect(function()
			if not head or not head.Parent then return end
			gameCamera.CFrame = head.CFrame * CFrame.new(0, -10, 0)
		end)
	end
	
	local function disableFakeCamera()
		if fakeCameraConnection then
			fakeCameraConnection:Disconnect()
			fakeCameraConnection = nil
		end
		gameCamera.CameraType = Enum.CameraType.Custom
	end
	
	local function enableFigureGodMode(character)
		pcall(function()
			if isFigureGodModeActive then return end
			local humanoid = character:FindFirstChild('Humanoid')
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if not (humanoid and hrp) then return end
			hrp.CFrame = hrp.CFrame + Vector3.new(0, 13, 0)
			humanoid.HipHeight = 13
			enableFakeCamera(character)
			isFigureGodModeActive = true
		end)
	end
	
	local function disableFigureGodMode(character)
		pcall(function()
			local humanoid = character:FindFirstChild('Humanoid')
			if humanoid then humanoid.HipHeight = 2 end
			disableFakeCamera()
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if hrp then hrp.CFrame = hrp.CFrame - Vector3.new(0, 13, 0) end
			isFigureGodModeActive = false
		end)
	end
	
	FigureGodMode = vape.Categories.Blatant:CreateModule({
		Name = 'FigureGodMode',
		Function = function(callback)
			if callback then
				lplr.CharacterAdded:Connect(function()
					isFigureGodModeActive = false
					disableFakeCamera()
				end)
				
				FigureGodMode:Clean(runService.Heartbeat:Connect(function()
					local character = lplr.Character
					if not character then return end
					local hrp = character:FindFirstChild('HumanoidRootPart')
					if not hrp then return end
					
					local figureNearby = false
					local currentRooms = workspace:FindFirstChild('CurrentRooms')
					if currentRooms then
						for _, room in pairs(currentRooms:GetChildren()) do
							local setup = room:FindFirstChild('FigureSetup')
							if setup then
								local rig = setup:FindFirstChild('FigureRig')
								if rig then
									local pos = getFigurePosition(rig)
									if pos and (hrp.Position - pos).Magnitude <= 30 then
										figureNearby = true
										break
									end
								end
							end
						end
					end
					
					if figureNearby and not isFigureGodModeActive then
						enableFigureGodMode(character)
					elseif not figureNearby and isFigureGodModeActive then
						disableFigureGodMode(character)
					end
				end))
			else
				if isFigureGodModeActive then
					local character = lplr.Character
					if character then disableFigureGodMode(character) end
				end
			end
		end,
		Tooltip = 'Auto-enables godmode when Figure is nearby'
	})
end)

-- Anti-Groundskeeper
run(function()
	local AntiGroundskeeper
	local isAntiGKActive = false
	local fakeGKCameraConn
	
	local function getModelPosition(model)
		if not model then return nil end
		local ok, pivot = pcall(function() return model:GetPivot() end)
		if ok and pivot then return pivot.Position end
		local part = model:FindFirstChildWhichIsA('BasePart', true)
		return part and part.Position or nil
	end
	
	local function enableFakeGKCamera(character)
		if fakeGKCameraConn then return end
		local head = character:FindFirstChild('Head')
		if not head then return end
		gameCamera.CameraType = Enum.CameraType.Scriptable
		fakeGKCameraConn = runService.RenderStepped:Connect(function()
			if not head or not head.Parent then return end
			gameCamera.CFrame = head.CFrame * CFrame.new(0, -2, 0)
		end)
	end
	
	local function disableFakeGKCamera()
		if fakeGKCameraConn then
			fakeGKCameraConn:Disconnect()
			fakeGKCameraConn = nil
		end
		gameCamera.CameraType = Enum.CameraType.Custom
	end
	
	local function enableAntiGroundskeeper(character)
		pcall(function()
			if isAntiGKActive then return end
			local humanoid = character:FindFirstChild('Humanoid')
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if not (humanoid and hrp) then return end
			hrp.CFrame = hrp.CFrame + Vector3.new(0, 2, 0)
			humanoid.HipHeight = 5
			enableFakeGKCamera(character)
			isAntiGKActive = true
		end)
	end
	
	local function disableAntiGroundskeeper(character)
		pcall(function()
			local humanoid = character:FindFirstChild('Humanoid')
			if humanoid then humanoid.HipHeight = 2 end
			disableFakeGKCamera()
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if hrp then hrp.CFrame = hrp.CFrame - Vector3.new(0, 2, 0) end
			isAntiGKActive = false
		end)
	end
	
	AntiGroundskeeper = vape.Categories.Blatant:CreateModule({
		Name = 'AntiGroundskeeper',
		Function = function(callback)
			if callback then
				lplr.CharacterAdded:Connect(function()
					isAntiGKActive = false
					disableFakeGKCamera()
				end)
				
				AntiGroundskeeper:Clean(runService.Heartbeat:Connect(function()
					local character = lplr.Character
					if not character then return end
					local hrp = character:FindFirstChild('HumanoidRootPart')
					if not hrp then return end
					
					local gkFound = false
					local currentRooms = workspace:FindFirstChild('CurrentRooms')
					if currentRooms then
						for _, room in pairs(currentRooms:GetChildren()) do
							local gk = room:FindFirstChild('Groundskeeper')
							if gk and gk:IsA('Model') then
								local gkPos = getModelPosition(gk)
								if gkPos and (hrp.Position - gkPos).Magnitude <= 300 then
									gkFound = true
									break
								end
							end
						end
					end
					
					if gkFound and not isAntiGKActive then
						enableAntiGroundskeeper(character)
					elseif not gkFound and isAntiGKActive then
						disableAntiGroundskeeper(character)
					end
				end))
			else
				if isAntiGKActive then
					local character = lplr.Character
					if character then disableAntiGroundskeeper(character) end
				end
			end
		end,
		Tooltip = 'Auto-enables protection when Groundskeeper is nearby'
	})
end)

-- Anticheat Manipulation
run(function()
	local AnticheatManip
	local isAnticheatKeyHeld = false
	local anticheatManipKey = Enum.KeyCode.T
	
	inputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == anticheatManipKey and not gameProcessed then
			isAnticheatKeyHeld = true
		end
	end)
	
	inputService.InputEnded:Connect(function(input)
		if input.KeyCode == anticheatManipKey then
			isAnticheatKeyHeld = false
		end
	end)
	
	AnticheatManip = vape.Categories.Blatant:CreateModule({
		Name = 'AnticheatManip',
		Function = function(callback)
			if callback then
				task.spawn(function()
					while AnticheatManip.Enabled do
						task.wait(0.00001)
						pcall(function()
							if isAnticheatKeyHeld and lplr.Character then
								lplr.Character:PivotTo(lplr.Character:GetPivot() + gameCamera.CFrame.LookVector * Vector3.new(1, 0, 1) * -100)
							end
						end)
					end
				end)
			end
		end,
		Tooltip = 'Hold T to use anticheat to teleport forward'
	})
end)

-- Hook-based modules
if store.hookSupported then
	run(function()
		local AntiHeartbeat
		local AntiA90
		local hooksInitialized = false
		
		local function initHooks()
			if hooksInitialized then return end
			pcall(function()
				local HideMonster = replicatedStorage:WaitForChild('RemotesFolder'):WaitForChild('HideMonster')
				local A90Remote = replicatedStorage:WaitForChild('RemotesFolder'):WaitForChild('A90')
				
				local oldNamecall
				oldNamecall = hookmetamethod(game, '__namecall', function(self, ...)
					local method = getnamecallmethod()
					if method == 'FireServer' then
						if AntiHeartbeat.Enabled and self == HideMonster then
							return
						end
						if AntiA90.Enabled and self == A90Remote then
							local args = {...}
							if args[1] == 'moved' then
								return oldNamecall(self, 'didnt')
							end
						end
					end
					return oldNamecall(self, ...)
				end)
				hooksInitialized = true
			end)
		end
		
		AntiHeartbeat = vape.Categories.Blatant:CreateModule({
			Name = 'AntiHeartbeat',
			Function = function(callback)
				if callback then initHooks() end
			end,
			Tooltip = 'Blocks Figure heartbeat minigame'
		})
		
		AntiA90 = vape.Categories.Blatant:CreateModule({
			Name = 'AntiA90',
			Function = function(callback)
				if callback then initHooks() end
			end,
			Tooltip = 'Replaces A-90 death signal'
		})
	end)
end
