local repo = 'https://raw.githubusercontent.com/ske-code/Crim/refs/heads/main/'
local splix = loadstring(game:HttpGet(repo .. 'splix.lua'))()
repeat
	task.wait()
until game:IsLoaded()
do
	local function isAdonisAC(table)
		return rawget(table, "Detected")
			and typeof(rawget(table, "Detected")) == "function"
			and rawget(table, "RLocked")
	end

	for _, v in next, getgc(true) do
		if typeof(v) == "table" and isAdonisAC(v) then
			for i, v in next, v do
				if rawequal(i, "Detected") then
					local old
					old = hookfunction(v, function(action, info, crash)
						if rawequal(action, "_") and rawequal(info, "_") and rawequal(crash, false) then
							return old(action, info, crash)
						end
						return task.wait(9e9)
					end)
					warn("bypassed")
					break
				end
			end
		end
	end
end
local Window = splix:New({
    name = "Skeet.gg",
    size = Vector2.new(500, 400),
    accent = Color3.fromRGB(255, 50, 50)
})

Window:Watermark({
    text = "Skeet.gg"
})

local Features = Window:Page({
    name = "Features"
})

local RageLeft = Features:Section({
    name = "Ragebot Settings",
    side = "left"
})

local RageRight = Features:Section({
    name = "Target Settings", 
    side = "right"
})

local WallbangLeft = Features:Section({
    name = "Wallbang",
    side = "left"
})

