-- ==========================================
-- KEREN HUB - CDID JATIM AUTO FARM TRUCK
-- FULL STATS & UNIVERSAL MONEY DETECTOR (FIXED)
-- ==========================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Keren Hub - Jatim",
    Icon = "sparkles",
    Author = "by Kenzo",
    Folder = "KerenHubJatimConfig"
})

-- TAB & SECTION
local MainTab = Window:Tab({ Title = "Home", Icon = "home" })
local StatsTab = Window:Tab({ Title = "Stats", Icon = "chart-bar" })

local MainSection = MainTab:Section({ Title = "Main Farm Jatim" })
local SettingsSection = MainTab:Section({ Title = "Settings & Extra" })
local StatsSection = StatsTab:Section({ Title = "Live Statistics" })

-- VARIABEL & LAYANAN UTAMA
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local AutoTruckEnabled = false
local AntiAfkEnabled = false
local NoclipEnabled = false
local BlackScreenEnabled = false

local TweenDuration = 10.0
local SelectedMode = "Auto (Sniffer)"
local ManualCityTarget = "surabaya"

local detectedDestinationCoords = nil
local farmThread = nil

-- TRACKING STATS
local InitialMoney = 0
local EarnedMoney = 0
local TotalTrips = 0

pcall(function()
    GuiService:SetGameplayPausedNotificationEnabled(false)
end)

-- KOORDINAT MAP JATIM
local COORDS = {
    Start = CFrame.new(34938.0234, 134.4782, -54577.8906),
    Spawn = CFrame.new(35161.5195, 134.4782, -54681.5781),
    Drive = CFrame.new(35170.3945, 134.4782, -54687.0977)
}

-- DATABASE RUKO TUJUAN
local DESTINATION_DATABASE = {
    ["kediri"]     = CFrame.new(-10032.3604, 211.4886, 5129.3950),
    ["ngawi"]      = CFrame.new(37564.2305, 132.8297, -47529.4883),
    ["surabaya"]   = CFrame.new(27153.5664, 387.3378, 37787.8828),
    ["sidoarjo"]   = CFrame.new(12900.3945, 385.6128, 52071.6250),
    ["malang"]     = CFrame.new(-7848.0903, 386.4347, 46865.0312),
}

-- FUNGSI HELPER STATS & FORMAT
local function formatNumber(n)
    local num = tostring(math.floor(n or 0))
    return num:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
end

local function notify(title, text, duration)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = text,
            Duration = duration or 2,
            Icon = "bell"
        })
    end)
end

-- ==========================================
-- UNIVERSAL MONEY SNIFFER (YOUR CUSTOM LOGIC)
-- ==========================================
local function isDompetFrame(obj)
    local success, isMatch = pcall(function()
        if not (obj:IsA("TextLabel") or obj:IsA("TextButton")) or not obj.Visible or obj.Text == "" then
            return false
        end
        
        local txtUpper = obj.Text:upper()
        if not (txtUpper:find("RP") and txtUpper:find("%d")) then
            return false
        end
        
        local pos = obj.AbsolutePosition
        local screenSize = workspace.CurrentCamera.ViewportSize
        
        if screenSize.X > 0 and screenSize.Y > 0 then
            return (pos.X < (screenSize.X * 0.35)) and (pos.Y > (screenSize.Y * 0.5))
        end
        
        return false
    end)
    
    return success and isMatch
end

local function getCDIDMoneyText()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return 0 end

    for _, obj in ipairs(pGui:GetDescendants()) do
        if isDompetFrame(obj) then
            local digitsOnly = obj.Text:gsub("%D", "")
            local cleanNum = tonumber(digitsOnly)
            if cleanNum and cleanNum > 0 then
                return cleanNum
            end
        end
    end

    return 0
end

-- STATS PARAGRAPH
local CurrentMoneyParagraph = StatsSection:Paragraph({ Title = "Uang Kita (Dompet)", Desc = "Rp 0", Image = "wallet" })
local EarnedMoneyParagraph = StatsSection:Paragraph({ Title = "Total Pendapatan (Sesi Ini)", Desc = "+ Rp 0", Image = "trending-up" })
local TripParagraph = StatsSection:Paragraph({ Title = "Total Trip Selesai", Desc = "0 Trip", Image = "truck" })

local function updateStatsDisplay()
    pcall(function()
        local currentVal = getCDIDMoneyText()
        if InitialMoney == 0 and currentVal > 0 then InitialMoney = currentVal end
        if InitialMoney > 0 and currentVal >= InitialMoney then EarnedMoney = currentVal - InitialMoney end

        CurrentMoneyParagraph:SetDesc("Rp " .. formatNumber(currentVal))
        EarnedMoneyParagraph:SetDesc("+ Rp " .. formatNumber(EarnedMoney))
        TripParagraph:SetDesc(tostring(TotalTrips) .. " Trip Selesai")
    end)
