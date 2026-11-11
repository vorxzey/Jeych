-- ==========================================
-- KEREN HUB - BARISTA AUTO FARM (ULTIMATE ANIMATED VERSION)
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Hapus UI lama kalau script-nya di-execute ulang
if PlayerGui:FindFirstChild("WindUIBarista") then
    PlayerGui.WindUIBarista:Destroy()
end

-- ==========================================
-- MEMBUAT CUSTOM WIND UI (MINIMALIST iOS DARK STYLE)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WindUIBarista"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.Position = UDim2.new(0.5, -125, 0.1, 0)
MainFrame.Size = UDim2.new(0, 250, 0, 135)
MainFrame.Active = true
MainFrame.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 14)
UICorner.Parent = MainFrame

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
})
UIGradient.Rotation = 45
UIGradient.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 80)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Title Header
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 0, 0, 12)
Title.Size = UDim2.new(1, 0, 0, 22)
Title.Font = Enum.Font.GothamBold
Title.Text = "☕ Wind UI • Barista Auto-Farm"
Title.TextColor3 = Color3.fromRGB(240, 240, 255)
Title.TextSize = 13

-- Status Text Label
local StatusText = Instance.new("TextLabel")
StatusText.Parent = MainFrame
StatusText.BackgroundTransparency = 1
StatusText.Position = UDim2.new(0, 10, 0, 42)
StatusText.Size = UDim2.new(1, -20, 0, 25)
StatusText.Font = Enum.Font.Gotham
StatusText.Text = "Status: Standby (Mati 🔴)"
StatusText.TextColor3 = Color3.fromRGB(170, 170, 190)
StatusText.TextSize = 11

-- Toggle Button (Wind UI Style)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = MainFrame
ToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
ToggleBtn.Position = UDim2.new(0.08, 0, 0, 78)
ToggleBtn.Size = UDim2.new(0.84, 0, 0, 36)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "AUTO FARM: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 12

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 10)
BtnCorner.Parent = ToggleBtn

-- ==========================================
-- LOGIC AUTO-FARM & WAYPOINT TELEPORT
-- ==========================================
local AutoBaristaEnabled = false
local BaristaEvent = ReplicatedStorage:WaitForChild("BaristaAssets"):WaitForChild("Events"):WaitForChild("BaristaEvent")
local LatestToken = nil

BaristaEvent.OnClientEvent:Connect(function(action, data)
    pcall(function()
        if type(data) == "table" and data.Token then
            LatestToken = data.Token
        end
    end)
end)

local COORDS = {
    ShiftSpot     = Vector3.new(-4992.262, 4.287, -716.253),
    CoffeeMachine = Vector3.new(-4997.648, 4.287, -794.613),
    Customer      = Vector3.new(-4996.451, 4.287, -760.959)
}

-- List Kordinat Waypoint Slow Load Seated Teleport
local shiftWaypoints = {
    CFrame.new(-898.326, 2.788, -630.031),
    CFrame.new(-2192.834, 37.488, -582.452),
    CFrame.new(-3533.805, 2.759, -582.758),
    CFrame.new(-4554.525, 2.759, -581.123),
    CFrame.new(-4943.070, 2.759, -582.773),
    CFrame.new(COORDS.ShiftSpot.X, COORDS.ShiftSpot.Y, COORDS.ShiftSpot.Z)
}

-- Anti-AFK
task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end)
end)

-- Fitur "Bar Gede" & Auto Click Minigame GUI
task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            if AutoBaristaEnabled then
                local baristaGui = PlayerGui:FindFirstChild("BaristaGUI")
                if baristaGui then
                    local targetZone = baristaGui:FindFirstChild("TargetZone", true)
                    if targetZone then
                        targetZone.Size = UDim2.new(targetZone.Size.X.Scale, targetZone.Size.X.Offset, 1, 0)
                    end
                    
                    for _, v in pairs(baristaGui:GetDescendants()) do
                        if (v:IsA("TextButton") or v:IsA("ImageButton")) and firesignal then
                            firesignal(v.MouseButton1Click)
                        end
                    end
                end
            end
        end)
    end
end)

-- Pilih Job Barista (Delay 3 detik)
local function selectBaristaJob()
    pcall(function()
        local Event = ReplicatedStorage:FindFirstChild("JobEvents") and ReplicatedStorage.JobEvents:FindFirstChild("TeamChangeRequest")
        if Event then 
            Event:FireServer("Barista", 11378976, 1, 0, "Detector") 
            task.wait(3) 
        end
    end)