local SoundRight = Features:Section({
    name = "Sound Settings",
    side = "right"
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

getgenv().RageEnabled = false
getgenv().FireRate = 5
getgenv().Prediction = true
getgenv().PredictionAmount = 0.1
getgenv().TracerEnabled = false
getgenv().TracerColor = Color3.fromRGB(255, 0, 0)
getgenv().TracerWidth = 0.3
getgenv().TracerLifetime = 0.3
getgenv().VisibilityCheck = true
getgenv().RandomTracer = true
getgenv().RandomTracerOffset = 5
getgenv().TeamCheck = false
getgenv().FovEnabled = true
getgenv().FovRadius = 100
getgenv().NoFovLimit = false
getgenv().DownedCheck = false
getgenv().TargetLock = false
getgenv().LockedTarget = nil
getgenv().WallbangEnabled = false
getgenv().HitSoundType = "Default"
getgenv().CustomHitSoundId = "rbxassetid://6534948092"

local function getCurrentTool()
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                return tool
            end
        end
    end
    return nil
end

local function RandomString(length)
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local result = ""
    for i = 1, length do
        result = result .. charset:sub(math.random(1, #charset), math.random(1, #charset))
    end
    return result
end

local function calculateSmartWallbang()
    local localHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
    if not localHead then
        return Camera.CFrame.Position
    end
    
    local headPosition = localHead.Position
    return Vector3.new(headPosition.X, headPosition.Y + 7, headPosition.Z)
end

local function enableWallbang()
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            local isPlayerPart = false
            local parentModel = part:FindFirstAncestorOfClass("Model")
            if parentModel then
                local player = Players:GetPlayerFromCharacter(parentModel)
                if player then
                    isPlayerPart = true
                end
            end
            
            if not isPlayerPart then
                CollectionService:AddTag(part, 'RANGED_CASTER_IGNORE_LIST')
            end
        end
    end
end

local function playHitSound()
    if getgenv().HitSoundType == "Weapon" then
        if LocalPlayer.Character then
            for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    for _, child in ipairs(tool:GetDescendants()) do
                        if child:IsA("Sound") and child.Name == "FireSound1" then
                            local soundClone = child:Clone()
                            soundClone.Parent = Camera
                            soundClone:Play()
                            game:GetService("Debris"):AddItem(soundClone, soundClone.TimeLength)
                            return
                        end
                    end
                end
            end
        end
    elseif getgenv().HitSoundType == "Custom" then
        local sound = Instance.new("Sound")
        sound.SoundId = getgenv().CustomHitSoundId
        sound.Volume = 1
        sound.PlayOnRemove = true
        sound.Parent = Camera
        sound:Destroy()
    else
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://6534948092"
        sound.Volume = 1
        sound.PlayOnRemove = true
        sound.Parent = Camera
        sound:Destroy()
    end
end

local function getClosest()
    if getgenv().TargetLock and getgenv().LockedTarget and getgenv().LockedTarget.Character then
        local head = getgenv().LockedTarget.Character:FindFirstChild("Head")
        local h = getgenv().LockedTarget.Character:FindFirstChild("Humanoid")
        if head and h and h.Health > 0 and (not getgenv().DownedCheck or h.Health > 0) then
            return head
        end
    end

    local closest = nil
    local shortest = math.huge
    local camera = workspace.CurrentCamera

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = p.Character:FindFirstChild("Humanoid")
            local head = p.Character:FindFirstChild("Head")
            if h and h.Health > 0 and head then
                if getgenv().TeamCheck and p.Team == LocalPlayer.Team then
                    continue
                end

                if not getgenv().NoFovLimit and getgenv().FovEnabled then
                    local screenPoint, onScreen = camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                        local mousePos = Vector2.new(screenPoint.X, screenPoint.Y)
                        local distance = (mousePos - center).Magnitude
                        
                        if distance > getgenv().FovRadius then
                            continue
                        end
                    else
                        continue
                    end
                end

                local dist = (head.Position - camera.CFrame.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = head
                    if getgenv().TargetLock then
                        getgenv().LockedTarget = p
                    end
                end
            end
        end
    end

    return closest
end

local function getRandomTracerPosition(targetHead)
    if not targetHead then return nil end
    
    local targetPos = targetHead.Position
    local startPos = Camera.CFrame.Position
    
    local distance = (targetPos - startPos).Magnitude
    
    local maxAngle = math.min(getgenv().RandomTracerOffset or 5, 15)
    local angleX = math.rad(math.random(-maxAngle, maxAngle))
    local angleY = math.rad(math.random(-maxAngle, maxAngle))
    
    local baseCFrame = CFrame.lookAt(startPos, targetPos)
    local rotatedCFrame = baseCFrame * CFrame.Angles(angleX, angleY, 0)
    local randomPosition = startPos + rotatedCFrame.LookVector * distance
    
    local playerFeetHeight = targetPos.Y - 3
    local playerHeadHeight = targetPos.Y + 2
    local maxHeight = playerHeadHeight + 2
    
    local clampedHeight = math.clamp(randomPosition.Y, playerFeetHeight, maxHeight)
    
    return Vector3.new(randomPosition.X, clampedHeight, randomPosition.Z)
end

local function createTracer(startPos, endPos)
    if not getgenv().TracerEnabled then return end

    if getgenv().RandomTracer then
        local targetPart = getClosest()
        if targetPart then
            local playerPos = targetPart.Position
            local maxHeight = playerPos.Y + 10
            local randomHeight = math.random(playerPos.Y, maxHeight)
            
            startPos = Vector3.new(
                startPos.X + math.random(-5, 5),
                randomHeight,
                startPos.Z + math.random(-5, 5)
            )
            
            endPos = Vector3.new(
                endPos.X + math.random(-3, 3),
                randomHeight,
                endPos.Z + math.random(-3, 3)
            )
        end
    end

    local tracerModel = Instance.new("Model")
    tracerModel.Name = "TracerBeam"

    local beam = Instance.new("Beam")
    beam.Color = ColorSequence.new(getgenv().TracerColor)
    beam.Width0 = getgenv().TracerWidth
    beam.Width1 = getgenv().TracerWidth
    beam.Texture = "rbxassetid://7136858729"
    beam.TextureSpeed = 1
    beam.Brightness = 5
    beam.LightEmission = 3
    beam.FaceCamera = true

    local a0 = Instance.new("Attachment")
    local a1 = Instance.new("Attachment")
    a0.WorldPosition = startPos
    a1.WorldPosition = endPos

    beam.Attachment0 = a0
    beam.Attachment1 = a1

    beam.Parent = tracerModel
    a0.Parent = tracerModel
    a1.Parent = tracerModel
    tracerModel.Parent = workspace

    local tweenInfo = TweenInfo.new(
        getgenv().TracerLifetime,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    local tween = game:GetService("TweenService"):Create(beam, tweenInfo, {
        Width0 = 0,
        Width1 = 0,
        Brightness = 0
    })

    tween:Play()

    tween.Completed:Connect(function()
        if tracerModel then 
            tracerModel:Destroy() 
        end
    end)
end

local function shoot(head)
    local tool = getCurrentTool()
    if not tool then return end
    
    local values = tool:FindFirstChild("Values")
    local hitMarker = tool:FindFirstChild("Hitmarker")
    if not values or not hitMarker then return end
    
    local ammo = values:FindFirstChild("SERVER_Ammo")
    local storedAmmo = values:FindFirstChild("SERVER_StoredAmmo")
    if not ammo or not storedAmmo then return end
    
    if ammo.Value <= 0 then return end
    
    local shootPosition = calculateSmartWallbang()
    local hitPosition = head.Position
    local hitDirection = (hitPosition - shootPosition).Unit
    
    if getgenv().Prediction then
        local velocity = head.Velocity or Vector3.zero
        hitPosition = hitPosition + velocity * getgenv().PredictionAmount
        hitDirection = (hitPosition - shootPosition).Unit
    end
    
    local VisualPosition = Camera.CFrame.Position
    local randomKey = RandomString(30) .. "0"
    local args1 = {tick(), randomKey, tool, "FDS9I83", shootPosition, {hitDirection}, false}
    local args2 = {"🧈", tool, randomKey, 1, head, hitPosition, hitDirection}
    
    local GNX_S = ReplicatedStorage:WaitForChild("Events"):WaitForChild("GNX_S")
    local ZFKLF__H = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ZFKLF__H")
    
    GNX_S:FireServer(unpack(args1))
    ZFKLF__H:FireServer(unpack(args2))
    
    ammo.Value = math.max(ammo.Value - 1, 0)
    hitMarker:Fire(head)
    storedAmmo.Value = storedAmmo.Value
    
    createTracer(VisualPosition, hitPosition)
    playHitSound()
end

RageLeft:Checkbox({
    name = "Enable Ragebot",
    def = false,
    callback = function(value)
        getgenv().RageEnabled = value
    end
})

RageLeft:Slider({
    name = "Fire Rate",
    min = 1,
    max = 1000,
    def = 5,
    callback = function(value)
        getgenv().FireRate = value
    end
})

RageLeft:Checkbox({
    name = "Prediction",
    def = true,
    callback = function(value)
        getgenv().Prediction = value
    end
})

RageLeft:Slider({
    name = "Prediction Amount",
    min = 0.05,
    max = 0.3,
    def = 0.1,
    rounding = 2,
    callback = function(value)
        getgenv().PredictionAmount = value
    end
})

RageLeft:Checkbox({
    name = "Random Tracer",
    def = true,
    callback = function(value)
        getgenv().RandomTracer = value
    end
})

RageLeft:Slider({
    name = "Tracer Offset",
    min = 1,
    max = 15,
    def = 5,
    callback = function(value)
        getgenv().RandomTracerOffset = value
    end
})

RageRight:Checkbox({
    name = "Visibility Check",
    def = true,
    callback = function(value)
        getgenv().VisibilityCheck = value
    end
})

RageRight:Checkbox({
    name = "Team Check",
    def = false,
    callback = function(value)
        getgenv().TeamCheck = value
    end
})

RageRight:Checkbox({
    name = "Downed Check",
    def = false,
    callback = function(value)
        getgenv().DownedCheck = value
    end
})

RageRight:Checkbox({
    name = "Target Lock",
    def = false,
    callback = function(value)
        getgenv().TargetLock = value
    end
})

RageRight:Checkbox({
    name = "FOV Circle",
    def = true,
    callback = function(value)
        getgenv().FovEnabled = value
    end
})

RageRight:Slider({
    name = "FOV Radius",
    min = 10,
    max = 500,
    def = 100,
    callback = function(value)
        getgenv().FovRadius = value
    end
})

WallbangLeft:Checkbox({
    name = "Enable Wallbang",
    def = false,
    callback = function(value)
        getgenv().WallbangEnabled = value
        if value then
            enableWallbang()
        end
    end
})

SoundRight:Checkbox({
    name = "Tracer Enabled",
    def = false,
    callback = function(value)
        getgenv().TracerEnabled = value
    end
})

SoundRight:Colorpicker({
    name = "Tracer Color",
    def = Color3.fromRGB(255, 0, 0),
    callback = function(color)
        getgenv().TracerColor = color
    end
})

SoundRight:Slider({
    name = "Tracer Width",
    min = 0.1,
    max = 2,
    def = 0.3,
    rounding = 1,
    callback = function(value)
        getgenv().TracerWidth = value
    end
})

SoundRight:Slider({
    name = "Tracer Lifetime",
    min = 0.1,
    max = 5,
    def = 0.3,
    rounding = 1,
    callback = function(value)
        getgenv().TracerLifetime = value
    end
})

SoundRight:Dropdown({
    name = "Hit Sound Type",
    options = {"Default", "Weapon", "Custom"},
    def = {"Default"},
    callback = function(value)
        getgenv().HitSoundType = value[1]
    end
})

SoundRight:Button({
    name = "Test Hit Sound",
    callback = function()
        playHitSound()
    end
})

local lastShotTime = 0
RunService.Heartbeat:Connect(function()
    if getgenv().RageEnabled then
        local currentTime = tick()
        local waitTime = 1 / getgenv().FireRate
        
        if currentTime - lastShotTime >= waitTime then
            local target = getClosest()
            if target then
                shoot(target)
                lastShotTime = currentTime
            end
        end
    end
end)
local PlayerSection = Features:Section({
    name = "Player",
    side = "left"
})

getgenv().FlyEnabled = false
getgenv().FlySpeed = 50

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local flying = false
local flyConnection

local function setupFly()
    local character = player.Character
    if not character then return end
    
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    
    local function flyUpdate()
        while flying and rootPart and humanoid and humanoid.Health > 0 do
            local cam = workspace.CurrentCamera
            local camCF = cam.CFrame
            
            local lookVector = camCF.LookVector
            local moveDirection = Vector3.new(lookVector.X, lookVector.Y, lookVector.Z).Unit
            
            rootPart.Velocity = moveDirection * getgenv().FlySpeed
            
            local args = {
                "__---r",
                Vector3.zero,
                CFrame.new(-4574, 3, -443, 0, 0, 1, 0, 1, 0, -1, 0, 0),
                false
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("__RZDONL"):FireServer(unpack(args))
            
            RunService.Heartbeat:Wait()
        end
    end
    
    if flying then
        humanoid.PlatformStand = true
        coroutine.wrap(flyUpdate)()
    end
end

local function stopFly()
    flying = false
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoid then
            humanoid.PlatformStand = false
        end
        if rootPart then
            rootPart.Velocity = Vector3.new(0, 0, 0)
        end
    end
end

player.CharacterAdded:Connect(function(character)
    if getgenv().FlyEnabled then
        wait(1)
        setupFly()
    else
        stopFly()
    end
end)

player.CharacterRemoving:Connect(function()
    stopFly()
end)

PlayerSection:Checkbox({
    name = "Fly",
    def = false,
    callback = function(value)
        getgenv().FlyEnabled = value
        flying = value
        
        if value then
            setupFly()
        else
            stopFly()
        end
    end
})

PlayerSection:Slider({
    name = "Fly Speed",
    min = 10,
    max = 200,
    def = 50,
    rounding = 1,
    callback = function(value)
        getgenv().FlySpeed = value
    end
})

local old
old = hookmetamethod(game, "__namecall", function(self, ...)
    local args = { ... }
    if getnamecallmethod() == "FireServer" and not checkcaller() and args[1] == "FlllD" and args[4] == false then
        args[2] = 0
        args[3] = 0
    end
    return old(self, unpack(args))
end)

