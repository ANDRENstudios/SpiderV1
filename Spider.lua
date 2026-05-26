-- Сервисы
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Переменные игрока
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Обновление персонажа
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    applySettings()
    if Settings.NoClip then
        enableNoClip()
    end
end)

-- Настройки
local Settings = {
    WalkSpeed = 16,
    JumpPower = 50,
    Gravity = 196.2,
    HipHeight = 2,
    FOV = 70,
    NoClip = false,
    FlySpeed = 50,
    FlyEnabled = false,
    GodSpider = false,
    ESP = false,
    GESP = false,
    InfiniteJump = false
}

-- Предметы для отслеживания
local TrackedItems = {
    "Battery", "Blue Key", "Bug Spray", "C4", "Crowbar",
    "Green Key", "Orange Key", "Purple Key",
    "Red Key", "Wrench", "Yellow Key"
}

-- Настройки God Spider
local GodSpiderConnection
local ESPCache = {}
local GESPCache = {}
local NoClipConnection

-- Применение настроек
function applySettings()
    if Humanoid then
        Humanoid.WalkSpeed = Settings.WalkSpeed
        Humanoid.JumpPower = Settings.JumpPower
        Humanoid.HipHeight = Settings.HipHeight
    end
    if Workspace.Gravity then
        Workspace.Gravity = Settings.Gravity
    end
end

-- Система уведомлений
local Notifications = {}
local ScreenGui

local function CreateNotification(title, message, duration, color)
    if not ScreenGui then return end
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 280, 0, 55)
    notif.Position = UDim2.new(1, 10, 0, #Notifications * 60 + 10)
    notif.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    notif.BorderSizePixel = 0
    notif.ZIndex = 999
    notif.Parent = ScreenGui
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 8)
    NotifCorner.Parent = notif
    
    local ColorBar = Instance.new("Frame")
    ColorBar.Size = UDim2.new(0, 3, 1, 0)
    ColorBar.BackgroundColor3 = color or Color3.fromRGB(200, 0, 0)
    ColorBar.BorderSizePixel = 0
    ColorBar.ZIndex = 999
    ColorBar.Parent = notif
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 0, 20)
    TitleLabel.Position = UDim2.new(0, 12, 0, 6)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 13
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 999
    TitleLabel.Parent = notif
    
    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Size = UDim2.new(1, -20, 0, 18)
    MessageLabel.Position = UDim2.new(0, 12, 0, 28)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.Text = message
    MessageLabel.TextColor3 = Color3.fromRGB(160, 160, 175)
    MessageLabel.TextSize = 11
    MessageLabel.Font = Enum.Font.GothamMedium
    MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
    MessageLabel.ZIndex = 999
    MessageLabel.Parent = notif
    
    table.insert(Notifications, notif)
    
    TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -290, 0, notif.Position.Y.Offset)
    }):Play()
    
    spawn(function()
        wait(duration or 3)
        if notif and notif.Parent then
            TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 10, 0, notif.Position.Y.Offset)
            }):Play()
            wait(0.3)
            if notif and notif.Parent then
                notif:Destroy()
                for i, n in ipairs(Notifications) do
                    if n == notif then
                        table.remove(Notifications, i)
                        break
                    end
                end
            end
            for i, n in ipairs(Notifications) do
                if n and n.Parent then
                    TweenService:Create(n, TweenInfo.new(0.2), {
                        Position = UDim2.new(1, -290, 0, (i-1) * 60 + 10)
                    }):Play()
                end
            end
        end
    end)
end

-- Fly
local FlyConnection
local function startFly()
    if FlyConnection then FlyConnection:Disconnect() end
    FlyConnection = RunService.Heartbeat:Connect(function()
        if Settings.FlyEnabled and Character and HumanoidRootPart then
            Humanoid.PlatformStand = true
            local direction = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + Workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - Workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - Workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + Workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction = direction - Vector3.new(0, 1, 0) end
            HumanoidRootPart.Velocity = direction * Settings.FlySpeed
        end
    end)
end

local function stopFly()
    if FlyConnection then FlyConnection:Disconnect() end
    if Humanoid then Humanoid.PlatformStand = false end
end

-- NoClip (исправленный - без проваливания)
local function enableNoClip()
    if NoClipConnection then NoClipConnection:Disconnect() end
    
    NoClipConnection = RunService.Stepped:Connect(function()
        if Settings.NoClip and Character then
            -- Отключаем коллизию для всех частей персонажа
            for _, part in ipairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            -- Держим персонажа на текущей высоте если он не летает
            if not Settings.FlyEnabled and Humanoid and HumanoidRootPart then
                -- Сохраняем позицию Y чтобы не провалиться
                local currentY = HumanoidRootPart.Position.Y
                -- Если персонаж начал падать, возвращаем на место
                if HumanoidRootPart.Velocity.Y < -50 then
                    HumanoidRootPart.Velocity = Vector3.new(HumanoidRootPart.Velocity.X, 0, HumanoidRootPart.Velocity.Z)
                end
            end
        end
    end)
end

local function disableNoClip()
    if NoClipConnection then 
        NoClipConnection:Disconnect() 
        NoClipConnection = nil
    end
    if Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Функция поиска предметов из списка на карте
