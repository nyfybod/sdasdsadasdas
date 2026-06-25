-- =====================================================
-- CHEAT HUB НА RAYFIELD UI (С TEAM CHECK)
-- =====================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- =====================================================
-- ЗАГРУЗКА RAYFIELD
-- =====================================================
local Rayfield
local success, err = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success then
    warn("RAYFIELD НЕ ЗАГРУЗИЛСЯ, БЛЯТЬ! Ошибка: " .. tostring(err))
    return
end

-- =====================================================
-- НАСТРОЙКИ
-- =====================================================
local Settings = {
    ESP = {
        Enabled = false,
        Color = Color3.fromRGB(255, 0, 0),
        Transparency = 0.5,
        ShowNames = true,
        ShowHealth = true,
        ShowDistance = true,
        TeamCheck = true -- ВКЛЮЧАЕМ ТИМЧЕК ПО УМОЛЧАНИЮ
    },
    Aimbot = {
        Enabled = false,
        FOV = 200,
        Target = "Head",
        Smoothness = 0.3,
        Key = "RightButton",
        ShowFOV = true,
        AimMode = "Hold",
        TeamCheck = true -- ВКЛЮЧАЕМ ТИМЧЕК ПО УМОЛЧАНИЮ
    },
    AntiAim = {
        Enabled = false,
        Mode = "Spin",
        Speed = 5
    },
    ThirdPerson = {
        Enabled = false,
        Distance = 10
    },
    Fly = {
        Enabled = false,
        Speed = 50
    },
    Noclip = {
        Enabled = false
    },
    InfiniteJump = {
        Enabled = false
    },
    Speed = {
        Enabled = false,
        Value = 16
    }
}

-- =====================================================
-- ФУНКЦИЯ TEAM CHECK
-- =====================================================
local function IsEnemy(player)
    if player == LocalPlayer then return false end
    
    -- Если тимчек выключен - все враги
    if not Settings.ESP.TeamCheck and not Settings.Aimbot.TeamCheck then
        return true
    end
    
    local localChar = LocalPlayer.Character
    local targetChar = player.Character
    
    if not localChar or not targetChar then return true end
    
    -- Проверяем по команде (Team)
    local localTeam = LocalPlayer.Team
    local targetTeam = player.Team
    
    if localTeam and targetTeam then
        if localTeam == targetTeam then
            return false -- Свой
        else
            return true -- Враг
        end
    end
    
    -- Проверяем по цвету (для игр где нет Team)
    local localColor = localChar:FindFirstChild("Head") and localChar.Head.BrickColor
    local targetColor = targetChar:FindFirstChild("Head") and targetChar.Head.BrickColor
    
    if localColor and targetColor then
        if localColor == targetColor then
            return false -- Свой
        else
            return true -- Враг
        end
    end
    
    -- Если не удалось определить - считаем врагом
    return true
end

-- =====================================================
-- ФУНКЦИЯ ПОЛУЧЕНИЯ ВРАГОВ
-- =====================================================
local function GetEnemies()
    local enemies = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsEnemy(player) then
            table.insert(enemies, player)
        end
    end
    return enemies
end

-- =====================================================
-- ПЕРЕМЕННЫЕ ДЛЯ ESP
-- =====================================================
local ActiveHighlights = {}
local ActiveNameTags = {}
local ActiveHealthBars = {}
local ActiveDistanceLabels = {}

-- =====================================================
-- ПЕРЕМЕННЫЕ ДЛЯ АИМА
-- =====================================================
local aimbotEnabled = false
local targetPart = "Head"
local fovRadius = 200
local smoothness = 0.3
local aimKey = "RightButton"
local aimMode = "Hold"
local currentTarget = nil
local aimConnection = nil
local fovCircle = nil
local isAiming = false
local aimToggled = false

-- =====================================================
-- ПЕРЕМЕННЫЕ ДЛЯ АНТИАИМА
-- =====================================================
local antiAimEnabled = false
local antiAimMode = "Spin"
local antiAimSpeed = 5
local antiAimConnection = nil
local currentAngle = 0

-- =====================================================
-- ПЕРЕМЕННЫЕ ДЛЯ 3 ЛИЦА
-- =====================================================
local thirdPersonEnabled = false
local originalCameraMode = nil
local originalMaxZoom = nil

-- =====================================================
-- ПЕРЕМЕННЫЕ ДЛЯ NOCLIP
-- =====================================================
_G.nc_cache = _G.nc_cache or {}
local noclipEnabled = false

-- =====================================================
-- ПЕРЕМЕННЫЕ ДЛЯ ПОЛЁТА
-- =====================================================
local flyEnabled = false
local flySpeed = 50
local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil

-- =====================================================
-- ПЕРЕМЕННЫЕ ДЛЯ INFINITE JUMP
-- =====================================================
local infiniteJumpConnection = nil
local InfiniteJumpEnabled = false
local originalJumpPower = 50

-- Функция получения персонажа
local function GetCharacter()
    local char = LocalPlayer.Character
    if not char or not char.Parent then
        char = LocalPlayer.CharacterAdded:Wait()
    end
    return char
end

local function GetHumanoid()
    local char = GetCharacter()
    return char:FindFirstChild("Humanoid")
end