end

task.spawn(function()
    while task.wait(1.5) do updateStatsDisplay() end
end)

-- OVERLAY HITAM PEKAT
local function showOverlay()
    pcall(function()
        if not BlackScreenEnabled or PlayerGui:FindFirstChild("KHubAutoFarmOverlay") then return end
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "KHubAutoFarmOverlay"
        screenGui.Parent = PlayerGui
        screenGui.IgnoreGuiInset = true
        screenGui.DisplayOrder = 999999999

        local bgFrame = Instance.new("Frame")
        bgFrame.Size = UDim2.new(1, 0, 1, 0)
        bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bgFrame.Parent = screenGui

        local centerContainer = Instance.new("Frame")
        centerContainer.Size = UDim2.new(0, 300, 0, 250)
        centerContainer.Position = UDim2.new(0.5, -150, 0.5, -125)
        centerContainer.BackgroundTransparency = 1
        centerContainer.Parent = bgFrame

        local logoBox = Instance.new("Frame")
        logoBox.Size = UDim2.new(0, 90, 0, 90)
        logoBox.Position = UDim2.new(0.5, -45, 0, 10)
        logoBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        logoBox.BorderColor3 = Color3.fromRGB(255, 255, 255)
        logoBox.BorderSizePixel = 2
        logoBox.Parent = centerContainer

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 12)
        uiCorner.Parent = logoBox

        local logoText = Instance.new("TextLabel")
        logoText.Size = UDim2.new(1, 0, 1, 0)
        logoText.BackgroundTransparency = 1
        logoText.Text = "K"
        logoText.TextColor3 = Color3.fromRGB(255, 255, 255)
        logoText.TextSize = 50
        logoText.Font = Enum.Font.GothamBold
        logoText.Parent = logoBox

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0, 40)
        titleLabel.Position = UDim2.new(0, 0, 0, 110)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "Keren Hub"
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 26
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Parent = centerContainer

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Size = UDim2.new(1, 0, 0, 25)
        statusLabel.Position = UDim2.new(0, 0, 0, 150)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "Auto-Farm Truck Running..."
        statusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
        statusLabel.TextSize = 13
        statusLabel.Font = Enum.Font.GothamMedium
        statusLabel.Parent = centerContainer
    end)
end

local function hideOverlay()
    pcall(function()
        if PlayerGui:FindFirstChild("KHubAutoFarmOverlay") then
            PlayerGui.KHubAutoFarmOverlay:Destroy()
        end
    end)
end

-- LOGIKA SNIFFER DESTINATION
local function processDestinationText(text)
    if text and text ~= "" then
        local lowerText = text:lower()
        if lowerText:find("destination") or lowerText:find("tujuan") then
            for city, cframeVal in pairs(DESTINATION_DATABASE) do
                if lowerText:find(city) then
                    detectedDestinationCoords = cframeVal
                    notify("Destination Sniffer", "Tujuan Terdeteksi: " .. city:upper(), 3)
                    return 
                end
            end
        end
    end
end