local function FindAllTrackedItems()
    local foundItems = {}
    local foundTypes = {}
    
    for _, v in ipairs(Workspace:GetDescendants()) do
        if (v:IsA("BasePart") or v:IsA("Model") or v:IsA("Tool")) then
            local nameLower = v.Name:lower()
            for _, itemName in ipairs(TrackedItems) do
                if not foundTypes[itemName] and nameLower:find(itemName:lower()) then
                    local part = v:IsA("Model") and (v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")) or v
                    if part and part:IsA("BasePart") then
                        table.insert(foundItems, {Item = v, Part = part, Name = itemName})
                        foundTypes[itemName] = true
                        break
                    end
                end
            end
        end
    end
    return foundItems
end

-- God Spider - телепорт к рандомному предмету из списка
local function TeleportToRandomItem()
    local items = FindAllTrackedItems()
    if #items > 0 then
        local randomItem = items[math.random(1, #items)]
        if Character and HumanoidRootPart then
            HumanoidRootPart.CFrame = randomItem.Part.CFrame * CFrame.new(0, 5, 0)
            CreateNotification("God Spider", "Teleported to " .. randomItem.Name, 2, Color3.fromRGB(255, 140, 0))
        end
    else
        CreateNotification("Warning", "No items found on map", 2, Color3.fromRGB(255, 0, 0))
    end
end

local function StartGodSpider()
    if GodSpiderConnection then GodSpiderConnection:Disconnect() end
    if Humanoid then
        local lastHealth = Humanoid.Health
        GodSpiderConnection = Humanoid.HealthChanged:Connect(function(health)
            if health < lastHealth and Settings.GodSpider then
                TeleportToRandomItem()
                if Humanoid then
                    Humanoid.Health = Humanoid.MaxHealth
                end
            end
            lastHealth = health
        end)
    end
end

-- === ESP ЧЕРЕЗ HIGHLIGHT И BILLBOARD GUI ===
local function createPlayerESP(player)
    local function setupESP(character)
        if not character then return end
        wait(0.3)
        
        local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
        if not rootPart then return end
        
        if ESPCache[player] then
            local old = ESPCache[player]
            if old.Highlight then old.Highlight:Destroy() end
            if old.Billboard then old.Billboard:Destroy() end
            if old.Tracer then old.Tracer:Destroy() end
        end
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = Color3.fromRGB(255, 30, 30)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character
        
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 5000
        billboard.Parent = character
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BackgroundTransparency = 0.5
        frame.BorderSizePixel = 0
        frame.Parent = billboard
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0, 25)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Parent = frame
        
        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, 0, 0, 25)
        distLabel.Position = UDim2.new(0, 0, 0, 25)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "0 studs"
        distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        distLabel.TextSize = 12
        distLabel.Font = Enum.Font.GothamMedium
        distLabel.TextStrokeTransparency = 0
        distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distLabel.Parent = frame
        
        local attachment0 = Instance.new("Attachment")
        attachment0.Name = "ESP_Attach0"
        attachment0.Parent = rootPart
        
        local attachment1 = Instance.new("Attachment")
        attachment1.Name = "ESP_Attach1"
        attachment1.Parent = rootPart
        
        local beam = Instance.new("Beam")
        beam.Name = "ESP_Beam"
        beam.Attachment0 = attachment0
        beam.Attachment1 = attachment1
        beam.Color = ColorSequence.new(Color3.fromRGB(255, 30, 30))
        beam.Width0 = 0.2
        beam.Width1 = 0.2
        beam.Transparency = NumberSequence.new(0.3)
        beam.Parent = attachment0
        
        ESPCache[player] = {
            Highlight = highlight,
            Billboard = billboard,
            Beam = beam,
            Attach0 = attachment0,
            Attach1 = attachment1,
            DistLabel = distLabel,
            RootPart = rootPart
        }
    end
    
    if player.Character then
        setupESP(player.Character)
    end
    
    player.CharacterAdded:Connect(function(char)
        if Settings.ESP then
            setupESP(char)
        end
    end)
end

local function removePlayerESP(player)
    if ESPCache[player] then
        local data = ESPCache[player]
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
        if data.Beam then data.Beam:Destroy() end
        if data.Attach0 then data.Attach0:Destroy() end
        if data.Attach1 then data.Attach1:Destroy() end
        ESPCache[player] = nil
    end
end

local function updateESPData()
    if not Settings.ESP then return end
    if not Character or not HumanoidRootPart then return end
    
    for player, data in pairs(ESPCache) do
        if data.RootPart and data.RootPart.Parent then
            local dist = (data.RootPart.Position - HumanoidRootPart.Position).Magnitude
            if data.DistLabel then
                data.DistLabel.Text = math.floor(dist) .. " studs"
            end
            if data.Attach1 and HumanoidRootPart then
                data.Attach1.WorldPosition = HumanoidRootPart.Position
            end
        end
    end
end

RunService.RenderStepped:Connect(updateESPData)

local function StartESP()
    for player, _ in pairs(ESPCache) do
        removePlayerESP(player)
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createPlayerESP(player)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        if Settings.ESP then
            createPlayerESP(player)
        end
    end)
end

local function StopESP()
    for player, _ in pairs(ESPCache) do
        removePlayerESP(player)
    end
end