local function GetRootPart()
    local char = GetCharacter()
    return char:FindFirstChild("HumanoidRootPart")
end

-- =====================================================
-- ФУНКЦИЯ 3 ЛИЦА
-- =====================================================
local function EnableThirdPerson()
    if thirdPersonEnabled then return end
    thirdPersonEnabled = true
    Settings.ThirdPerson.Enabled = true
    
    originalCameraMode = LocalPlayer.CameraMode
    originalMaxZoom = LocalPlayer.CameraMaxZoomDistance
    
    LocalPlayer.CameraMaxZoomDistance = Settings.ThirdPerson.Distance or 10
    LocalPlayer.CameraMode = Enum.CameraMode.Classic
end

local function DisableThirdPerson()
    if not thirdPersonEnabled then return end
    thirdPersonEnabled = false
    Settings.ThirdPerson.Enabled = false
    
    LocalPlayer.CameraMaxZoomDistance = originalMaxZoom or 20
    LocalPlayer.CameraMode = originalCameraMode or Enum.CameraMode.LockFirstPerson
end

local function ToggleThirdPerson()
    if thirdPersonEnabled then
        DisableThirdPerson()
        ThirdPersonToggle:Set(false)
    else
        EnableThirdPerson()
        ThirdPersonToggle:Set(true)
    end
end

-- =====================================================
-- ФУНКЦИЯ FOV КРУГА
-- =====================================================
local function CreateFOVCircle()
    if fovCircle then
        fovCircle:Destroy()
        fovCircle = nil
    end
    
    if not Settings.Aimbot.ShowFOV then return end
    if not Settings.Aimbot.Enabled then return end
    
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    fovCircle = Instance.new("ImageLabel")
    fovCircle.Name = "FOVCircle"
    fovCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
    fovCircle.Position = UDim2.new(0.5, -fovRadius, 0.5, -fovRadius)
    fovCircle.BackgroundTransparency = 1
    fovCircle.Image = "rbxassetid://15242488769"
    fovCircle.ImageColor3 = Color3.fromRGB(255, 0, 0)
    fovCircle.ImageTransparency = 0.7
    fovCircle.ZIndex = 999
    fovCircle.Parent = playerGui
end

local function UpdateFOVCircle()
    if fovCircle then
        fovCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
        fovCircle.Position = UDim2.new(0.5, -fovRadius, 0.5, -fovRadius)
        fovCircle.Visible = Settings.Aimbot.ShowFOV and Settings.Aimbot.Enabled
    end
end

local function RemoveFOVCircle()
    if fovCircle then
        fovCircle:Destroy()
        fovCircle = nil
    end
end

-- =====================================================
-- ФУНКЦИЯ АИМА (С TEAM CHECK)
-- =====================================================
local function GetClosestEnemy()
    local char = GetCharacter()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    
    local closestPlayer = nil
    local closestDistance = fovRadius
    
    -- Получаем только врагов
    local enemies = GetEnemies()
    
    for _, player in pairs(enemies) do
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local targetChar = player.Character
            local targetPartObj = targetChar:FindFirstChild(targetPart)
            
            if targetPartObj then
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPartObj.Position)
                if onScreen then
                    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local function AimAtTarget()
    if not Settings.Aimbot.Enabled then return end
    
    local target = GetClosestEnemy()
    if not target then 
        currentTarget = nil
        return 
    end
    
    currentTarget = target
    
    local targetChar = target.Character
    if not targetChar then return end
    
    local targetPartObj = targetChar:FindFirstChild(targetPart)
    if not targetPartObj then return end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local targetPos = targetPartObj.Position
    local currentLook = camera.CFrame.LookVector
    local targetLook = (targetPos - camera.CFrame.Position).Unit
    
    local smoothFactor = Settings.Aimbot.Smoothness or 0.3
    local newLook = currentLook:Lerp(targetLook, smoothFactor)
    
    camera.CFrame = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + newLook)
end

local function StartAim()
    if aimConnection then return end
    isAiming = true
    
    aimConnection = RunService.RenderStepped:Connect(function()
        if not Settings.Aimbot.Enabled then
            isAiming = false
            if aimConnection then
                aimConnection:Disconnect()
                aimConnection = nil
            end
            return
        end
        
        local shouldAim = false
        
        if Settings.Aimbot.AimMode == "Hold" then
            if Settings.Aimbot.Key == "RightButton" then
                shouldAim = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            elseif Settings.Aimbot.Key == "LeftButton" then
                shouldAim = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            elseif Settings.Aimbot.Key == "None" then
                shouldAim = true
            end
        else
            shouldAim = aimToggled
        end
        
        if shouldAim then
            AimAtTarget()
        else
            currentTarget = nil
        end
    end)
end

local function StopAim()
    if aimConnection then
        aimConnection:Disconnect()
        aimConnection = nil
    end
    isAiming = false
    currentTarget = nil
end

local function ToggleAimbot()
    if Settings.Aimbot.Enabled then
        StartAim()
        CreateFOVCircle()
        UpdateFOVCircle()
    else
        StopAim()
        RemoveFOVCircle()
        aimToggled = false
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if Settings.Aimbot.AimMode == "Toggle" then
        if Settings.Aimbot.Key == "RightButton" and input.UserInputType == Enum.UserInputType.MouseButton2 then
            aimToggled = not aimToggled
        elseif Settings.Aimbot.Key == "LeftButton" and input.UserInputType == Enum.UserInputType.MouseButton1 then
            aimToggled = not aimToggled
        end
    end
