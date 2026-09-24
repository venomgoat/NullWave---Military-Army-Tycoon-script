-- =========================================================
-- NullWave — Military Army Tycoon Edition
-- made by zetronixxx61 (discord: zetronixxx61)
-- =========================================================

local Players             = game:GetService("Players")
local UserInputService    = game:GetService("UserInputService")
local RunService          = game:GetService("RunService")
local VirtualUser         = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace           = game:GetService("Workspace")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local TeleportService     = game:GetService("TeleportService")
local HttpService         = game:GetService("HttpService")
local player              = Players.LocalPlayer

-- =========================================================
-- REMOTES
-- =========================================================
local Events = ReplicatedStorage:WaitForChild("Events", 60)
local RebirthRemote, UpgradeBarrackRemote, ChooseBarrackRemote, BuyChosenBarrackRm

if Events then
    RebirthRemote        = Events:WaitForChild("Rebirth", 30)
    UpgradeBarrackRemote = Events:WaitForChild("UpgradeBarrack", 30)
    ChooseBarrackRemote  = Events:WaitForChild("ChooseBarrack", 30)
    BuyChosenBarrackRm   = Events:WaitForChild("BuyChosenBarrack", 30)
end

if not player.Character then
    player.CharacterAdded:Wait()
end
task.wait(2)
print("[NullWave] Game loaded, ready")

-- =========================================================
-- OBSIDIAN LOADER
-- =========================================================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "NullWave",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
})

local Tabs = {
    Main     = Window:AddTab("Main", "house"),
    Tycoon   = Window:AddTab("Tycoon", "coins"),
    Combat   = Window:AddTab("Combat", "crosshair"),
    Movement = Window:AddTab("Movement", "activity"),
    Debug    = Window:AddTab("Debug", "search"),
    Settings = Window:AddTab("UI Settings", "settings"),
}

local settingsOK = pcall(function()
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    ThemeManager:SetFolder("NullWave")
    SaveManager:SetFolder("NullWave/Configs")
    SaveManager:BuildConfigSection(Tabs.Settings)
    ThemeManager:ApplyToTab(Tabs.Settings)
end)

if not settingsOK then
    local FB = Tabs.Settings:AddLeftGroupbox("Menu")
    FB:AddButton("Unload UI", function() pcall(function() Library:Unload() end) end)
end

pcall(function() Library.ToggleKeybind = Enum.KeyCode.RightShift end)

-- =========================================================
-- NOTIFICATION CLEANUP
-- =========================================================
task.spawn(function()
    for _, parent in ipairs({game:GetService("CoreGui"), player:FindFirstChild("PlayerGui")}) do
        if parent then
            for _, obj in ipairs(parent:GetChildren()) do
                if obj:IsA("ScreenGui") and obj.Name:lower():find("notif") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end
end)

local NOTIFICATIONS_ENABLED = false
local originalNotify = Library.Notify
Library.Notify = function(...)
    if NOTIFICATIONS_ENABLED then return originalNotify(...) end
    return nil
end

-- =========================================================
-- CONFIG
-- =========================================================
local REBIRTH_COST_PER_LEVEL = 250000

-- =========================================================
-- STATE
-- =========================================================
local destroyed  = false
local afkEnabled = true

local infiniteJumpEnabled = false
local spaceWasDown        = false
local noclipEnabled       = false
local speedValue          = 16
local jumpPowerValue      = 50
local fovValue            = 70

local autoCollectEnabled  = false
local collectCooldown     = 1
local lastCollectTime     = 0

local autoBuyEnabled      = false
local buyCooldown         = 2
local lastBuyTime         = 0

local autoUpgradeEnabled  = false
local upgradeCooldown     = 3
local lastUpgradeTime     = 0

local autoRebirthEnabled  = false
local rebirthCheckDelay   = 5
local lastRebirthCheck    = 0

local autoStealEnabled    = false
local stealCooldown       = 120
local lastStealTime       = 0

local infiniteAmmoEnabled = false
local rapidFireEnabled    = false
local autoReloadEnabled   = false
local autoReloadThreshold = 10
local lastReloadTime      = 0
local rapidFireDelay      = 0.05

local maxAmmoPerTool = {}

-- =========================================================
-- TROOPS
-- =========================================================
local ALL_TROOPS = {
    "Pistol Squad", "Bizon Squad", "Grenade Assault Squad",
    "Breacher Squad", "Assault Squad", "Anti-Tank Squad",
    "Riot Squad", "Machine Gun Squad", "Elite Squad",
    "Grenade Launcher Squad", "Flamethrower Squad", "Intervention Sniper",
    "Mafia Squad", "SMG Squad", "Demolition Squad", "Sniper Squad", "Rifle Squad",
}

local function troopToRemoteFormat(name)
    return (name:gsub("%s+", ""))