-- Item ESP (GESP)
local function createItemESP(item, itemName)
    if not item then return end
    
    local part = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) or item
    if not part or not part:IsA("BasePart") then return end
    
    if GESPCache[item] then
        local old = GESPCache[item]
        if old.Highlight then old.Highlight:Destroy() end
        if old.Billboard then old.Billboard:Destroy() end
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "GESP_Highlight"
    highlight.FillColor = Color3.fromRGB(255, 200, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.4
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = part
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GESP_Billboard"
    billboard.Size = UDim2.new(0, 150, 0, 25)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 5000
    billboard.Parent = part
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = itemName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = frame
    
    GESPCache[item] = {
        Highlight = highlight,
        Billboard = billboard
    }
end

local function removeItemESP(item)
    if GESPCache[item] then
        local data = GESPCache[item]
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
        GESPCache[item] = nil
    end
end

local function StartGESP()
    for item, _ in pairs(GESPCache) do
        removeItemESP(item)
    end
    
    local foundTypes = {}
    
    for _, v in ipairs(Workspace:GetDescendants()) do
        if (v:IsA("BasePart") or v:IsA("Model") or v:IsA("Tool")) and v.Parent ~= Character then
            local nameLower = v.Name:lower()
            for _, itemName in ipairs(TrackedItems) do
                if not foundTypes[itemName] and nameLower:find(itemName:lower()) then
                    createItemESP(v, itemName)
                    foundTypes[itemName] = true
                    break
                end
            end
        end
    end
end

local function StopGESP()
    for item, _ in pairs(GESPCache) do
        removeItemESP(item)
    end
end

-- Создание GUI
ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VRSS_Spider_Menu"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- === СВОРАЧИВАЕМЫЙ КРУГ ===
local CollapseButton = Instance.new("TextButton")
CollapseButton.Size = UDim2.new(0, 45, 0, 45)
CollapseButton.Position = UDim2.new(0.9, 0, 0.1, 0)
CollapseButton.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
CollapseButton.BackgroundTransparency = 0.1
CollapseButton.Text = ""
CollapseButton.BorderSizePixel = 0
CollapseButton.Active = true
CollapseButton.Draggable = true
CollapseButton.ZIndex = 200
CollapseButton.Parent = ScreenGui

local CollapseCorner = Instance.new("UICorner")
CollapseCorner.CornerRadius = UDim.new(1, 0)
CollapseCorner.Parent = CollapseButton

local CollapseStroke = Instance.new("UIStroke")
CollapseStroke.Color = Color3.fromRGB(180, 0, 0)
CollapseStroke.Thickness = 2
CollapseStroke.Transparency = 0.3
CollapseStroke.Parent = CollapseButton

local VText = Instance.new("TextLabel")
VText.Size = UDim2.new(1, 0, 1, 0)
VText.BackgroundTransparency = 1
VText.Text = "V"
VText.TextColor3 = Color3.fromRGB(200, 30, 30)
VText.TextSize = 26
VText.Font = Enum.Font.GothamBlack
VText.ZIndex = 201
VText.Parent = CollapseButton

-- === ГЛАВНОЕ МЕНЮ ===
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 720, 0, 500)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false
MainFrame.ZIndex = 100
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(60, 0, 0)
MainStroke.Thickness = 1
MainStroke.Transparency = 0.5
MainStroke.Parent = MainFrame

-- Заголовок
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundTransparency = 1
TitleBar.ZIndex = 100
TitleBar.Parent = MainFrame

local TitleLine = Instance.new("Frame")
TitleLine.Size = UDim2.new(1, -20, 0, 1)
TitleLine.Position = UDim2.new(0, 10, 0, 49)
TitleLine.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
TitleLine.BorderSizePixel = 0
TitleLine.ZIndex = 100
TitleLine.Parent = TitleBar

local LogoFrame = Instance.new("Frame")
LogoFrame.Size = UDim2.new(0, 30, 0, 30)
LogoFrame.Position = UDim2.new(0, 12, 0.5, -15)
LogoFrame.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
LogoFrame.BorderSizePixel = 0
LogoFrame.ZIndex = 100
LogoFrame.Parent = TitleBar

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 6)
LogoCorner.Parent = LogoFrame

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "V"
LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoText.TextSize = 18
LogoText.Font = Enum.Font.GothamBlack
LogoText.ZIndex = 100
LogoText.Parent = LogoFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 50, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "VRSS | Spider"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBlack
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 100
Title.Parent = TitleBar

local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(0, 60, 0, 18)
Version.Position = UDim2.new(0, 157, 1, -22)
Version.BackgroundTransparency = 1
Version.Text = "v1.0.1"
Version.TextColor3 = Color3.fromRGB(140, 140, 155)
Version.TextSize = 10
Version.Font = Enum.Font.GothamMedium
Version.TextXAlignment = Enum.TextXAlignment.Left
Version.ZIndex = 100
Version.Parent = TitleBar

local StatusBadge = Instance.new("Frame")
StatusBadge.Size = UDim2.new(0, 75, 0, 22)
StatusBadge.Position = UDim2.new(1, -110, 0.5, -11)
StatusBadge.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
StatusBadge.BorderSizePixel = 0
StatusBadge.ZIndex = 100
StatusBadge.Parent = TitleBar

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = StatusBadge

local StatusStroke = Instance.new("UIStroke")
StatusStroke.Color = Color3.fromRGB(0, 200, 0)
StatusStroke.Thickness = 1
StatusStroke.Parent = StatusBadge

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 6, 0, 6)
StatusDot.Position = UDim2.new(0, 8, 0.5, -3)
StatusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 100
StatusDot.Parent = StatusBadge

local StatusDotCorner = Instance.new("UICorner")
StatusDotCorner.CornerRadius = UDim.new(1, 0)
StatusDotCorner.Parent = StatusDot

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(0, 50, 1, 0)
StatusText.Position = UDim2.new(0, 18, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "ACTIVE"
StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusText.TextSize = 10
StatusText.Font = Enum.Font.GothamBold
StatusText.ZIndex = 100
StatusText.Parent = StatusBadge

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.Position = UDim2.new(1, -34, 0, 13)
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseButton.TextSize = 12
CloseButton.Font = Enum.Font.GothamBold
CloseButton.BorderSizePixel = 0
CloseButton.ZIndex = 100
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 40, 40)}):Play()
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 48)}):Play()
end)

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    CollapseButton.Visible = true
end)