end)

-- =====================================================
-- ФУНКЦИЯ АНТИАИМА
-- =====================================================
local function EnableAntiAim()
    if antiAimEnabled then return end
    antiAimEnabled = true
    Settings.AntiAim.Enabled = true
    
    if antiAimConnection then
        antiAimConnection:Disconnect()
    end
    
    antiAimConnection = RunService.RenderStepped:Connect(function()
        if not antiAimEnabled then return end
        
        local char = GetCharacter()
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local hum = GetHumanoid()
        if not hum or hum.Health <= 0 then return end
        
        local mode = Settings.AntiAim.Mode or "Spin"
        local speed = Settings.AntiAim.Speed or 5
        
        if mode == "Spin" then
            currentAngle = currentAngle + speed * 0.1
            if currentAngle > 360 then currentAngle = 0 end
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(currentAngle), 0)
            
        elseif mode == "Jitter" then
            local angle = math.sin(tick() * speed) * 45
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(angle), 0)
            
        elseif mode == "Random" then
            if math.random(1, 10) == 1 then
                local randomAngle = math.random(0, 360)
                root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(randomAngle), 0)
            end
        end
    end)
end

local function DisableAntiAim()
    if not antiAimEnabled then return end
    antiAimEnabled = false
    Settings.AntiAim.Enabled = false
    
    if antiAimConnection then
        antiAimConnection:Disconnect()
        antiAimConnection = nil
    end
    
    local char = GetCharacter()
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local hum = GetHumanoid()
        if hum and hum.Health > 0 then
            root.CFrame = CFrame.new(root.Position)
        end
    end
end

local function ToggleAntiAim()
    if antiAimEnabled then
        DisableAntiAim()
        AntiAimToggle:Set(false)
    else
        EnableAntiAim()
        AntiAimToggle:Set(true)
    end
end