local function initSniffer()
    pcall(function()
        for _, obj in ipairs(PlayerGui:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                processDestinationText(obj.Text)
                if not obj:GetAttribute("SnifferHooked") then
                    obj:SetAttribute("SnifferHooked", true)
                    obj:GetPropertyChangedSignal("Text"):Connect(function()
                        processDestinationText(obj.Text)
                    end)
                end
            end
        end
    end)
end

initSniffer()
PlayerGui.DescendantAdded:Connect(function(child)
    if child:IsA("TextLabel") or child:IsA("TextButton") then
        processDestinationText(child.Text)
        child:GetPropertyChangedSignal("Text"):Connect(function() processDestinationText(child.Text) end)
    end
end)

-- NOCLIP & ANTI-AFK
RunService.Stepped:Connect(function()
    if NoclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

task.spawn(function()
    local vu = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if AntiAfkEnabled then
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end)
end)

task.spawn(function()
    pcall(function()
        for _, v in ipairs(Workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then v.HoldDuration = 0 end end
        Workspace.DescendantAdded:Connect(function(v) if v:IsA("ProximityPrompt") then v.HoldDuration = 0 end end)
    end)
end)

-- TELEPORT & INTERACT
local function tp(cf)
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local seat = humanoid and humanoid.SeatPart
            local targetObj = (seat and seat.Parent) or char:FindFirstChild("HumanoidRootPart")
            if not targetObj then return end

            for _, part in ipairs(targetObj:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end

            local targetCFrame = CFrame.new(cf.Position + Vector3.new(0, 3, 0))
            if targetObj:IsA("Model") and targetObj.PrimaryPart then
                targetObj:SetPrimaryPartCFrame(targetCFrame)
            elseif targetObj:IsA("Model") then
                local part = targetObj:FindFirstChildWhichIsA("BasePart")
                if part then part.CFrame = targetCFrame end
            else
                targetObj.CFrame = targetCFrame
            end
        end
    end)
end

local function getNearestPrompt(maxDistance)
    maxDistance = maxDistance or 20
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local nearestPrompt = nil
    local shortestDist = maxDistance

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Parent then
            local partPos = v.Parent:IsA("Model") and v.Parent.PrimaryPart and v.Parent.PrimaryPart.Position or (v.Parent:IsA("BasePart") and v.Parent.Position)
            if partPos then
                local dist = (partPos - hrp.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    nearestPrompt = v
                end
            end
        end
    end
    return nearestPrompt
end

local function firePromptOrKey(keyFallback)
    local prompt = getNearestPrompt(20)
    if prompt then
        if fireproximityprompt then 
            fireproximityprompt(prompt) 
        else 
            prompt:InputHoldBegin() 
            task.wait(prompt.HoldDuration) 
            prompt:InputHoldEnd() 
        end
    else
        VirtualInputManager:SendKeyEvent(true, keyFallback, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, keyFallback, false, game)
    end
end

-- TWEEN SLOW-LOAD TELEPORT
local function tpDestination(targetCF)
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local seat = humanoid and humanoid.SeatPart
            local vehicle = seat and seat.Parent
            
            if not vehicle or not vehicle:IsA("Model") then vehicle = char:FindFirstChild("HumanoidRootPart") end
            if not vehicle then return end

            local startCFrame = vehicle:IsA("Model") and (vehicle.PrimaryPart and vehicle.PrimaryPart.CFrame or vehicle:GetPivot()) or vehicle.CFrame
            local endCFrame = CFrame.new(targetCF.Position + Vector3.new(0, 8, 0))
            local totalSteps = math.max(20, math.floor(TweenDuration * 8)) 
            
            for i = 1, totalSteps do
                if not AutoTruckEnabled then break end
                local alpha = i / totalSteps
                local intermediateCFrame = startCFrame:Lerp(endCFrame, alpha)
                
                for _, part in ipairs(vehicle:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end
                end
                
                if vehicle:IsA("Model") then vehicle:PivotTo(intermediateCFrame) else vehicle.CFrame = intermediateCFrame end
                task.wait(TweenDuration / totalSteps)
            end

            notify("Keren Hub 🚚", "Menunggu Ruko/Destination Ter-render...", 2)
            local renderTimer = tick()
            while (tick() - renderTimer) < 5 do
                if not AutoTruckEnabled then break end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local prompt = getNearestPrompt(25)
                local raycast = hrp and workspace:Raycast(hrp.Position, Vector3.new(0, -20, 0))
                if prompt or raycast then break end
                task.wait(0.3)
            end

            task.wait(1.5)
            notify("Keren Hub 🎯", "Finishing Cargo...", 2)
            for i = 1, 5 do
                if not AutoTruckEnabled then break end
                firePromptOrKey(Enum.KeyCode.E)
                task.wait(0.3)
            end

            TotalTrips = TotalTrips + 1
            updateStatsDisplay()
            task.wait(1.5)
        end
    end)
end

-- TAHAP PREPARASI
local function tryFullPreparationSequence()
    if not AutoTruckEnabled then return false end

    notify("Keren Hub [1/3]", "Teleport ke Start Job...", 2)
    tp(COORDS.Start)
    task.wait(1.5)

    pcall(function() ReplicatedStorage.NetworkContainer.RemoteEvents.Job:FireServer("Truck") end)

    local startPrompt = nil
    local startTime = tick()
    while (tick() - startTime) < 3.5 do
        startPrompt = getNearestPrompt(20)
        if startPrompt then break end
        task.wait(0.2)
    end

    for i = 1, 5 do firePromptOrKey(Enum.KeyCode.E) task.wait(0.2) end
    task.wait(1.5)

    if not AutoTruckEnabled then return false end

    notify("Keren Hub [2/3]", "Teleport & SPAWN TRUCK...", 2)
    tp(COORDS.Spawn)
    task.wait(1.2)
    for i = 1, 3 do firePromptOrKey(Enum.KeyCode.F) task.wait(0.3) end
    task.wait(2.0)

    if not AutoTruckEnabled then return false end

    notify("Keren Hub [3/3]", "Teleport & DRIVE SEAT...", 2)
    tp(COORDS.Drive)
    task.wait(1.2)
    for i = 1, 3 do firePromptOrKey(Enum.KeyCode.E) task.wait(0.3) end
    task.wait(1.5)
    
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.SeatPart then
        notify("Keren Hub ✅", "Berhasil Naik Truk! Persiapan Lolos.", 3)
        return true
    else
        notify("Keren Hub ❌", "Luput/Gagal Naik Truk! Reset dari Start...", 2)
        return false
    end
end

-- LOOPING AUTO FARM
local function startFarmLoop()
    if farmThread then task.cancel(farmThread) end
    
    farmThread = task.spawn(function()
        while AutoTruckEnabled do
            detectedDestinationCoords = nil
            local lockedDestination = nil
            local preparationSuccess = false
            local attemptCount = 0

            while not preparationSuccess and AutoTruckEnabled do
                attemptCount = attemptCount + 1
                notify("Keren Hub 🔄", "Persiapan Route #" .. attemptCount, 2)
                preparationSuccess = tryFullPreparationSequence()
                if not preparationSuccess then task.wait(1.5) end
            end

            if not AutoTruckEnabled then break end

            notify("Keren Hub 🚚💨", "Persiapan Selesai! Menunggu Sniffer/Otw...", 3)

            local preDelay = 0
            while preDelay < 30 do
                if not AutoTruckEnabled then break end
                if SelectedMode == "Auto (Sniffer)" and detectedDestinationCoords and not lockedDestination then
                    lockedDestination = detectedDestinationCoords
                end
                task.wait(1)
                preDelay = preDelay + 1
            end
            if not AutoTruckEnabled then break end

            local targetRuko = nil
            if SelectedMode == "Auto (Sniffer)" then
                targetRuko = lockedDestination or detectedDestinationCoords
            else
                targetRuko = DESTINATION_DATABASE[ManualCityTarget]
            end

            if not targetRuko then
                targetRuko = DESTINATION_DATABASE[ManualCityTarget] or DESTINATION_DATABASE["surabaya"]
            end

            tpDestination(targetRuko)
            if not AutoTruckEnabled then break end
            task.wait(2.0)
        end
    end)
end

-- ELEMENT UI CONTROL
MainSection:Toggle({
    Title = "Auto Farm Truck Jatim",
    Desc = "Jalan otomatis, antar kargo aman",
    Value = false,
    Callback = function(State)
        AutoTruckEnabled = State
        NoclipEnabled = State 
        
        if State then
            showOverlay()
            notify("Jatim Truck Farm", "Auto Farm Aktif!", 2)
            startFarmLoop()
        else
            hideOverlay()
            notify("Jatim Truck Farm", "Auto Farm Dimatikan.", 2)
            if farmThread then
                task.cancel(farmThread)
                farmThread = nil
            end
        end
    end
})

MainSection:Dropdown({
    Title = "Mode Tujuan Rute",
    Values = {"Auto (Sniffer)", "Manual (Pilih Kota)"},
    Value = "Auto (Sniffer)",
    Callback = function(Option)
        SelectedMode = Option
        notify("Mode Diubah", "Mode: " .. tostring(Option), 2)
    end
})

MainSection:Dropdown({
    Title = "Pilih Kota Tujuan (Jika Manual)",
    Values = {"surabaya", "sidoarjo", "ngawi", "kediri", "malang"},
    Value = "surabaya",
    Callback = function(Option)
        ManualCityTarget = Option:lower()
        notify("Kota Dipilih", "Target Manual: " .. Option:upper(), 2)
    end
})

SettingsSection:Toggle({
    Title = "Black Screen Overlay",
    Desc = "Layar hitam pekat saat auto-farm menyala",
    Value = false,
    Callback = function(State)
        BlackScreenEnabled = State
        if State and AutoTruckEnabled then showOverlay() else hideOverlay() end
        notify("Black Screen", "Status: " .. (State and "Aktif" or "Mati"), 2)
    end
})

SettingsSection:Input({
    Title = "Durasi Perjalanan Ruko (Detik)",
    Placeholder = "Contoh: 10",
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            TweenDuration = num
            notify("Durasi Diubah", "Waktu jalan ruko diset: " .. num .. " detik", 2)
        end
    end
})

SettingsSection:Toggle({
    Title = "Anti-AFK",
    Desc = "Mencegah agar tidak ke-kick otomatis oleh server",
    Value = false,
    Callback = function(State)
        AntiAfkEnabled = State
        notify("Anti-AFK", State and "Anti-AFK Diaktifkan!" or "Anti-AFK Dimatikan.", 2)
    end
})

notify("Keren Hub Loaded", "Universal Money Sniffer Aktif! Cek Tab Stats 🔥", 4)