-- Контейнер вкладок
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 0, 38)
TabContainer.Position = UDim2.new(0, 10, 0, 58)
TabContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
TabContainer.BorderSizePixel = 0
TabContainer.ZIndex = 100
TabContainer.Parent = MainFrame

local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 8)
TabCorner.Parent = TabContainer

local TabStroke = Instance.new("UIStroke")
TabStroke.Color = Color3.fromRGB(40, 0, 0)
TabStroke.Thickness = 1
TabStroke.Transparency = 0.5
TabStroke.Parent = TabContainer

-- Контейнер контента
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -20, 1, -105)
ContentContainer.Position = UDim2.new(0, 10, 0, 102)
ContentContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
ContentContainer.BorderSizePixel = 0
ContentContainer.ZIndex = 100
ContentContainer.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = ContentContainer

local ContentStroke = Instance.new("UIStroke")
ContentStroke.Color = Color3.fromRGB(40, 0, 0)
ContentStroke.Thickness = 1
ContentStroke.Transparency = 0.5
ContentStroke.Parent = ContentContainer

-- Функция создания вкладки
local Tabs = {}
local TabButtons = {}
local function createTab()
    local TabFrame = Instance.new("Frame")
    TabFrame.Size = UDim2.new(1, 0, 1, 0)
    TabFrame.BackgroundTransparency = 1
    TabFrame.Visible = false
    TabFrame.ZIndex = 100
    TabFrame.Parent = ContentContainer
    
    local LeftPanel = Instance.new("Frame")
    LeftPanel.Size = UDim2.new(0, 310, 1, -10)
    LeftPanel.Position = UDim2.new(0, 5, 0, 5)
    LeftPanel.BackgroundTransparency = 1
    LeftPanel.ZIndex = 100
    LeftPanel.Parent = TabFrame
    
    local RightPanel = Instance.new("Frame")
    RightPanel.Size = UDim2.new(1, -325, 1, -10)
    RightPanel.Position = UDim2.new(0, 320, 0, 5)
    RightPanel.BackgroundTransparency = 1
    RightPanel.ZIndex = 100
    RightPanel.Parent = TabFrame
    
    local LeftScroll = Instance.new("ScrollingFrame")
    LeftScroll.Size = UDim2.new(1, 0, 1, 0)
    LeftScroll.BackgroundTransparency = 1
    LeftScroll.ScrollBarThickness = 2
    LeftScroll.ScrollBarImageColor3 = Color3.fromRGB(180, 0, 0)
    LeftScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    LeftScroll.ZIndex = 100
    LeftScroll.Parent = LeftPanel
    
    local LeftList = Instance.new("UIListLayout")
    LeftList.Padding = UDim.new(0, 6)
    LeftList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    LeftList.SortOrder = Enum.SortOrder.LayoutOrder
    LeftList.Parent = LeftScroll
    
    local RightScroll = Instance.new("ScrollingFrame")
    RightScroll.Size = UDim2.new(1, 0, 1, 0)
    RightScroll.BackgroundTransparency = 1
    RightScroll.ScrollBarThickness = 2
    RightScroll.ScrollBarImageColor3 = Color3.fromRGB(180, 0, 0)
    RightScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    RightScroll.ZIndex = 100
    RightScroll.Parent = RightPanel
    
    local RightList = Instance.new("UIListLayout")
    RightList.Padding = UDim.new(0, 6)
    RightList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    RightList.SortOrder = Enum.SortOrder.LayoutOrder
    RightList.Parent = RightScroll
    
    table.insert(Tabs, {
        Frame = TabFrame,
        LeftScroll = LeftScroll,
        RightScroll = RightScroll,
        LeftList = LeftList,
        RightList = RightList
    })
    
    return LeftScroll, RightScroll
end