end

-- =========================================================
-- HELPERS
-- =========================================================
local function getHumanoid()
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    return hum
end

local function getHRP()
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not hrp.Parent then return nil end
    return hrp
end

local function waitForMainUi(timeout)
    timeout = timeout or 60
    local start = tick()
    while tick() - start < timeout do
        local pg = player:FindFirstChild("PlayerGui")
        if pg then
            local ui = pg:FindFirstChild("MainUi")
            if ui then return ui end
        end
        task.wait(0.5)
    end
    return nil
end

local function getMainUi()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    return pg:FindFirstChild("MainUi")
end

local function readHudAmmo()
    local mainUi = getMainUi()
    if not mainUi then return nil end
    local ui = mainUi:FindFirstChild("Ui")
    if not ui then return nil end
    local hud = ui:FindFirstChild("Hud")
    if not hud then return nil end
    local gunStats = hud:FindFirstChild("GunStatsFrame")
    if not gunStats then return nil end
    local ammoLabel = gunStats:FindFirstChild("AmmoLeftText")
    if not ammoLabel or not ammoLabel:IsA("TextLabel") then return nil end
    return tonumber(ammoLabel.Text) or nil
end

local function getCash()
    local mainUi = getMainUi()
    if not mainUi then return 0 end
    local best = 0
    for _, obj in ipairs(mainUi:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text then
            local clean = obj.Text:gsub(",", ""):gsub("%$", "")
            local num = tonumber(clean)
            if num and num > best then
                best = num
            end
        end
    end
    return best
end

local function getRebirthInfo()
    local mainUi = getMainUi()
    if not mainUi then return REBIRTH_COST_PER_LEVEL, 0 end

    local costLabel = nil
    for _, obj in ipairs(mainUi:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text
           and obj.Text:lower():find("rebirth cost") then
            costLabel = obj
            break
        end
    end

    if not costLabel then return REBIRTH_COST_PER_LEVEL, 0 end

    local parsedCost = nil
    local costText = costLabel.Text
    local moneyStr, suffix = costText:match("Rebirth Cost:%s*%$([%d%.]+)([KMB]?)")
    if moneyStr then
        local n = tonumber(moneyStr)
        if n then
            if suffix == "K" then n = n * 1000 end
            if suffix == "M" then n = n * 1000000 end
            if suffix == "B" then n = n * 1000000000 end
            parsedCost = n
        end
    end

    local parent = costLabel.Parent
    local rebirths = 0
    if parent then
        for _, sibling in ipairs(parent:GetDescendants()) do
            if sibling:IsA("TextLabel") and sibling.Text then
                local n = sibling.Text:match("Rebirths:%s*(%d+)")
                if n then
                    rebirths = tonumber(n) or 0
                    break
                end
            end
        end
    end

    local cost = parsedCost or ((rebirths + 1) * REBIRTH_COST_PER_LEVEL)
    return cost, rebirths
end

-- =========================================================
-- ATM
-- =========================================================
local function findATMCollectors()
    local found = {}
    local map = Workspace:FindFirstChild("Map")
    if not map then return found end
    local tycoonsFolder = map:FindFirstChild("Tycoons")
    if not tycoonsFolder then return found end

    for _, tycoon in ipairs(tycoonsFolder:GetChildren()) do
        local unlockables = tycoon:FindFirstChild("Unlockables")
        if unlockables then
            local atm = unlockables:FindFirstChild("ATM")
            if atm then
                local base = atm:FindFirstChild("Base")
                local part = (base and base:IsA("BasePart")) and base
                          or atm:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    table.insert(found, {
                        part = part,
                        ownerId = tonumber(tycoon.Name) or tycoon.Name,
                        tycoonName = tycoon.Name,
                    })
                end
            end
        end
    end
    return found
end

local function sortCollectorsByDistance(collectors, fromPos)
    local out = {}
    for _, c in ipairs(collectors) do
        if c.part and c.part.Parent then
            table.insert(out, {
                part = c.part,
                ownerId = c.ownerId,
                tycoonName = c.tycoonName,
                dist = (c.part.Position - fromPos).Magnitude,
            })
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

-- =========================================================
-- BUY PADS
-- =========================================================
local function parseMoneyText(txt)
    if not txt then return nil end
    if txt:find("R%$") or txt:lower():find("robux") then return nil end
    local numStr, suffix = txt:match("%$([%d%.]+)([KMB]?)")
    if not numStr then return nil end
    local n = tonumber(numStr)
    if not n then return nil end
    if suffix == "K" then n = n * 1000 end
    if suffix == "M" then n = n * 1000000 end
    if suffix == "B" then n = n * 1000000000 end
    return n
end

local function findBuyPads()
    local found = {}
    local map = Workspace:FindFirstChild("Map")
    if not map then return found end
    local tycoonsFolder = map:FindFirstChild("Tycoons")
    if not tycoonsFolder then return found end

    local myTycoon = tycoonsFolder:FindFirstChild(tostring(player.UserId))
    if not myTycoon then return found end

    for _, obj in ipairs(myTycoon:GetDescendants()) do
        if obj:IsA("BasePart") then
            local fullName = obj:GetFullName()
            local lowerName = fullName:lower()

            local skip = false
            if lowerName:find("dropped") then skip = true end
            if lowerName:find(".atm") then skip = true end

            if not skip then
                local inButton = false
                local p = obj
                for _ = 1, 5 do
                    p = p.Parent
                    if not p or p == myTycoon then break end
                    if p.Name:lower():find("button") then
                        inButton = true
                        break
                    end
                end

                if inButton then
                    local bestPrice = nil
                    local billboardFound = nil

                    for _, child in ipairs(obj:GetChildren()) do
                        if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
                            for _, d in ipairs(child:GetDescendants()) do
                                if d:IsA("TextLabel") and d.Text then
                                    local price = parseMoneyText(d.Text)
                                    if price and (not bestPrice or price < bestPrice) then
                                        bestPrice = price
                                        billboardFound = child
                                    end
                                end
                            end
                        end
                    end

                    if bestPrice then
                        table.insert(found, {
                            part = obj,
                            price = bestPrice,
                            billboard = billboardFound,
                        })
                    end
                end
            end
        end
    end

    return found
end

-- =========================================================
-- TOUCH HELPER
-- =========================================================
local function touchPart(target)
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() firetouchinterest(p, target, 0) end)
        end
    end
    task.wait(0.03)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() firetouchinterest(p, target, 1) end)
        end
    end

    for _, d in ipairs(target:GetDescendants()) do
        if d:IsA("ClickDetector") then
            pcall(function() fireclickdetector(d) end)
        end
    end
    local topCd = target:FindFirstChildOfClass("ClickDetector")
    if topCd then
        pcall(function() fireclickdetector(topCd) end)
    end

    local origCF = hrp.CFrame
    local targetCF = CFrame.new(target.Position + Vector3.new(0, 3, 0))
    pcall(function()
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
        hrp.CFrame = targetCF
    end)
    task.wait(0.25)
    pcall(function()
        hrp.CFrame = targetCF
        hrp.Velocity = Vector3.zero
    end)
    task.wait(0.1)
    pcall(function()
        hrp.CFrame = origCF
        hrp.Velocity = Vector3.zero
    end)

    return true