-- =====================================================
-- ФУНКЦИЯ СОЗДАНИЯ ESP (ТОЛЬКО НА ВРАГОВ)
-- =====================================================
local function CreateESPForPlayer(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    if not Settings.ESP.Enabled then return end
    
    -- TEAM CHECK - пропускаем союзников
    if Settings.ESP.TeamCheck and not IsEnemy(player) then
        return
    end
    
    local char = player.Character
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChild("Humanoid")
    
    if not head or not hum then return end
    
    -- Удаляем старые объекты
    if ActiveHighlights[player] then
        pcall(function() ActiveHighlights[player]:Destroy() end)
        ActiveHighlights[player] = nil
    end
    if ActiveNameTags[player] then
        pcall(function() ActiveNameTags[player]:Destroy() end)
        ActiveNameTags[player] = nil
    end
    if ActiveHealthBars[player] then
        pcall(function() ActiveHealthBars[player]:Destroy() end)
        ActiveHealthBars[player] = nil
    end
    if ActiveDistanceLabels[player] then
        pcall(function() ActiveDistanceLabels[player]:Destroy() end)
        ActiveDistanceLabels[player] = nil
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_HIGHLIGHT"
    highlight.Adornee = char
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Settings.ESP.Color
    highlight.FillTransparency = Settings.ESP.Transparency
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    highlight.Parent = char
    ActiveHighlights[player] = highlight
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_NameTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.MaxDistance = 1000
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    
    local nameFrame = Instance.new("Frame")
    nameFrame.Size = UDim2.new(1, 0, 1, 0)
    nameFrame.BackgroundTransparency = 1
    nameFrame.Parent = billboard
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = nameFrame
    ActiveNameTags[player] = billboard
    
    if Settings.ESP.ShowHealth then
        local healthFrame = Instance.new("Frame")
        healthFrame.Size = UDim2.new(0.8, 0, 0.2, 0)
        healthFrame.Position = UDim2.new(0.1, 0, 0.55, 0)
        healthFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        healthFrame.BackgroundTransparency = 0.5
        healthFrame.BorderSizePixel = 0
        healthFrame.Parent = nameFrame
        
        local healthBar = Instance.new("Frame")
        healthBar.Name = "HealthBar"
        healthBar.Size = UDim2.new(1, 0, 1, 0)
        healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthBar.BorderSizePixel = 0
        healthBar.Parent = healthFrame
        
        local function updateHealth()
            local currentHum = player.Character and player.Character:FindFirstChild("Humanoid")
            if currentHum then
                local healthPercent = currentHum.Health / currentHum.MaxHealth
                healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
                if healthPercent > 0.5 then
                    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                elseif healthPercent > 0.25 then
                    healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                else
                    healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                end
            end
        end
        
        updateHealth()
        ActiveHealthBars[player] = healthBar
        
        player.CharacterAdded:Connect(function()
            wait(0.1)
            local newHum = player.Character and player.Character:FindFirstChild("Humanoid")
            if newHum then
                newHum.HealthChanged:Connect(function()
                    updateHealth()
                end)
            end
        end)
    end
    
    if Settings.ESP.ShowDistance then
        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, 0, 0.3, 0)
        distLabel.Position = UDim2.new(0, 0, 0.7, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = ""
        distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        distLabel.TextScaled = true
        distLabel.TextSize = 10
        distLabel.Font = Enum.Font.Gotham
        distLabel.TextStrokeTransparency = 0.5
        distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distLabel.Parent = nameFrame
        ActiveDistanceLabels[player] = distLabel
    end
end

local function RemoveAllESP()
    for player, highlight in pairs(ActiveHighlights) do
        pcall(function() highlight:Destroy() end)
    end
    ActiveHighlights = {}
    
    for player, tag in pairs(ActiveNameTags) do
        pcall(function() tag:Destroy() end)
    end
    ActiveNameTags = {}
    
    ActiveHealthBars = {}
    ActiveDistanceLabels = {}
end

local function UpdateAllESP()
    RemoveAllESP()
    if not Settings.ESP.Enabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateESPForPlayer(player)
        end
    end
end

local function UpdateDistances()
    if not Settings.ESP.Enabled then return end
    
    local localChar = GetCharacter()
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    for player, distLabel in pairs(ActiveDistanceLabels) do
        if player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local dist = (localRoot.Position - targetRoot.Position).Magnitude
                distLabel.Text = string.format("%.1fм", dist)
            end
        end
    end
end

-- =====================================================
-- ФУНКЦИИ NOCLIP, FLY, INFINITE JUMP
-- =====================================================
local function EnableNoclip()
    if noclipEnabled then return end
    noclipEnabled = true
    Settings.Noclip.Enabled = true
    
    for _, p in next, game:GetDescendants() do
        if p:IsA('BasePart') then
            if _G.nc_cache[p] == nil and p.CanCollide then
                p.CanCollide = false
                _G.nc_cache[p] = true
            end
        end
    end
    
    local function onDescendantAdded(part)
        if part:IsA('BasePart') then
            if _G.nc_cache[part] == nil and part.CanCollide then
                part.CanCollide = false
                _G.nc_cache[part] = true
            end
        end
    end
    
    game.DescendantAdded:Connect(onDescendantAdded)
    
    local char = GetCharacter()
    char.DescendantAdded:Connect(function(part)
        if part:IsA('BasePart') then
            if _G.nc_cache[part] == nil and part.CanCollide then
                part.CanCollide = false
                _G.nc_cache[part] = true
            end
        end
    end)
end

local function DisableNoclip()
    if not noclipEnabled then return end
    noclipEnabled = false
    Settings.Noclip.Enabled = false
    
    for p, _ in next, _G.nc_cache do
        pcall(function()
            if p and p.Parent then
                p.CanCollide = true
            end
        end)
    end
    _G.nc_cache = {}
end

local function ToggleNoclip()
    if noclipEnabled then
        DisableNoclip()
        NoclipToggle:Set(false)
    else
        EnableNoclip()
        NoclipToggle:Set(true)
    end
end

local function StartFly()
    if flyEnabled then return end
    flyEnabled = true
    Settings.Fly.Enabled = true
    
    local char = GetCharacter()
    local hum = GetHumanoid()
    local root = GetRootPart()
    
    if not hum or not root then
        flyEnabled = false
        return
    end
    
    local animator = char:FindFirstChild("Animate")
    if animator then
        animator.Disabled = true
    end
    
    hum.PlatformStand = true
    
    bodyGyro = Instance.new("BodyGyro", root)
    bodyGyro.P = 9e4
    bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.cframe = root.CFrame
    
    bodyVelocity = Instance.new("BodyVelocity", root)
    bodyVelocity.velocity = Vector3.new(0, 0.1, 0)
    bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
    
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled then
            return
        end
        
        local currentRoot = GetRootPart()
        local currentHum = GetHumanoid()
        
        if not currentRoot or not currentHum then
            return
        end
        
        local camera = workspace.CurrentCamera
        if not camera then return end
        
        local forward = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local up = camera.CFrame.UpVector
        
        forward = Vector3.new(forward.X, 0, forward.Z).Unit
        right = Vector3.new(right.X, 0, right.Z).Unit
        
        local moveVector = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVector = moveVector + forward * flySpeed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVector = moveVector - forward * flySpeed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVector = moveVector - right * flySpeed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVector = moveVector + right * flySpeed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVector = moveVector + up * flySpeed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveVector = moveVector - up * flySpeed
        end
        
        if bodyVelocity then
            bodyVelocity.Velocity = moveVector
        end
        
        if bodyGyro and moveVector.Magnitude > 0.1 then
            local targetCF = CFrame.lookAt(currentRoot.Position, currentRoot.Position + moveVector)
            bodyGyro.cframe = targetCF
        end
        
        currentHum.PlatformStand = true
    end)
end

local function StopFly()
    if not flyEnabled then return end
    flyEnabled = false
    Settings.Fly.Enabled = false
    
    if bodyVelocity then
        pcall(function() bodyVelocity:Destroy() end)
        bodyVelocity = nil
    end
    
    if bodyGyro then
        pcall(function() bodyGyro:Destroy() end)
        bodyGyro = nil
    end
    
    if flyConnection then
        pcall(function() flyConnection:Disconnect() end)
        flyConnection = nil
    end
    
    local hum = GetHumanoid()
    if hum then
        hum.PlatformStand = false
    end
    
    local char = GetCharacter()
    local animator = char:FindFirstChild("Animate")
    if animator then
        animator.Disabled = false
    end