-- Функция создания кнопки вкладки
local function createTabButton(name, tabFrame)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 100, 1, -4)
    Button.Position = UDim2.new(0, 0, 0, 2)
    Button.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    Button.Text = name
    Button.TextColor3 = Color3.fromRGB(170, 170, 185)
    Button.TextSize = 12
    Button.Font = Enum.Font.GothamBold
    Button.BorderSizePixel = 0
    Button.ZIndex = 100
    Button.Parent = TabContainer
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Button
    
    Button.MouseEnter:Connect(function()
        if Button.BackgroundColor3 ~= Color3.fromRGB(180, 0, 0) then
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play()
        end
    end)
    
    Button.MouseLeave:Connect(function()
        if Button.BackgroundColor3 ~= Color3.fromRGB(180, 0, 0) then
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 38)}):Play()
        end
    end)
    
    Button.MouseButton1Click:Connect(function()
        for _, tab in ipairs(Tabs) do
            tab.Frame.Visible = false
        end
        tabFrame.Frame.Visible = true
        for _, btn in ipairs(TabButtons) do
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(30, 30, 38),
                TextColor3 = Color3.fromRGB(170, 170, 185)
            }):Play()
        end
        TweenService:Create(Button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(180, 0, 0),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    
    table.insert(TabButtons, Button)
    return Button
end

-- Функция создания слайдера
local function createSlider(parent, name, min, max, default, suffix, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 70)
    Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    Frame.BorderSizePixel = 0
    Frame.ZIndex = 100
    Frame.Parent = parent
    
    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius = UDim.new(0, 8)
    FrameCorner.Parent = Frame
    
    local FrameStroke = Instance.new("UIStroke")
    FrameStroke.Color = Color3.fromRGB(35, 35, 45)
    FrameStroke.Thickness = 1
    FrameStroke.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -16, 0, 18)
    Label.Position = UDim2.new(0, 8, 0, 8)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(190, 190, 200)
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 100
    Label.Parent = Frame
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 70, 0, 18)
    ValueLabel.Position = UDim2.new(1, -78, 0, 8)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(default) .. " " .. suffix
    ValueLabel.TextColor3 = Color3.fromRGB(200, 60, 60)
    ValueLabel.TextSize = 11
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.ZIndex = 100
    ValueLabel.Parent = Frame
    
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, -16, 0, 4)
    SliderFrame.Position = UDim2.new(0, 8, 0, 38)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    SliderFrame.BorderSizePixel = 0
    SliderFrame.ZIndex = 100
    SliderFrame.Parent = Frame
    
    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(1, 0)
    SliderCorner.Parent = SliderFrame
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    SliderFill.BorderSizePixel = 0
    SliderFill.ZIndex = 100
    SliderFill.Parent = SliderFrame
    
    local SliderFillCorner = Instance.new("UICorner")
    SliderFillCorner.CornerRadius = UDim.new(1, 0)
    SliderFillCorner.Parent = SliderFill
    
    local SliderButton = Instance.new("TextButton")
    SliderButton.Size = UDim2.new(0, 14, 0, 14)
    SliderButton.Position = UDim2.new((default - min) / (max - min), -7, 0, -5)
    SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderButton.Text = ""
    SliderButton.BorderSizePixel = 0
    SliderButton.ZIndex = 100
    SliderButton.Parent = SliderFrame
    
    local SliderBtnCorner = Instance.new("UICorner")
    SliderBtnCorner.CornerRadius = UDim.new(1, 0)
    SliderBtnCorner.Parent = SliderButton
    
    local dragging = false
    SliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = SliderFrame.AbsolutePosition.X
            local sliderSize = SliderFrame.AbsoluteSize.X
            local percent = math.clamp((mousePos.X - sliderPos) / sliderSize, 0, 1)
            local value = min + (max - min) * percent
            value = math.floor(value * 100) / 100
            SliderFill.Size = UDim2.new(percent, 0, 1, 0)
            SliderButton.Position = UDim2.new(percent, -7, 0, -5)
            ValueLabel.Text = tostring(value) .. " " .. suffix
            callback(value)
        end
    end)
    
    return Frame
end

-- Функция создания кнопки
local function createButton(parent, name, callback, color)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 38)
    Button.BackgroundColor3 = color or Color3.fromRGB(30, 30, 38)
    Button.Text = ""
    Button.BorderSizePixel = 0
    Button.ZIndex = 100
    Button.Parent = parent
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = Button
    
    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Color = Color3.fromRGB(45, 45, 55)
    BtnStroke.Thickness = 1
    BtnStroke.Parent = Button
    
    local ButtonText = Instance.new("TextLabel")
    ButtonText.Size = UDim2.new(1, -16, 1, 0)
    ButtonText.Position = UDim2.new(0, 8, 0, 0)
    ButtonText.BackgroundTransparency = 1
    ButtonText.Text = name
    ButtonText.TextColor3 = Color3.fromRGB(210, 210, 220)
    ButtonText.TextSize = 12
    ButtonText.Font = Enum.Font.GothamMedium
    ButtonText.TextXAlignment = Enum.TextXAlignment.Left
    ButtonText.ZIndex = 100
    ButtonText.Parent = Button
    
    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play()
        BtnStroke.Color = Color3.fromRGB(180, 0, 0)
    end)
    
    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = color or Color3.fromRGB(30, 30, 38)}):Play()
        BtnStroke.Color = Color3.fromRGB(45, 45, 55)
    end)
    
    Button.MouseButton1Click:Connect(function()
        callback()
        spawn(function()
            TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(180, 0, 0)}):Play()
            wait(0.15)
            TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = color or Color3.fromRGB(30, 30, 38)}):Play()
        end)
    end)
    
    return Button
end

-- Функция создания тогла
local function createToggle(parent, name, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 44)
    Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    Frame.BorderSizePixel = 0
    Frame.ZIndex = 100
    Frame.Parent = parent
    
    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius = UDim.new(0, 8)
    FrameCorner.Parent = Frame
    
    local FrameStroke = Instance.new("UIStroke")
    FrameStroke.Color = Color3.fromRGB(35, 35, 45)
    FrameStroke.Thickness = 1
    FrameStroke.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 160, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(190, 190, 200)
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 100
    Label.Parent = Frame
    
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(0, 30, 1, 0)
    StatusLabel.Position = UDim2.new(1, -90, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = default and "ON" or "OFF"
    StatusLabel.TextColor3 = default and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    StatusLabel.TextSize = 10
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.ZIndex = 100
    StatusLabel.Parent = Frame
    
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(0, 40, 0, 20)
    ToggleFrame.Position = UDim2.new(1, -50, 0.5, -10)
    ToggleFrame.BackgroundColor3 = default and Color3.fromRGB(0, 160, 0) or Color3.fromRGB(55, 55, 65)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.ZIndex = 100
    ToggleFrame.Parent = Frame
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleFrame
    
    local ToggleDot = Instance.new("Frame")
    ToggleDot.Size = UDim2.new(0, 16, 0, 16)
    ToggleDot.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    ToggleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleDot.BorderSizePixel = 0
    ToggleDot.ZIndex = 100
    ToggleDot.Parent = ToggleFrame
    
    local DotCorner = Instance.new("UICorner")
    DotCorner.CornerRadius = UDim.new(1, 0)
    DotCorner.Parent = ToggleDot
    
    local enabled = default
    
    local function updateToggle()
        if enabled then
            TweenService:Create(ToggleFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 160, 0)}):Play()
            TweenService:Create(ToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
            StatusLabel.Text = "ON"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
        else
            TweenService:Create(ToggleFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55, 55, 65)}):Play()
            TweenService:Create(ToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
            StatusLabel.Text = "OFF"
            StatusLabel.TextColor3 = Color3.fromRGB(200, 0, 0)
        end
    end
    
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            enabled = not enabled
            updateToggle()
            callback(enabled)
        end
    end)
    
    return Frame