end

-- =========================================================
-- UI CLICK
-- =========================================================
local function clickUIButton(btn)
    if not btn or not btn.Parent then return false end
    pcall(function() btn:Activate() end)
    pcall(function()
        local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait(0.03)
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
    return true
end

local function findUpgradeBarrackPanel()
    local mainUi = getMainUi()
    if not mainUi then return nil end
    for _, obj in ipairs(mainUi:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text
           and obj.Text:lower():find("upgrade barrack") then
            local p = obj.Parent
            while p and not p:IsA("Frame") and p ~= mainUi do
                p = p.Parent
            end
            if p and p:IsA("Frame") then
                return p.Parent or p
            end
        end
    end
    return nil
end

local function findTroopCard(troopName)
    local panel = findUpgradeBarrackPanel()
    if not panel then return nil end
    local target = troopName:lower()
    for _, obj in ipairs(panel:GetDescendants()) do
        if (obj:IsA("ImageButton") or obj:IsA("TextButton")) and obj.Visible then
            for _, d in ipairs(obj:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text then
                    if d.Text:lower():find(target, 1, true) then
                        return obj
                    end
                end
            end
        end
    end
    return nil
end

local function findGreenUpgradeButton()
    local panel = findUpgradeBarrackPanel()
    if not panel then return nil end
    for _, obj in ipairs(panel:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
            local txt = obj.Text or ""
            if txt:find("%$") and not txt:lower():find("equip") then
                local c = obj.BackgroundColor3
                if c.G > 0.5 and c.R < 0.6 then
                    return obj
                end
            end
        end
    end
    return nil
end

-- =========================================================
-- RELOAD KEY
-- =========================================================
local R_KEY_CODE = 0x52

local function pressReload()
    pcall(function()
        if keypress and keyrelease then
            keypress(R_KEY_CODE)
            task.wait(0.02)
            keyrelease(R_KEY_CODE)
        else
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        end
    end)
end

local function forceReleaseR()
    pcall(function()
        if keyrelease then
            keyrelease(R_KEY_CODE)
        end
    end)
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end)
end

-- =========================================================
-- INFINITE JUMP
-- =========================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Space then
        if not spaceWasDown then
            spaceWasDown = true
            if infiniteJumpEnabled then
                local hum = getHumanoid()
                if hum then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                end
            end
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then spaceWasDown = false end
end)

-- =========================================================
-- SPEED / JUMP POWER / FOV
-- =========================================================
player.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = speedValue
        pcall(function() hum.UseJumpPower = true end)
        hum.JumpPower = jumpPowerValue
    end
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = fovValue end
end)

RunService.Heartbeat:Connect(function()
    if destroyed then return end
    local hum = getHumanoid()
    if not hum then return end
    if hum.WalkSpeed ~= speedValue then hum.WalkSpeed = speedValue end
    if hum.JumpPower ~= jumpPowerValue then
        if hum.UseJumpPower == false then
            pcall(function() hum.UseJumpPower = true end)
        end
        hum.JumpPower = jumpPowerValue
    end
    local cam = workspace.CurrentCamera
    if cam and cam.FieldOfView ~= fovValue then
        cam.FieldOfView = fovValue
    end
end)

-- =========================================================
-- NOCLIP
-- =========================================================
RunService.Stepped:Connect(function()
    if destroyed or not noclipEnabled then return end
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end)

-- =========================================================
-- RAPID FIRE (spams Tool:Activate + R)
-- =========================================================
task.spawn(function()
    while not destroyed do
        task.wait(0.01)
        if not rapidFireEnabled then continue end

        local char = player.Character
        if not char then continue end
        local tool = char:FindFirstChildWhichIsA("Tool")
        if not tool then continue end

        local now = tick()
        if now - lastReloadTime < rapidFireDelay then continue end
        lastReloadTime = now

        -- Fire + reload in same tick
        pcall(function() tool:Activate() end)
        pressReload()
    end
end)

-- =========================================================
-- INSTANT RELOAD (spams R when mag isn't full)
-- =========================================================
task.spawn(function()
    while not destroyed do
        task.wait(0.02)
        if not infiniteAmmoEnabled and not autoReloadEnabled then continue end

        local char = player.Character
        if not char then continue end
        local tool = char:FindFirstChildWhichIsA("Tool")
        if not tool then continue end

        local ammo = readHudAmmo()
        if ammo == nil then continue end

        local now = tick()
        local toolName = tool.Name

        if not maxAmmoPerTool[toolName] or ammo > maxAmmoPerTool[toolName] then
            maxAmmoPerTool[toolName] = ammo
        end
        local maxAmmo = maxAmmoPerTool[toolName]

        if infiniteAmmoEnabled then
            if ammo < maxAmmo then
                if now - lastReloadTime > 0.05 then
                    lastReloadTime = now
                    pressReload()
                end
            end
        end

        if autoReloadEnabled then
            if ammo <= autoReloadThreshold and now - lastReloadTime > 1 then
                lastReloadTime = now
                pressReload()
            end
        end
    end
end)

-- =========================================================
-- AUTO COLLECT
-- =========================================================
task.spawn(function()
    while not destroyed do
        task.wait(0.3)
        if not autoCollectEnabled then continue end
        if not getMainUi() then waitForMainUi(30) end

        local now = tick()
        if now - lastCollectTime < collectCooldown then continue end
        lastCollectTime = now

        local hrp = getHRP()
        if not hrp then continue end

        local atms = findATMCollectors()
        if #atms == 0 then continue end

        local myIdStr = tostring(player.UserId)
        for _, atm in ipairs(atms) do
            if tostring(atm.ownerId) == myIdStr then
                print("[NullWave] Auto Collect → YOUR ATM")
                touchPart(atm.part)
                break
            end
        end
    end
end)

-- =========================================================
-- AUTO BUY
-- =========================================================
task.spawn(function()
    while not destroyed do
        task.wait(0.5)
        if not autoBuyEnabled then continue end
        if not getMainUi() then waitForMainUi(30) end

        local now = tick()
        if now - lastBuyTime < buyCooldown then continue end
        lastBuyTime = now

        local cash = getCash()
        local pads = findBuyPads()
        if #pads == 0 then continue end

        table.sort(pads, function(a, b) return a.price < b.price end)

        local target = nil
        for _, pad in ipairs(pads) do
            if pad.price <= cash then
                target = pad
                break
            end
        end

        if not target then continue end

        print("[NullWave] Auto Buy → " .. target.part.Name .. " ($" .. target.price .. ")")
        touchPart(target.part)
    end
end)

-- =========================================================
-- DROPDOWN
-- =========================================================
local troopDropdownOption

local function getSelectedTroops()
    if not troopDropdownOption then return {} end
    local val
    pcall(function()
        val = troopDropdownOption.Value
    end)
    if type(val) ~= "table" then return {} end
    local out = {}
    for k, v in pairs(val) do
        if type(k) == "string" and v == true then
            table.insert(out, k)
        elseif type(k) == "number" and type(v) == "string" then
            table.insert(out, v)
        end
    end
    local ordered = {}
    for _, troopName in ipairs(ALL_TROOPS) do
        for _, sel in ipairs(out) do
            if sel == troopName then
                table.insert(ordered, troopName)
                break
            end
        end
    end
    return ordered
end

-- =========================================================
-- AUTO UPGRADE
-- =========================================================
local function tryUpgradeRemote(remoteArg)
    if ChooseBarrackRemote then
        pcall(function() ChooseBarrackRemote:FireServer(remoteArg) end)
        print("  → ChooseBarrack(\"" .. remoteArg .. "\")")
    end
    task.wait(0.5)
    if UpgradeBarrackRemote then
        pcall(function() UpgradeBarrackRemote:FireServer(remoteArg) end)
        print("  → UpgradeBarrack(\"" .. remoteArg .. "\")")
    end
end

local function tryUpgradeUI(troopName)
    local panel = findUpgradeBarrackPanel()
    if not panel then return false end
    local card = findTroopCard(troopName)
    if card then
        clickUIButton(card)
        task.wait(0.3)
    end
    local greenBtn = findGreenUpgradeButton()
    if not greenBtn then return false end
    clickUIButton(greenBtn)
    return true
end

task.spawn(function()
    while not destroyed do
        task.wait(0.5)
        if not autoUpgradeEnabled then continue end
        if not getMainUi() then waitForMainUi(30) end

        local selected = getSelectedTroops()
        if #selected == 0 then continue end

        local now = tick()
        if now - lastUpgradeTime < upgradeCooldown then continue end
        lastUpgradeTime = now

        local targetTroop = selected[1]
        if not targetTroop then continue end

        local remoteArg = troopToRemoteFormat(targetTroop)
        local cashBefore = getCash()

        print("[NullWave] Auto Upgrade: " .. targetTroop .. " (cash: " .. cashBefore .. ")")
        tryUpgradeRemote(remoteArg)

        task.wait(2)
        local cashAfter = getCash()
        if cashAfter < cashBefore then
            print("  ✓ Success (cash → " .. cashAfter .. ")")
        else
            tryUpgradeUI(targetTroop)
        end
    end
end)

-- =========================================================
-- AUTO REBIRTH
-- =========================================================
task.spawn(function()
    while not destroyed do
        task.wait(1)
        if not autoRebirthEnabled then continue end
        if not getMainUi() then waitForMainUi(30) end

        local now = tick()
        if now - lastRebirthCheck < rebirthCheckDelay then continue end
        lastRebirthCheck = now

        local cash = getCash()
        local cost = getRebirthInfo()

        if cash >= cost then
            print("[NullWave] Auto Rebirth (cash=" .. cash .. " cost=" .. cost .. ")")
            if RebirthRemote then
                pcall(function() RebirthRemote:FireServer() end)
            end
            task.wait(3)
        end
    end
end)

-- =========================================================
-- AUTO STEAL
-- =========================================================
task.spawn(function()
    while not destroyed do
        task.wait(2)
        if not autoStealEnabled then continue end
        if not getMainUi() then waitForMainUi(30) end

        local now = tick()
        if now - lastStealTime < stealCooldown then continue end
        lastStealTime = now

        local hrp = getHRP()
        if not hrp then continue end

        local atms = findATMCollectors()
        if #atms == 0 then continue end

        local myIdStr = tostring(player.UserId)
        local others = {}
        for _, atm in ipairs(atms) do
            if tostring(atm.ownerId) ~= myIdStr then
                table.insert(others, atm)
            end
        end
        if #others == 0 then continue end

        local sorted = sortCollectorsByDistance(others, hrp.Position)

        for i = 1, #sorted do
            local target = sorted[i]
            if not target then break end
            print("[NullWave] Auto Steal → " .. target.tycoonName)
            touchPart(target.part)
            if destroyed or not autoStealEnabled then break end
            task.wait(0.3)
        end
    end
end)

-- =========================================================
-- SERVER HOP / REJOIN
-- =========================================================
local function serverHop()
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local body
    pcall(function() body = game:HttpGet(url) end)
    if not body then return end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or not decoded or not decoded.data then return end
    for _, s in ipairs(decoded.data) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            print("[NullWave] Server Hop → " .. s.id)
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player) end)
            return
        end
    end