end

local function ToggleFly()
    if flyEnabled then
        StopFly()
        FlyToggle:Set(false)
    else
        StartFly()
        FlyToggle:Set(true)
    end
end

local function EnableInfiniteJump()
    if InfiniteJumpEnabled then return end
    InfiniteJumpEnabled = true
    Settings.InfiniteJump.Enabled = true
    
    local hum = GetHumanoid()
    if hum then
        originalJumpPower = hum.JumpPower or 50
    end
    
    if infiniteJumpConnection then
        infiniteJumpConnection:Disconnect()
    end
    
    infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
        if InfiniteJumpEnabled then
            local char = GetCharacter()
            local hum = char:FindFirstChildOfClass('Humanoid')
            if hum then
                pcall(function()
                    hum:ChangeState("Jumping")
                end)
            end
        end
    end)
end

local function DisableInfiniteJump()
    if not InfiniteJumpEnabled then return end
    InfiniteJumpEnabled = false
    Settings.InfiniteJump.Enabled = false
    
    if infiniteJumpConnection then
        pcall(function() infiniteJumpConnection:Disconnect() end)
        infiniteJumpConnection = nil
    end
    
    local hum = GetHumanoid()
    if hum then
        hum.JumpPower = originalJumpPower or 50
    end
end

-- =====================================================
-- СОЗДАНИЕ ОКНА RAYFIELD
-- =====================================================
local Window = Rayfield:CreateWindow({
    Name = "🔴 CHEAT HUB",
    LoadingTitle = "CHEAT HUB ЗАГРУЖАЕТСЯ...",
    LoadingSubtitle = "by q0wus",
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "CheatHubConfig",
        FileName = "CheatHubSettings"
    },
    KeySystem = false,
    ToggleUIKeybind = "K"
})

-- =====================================================
-- ТАБЫ
-- =====================================================
local MainTab = Window:CreateTab("ГЛАВНАЯ", 4483362458)
local VisualTab = Window:CreateTab("ВИЗУАЛ", 4483362458)
local AimbotTab = Window:CreateTab("АИМБОТ", 4483362458)
local AntiAimTab = Window:CreateTab("АНТИАИМ", 4483362458)
local CameraTab = Window:CreateTab("КАМЕРА", 4483362458)
local MovementTab = Window:CreateTab("ДВИЖЕНИЕ", 4483362458)
local MiscTab = Window:CreateTab("РАЗНОЕ", 4483362458)

-- =====================================================
-- ГЛАВНАЯ
-- =====================================================
MainTab:CreateSection("УПРАВЛЕНИЕ")
MainTab:CreateParagraph({
    Title = "🔴 CHEAT HUB v7.0",
    Content = "F1 - ESP | F2 - Fly | F3 - Noclip | K - Меню"
})

-- =====================================================
-- ВИЗУАЛ
-- =====================================================
VisualTab:CreateSection("ESP WALLHACK + НИКИ")

local ESPToggle = VisualTab:CreateToggle({
    Name = "Включить ESP",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(Value)
        Settings.ESP.Enabled = Value
        if Value then UpdateAllESP() else RemoveAllESP() end
    end
})

VisualTab:CreateSection("НАСТРОЙКИ ESP")

local TeamCheckESP = VisualTab:CreateToggle({
    Name = "Team Check (Только враги)",
    CurrentValue = true,
    Flag = "TeamCheckESP",
    Callback = function(Value)
        Settings.ESP.TeamCheck = Value
        if Settings.ESP.Enabled then UpdateAllESP() end
    end
})

VisualTab:CreateParagraph({
    Title = "👥 Team Check",
    Content = "Включено - ESP видит только врагов\nВыключено - ESP видит всех"
})

VisualTab:CreateSection("ЦВЕТ ESP")
local ESPColorPicker = VisualTab:CreateColorPicker({
    Name = "Цвет подсветки",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(Color)
        Settings.ESP.Color = Color
        if Settings.ESP.Enabled then UpdateAllESP() end
    end
})

VisualTab:CreateSection("ПРОЗРАЧНОСТЬ")
local ESPTransparency = VisualTab:CreateSlider({
    Name = "Прозрачность подсветки",
    Range = {0, 100},
    Increment = 10,
    Suffix = "%",
    CurrentValue = 50,
    Flag = "ESPTransparency",
    Callback = function(Value)
        Settings.ESP.Transparency = Value / 100
        if Settings.ESP.Enabled then UpdateAllESP() end
    end
})

VisualTab:CreateSection("ОТОБРАЖЕНИЕ НАД ГОЛОВОЙ")

local ShowNamesToggle = VisualTab:CreateToggle({
    Name = "Показывать имена",
    CurrentValue = true,
    Flag = "ShowNames",
    Callback = function(Value)
        Settings.ESP.ShowNames = Value
        if Settings.ESP.Enabled then UpdateAllESP() end
    end
})

local ShowHealthToggle = VisualTab:CreateToggle({
    Name = "Показывать здоровье",
    CurrentValue = true,
    Flag = "ShowHealth",
    Callback = function(Value)
        Settings.ESP.ShowHealth = Value
        if Settings.ESP.Enabled then UpdateAllESP() end
    end
})