end

-- Создание вкладок
local PlayerLeft, PlayerRight = createTab()
local TPLeft, TPRight = createTab()
local AVILeft, AVIRight = createTab()
local WorldLeft, WorldRight = createTab()
local MiscLeft, MiscRight = createTab()
local CRLeft, CRRight = createTab()

-- Размещение кнопок вкладок
local tabButtonList = Instance.new("UIListLayout")
tabButtonList.FillDirection = Enum.FillDirection.Horizontal
tabButtonList.Padding = UDim.new(0, 4)
tabButtonList.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabButtonList.VerticalAlignment = Enum.VerticalAlignment.Center
tabButtonList.SortOrder = Enum.SortOrder.LayoutOrder
tabButtonList.Parent = TabContainer

local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingLeft = UDim.new(0, 6)
tabPadding.Parent = TabContainer

local tab1 = createTabButton("Player", Tabs[1])
local tab2 = createTabButton("Teleport", Tabs[2])
local tab3 = createTabButton("AVI", Tabs[3])
local tab4 = createTabButton("World", Tabs[4])
local tab5 = createTabButton("Misc", Tabs[5])
local tab6 = createTabButton("CR", Tabs[6])

tab1.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
tab1.TextColor3 = Color3.fromRGB(255, 255, 255)
Tabs[1].Frame.Visible = true

-- === PLAYER TAB ===
createSlider(PlayerLeft, "Walk Speed", 0, 200, 16, "studs/s", function(value)
    Settings.WalkSpeed = value
    if Humanoid then Humanoid.WalkSpeed = value end
end)

createSlider(PlayerLeft, "Jump Power", 0, 300, 50, "power", function(value)
    Settings.JumpPower = value
    if Humanoid then Humanoid.JumpPower = value end
end)

createSlider(PlayerLeft, "Gravity", 0, 500, 196.2, "studs/s2", function(value)
    Settings.Gravity = value
    Workspace.Gravity = value
end)

createSlider(PlayerLeft, "Hip Height", 0, 10, 2, "studs", function(value)
    Settings.HipHeight = value
    if Humanoid then Humanoid.HipHeight = value end
end)

createSlider(PlayerRight, "Field of View", 30, 120, 70, "deg", function(value)
    Settings.FOV = value
    Workspace.CurrentCamera.FieldOfView = value
end)

createSlider(PlayerRight, "Fly Speed", 10, 200, 50, "studs/s", function(value)
    Settings.FlySpeed = value
end)

createToggle(PlayerRight, "Fly Mode (WASD/Space/Ctrl)", false, function(enabled)
    Settings.FlyEnabled = enabled
    if enabled then
        startFly()
        CreateNotification("Fly Mode", "Activated", 2, Color3.fromRGB(0, 200, 0))
    else
        stopFly()
        CreateNotification("Fly Mode", "Deactivated", 2, Color3.fromRGB(200, 0, 0))
    end
end)

createToggle(PlayerRight, "NoClip", false, function(enabled)
    Settings.NoClip = enabled
    if enabled then
        enableNoClip()
        CreateNotification("NoClip", "Activated - safe mode", 2, Color3.fromRGB(0, 200, 0))
    else
        disableNoClip()
        CreateNotification("NoClip", "Deactivated", 2, Color3.fromRGB(200, 0, 0))
    end
end)

