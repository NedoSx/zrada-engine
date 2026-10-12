-- Zrada Engine by Rustex
-- Универсальный ESP + Aimbot

-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Настройки
local Settings = {
    ESPEnabled = true,
    AimbotEnabled = false,
    AimSmoothness = 0.25,
    AimFOV = 120,
    ESPColor = Color3.fromRGB(255, 0, 0),
    ESPTextColor = Color3.fromRGB(255, 255, 255),
    TeamCheck = true,
    WallCheck = false,
}

-- === МЕНЮ (Zrada Engine) ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZradaEngine"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 280)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -20, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Zrada Engine by Rustex"
TitleLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Кнопка закрытия
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
end)

-- === Функция создания тумблера ===
local function CreateToggle(name, default, callback, parent)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, -20, 0, 35)
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.TextSize = 14
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = ToggleFrame

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 50, 0, 25)
    Button.Position = UDim2.new(1, -55, 0.5, -12)
    Button.BackgroundColor3 = default and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(80, 80, 90)
    Button.Text = default and "ON" or "OFF"
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 12
    Button.Font = Enum.Font.GothamBold
    Button.BorderSizePixel = 0
    Button.Parent = ToggleFrame

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 5)
    BtnCorner.Parent = Button

    local state = default

    Button.MouseButton1Click:Connect(function()
        state = not state
        Button.Text = state and "ON" or "OFF"
        Button.BackgroundColor3 = state and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(80, 80, 90)
        callback(state)
    end)

    return ToggleFrame, function()
        return state
    end
end

-- === ESP ===
local ESPObjects = {}

local function CleanupESP()
    for _, obj in pairs(ESPObjects) do
        if obj.Box and obj.Box.Parent then obj.Box:Destroy() end
        if obj.Name and obj.Name.Parent then obj.Name:Destroy() end
        if obj.Distance and obj.Distance.Parent then obj.Distance:Destroy() end
    end
    ESPObjects = {}
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Color = Settings.ESPColor
    box.Filled = false
    box.Transparency = 1
    
    local nameTag = Drawing.new("Text")
    nameTag.Size = 14
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = Settings.ESPTextColor
    nameTag.Transparency = 1
    
    local distTag = Drawing.new("Text")
    distTag.Size = 12
    distTag.Center = true
    distTag.Outline = true
    distTag.Color = Color3.fromRGB(200, 200, 200)
    distTag.Transparency = 1
    
    ESPObjects[player] = {Box = box, Name = nameTag, Distance = distTag}
end

local function UpdateESP()
    if not Settings.ESPEnabled then
        for _, obj in pairs(ESPObjects) do
            obj.Box.Visible = false
            obj.Name.Visible = false
            obj.Distance.Visible = false
        end
        return
    end

    for player, objs in pairs(ESPObjects) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            local root = character.HumanoidRootPart
            local head = character:FindFirstChild("Head")
            
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then
                objs.Box.Visible = false
                objs.Name.Visible = false
                objs.Distance.Visible = false
                continue
            end
            
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen then
                local headPos = Camera:WorldToViewportPoint(head.Position)
                local height = math.abs(screenPos.Y - headPos.Y)
                local width = height * 0.6
                
                objs.Box.Size = Vector2.new(width, height)
                objs.Box.Position = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)
                objs.Box.Visible = true
                
                local distance = (Camera.CFrame.Position - root.Position).Magnitude
                objs.Name.Text = player.Name
                objs.Name.Position = Vector2.new(screenPos.X, screenPos.Y - height / 2 - 18)
                objs.Name.Visible = true
                
                objs.Distance.Text = string.format("[%d studs]", math.floor(distance))
                objs.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + height / 2 + 4)
                objs.Distance.Visible = true
            else
                objs.Box.Visible = false
                objs.Name.Visible = false
                objs.Distance.Visible = false
            end
        else
            objs.Box.Visible = false
            objs.Name.Visible = false
            objs.Distance.Visible = false
        end
    end
end

-- === АИМБОТ ===
local function GetClosestPlayer()
    local closest = nil
    local shortestDist = Settings.AimFOV
    local center = Camera.ViewportSize / 2
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local character = player.Character
        if not character then continue end
        
        local head = character:FindFirstChild("Head")
        local humanoid = character:FindFirstChild("Humanoid")
        if not head or not humanoid or humanoid.Health <= 0 then continue end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < shortestDist then
            shortestDist = dist
            closest = head
        end
    end
    
    return closest
end

local function AimbotLoop()
    RunService.RenderStepped:Connect(function()
        if not Settings.AimbotEnabled then return end
        
        local target = GetClosestPlayer()
        if target then
            local targetPos = target.Position
            local currentCFrame = Camera.CFrame
            local newCFrame = CFrame.new(currentCFrame.Position, targetPos)
            Camera.CFrame = currentCFrame:Lerp(newCFrame, Settings.AimSmoothness)
        end
    end)
end

-- === ИНИЦИАЛИЗАЦИЯ ===
for _, player in ipairs(Players:GetPlayers()) do
    CreateESP(player)
end

Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        ESPObjects[player].Box:Destroy()
        ESPObjects[player].Name:Destroy()
        ESPObjects[player].Distance:Destroy()
        ESPObjects[player] = nil
    end
end)

-- Создание меню
local OptionsFrame = Instance.new("Frame")
OptionsFrame.Size = UDim2.new(1, -20, 1, -50)
OptionsFrame.Position = UDim2.new(0, 10, 0, 45)
OptionsFrame.BackgroundTransparency = 1
OptionsFrame.Parent = MainFrame

local espToggle = CreateToggle("ESP", Settings.ESPEnabled, function(state)
    Settings.ESPEnabled = state
end, OptionsFrame)
espToggle.Position = UDim2.new(0, 0, 0, 0)

local aimToggle = CreateToggle("Aimbot", Settings.AimbotEnabled, function(state)
    Settings.AimbotEnabled = state
end, OptionsFrame)
aimToggle.Position = UDim2.new(0, 0, 0, 45)

local teamToggle = CreateToggle("Team Check", Settings.TeamCheck, function(state)
    Settings.TeamCheck = state
end, OptionsFrame)
teamToggle.Position = UDim2.new(0, 0, 0, 90)

-- Запуск
RunService.RenderStepped:Connect(UpdateESP)
AimbotLoop()

print("Zrada Engine by Rustex loaded!")