local ShowDistanceToggle = VisualTab:CreateToggle({
    Name = "Показывать дистанцию",
    CurrentValue = true,
    Flag = "ShowDistance",
    Callback = function(Value)
        Settings.ESP.ShowDistance = Value
        if Settings.ESP.Enabled then UpdateAllESP() end
    end
})

-- =====================================================
-- АИМБОТ
-- =====================================================
AimbotTab:CreateSection("НАСТРОЙКИ АИМА")

local AimbotToggle = AimbotTab:CreateToggle({
    Name = "Включить аимбот",
    CurrentValue = false,
    Flag = "AimbotEnabled",
    Callback = function(Value)
        Settings.Aimbot.Enabled = Value
        ToggleAimbot()
    end
})

AimbotTab:CreateSection("НАСТРОЙКИ АИМА")

local TeamCheckAimbot = AimbotTab:CreateToggle({
    Name = "Team Check (Только враги)",
    CurrentValue = true,
    Flag = "TeamCheckAimbot",
    Callback = function(Value)
        Settings.Aimbot.TeamCheck = Value
    end
})

AimbotTab:CreateParagraph({
    Title = "👥 Team Check",
    Content = "Включено - аим только по врагам\nВыключено - аим по всем"
})

AimbotTab:CreateSection("РЕЖИМ АКТИВАЦИИ")

local AimModeDropdown = AimbotTab:CreateDropdown({
    Name = "Режим работы",
    Options = {"По зажатию (Hold)", "По нажатию (Toggle)"},
    CurrentOption = "По зажатию (Hold)",
    Flag = "AimMode",
    Callback = function(Option)
        if Option == "По зажатию (Hold)" then
            Settings.Aimbot.AimMode = "Hold"
            aimMode = "Hold"
        else
            Settings.Aimbot.AimMode = "Toggle"
            aimMode = "Toggle"
        end
    end
})

AimbotTab:CreateSection("ЦЕЛЬ")

local TargetDropdown = AimbotTab:CreateDropdown({
    Name = "Куда целиться",
    Options = {"Голова", "Тело"},
    CurrentOption = "Голова",
    Flag = "AimbotTarget",
    Callback = function(Option)
        if Option == "Голова" then
            Settings.Aimbot.Target = "Head"
            targetPart = "Head"
        else
            Settings.Aimbot.Target = "Torso"
            targetPart = "Torso"
        end
    end
})

AimbotTab:CreateSection("РАДИУС FOV")

local FOVSlider = AimbotTab:CreateSlider({
    Name = "Радиус FOV",
    Range = {50, 500},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 200,
    Flag = "AimbotFOV",
    Callback = function(Value)
        Settings.Aimbot.FOV = Value
        fovRadius = Value
        UpdateFOVCircle()
    end
})

AimbotTab:CreateSection("СГЛАЖИВАНИЕ")