end

local function rejoin()
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end

-- =========================================================
-- SPY
-- =========================================================
local spyEnabled = false
local origNamecall

local function startSpy()
    if spyEnabled then return end
    spyEnabled = true
    origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and (self == UpgradeBarrackRemote
            or self == ChooseBarrackRemote or self == BuyChosenBarrackRm) then
            local args = {...}
            print("[SPY] " .. self.Name .. " (" .. #args .. " args)")
            for i, a in ipairs(args) do
                print("   [" .. i .. "] " .. typeof(a) .. " = " .. tostring(a))
            end
        end
        return origNamecall(self, ...)
    end)
end

local function stopSpy()
    if not spyEnabled then return end
    spyEnabled = false
    if origNamecall then
        pcall(function() hookmetamethod(game, "__namecall", origNamecall) end)
        origNamecall = nil
    end
end

-- =========================================================
-- MAIN TAB
-- =========================================================
local AFKGroup = Tabs.Main:AddLeftGroupbox("Anti-AFK")
AFKGroup:AddToggle("AFKEnabled", {
    Text = "Anti-AFK", Default = true,
    Callback = function(v) afkEnabled = v end,
})

local SessionGroup = Tabs.Main:AddLeftGroupbox("Session")
SessionGroup:AddButton("Server Hop", function() serverHop() end)
SessionGroup:AddButton("Rejoin", function() rejoin() end)