createToggle(PlayerRight, "Infinite Jump", false, function(enabled)
    Settings.InfiniteJump = enabled
    if enabled then
        CreateNotification("Infinite Jump", "Activated", 2, Color3.fromRGB(0, 200, 0))
    else
        CreateNotification("Infinite Jump", "Deactivated", 2, Color3.fromRGB(200, 0, 0))
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Settings.InfiniteJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- === TP TAB ===
local Items = {
    {Name = "Battery", Paths = {"Battery", "battery", "Bat"}},
    {Name = "Blue Key", Paths = {"BlueKey", "Blue Key", "bluekey", "Key_Blue"}},
    {Name = "Bug Spray", Paths = {"BugSpray", "Bug Spray", "bugspray", "Spray"}},
    {Name = "C4", Paths = {"C4", "c4", "ExplosiveC4"}},
    {Name = "Crowbar", Paths = {"Crowbar", "crowbar", "Crow"}},
    {Name = "Green Key", Paths = {"GreenKey", "Green Key", "greenkey", "Key_Green"}},
    {Name = "Orange Key", Paths = {"OrangeKey", "Orange Key", "orangekey", "Key_Orange"}},
    {Name = "Purple Key", Paths = {"PurpleKey", "Purple Key", "purplekey", "Key_Purple"}},
    {Name = "Red Key", Paths = {"RedKey", "Red Key", "redkey", "Key_Red"}},
    {Name = "Wrench", Paths = {"Wrench", "wrench", "Wren"}},
    {Name = "Yellow Key", Paths = {"YellowKey", "Yellow Key", "yellowkey", "Key_Yellow"}}
}

local function FindItem(itemPaths)
    for _, path in ipairs(itemPaths) do
        local item = Workspace:FindFirstChild(path, true)
        if item then return item end
        local itemsFolder = Workspace:FindFirstChild("Items", false)
        if itemsFolder then
            item = itemsFolder:FindFirstChild(path, true)
            if item then return item end
        end
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Model") or v:IsA("Tool") then
                if string.find(string.lower(v.Name), string.lower(path)) then
                    return v
                end
            end
        end
    end
    return nil
end

local function TeleportToItem(item)
    if not item or not Character or not HumanoidRootPart then return false end
    local targetPosition
    if item:IsA("BasePart") then
        targetPosition = item.Position + Vector3.new(0, 3, 0)
    elseif item:IsA("Model") then
        local primaryPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            targetPosition = primaryPart.Position + Vector3.new(0, 3, 0)
        end
    elseif item:IsA("Tool") then
        if item.Handle then
            targetPosition = item.Handle.Position + Vector3.new(0, 3, 0)
        end
    end
    if targetPosition then
        TweenService:Create(HumanoidRootPart, TweenInfo.new(0.5), {CFrame = CFrame.new(targetPosition)}):Play()
        return true
    end
    return false
end

for i, itemData in ipairs(Items) do
    local targetPanel = i <= 6 and TPLeft or TPRight
    createButton(targetPanel, itemData.Name, function()
        local item = FindItem(itemData.Paths)
        if item then
            TeleportToItem(item)
            CreateNotification("Teleport", "Teleported to " .. itemData.Name, 2, Color3.fromRGB(0, 200, 0))
        else
            CreateNotification("Error", itemData.Name .. " not found", 2, Color3.fromRGB(255, 0, 0))
        end
    end)
end

createButton(TPLeft, "Teleport to Spawn", function()
    if Character and HumanoidRootPart then
        local spawnLocation = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn")
        if spawnLocation then
            HumanoidRootPart.CFrame = spawnLocation.CFrame * CFrame.new(0, 3, 0)
            CreateNotification("Teleport", "Teleported to spawn", 2, Color3.fromRGB(0, 200, 0))
        end
    end
end)

createButton(TPLeft, "Teleport to Mouse", function()
    local mouse = LocalPlayer:GetMouse()
    if Character and HumanoidRootPart then
        HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        CreateNotification("Teleport", "Teleported to cursor", 2, Color3.fromRGB(0, 200, 0))
    end
end)

-- === AVI TAB ===
createToggle(AVILeft, "God Spider", false, function(enabled)
    Settings.GodSpider = enabled
    if enabled then
        StartGodSpider()
        CreateNotification("God Spider", "Activated - TP to random item on damage", 3, Color3.fromRGB(0, 200, 0))
    else
        if GodSpiderConnection then GodSpiderConnection:Disconnect() end
        CreateNotification("God Spider", "Deactivated", 2, Color3.fromRGB(200, 0, 0))
    end
end)

createToggle(AVILeft, "Player ESP", false, function(enabled)
    Settings.ESP = enabled
    if enabled then
        StartESP()
        CreateNotification("ESP", "Player ESP activated", 2, Color3.fromRGB(0, 200, 0))
    else
        StopESP()
        CreateNotification("ESP", "Player ESP deactivated", 2, Color3.fromRGB(200, 0, 0))
    end
end)

createToggle(AVILeft, "Item ESP", false, function(enabled)
    Settings.GESP = enabled
    if enabled then
        StartGESP()
        CreateNotification("GESP", "Item ESP activated - one per type", 2, Color3.fromRGB(0, 200, 0))
    else
        StopGESP()
        CreateNotification("GESP", "Item ESP deactivated", 2, Color3.fromRGB(200, 0, 0))
    end
end)

createButton(AVIRight, "Find Items Count", function()
    local items = FindAllTrackedItems()
    CreateNotification("Items Found", "Found " .. #items .. " unique items on map", 2, Color3.fromRGB(255, 200, 0))
end)

createButton(AVIRight, "Random Item Teleport", function()
    TeleportToRandomItem()
end)

-- === WORLD TAB ===
createSlider(WorldLeft, "Server Gravity", 0, 500, 196.2, "studs/s2", function(value)
    Workspace.Gravity = value
end)

createSlider(WorldLeft, "Time of Day", 0, 24, 12, "h", function(value)
    Lighting.ClockTime = value
end)

createSlider(WorldRight, "Brightness", 0, 5, 1, "x", function(value)
    Lighting.Brightness = value
end)

createToggle(WorldLeft, "Full Bright", false, function(enabled)
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 99999
        CreateNotification("Full Bright", "Activated", 2, Color3.fromRGB(0, 200, 0))
    else
        Lighting.Brightness = 1
        Lighting.FogEnd = 1000
        CreateNotification("Full Bright", "Deactivated", 2, Color3.fromRGB(200, 0, 0))
    end
end)

createToggle(WorldLeft, "Anti-Fog", false, function(enabled)
    Lighting.FogEnd = enabled and 99999 or 1000
    Lighting.FogStart = 0
    if enabled then
        CreateNotification("Anti-Fog", "Activated", 2, Color3.fromRGB(0, 200, 0))
    else
        CreateNotification("Anti-Fog", "Deactivated", 2, Color3.fromRGB(200, 0, 0))
    end
end)

createToggle(WorldRight, "No Depth of Field", false, function(enabled)
    if Lighting:FindFirstChild("DepthOfField") then
        Lighting.DepthOfField.Enabled = not enabled
    end
end)

createToggle(WorldRight, "No Bloom", false, function(enabled)
    if Lighting:FindFirstChild("Bloom") then
        Lighting.Bloom.Enabled = not enabled
    end
end)

-- === MISC TAB ===
createButton(MiscLeft, "Rejoin Server", function()
    CreateNotification("Rejoin", "Rejoining server...", 2, Color3.fromRGB(255, 140, 0))
    wait(0.5)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end, Color3.fromRGB(35, 35, 45))

createButton(MiscLeft, "Server Hop", function()
    CreateNotification("Server Hop", "Searching for server...", 2, Color3.fromRGB(255, 140, 0))
    local ApiUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(ApiUrl))
    end)
    if success and result and result.data and #result.data > 0 then
        for _, server in ipairs(result.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                break
            end
        end
    end
end, Color3.fromRGB(35, 35, 45))

createButton(MiscLeft, "Reset Character", function()
    if Character then
        Character:BreakJoints()
        CreateNotification("Reset", "Character reset", 2, Color3.fromRGB(255, 140, 0))
    end
end, Color3.fromRGB(160, 35, 35))

createButton(MiscLeft, "Infinite Yield", function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    CreateNotification("Loaded", "Infinite Yield loaded", 2, Color3.fromRGB(0, 200, 0))
end, Color3.fromRGB(30, 30, 45))

createButton(MiscRight, "Dex Explorer", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
    CreateNotification("Loaded", "Dex Explorer loaded", 2, Color3.fromRGB(0, 200, 0))
end, Color3.fromRGB(30, 30, 45))

createButton(MiscRight, "FPS Booster", function()
    local settings = {
        Lighting = {GlobalShadows = false, ShadowMap = false, Technology = Enum.Technology.Compatibility},
        Rendering = {QualityLevel = Enum.QualityLevel.Level01}
    }
    for category, values in pairs(settings) do
        local service = game:GetService(category)
        for property, value in pairs(values) do
            service[property] = value
        end
    end
    CreateNotification("FPS", "FPS Booster activated", 2, Color3.fromRGB(0, 200, 0))
end, Color3.fromRGB(30, 30, 45))

-- === CR TAB ===

local CRTitle = Instance.new("TextLabel")
CRTitle.Size = UDim2.new(1, -10, 0, 35)
CRTitle.Position = UDim2.new(0, 5, 0, 5)
CRTitle.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
CRTitle.Text = "Script by VRSS"
CRTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
CRTitle.TextSize = 16
CRTitle.Font = Enum.Font.GothamBlack
CRTitle.BorderSizePixel = 0
CRTitle.ZIndex = 100
CRTitle.Parent = CRLeft

local CRTitleCorner = Instance.new("UICorner")
CRTitleCorner.CornerRadius = UDim.new(0, 8)
CRTitleCorner.Parent = CRTitle

local CRTextFrame = Instance.new("Frame")
CRTextFrame.Size = UDim2.new(1, -10, 0, 200)
CRTextFrame.Position = UDim2.new(0, 5, 0, 46)
CRTextFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
CRTextFrame.BorderSizePixel = 0
CRTextFrame.ZIndex = 100
CRTextFrame.Parent = CRLeft

local CRTextFrameCorner = Instance.new("UICorner")
CRTextFrameCorner.CornerRadius = UDim.new(0, 8)
CRTextFrameCorner.Parent = CRTextFrame

local CRClickText = Instance.new("TextButton")
CRClickText.Size = UDim2.new(1, -20, 0, 100)
CRClickText.Position = UDim2.new(0, 10, 0, 10)
CRClickText.BackgroundTransparency = 2
CRClickText.Text = "Telegram Channel:\n@HiVRSS (Click)"
CRClickText.TextColor3 = Color3.fromRGB(50, 150, 255)
CRClickText.TextSize = 22
CRClickText.Font = Enum.Font.GothamBlack
CRClickText.TextXAlignment = Enum.TextXAlignment.Left
CRClickText.ZIndex = 150
CRClickText.Parent = CRTextFrame

CRClickText.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard("https://t.me/HiVRSS")
    end
    CreateNotification("Link Copied", "t.me/HiVRSS", 2, Color3.fromRGB(0, 200, 255))
end)