local SmoothnessSlider = AimbotTab:CreateSlider({
    Name = "Сглаживание",
    Range = {1, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 30,
    Flag = "AimbotSmoothness",
    Callback = function(Value)
        Settings.Aimbot.Smoothness = Value / 100
        smoothness = Value / 100
    end
})

AimbotTab:CreateSection("ОТОБРАЖЕНИЕ FOV")

local ShowFOVToggle = AimbotTab:CreateToggle({
    Name = "Показывать FOV круг",
    CurrentValue = true,
    Flag = "ShowFOV",
    Callback = function(Value)
        Settings.Aimbot.ShowFOV = Value
        if Value then
            CreateFOVCircle()
            UpdateFOVCircle()
        else
            RemoveFOVCircle()
        end
    end
})

-- =====================================================
-- АНТИАИМ
-- =====================================================
AntiAimTab:CreateSection("НАСТРОЙКИ АНТИАИМА")

local AntiAimToggle = AntiAimTab:CreateToggle({
    Name = "Включить антиаим",
    CurrentValue = false,
    Flag = "AntiAimEnabled",
    Callback = function(Value)
        Settings.AntiAim.Enabled = Value
        if Value then
            EnableAntiAim()
        else
            DisableAntiAim()
        end
    end
})

AntiAimTab:CreateSection("РЕЖИМ КРУЧЕНИЯ")

local AntiAimModeDropdown = AntiAimTab:CreateDropdown({
    Name = "Режим антиаима",
    Options = {"Spin (Вращение)", "Jitter (Дёрганье)", "Random (Рандом)"},
    CurrentOption = "Spin (Вращение)",
    Flag = "AntiAimMode",
    Callback = function(Option)
        if Option == "Spin (Вращение)" then
            Settings.AntiAim.Mode = "Spin"
            antiAimMode = "Spin"
        elseif Option == "Jitter (Дёрганье)" then
            Settings.AntiAim.Mode = "Jitter"
            antiAimMode = "Jitter"
        else
            Settings.AntiAim.Mode = "Random"
            antiAimMode = "Random"
        end
    end
})

AntiAimTab:CreateSection("СКОРОСТЬ")

local AntiAimSpeedSlider = AntiAimTab:CreateSlider({
    Name = "Скорость вращения",
    Range = {1, 20},
    Increment = 1,
    Suffix = "",
    CurrentValue = 5,
    Flag = "AntiAimSpeed",
    Callback = function(Value)
        Settings.AntiAim.Speed = Value
        antiAimSpeed = Value
    end
})

-- =====================================================
-- КАМЕРА
-- =====================================================
CameraTab:CreateSection("РЕЖИМ КАМЕРЫ")

local ThirdPersonToggle = CameraTab:CreateToggle({
    Name = "Включить 3 лицо",
    CurrentValue = false,
    Flag = "ThirdPerson",
    Callback = function(Value)
        Settings.ThirdPerson.Enabled = Value
        if Value then
            EnableThirdPerson()
        else
            DisableThirdPerson()
        end
    end
})

CameraTab:CreateSection("НАСТРОЙКИ 3 ЛИЦА")

local ThirdPersonDistance = CameraTab:CreateSlider({
    Name = "Дистанция камеры",
    Range = {3, 20},
    Increment = 0.5,
    Suffix = "",
    CurrentValue = 10,
    Flag = "ThirdPersonDistance",
    Callback = function(Value)
        Settings.ThirdPerson.Distance = Value
        if thirdPersonEnabled then
            LocalPlayer.CameraMaxZoomDistance = Value
        end
    end
})

-- =====================================================
-- ДВИЖЕНИЕ
-- =====================================================
MovementTab:CreateSection("ПОЛЁТ (FLY)")

local FlyToggle = MovementTab:CreateToggle({
    Name = "Включить полёт",
    CurrentValue = false,
    Flag = "FlyEnabled",
    Callback = function(Value)
        if Value then
            flySpeed = Settings.Fly.Speed
            StartFly()
        else
            StopFly()
        end
    end
})

local FlySpeed = MovementTab:CreateSlider({
    Name = "Скорость полёта",
    Range = {10, 200},
    Increment = 5,
    Suffix = "",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(Value)
        Settings.Fly.Speed = Value
        flySpeed = Value
    end
})

MovementTab:CreateParagraph({
    Title = "Управление полётом",
    Content = "WASD - Движение\nSpace - Вверх\nShift - Вниз"
})

MovementTab:CreateSection("НОКЛИП (NOCLIP)")

local NoclipToggle = MovementTab:CreateToggle({
    Name = "Включить ноклип",
    CurrentValue = false,
    Flag = "NoclipEnabled",
    Callback = function(Value)
        if Value then
            EnableNoclip()
        else
            DisableNoclip()
        end
    end
})

MovementTab:CreateSection("БЕСКОНЕЧНЫЕ ПРЫЖКИ")

local InfiniteJumpToggle = MovementTab:CreateToggle({
    Name = "Включить бесконечные прыжки",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(Value)
        if Value then
            EnableInfiniteJump()
        else
            DisableInfiniteJump()
        end
    end
})

MovementTab:CreateSection("СКОРОСТЬ ХОДЬБЫ")

local SpeedToggle = MovementTab:CreateToggle({
    Name = "Изменить скорость",
    CurrentValue = false,
    Flag = "SpeedEnabled",
    Callback = function(Value)
        Settings.Speed.Enabled = Value
        local hum = GetHumanoid()
        if hum then
            hum.WalkSpeed = Value and Settings.Speed.Value or 16
        end
    end
})

local SpeedSlider = MovementTab:CreateSlider({
    Name = "Скорость ходьбы",
    Range = {16, 200},
    Increment = 1,
    Suffix = "",
    CurrentValue = 16,
    Flag = "SpeedValue",
    Callback = function(Value)
        Settings.Speed.Value = Value
        if Settings.Speed.Enabled then
            local hum = GetHumanoid()
            if hum then hum.WalkSpeed = Value end
        end
    end
})

-- =====================================================
-- РАЗНОЕ
-- =====================================================
MiscTab:CreateSection("ГОРЯЧИЕ КЛАВИШИ")
MiscTab:CreateParagraph({
    Title = "⌨️ Клавиши",
    Content = "F1 - ESP\nF2 - FLY\nF3 - NOCLIP\nK - Скрыть меню"
})

MiscTab:CreateSection("УТИЛИТЫ")

MiscTab:CreateButton({
    Name = "🔴 Сбросить всё",
    Callback = function()
        if Settings.ESP.Enabled then
            Settings.ESP.Enabled = false
            RemoveAllESP()
            ESPToggle:Set(false)
        end
        if Settings.Aimbot.Enabled then
            Settings.Aimbot.Enabled = false
            ToggleAimbot()
            AimbotToggle:Set(false)
        end
        if Settings.AntiAim.Enabled then
            Settings.AntiAim.Enabled = false
            DisableAntiAim()
            AntiAimToggle:Set(false)
        end
        if Settings.ThirdPerson.Enabled then
            Settings.ThirdPerson.Enabled = false
            DisableThirdPerson()
            ThirdPersonToggle:Set(false)
        end
        if flyEnabled then
            StopFly()
            FlyToggle:Set(false)
        end
        if noclipEnabled then
            DisableNoclip()
            NoclipToggle:Set(false)
        end
        if InfiniteJumpEnabled then
            DisableInfiniteJump()
            InfiniteJumpToggle:Set(false)
        end
        if Settings.Speed.Enabled then
            Settings.Speed.Enabled = false
            local hum = GetHumanoid()
            if hum then hum.WalkSpeed = 16 end
            SpeedToggle:Set(false)
        end
        Rayfield:Notify({Title = "✅ Сброс", Content = "Всё выключено нахуй!", Duration = 3})
    end
})

MiscTab:CreateButton({
    Name = "💀 Респавн",
    Callback = function()
        local char = GetCharacter()
        if char then char:BreakJoints() end
        Rayfield:Notify({Title = "💀 Респавн", Content = "Ты сдох, мудак!", Duration = 2})
    end
})

-- =====================================================
-- ОБРАБОТЧИКИ ДЛЯ ESP
-- =====================================================
local function OnPlayerAdded(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function()
        wait(0.2)
        if Settings.ESP.Enabled and player.Character then
            CreateESPForPlayer(player)
        end
    end)
    if player.Character then
        wait(0.2)
        if Settings.ESP.Enabled then CreateESPForPlayer(player) end
    end
end

for _, player in pairs(Players:GetPlayers()) do
    OnPlayerAdded(player)
end
Players.PlayerAdded:Connect(OnPlayerAdded)

-- Обновление ESP
RunService.RenderStepped:Connect(function()
    if not Settings.ESP.Enabled then
        for player, highlight in pairs(ActiveHighlights) do
            if highlight and highlight.Parent then
                pcall(function() highlight:Destroy() end)
            end
        end
        ActiveHighlights = {}
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- Проверяем, есть ли уже ESP и нужно ли его обновить
            local hasESP = ActiveHighlights[player] and ActiveHighlights[player].Parent ~= nil
            local shouldHaveESP = Settings.ESP.TeamCheck and IsEnemy(player) or not Settings.ESP.TeamCheck
            
            if shouldHaveESP and not hasESP then
                CreateESPForPlayer(player)
            elseif not shouldHaveESP and hasESP then
                -- Удаляем ESP если это союзник
                if ActiveHighlights[player] then
                    pcall(function() ActiveHighlights[player]:Destroy() end)
                    ActiveHighlights[player] = nil
                end
                if ActiveNameTags[player] then
                    pcall(function() ActiveNameTags[player]:Destroy() end)
                    ActiveNameTags[player] = nil
                end
                if ActiveHealthBars[player] then
                    ActiveHealthBars[player] = nil
                end
                if ActiveDistanceLabels[player] then
                    ActiveDistanceLabels[player] = nil
                end
            end
        end
    end
    
    UpdateDistances()
end)

-- =====================================================
-- ПЕРЕСОЗДАНИЕ ПЕРСОНАЖА
-- =====================================================
LocalPlayer.CharacterAdded:Connect(function()
    wait(0.5)
    
    local hum = GetHumanoid()
    if hum then
        hum.WalkSpeed = Settings.Speed.Enabled and Settings.Speed.Value or 16
    end
    
    if flyEnabled then
        StopFly()
        wait(0.3)
        StartFly()
    end
    
    if noclipEnabled then
        print("🔴 NOCLIP ОСТАЕТСЯ ВКЛЮЧЕННЫМ")
    end
    
    if InfiniteJumpEnabled then
        DisableInfiniteJump()
        wait(0.3)
        EnableInfiniteJump()
    end
    
    if antiAimEnabled then
        DisableAntiAim()
        wait(0.3)
        EnableAntiAim()
    end
    
    if thirdPersonEnabled then
        DisableThirdPerson()
        wait(0.3)
        EnableThirdPerson()
    end
end)

-- =====================================================
-- ИЗМЕНЕНИЕ ДИСТАНЦИИ КОЛЕСИКОМ МЫШИ
-- =====================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        if thirdPersonEnabled then
            local delta = input.Position.Z
            local newDist = math.clamp(Settings.ThirdPerson.Distance - delta * 0.5, 3, 20)
            Settings.ThirdPerson.Distance = newDist
            LocalPlayer.CameraMaxZoomDistance = newDist
            pcall(function()
                ThirdPersonDistance:Set(newDist)
            end)
        end
    end
end)

-- =====================================================
-- ГОРЯЧИЕ КЛАВИШИ
-- =====================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        Settings.ESP.Enabled = not Settings.ESP.Enabled
        ESPToggle:Set(Settings.ESP.Enabled)
        if Settings.ESP.Enabled then UpdateAllESP() else RemoveAllESP() end
    end
    
    if input.KeyCode == Enum.KeyCode.F2 then
        ToggleFly()
    end
    
    if input.KeyCode == Enum.KeyCode.F3 then
        ToggleNoclip()
    end
end)

-- =====================================================
-- ПРИВЕТСТВИЕ
-- =====================================================
Rayfield:Notify({
    Title = "🔴 CHEAT HUB v7.0",
    Content = "Загружен с Team Check нахуй! Жми K для меню",
    Duration = 5,
    Image = 4483362458
})

print("═══════════════════════════════════════════")
print("🔴 CHEAT HUB v7.0 ЗАГРУЖЕН!")
print("═══════════════════════════════════════════")
print("F1 - ESP WALLHACK (ТОЛЬКО ВРАГИ!)")
print("F2 - FLY MODE")
print("F3 - NOCLIP")
print("K - Скрыть/Показать меню")
print("═══════════════════════════════════════════")