local CameraGroup = Tabs.Main:AddLeftGroupbox("Camera")
CameraGroup:AddButton("Fix Camera", function()
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
    pcall(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = hum
        local cf = cam.CFrame
        local look = cf.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude > 0.01 then
            cam.CFrame = CFrame.lookAt(cf.Position, cf.Position + flat.Unit)
        end
    end)
    local hum = getHumanoid()
    if hum then
        pcall(function()
            hum.PlatformStand = false
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
        task.wait(0.05)
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end
end)

local InfoGroup = Tabs.Main:AddRightGroupbox("Info")
InfoGroup:AddLabel("NullWave")
InfoGroup:AddLabel("by discord: zetronixxx61")
InfoGroup:AddLabel("Menu: RightShift")

-- =========================================================
-- TYCOON TAB
-- =========================================================
local CollectGroup = Tabs.Tycoon:AddLeftGroupbox("Auto Collect")
CollectGroup:AddToggle("AutoCollect", {
    Text = "Auto Collect", Default = false,
    Tooltip = "Goes to YOUR ATM",
    Callback = function(v)
        autoCollectEnabled = v
        if v then lastCollectTime = 0 end
    end,
})
CollectGroup:AddSlider("CollectCooldown", {
    Text = "Cooldown", Default = 1, Min = 1, Max = 10, Rounding = 1, Suffix = "s",
    Callback = function(v) collectCooldown = v end,
})

local BuyGroup = Tabs.Tycoon:AddLeftGroupbox("Auto Buy")
BuyGroup:AddToggle("AutoBuy", {
    Text = "Auto Buy", Default = false,
    Tooltip = "Teleports to buy pads",
    Callback = function(v)
        autoBuyEnabled = v
        if v then lastBuyTime = 0 end
    end,
})
BuyGroup:AddSlider("BuyCooldown", {
    Text = "Cooldown", Default = 2, Min = 1, Max = 10, Rounding = 1, Suffix = "s",
    Callback = function(v) buyCooldown = v end,
})

local UpgradeGroup = Tabs.Tycoon:AddRightGroupbox("Auto Upgrade")
UpgradeGroup:AddToggle("AutoUpgrade", {
    Text = "Auto Upgrade", Default = false,
    Callback = function(v)
        autoUpgradeEnabled = v
        if v then lastUpgradeTime = 0 end
    end,
})
UpgradeGroup:AddSlider("UpgradeCooldown", {
    Text = "Cooldown", Default = 3, Min = 1, Max = 10, Rounding = 1, Suffix = "s",
    Callback = function(v) upgradeCooldown = v end,
})

troopDropdownOption = UpgradeGroup:AddDropdown("TroopPriority", {
    Text = "Priority troops",
    Values = ALL_TROOPS,
    Multi = true,
    Default = {},
    Callback = function(selected) end,
})

UpgradeGroup:AddButton("Clear Priority", function()
    pcall(function()
        if troopDropdownOption and troopDropdownOption.SetValue then
            troopDropdownOption:SetValue({})
        end
    end)
end)

local RebirthGroup = Tabs.Tycoon:AddLeftGroupbox("Auto Rebirth")
RebirthGroup:AddToggle("AutoRebirth", {
    Text = "Auto Rebirth", Default = false,
    Tooltip = "Cost = (rebirths + 1) * 250k",
    Callback = function(v)
        autoRebirthEnabled = v
        if v then lastRebirthCheck = 0 end
    end,
})
RebirthGroup:AddSlider("RebirthCheckDelay", {
    Text = "Check delay", Default = 5, Min = 1, Max = 30, Rounding = 0, Suffix = "s",
    Callback = function(v) rebirthCheckDelay = v end,
})

local StealGroup = Tabs.Tycoon:AddLeftGroupbox("Auto Steal")
StealGroup:AddToggle("AutoSteal", {
    Text = "Auto Steal", Default = false,
    Tooltip = "Robs OTHER players' ATMs",
    Callback = function(v)
        autoStealEnabled = v
        if v then lastStealTime = 0 end
    end,
})
StealGroup:AddSlider("StealCooldown", {
    Text = "Cooldown", Default = 120, Min = 120, Max = 300, Rounding = 0, Suffix = "s",
    Callback = function(v) stealCooldown = v end,
})

-- =========================================================
-- COMBAT TAB
-- =========================================================
local AmmoGroup = Tabs.Combat:AddLeftGroupbox("Ammo")

AmmoGroup:AddToggle("RapidFire", {
    Text = "⚡ Rapid Fire", Default = false,
    Tooltip = "Spams Tool:Activate + R together — interrupts reload, near-infinite fire",
    Callback = function(v)
        rapidFireEnabled = v
        if not v then forceReleaseR() end
    end,
})

AmmoGroup:AddSlider("RapidFireDelay", {
    Text = "Rapid Fire delay", Default = 0.05, Min = 0.01, Max = 0.2, Rounding = 2, Suffix = "s",
    Callback = function(v) rapidFireDelay = v end,
})

AmmoGroup:AddToggle("InfiniteAmmo", {
    Text = "Instant Reload", Default = false,
    Tooltip = "Spams R when mag isn't full",
    Callback = function(v)
        infiniteAmmoEnabled = v
        if not v then forceReleaseR() end
    end,
})

AmmoGroup:AddToggle("AutoReload", {
    Text = "Auto Reload", Default = false,
    Callback = function(v)
        autoReloadEnabled = v
        if not v then forceReleaseR() end
    end,
})

AmmoGroup:AddSlider("AutoReloadThreshold", {
    Text = "Auto Reload below", Default = 10, Min = 0, Max = 100, Rounding = 0, Suffix = "",
    Callback = function(v) autoReloadThreshold = v end,
})

local AmmoInfoGroup = Tabs.Combat:AddRightGroupbox("Info")
AmmoInfoGroup:AddLabel("⚡ Rapid Fire")
AmmoInfoGroup:AddLabel("= near-infinite fire rate")
AmmoInfoGroup:AddLabel("(spams Activate + R)")
AmmoInfoGroup:AddButton("Clear Max Ammo Cache", function()
    maxAmmoPerTool = {}
    print("[NullWave] Max ammo cache cleared")
end)

-- =========================================================
-- DEBUG TAB
-- =========================================================
local DebugGroup = Tabs.Debug:AddLeftGroupbox("Debug")

DebugGroup:AddButton("Test Read HUD Ammo", function()
    local ammo = readHudAmmo()
    local char = player.Character
    local tool = char and char:FindFirstChildWhichIsA("Tool")
    local toolName = tool and tool.Name or "none"
    print("[TEST] Tool: " .. toolName)
    print("[TEST] HUD Ammo = " .. tostring(ammo))
    print("[TEST] Cached max = " .. tostring(maxAmmoPerTool[toolName]))
end)

DebugGroup:AddButton("Test Reload (R key)", function()
    pressReload()
    print("[TEST] Pressed R")
end)

DebugGroup:AddButton("Test Tool:Activate()", function()
    local char = player.Character
    if not char then return end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if not tool then
        print("[TEST] No tool")
        return
    end
    pcall(function() tool:Activate() end)
    print("[TEST] Activated: " .. tool.Name)
end)

DebugGroup:AddButton("Force Release R Key", function()
    forceReleaseR()
    print("[TEST] R key released")
end)

DebugGroup:AddButton("Check Selected Troops", function()
    local sel = getSelectedTroops()
    print("[DEBUG] Selected troops: " .. #sel)
    for i, name in ipairs(sel) do
        print("  [" .. i .. "] " .. name)
    end
end)

DebugGroup:AddButton("Scan All ATMs", function()
    local atms = findATMCollectors()
    print("[SCAN] Found " .. #atms .. " ATMs")
    for _, atm in ipairs(atms) do
        local mine = tostring(atm.ownerId) == tostring(player.UserId)
        print("  " .. atm.part:GetFullName() .. (mine and "  ← YOURS" or ""))
    end
end)

DebugGroup:AddButton("Scan Buy Pads", function()
    local pads = findBuyPads()
    print("[SCAN] Found " .. #pads .. " buy pads:")
    for _, pad in ipairs(pads) do
        print("  " .. pad.part:GetFullName() .. " | price: " .. pad.price)
    end
end)

local DebugGroup2 = Tabs.Debug:AddRightGroupbox("Spy")
DebugGroup2:AddToggle("Spy", {
    Text = "Enable Upgrade Spy", Default = false,
    Callback = function(v)
        if v then startSpy() else stopSpy() end
    end,
})
DebugGroup2:AddButton("Fire BOTH (RifleSquad)", function()
    if ChooseBarrackRemote then
        pcall(function() ChooseBarrackRemote:FireServer("RifleSquad") end)
    end
    task.wait(0.5)
    if UpgradeBarrackRemote then
        pcall(function() UpgradeBarrackRemote:FireServer("RifleSquad") end)
    end
end)

-- =========================================================
-- MOVEMENT TAB
-- =========================================================
local JumpGroup = Tabs.Movement:AddLeftGroupbox("Jump")
JumpGroup:AddToggle("InfJump", {
    Text = "Infinite Jump", Default = false,
    Callback = function(v) infiniteJumpEnabled = v end,
})
JumpGroup:AddSlider("JumpPower", {
    Text = "Jump Power", Default = 50, Min = 50, Max = 300, Rounding = 0, Suffix = "",
    Callback = function(v)
        jumpPowerValue = v
        local hum = getHumanoid()
        if hum then
            pcall(function() hum.UseJumpPower = true end)
            hum.JumpPower = v
        end
    end,
})

local SpeedGroup = Tabs.Movement:AddLeftGroupbox("Speed")
SpeedGroup:AddSlider("WalkSpeed", {
    Text = "Walk Speed", Default = 16, Min = 16, Max = 200, Rounding = 0, Suffix = "",
    Callback = function(v)
        speedValue = v
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
    end,
})
SpeedGroup:AddButton("Reset to Default (16)", function()
    speedValue = 16
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = 16 end
end)

local MiscGroup = Tabs.Movement:AddRightGroupbox("Camera & Misc")
MiscGroup:AddSlider("FOV", {
    Text = "Camera FOV", Default = 70, Min = 70, Max = 120, Rounding = 0, Suffix = "",
    Callback = function(v)
        fovValue = v
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = v end
    end,
})
MiscGroup:AddToggle("Noclip", {
    Text = "Noclip", Default = false,
    Callback = function(v)
        noclipEnabled = v
        if not v then
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end,
})

-- =========================================================
-- KILL SCRIPT
-- =========================================================
local KillGroup = Tabs.Settings:AddRightGroupbox("Danger Zone")
KillGroup:AddButton("KILL SCRIPT", function()
    destroyed = true
    afkEnabled = false
    infiniteJumpEnabled = false
    noclipEnabled = false
    autoCollectEnabled = false
    autoBuyEnabled = false
    autoUpgradeEnabled = false
    autoRebirthEnabled = false
    autoStealEnabled = false
    infiniteAmmoEnabled = false
    rapidFireEnabled = false
    autoReloadEnabled = false
    stopSpy()
    forceReleaseR()
    spaceWasDown = false
    speedValue = 16
    jumpPowerValue = 50
    fovValue = 70

    local hum = getHumanoid()
    if hum then
        pcall(function()
            hum.PlatformStand = false
            hum.Sit = false
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.UseJumpPower = true
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
        task.wait(0.15)
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end

    local char = player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                hrp.Velocity = Vector3.zero
                hrp.RotVelocity = Vector3.zero
            end)
        end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    part.CanCollide = true
                end)
            end
        end
    end

    pcall(function()
        if Library.Toggles then
            for _, flag in ipairs({
                "InfJump", "Noclip", "AFKEnabled",
                "AutoCollect", "AutoBuy", "AutoUpgrade", "AutoRebirth", "AutoSteal",
                "InfiniteAmmo", "AutoReload", "RapidFire"
            }) do
                if Library.Toggles[flag] then
                    Library.Toggles[flag]:SetValue(false)
                end
            end
        end
        if Library.Options then
            if Library.Options.JumpPower then Library.Options.JumpPower:SetValue(50) end
            if Library.Options.WalkSpeed then Library.Options.WalkSpeed:SetValue(16) end
            if Library.Options.FOV then Library.Options.FOV:SetValue(70) end
        end
    end)

    for _, parent in ipairs({game:GetService("CoreGui"), player:FindFirstChild("PlayerGui")}) do
        if parent then
            for _, obj in ipairs(parent:GetChildren()) do
                if obj:IsA("ScreenGui") and obj.Name:lower():find("notif") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end

    pcall(function() Library:Unload() end)
    print("[NullWave] KILLED")
end)
KillGroup:AddLabel("Kills NullWave completely")

-- =========================================================
-- ANTI-AFK
-- =========================================================
player.Idled:Connect(function()
    if not afkEnabled or destroyed then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- =========================================================
-- BOOT
-- =========================================================
print("[NullWave] Military Army Tycoon loaded — by discord: zetronixxx61")
print("[NullWave] Menu: RightShift")