end

-- Slow Load Seated Teleport dengan jeda 0,5 detik per waypoint
local function slowLoadSeatedTeleport(waypointList)
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then return end

        for _, targetCFrame in ipairs(waypointList) do
            if not AutoBaristaEnabled then break end
            humanoid.Sit = true
            task.wait(0.15)
            hrp.CFrame = targetCFrame
            task.wait(0.5)
        end

        humanoid.Sit = false
        task.wait(0.2)
    end)
end

-- Fungsi Jalan Melangkah Normal (Dengan Orientasi Hadap Biar Animasi Keluar)
local function walkTo(targetVector)
    pcall(function()
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp then return end

        local lookAtTarget = Vector3.new(targetVector.X, hrp.Position.Y, targetVector.Z)
        hrp.CFrame = CFrame.new(hrp.Position, lookAtTarget)
        
        humanoid:MoveTo(targetVector)
        
        local startTime = tick()
        while AutoBaristaEnabled do
            local currentPos = hrp.Position
            local dist = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(targetVector.X, 0, targetVector.Z)).Magnitude
            
            if dist <= 3.5 or (tick() - startTime) > 6 then
                humanoid:MoveTo(currentPos)
                break
            end
            
            hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetVector.X, hrp.Position.Y, targetVector.Z))
            task.wait(0.1)
        end
    end)
end

local function fireNearestPrompt()
    pcall(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Parent then
                local partPos = v.Parent:IsA("Model") and v.Parent.PrimaryPart and v.Parent.PrimaryPart.Position or (v.Parent:IsA("BasePart") and v.Parent.Position)
                if partPos and (partPos - hrp.Position).Magnitude <= 15 then
                    if fireproximityprompt then fireproximityprompt(v) end
                end
            end
        end
    end)
end

-- MAIN LOOP
task.spawn(function()
    while true do
        if AutoBaristaEnabled then
            pcall(function()
                -- Step 1: Pilih Job Barista
                StatusText.Text = "Status: Memilih Job Barista..."
                selectBaristaJob()

                -- Step 2: Slow Load Seated Teleport ke Shift Spot
                StatusText.Text = "Status: Teleport ke Shift Spot..."
                slowLoadSeatedTeleport(shiftWaypoints)
                task.wait(0.5)
                
                -- Step 3: Toggle Job & ProximityPrompt
                BaristaEvent:FireServer("ToggleJob")
                fireNearestPrompt()
                task.wait(1)

                -- Loop Siklus Kerja (Jalan Kaki Normal dengan Animasi)
                while AutoBaristaEnabled do
                    StatusText.Text = "Status: Memanggil Pelanggan..."
                    BaristaEvent:FireServer("RequestCustomer")
                    task.wait(1)
                    if not AutoBaristaEnabled then break end

                    StatusText.Text = "Status: Berjalan ke Mesin Kopi..."
                    walkTo(COORDS.CoffeeMachine)
                    BaristaEvent:FireServer("TryBrew")
                    task.wait(0.5)

                    local tokenToUse = LatestToken or "6c0c8fd5-012a-4566-85dc-a5edcbb5cd00"
                    BaristaEvent:FireServer("StartMinigame", { Token = tokenToUse })
                    task.wait(0.3)
                    BaristaEvent:FireServer("CompleteMinigame", { Token = tokenToUse })
                    task.wait(1)
                    if not AutoBaristaEnabled then break end

                    StatusText.Text = "Status: Berjalan ke Pelanggan..."
                    walkTo(COORDS.Customer)
                    BaristaEvent:FireServer("ServeOrder")
                    
                    StatusText.Text = "Status: Selesai, Next Customer..."
                    task.wait(1.5)
                end
            end)
        else
            StatusText.Text = "Status: Standby (Mati 🔴)"
            task.wait(0.5)
        end
        task.wait(0.5)
    end
end)

-- Tombol On / Off Callback
ToggleBtn.MouseButton1Click:Connect(function()
    AutoBaristaEnabled = not AutoBaristaEnabled
    if AutoBaristaEnabled then
        ToggleBtn.Text = "AUTO FARM: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 90)
    else
        ToggleBtn.Text = "AUTO FARM: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        StatusText.Text = "Status: Dimatikan Manual"
    end
end)

print("[Wind UI] Barista Auto-Farm Animated Version Berhasil Dimuat!")