CRClickText.MouseEnter:Connect(function()
    CRClickText.TextColor3 = Color3.fromRGB(100, 180, 255)
end)

CRClickText.MouseLeave:Connect(function()
    CRClickText.TextColor3 = Color3.fromRGB(50, 150, 255)
end)

-- === ОБРАБОТЧИК КНОПКИ V ===
CollapseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        CreateNotification("Menu", "Opened", 1.5, Color3.fromRGB(180, 0, 0))
    end
end)

-- Пульсация V
spawn(function()
    while ScreenGui and ScreenGui.Parent and VText and VText.Parent do
        for i = 0, 1, 0.03 do
            if not VText or not VText.Parent then break end
            local alpha = 0.4 + math.sin(i * math.pi * 2) * 0.8
            VText.TextColor3 = Color3.fromRGB(200 + 75 * alpha, 0, 0)
            CollapseStroke.Transparency = 0.7 - alpha * 0.5
            wait(0.03)
        end
    end
end)

-- Обновление скроллов
local function updateCanvasSizes()
    for _, tab in ipairs(Tabs) do
        for _, scrollFrame in ipairs({tab.LeftScroll, tab.RightScroll}) do
            local contentSize = 0
            for _, child in ipairs(scrollFrame:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextButton") then
                    contentSize = contentSize + child.AbsoluteSize.Y + 6
                end
            end
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize + 10)
        end
    end
end

MainFrame.ChildAdded:Connect(updateCanvasSizes)
wait(0.5)
updateCanvasSizes()

-- Клавиша скрытия
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
        if not MainFrame.Visible then
            CollapseButton.Visible = true
        end
    end
end)

-- Запуск
CreateNotification("VRSS Spider v1.0.1", "Loaded!", 2, Color3.fromRGB(0, 200, 0))
print("[VRSS | Spider | v1.0.1] Loaded! \\\ t.me/HiVRSS")
