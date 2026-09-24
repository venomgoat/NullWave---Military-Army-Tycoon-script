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
local GuiService          = game:GetService("GuiService")
local CollectionService   = game:GetService("CollectionService")
local player              = Players.LocalPlayer

-- =========================================================
-- REMOTES
-- =========================================================
local Events = ReplicatedStorage:WaitForChild("Events", 60)

if not Events then
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        local n = child.Name:lower()
        if child:IsA("Folder") and (n:find("event") or n:find("remote")) then
            Events = child
            break
        end
    end
end

local RebirthRemote, UpgradeBarrackRemote, ChooseBarrackRemote, BuyChosenBarrackRm

if Events then
    RebirthRemote        = Events:WaitForChild("Rebirth", 10)
    UpgradeBarrackRemote = Events:WaitForChild("UpgradeBarrack", 10)
    ChooseBarrackRemote  = Events:WaitForChild("ChooseBarrack", 10)
    BuyChosenBarrackRm   = Events:WaitForChild("BuyChosenBarrack", 10)

    if not RebirthRemote then
        for _, child in ipairs(Events:GetChildren()) do
            if child.Name:lower():find("rebirth") then
                RebirthRemote = child
                break
            end
        end
    end
    if not UpgradeBarrackRemote then
        for _, child in ipairs(Events:GetChildren()) do
            local n = child.Name:lower()
            if n:find("upgrade") and n:find("barrack") then
                UpgradeBarrackRemote = child; break
            end
        end
    end
    if not ChooseBarrackRemote then
        for _, child in ipairs(Events:GetChildren()) do
            local n = child.Name:lower()
            if n:find("choose") and n:find("barrack") then
                ChooseBarrackRemote = child; break
            end
        end
    end
    if not BuyChosenBarrackRm then
        for _, child in ipairs(Events:GetChildren()) do
            local n = child.Name:lower()
            if n:find("buy") and n:find("barrack") then
                BuyChosenBarrackRm = child; break
            end
        end
    end
end

if not player.Character then player.CharacterAdded:Wait() end
task.wait(2)
print("[NullWave] Game loaded, ready")

-- =========================================================
-- OBSIDIAN
-- =========================================================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library, ThemeManager, SaveManager

local libOk = pcall(function()
    Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
end)
if not libOk or not Library then
    error("[NullWave] Failed to load Obsidian Library — aborting")
end

pcall(function() ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))() end)
pcall(function() SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))() end)

local Window = Library:CreateWindow({
    Title = "NullWave", Center = true, AutoShow = true,
    TabPadding = 8, MenuFadeTime = 0.2,
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
local buyCooldown         = 0.5
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

local ATM_STEAL_DELAY = 0.6
local ATM_GAP_DELAY   = 0.25

local autoReloadEnabled   = false
local autoReloadThreshold = 10
local lastReloadTime      = 0

-- AIMBOT
local aimbotEnabled    = false
local aimbotKey        = Enum.KeyCode.V
local aimbotMode       = "Toggle"
local aimbotHitbox     = "Head"
local aimbotFOV        = 150
local aimbotSmoothness = 0.15
local aimbotMaxDist    = 1500
local aimbotTeam       = true
local aimbotWall       = false

-- Manual friendly keyword override
local friendlyKeyword = ""

-- TRIGGER BOT
local triggerBotEnabled   = false
local triggerBotDelay     = 100
local triggerBotRange     = 500
local triggerBotParts     = {"Head"}
local triggerBotTeam      = true
local triggerBotTolerance = 20
local triggerBotAllParts = {
    "Head", "HumanoidRootPart", "UpperTorso", "Torso",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftHand", "RightHand",
    "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
    "LeftFoot", "RightFoot",
}
local lastTriggerTime     = 0

-- FOV CIRCLE
local fovThickness    = 2
local fovColorR       = 255
local fovColorG       = 60
local fovColorB       = 60
local fovRainbow      = false
local fovRainbowSpeed = 1

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
-- CONNECTION TRACKING
-- =========================================================
local connections = {}
local function track(conn)
    table.insert(connections, conn)
    return conn
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
            if num and num > best then best = num end
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
            costLabel = obj; break
        end
    end
    if not costLabel then return REBIRTH_COST_PER_LEVEL, 0 end

    local parsedCost = nil
    local moneyStr, suffix = costLabel.Text:match("Rebirth Cost:%s*%$([%d%.]+)([KMB]?)")
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
                if n then rebirths = tonumber(n) or 0; break end
            end
        end
    end
    return parsedCost or ((rebirths + 1) * REBIRTH_COST_PER_LEVEL), rebirths
end

-- =========================================================
-- OWN-UNIT DETECTION
-- =========================================================
local ownUnitCache = setmetatable({}, {__mode = "k"})

local function modelOwnedByMe(model)
    if not model then return false end

    for _, attrName in ipairs({"Owner", "OwnerId", "UserId", "Player", "Creator", "PlayerId", "OwnerUserId"}) do
        local ok, val = pcall(function() return model:GetAttribute(attrName) end)
        if ok and val ~= nil then
            if tostring(val) == tostring(player.UserId) or tostring(val) == player.Name then
                return true
            end
        end
    end

    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, attrName in ipairs({"Owner", "OwnerId", "UserId", "Player", "Creator", "PlayerId"}) do
            local ok, val = pcall(function() return hum:GetAttribute(attrName) end)
            if ok and val ~= nil then
                if tostring(val) == tostring(player.UserId) or tostring(val) == player.Name then
                    return true
                end
            end
        end
    end

    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("ObjectValue") then
            if child.Value == player then return true end
            if child.Value and child.Value:IsA("Model") and child.Value == player.Character then return true end
        elseif child:IsA("StringValue") or child:IsA("IntValue") or child:IsA("NumberValue") then
            local v = tostring(child.Value)
            if v == tostring(player.UserId) or v == player.Name then return true end
        end
    end

    local map = workspace:FindFirstChild("Map")
    if map then
        local tys = map:FindFirstChild("Tycoons")
        if tys then
            local myT = tys:FindFirstChild(tostring(player.UserId))
            if myT and model:IsDescendantOf(myT) then return true end
        end
    end

    local p = model.Parent
    while p and p ~= workspace do
        local n = p.Name
        if n == tostring(player.UserId) or n == player.Name
           or n == tostring(player.UserId) .. "'s" or n == player.Name .. "'s"
           or n:find(tostring(player.UserId)) or n:find(player.Name) then
            return true
        end
        p = p.Parent
    end

    local modelName = model.Name
    if modelName:find(tostring(player.UserId))
       or modelName:lower():find(player.Name:lower()) then
        return true
    end

    local tags = CollectionService:GetTags(model)
    for _, tag in ipairs(tags) do
        if tag:find(tostring(player.UserId)) or tag:lower():find(player.Name:lower())
           or tag:lower():find("own") then
            return true
        end
    end

    if hum then
        local ok, team = pcall(function() return hum.Team end)
        if ok and team and team == player.Team then
            return true
        end
    end

    return false
end

local function isOwnUnit(model)
    local cached = ownUnitCache[model]
    if cached ~= nil then return cached end

    -- Manual keyword override (highest priority)
    if friendlyKeyword ~= "" then
        local kw = friendlyKeyword:lower()
        if model.Name:lower():find(kw, 1, true) then
            ownUnitCache[model] = true
            return true
        end
        local p = model.Parent
        while p and p ~= workspace do
            if p.Name:lower():find(kw, 1, true) then
                ownUnitCache[model] = true
                return true
            end
            p = p.Parent
        end
    end

    local result = modelOwnedByMe(model)
    ownUnitCache[model] = result
    return result
end

-- =========================================================
-- TARGET DETECTION
-- =========================================================
local candidateCache     = {}
local candidateCacheTime = 0
local CANDIDATE_REFRESH  = 0.1

local function gatherCandidates()
    local now = tick()
    if (now - candidateCacheTime) < CANDIDATE_REFRESH and #candidateCache > 0 then
        return candidateCache
    end
    candidateCacheTime = now

    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            table.insert(list, plr.Character)
        end
    end
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
            table.insert(list, m)
        end
    end
    candidateCache = list
    return list
end

-- Reject props — must be a real character rig
local function isRealCharacterRig(model)
    if not model:FindFirstChild("HumanoidRootPart") then return false end
    if not model:FindFirstChild("Head") then return false end
    return true
end

local function isHostile(model, teamCheck)
    if not model or model == player.Character then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    -- Must be a real rig, not a prop with a fake Humanoid
    if not isRealCharacterRig(model) then return false end

    -- Anything tagged "Unlockable" is a tycoon prop / decoration, never an enemy
    for _, t in ipairs(CollectionService:GetTags(model)) do
        if t == "Unlockable" then return false end
    end

    -- PLAYER CHARACTERS: normal team logic
    local tp = Players:GetPlayerFromCharacter(model)
    if tp then
        if teamCheck then
            if tp.Team == player.Team then return false end
            if not tp.Team or not player.Team then return false end
        end
        return true
    end

    -- NPCs: only hostile if the NAME contains "enemy" or "hostile" (substring).
    -- Your own troops are named after weapons (M4A1EliteSoldier, BizonSoldier, etc.)
    -- so they won't match. Enemy NPCs are always named like "AK-47Enemy".
    local name = model.Name:lower()
    local isEnemyName = name:find("enemy") ~= nil or name:find("hostile") ~= nil
    if not isEnemyName then return false end

    if teamCheck and isOwnUnit(model) then return false end

    return true
end

local function isVisible(model, part, wallCheck)
    if not wallCheck then return true end
    local cam = workspace.CurrentCamera
    if not cam then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character}
    params.IgnoreWater = true
    local result = workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, params)
    if not result then return true end
    return result.Instance:IsDescendantOf(model)
end

local function getFovCenter()
    local cam = workspace.CurrentCamera
    if not cam then return Vector2.new(0, 0) end
    return Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
end

local function findTarget(hitbox, fov, maxDist, wallCheck, teamCheck)
    local cam = workspace.CurrentCamera
    local hrp = getHRP()
    if not cam or not hrp then return nil end
    local center = getFovCenter()
    local best, bestScore = nil, math.huge

    for _, model in ipairs(gatherCandidates()) do
        if model ~= player.Character and model.Parent then
            if isHostile(model, teamCheck) then
                local targetPart = model:FindFirstChild(hitbox)
                    or model:FindFirstChild("Head")
                    or model.PrimaryPart
                if targetPart then
                    local dist = (targetPart.Position - hrp.Position).Magnitude
                    if dist <= maxDist then
                        local sp, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                        if onScreen and sp.Z > 0 then
                            local sd = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if sd <= fov and sd < bestScore then
                                if isVisible(model, targetPart, wallCheck) then
                                    best = targetPart
                                    bestScore = sd
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function findTargetMulti(partNames, maxDist, teamCheck)
    local cam = workspace.CurrentCamera
    local hrp = getHRP()
    if not cam or not hrp then return nil, math.huge end
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local best, bestScore = nil, math.huge

    for _, model in ipairs(gatherCandidates()) do
        if model ~= player.Character and model.Parent then
            if isHostile(model, teamCheck) then
                for _, partName in ipairs(partNames) do
                    local p = model:FindFirstChild(partName)
                    if p then
                        local dist = (p.Position - hrp.Position).Magnitude
                        if dist <= maxDist then
                            local sp, onScreen = cam:WorldToViewportPoint(p.Position)
                            if onScreen and sp.Z > 0 then
                                local sd = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                if sd < bestScore then
                                    best, bestScore = p, sd
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best, bestScore
end

-- =========================================================
-- ATM
-- =========================================================
local function findATMCollectors()
    local found = {}
    local map = Workspace:FindFirstChild("Map")
    if not map then return found end
    local tyFolder = map:FindFirstChild("Tycoons")
    if not tyFolder then return found end
    for _, tycoon in ipairs(tyFolder:GetChildren()) do
        local unlock = tycoon:FindFirstChild("Unlockables")
        if unlock then
            local atm = unlock:FindFirstChild("ATM")
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

local function sortByDist(list, fromPos)
    local out = {}
    for _, c in ipairs(list) do
        if c.part and c.part.Parent then
            table.insert(out, {
                part = c.part, ownerId = c.ownerId, tycoonName = c.tycoonName,
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
    local tyFolder = map:FindFirstChild("Tycoons")
    if not tyFolder then return found end
    local myTycoon = tyFolder:FindFirstChild(tostring(player.UserId))
    if not myTycoon then return found end

    for _, obj in ipairs(myTycoon:GetDescendants()) do
        if obj:IsA("BasePart") then
            local fn = obj:GetFullName():lower()
            local skip = fn:find("dropped") or fn:find(".atm")
            if not skip then
                local inBtn = false
                local p = obj
                for _ = 1, 5 do
                    p = p.Parent
                    if not p or p == myTycoon then break end
                    if p.Name:lower():find("button") then inBtn = true; break end
                end
                if inBtn then
                    local best, bb = nil, nil
                    for _, child in ipairs(obj:GetChildren()) do
                        if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
                            for _, d in ipairs(child:GetDescendants()) do
                                if d:IsA("TextLabel") and d.Text then
                                    local price = parseMoneyText(d.Text)
                                    if price and (not best or price < best) then
                                        best, bb = price, child
                                    end
                                end
                            end
                        end
                    end
                    if best then
                        table.insert(found, {part = obj, price = best, billboard = bb})
                    end
                end
            end
        end
    end
    return found
end

-- =========================================================
-- TOUCH
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
    if topCd then pcall(function() fireclickdetector(topCd) end) end

    local origCF = hrp.CFrame
    local targetCF = CFrame.new(target.Position + Vector3.new(0, 3, 0))
    pcall(function()
        hrp.Velocity = Vector3.zero; hrp.RotVelocity = Vector3.zero
        hrp.CFrame = targetCF
    end)
    task.wait(0.25)
    pcall(function() hrp.CFrame = targetCF; hrp.Velocity = Vector3.zero end)
    task.wait(0.1)
    pcall(function() hrp.CFrame = origCF; hrp.Velocity = Vector3.zero end)
    return true
end

-- =========================================================
-- STEAL FROM ATM
-- =========================================================
local function stealFromATM(atmPart, waitTime)
    if not atmPart or not atmPart.Parent then return false end
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local origCF = hrp.CFrame
    local targetCF = CFrame.new(atmPart.Position + Vector3.new(0, 3, 0))

    pcall(function()
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
        hrp.CFrame = targetCF
    end)

    task.wait(0.15)
    pcall(function() hrp.CFrame = targetCF; hrp.Velocity = Vector3.zero end)
    task.wait(0.15)

    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() firetouchinterest(p, atmPart, 0) end)
        end
    end
    task.wait(0.05)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() firetouchinterest(p, atmPart, 1) end)
        end
    end

    for _, d in ipairs(atmPart:GetDescendants()) do
        if d:IsA("ClickDetector") then
            pcall(function() fireclickdetector(d) end)
        end
    end
    local topCd = atmPart:FindFirstChildOfClass("ClickDetector")
    if topCd then pcall(function() fireclickdetector(topCd) end) end

    task.wait(waitTime or ATM_STEAL_DELAY)

    pcall(function()
        hrp.CFrame = origCF
        hrp.Velocity = Vector3.zero
    end)
    task.wait(0.1)

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

local function findBarrackPanel()
    local mainUi = getMainUi()
    if not mainUi then return nil end
    for _, obj in ipairs(mainUi:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text
           and obj.Text:lower():find("upgrade barrack") then
            local p = obj.Parent
            while p and not p:IsA("Frame") and p ~= mainUi do p = p.Parent end
            if p and p:IsA("Frame") then return p.Parent or p end
        end
    end
    return nil
end

local function findTroopCard(name)
    local panel = findBarrackPanel()
    if not panel then return nil end
    local t = name:lower()
    for _, obj in ipairs(panel:GetDescendants()) do
        if (obj:IsA("ImageButton") or obj:IsA("TextButton")) and obj.Visible then
            for _, d in ipairs(obj:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text and d.Text:lower():find(t, 1, true) then
                    return obj
                end
            end
        end
    end
    return nil
end

local function findGreenButton()
    local panel = findBarrackPanel()
    if not panel then return nil end
    for _, obj in ipairs(panel:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
            local c = obj.BackgroundColor3
            if c.G > 0.5 and c.R < 0.6 then return obj end
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
    pcall(function() if keyrelease then keyrelease(R_KEY_CODE) end end)
    pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game) end)
end

-- =========================================================
-- INFINITE JUMP
-- =========================================================
track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Space then
        if not spaceWasDown then
            spaceWasDown = true
            if infiniteJumpEnabled then
                local hum = getHumanoid()
                if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
            end
        end
    end
end))

track(UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then spaceWasDown = false end
end))

-- =========================================================
-- AIMBOT KEYBIND
-- =========================================================
track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == aimbotKey then
        if aimbotMode == "Toggle" then
            aimbotEnabled = not aimbotEnabled
        else
            aimbotEnabled = true
        end
        pcall(function()
            if Library.Toggles and Library.Toggles.AimbotEnabled then
                Library.Toggles.AimbotEnabled:SetValue(aimbotEnabled)
            end
        end)
    end
end))

track(UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == aimbotKey and aimbotMode == "Hold" then
        aimbotEnabled = false
        pcall(function()
            if Library.Toggles and Library.Toggles.AimbotEnabled then
                Library.Toggles.AimbotEnabled:SetValue(false)
            end
        end)
    end
end))

-- =========================================================
-- SPEED / JUMP / FOV
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
        if hum.UseJumpPower == false then pcall(function() hum.UseJumpPower = true end) end
        hum.JumpPower = jumpPowerValue
    end
    local cam = workspace.CurrentCamera
    if cam and cam.FieldOfView ~= fovValue then cam.FieldOfView = fovValue end
end)

-- =========================================================
-- NOCLIP
-- =========================================================
RunService.Stepped:Connect(function()
    if destroyed or not noclipEnabled then return end
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
    end
end)

-- =========================================================
-- AIMBOT LOOP + FOV CIRCLE
-- =========================================================
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "NullWave_FOV"
fovGui.ResetOnSpawn = false
fovGui.IgnoreGuiInset = true
fovGui.DisplayOrder = 999
local pg = player:WaitForChild("PlayerGui", 30)
if pg then
    fovGui.Parent = pg
else
    fovGui.Parent = player:WaitForChild("PlayerGui")
end

local fovCircles = {}

local function ensureCircle(name)
    if fovCircles[name] and fovCircles[name].Parent then
        return fovCircles[name]
    end
    local c = Instance.new("Frame")
    c.Name = name
    c.AnchorPoint = Vector2.new(0.5, 0.5)
    c.BackgroundTransparency = 1
    c.BorderSizePixel = 0
    c.Visible = false
    c.ZIndex = 1
    c.Parent = fovGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = c
    local stroke = Instance.new("UIStroke")
    stroke.Name = "FOVStroke"
    stroke.Color = Color3.fromRGB(fovColorR, fovColorG, fovColorB)
    stroke.Thickness = fovThickness
    stroke.Transparency = 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    stroke.Parent = c
    fovCircles[name] = c
    return c
end

local function getFovColor()
    if fovRainbow then
        local hue = (tick() * fovRainbowSpeed) % 1
        return Color3.fromHSV(hue, 1, 1)
    else
        return Color3.fromRGB(fovColorR, fovColorG, fovColorB)
    end
end

pcall(function() RunService:UnbindFromRenderStep("NullWaveAimbot") end)
RunService:BindToRenderStep("NullWaveAimbot", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if destroyed then return end
    local cam = workspace.CurrentCamera
    if not cam then return end

    if aimbotEnabled then
        local target = findTarget(aimbotHitbox, aimbotFOV, aimbotMaxDist, aimbotWall, aimbotTeam)
        if target then
            local desired = CFrame.lookAt(cam.CFrame.Position, target.Position)
            local alpha
            if aimbotSmoothness <= 0 then
                alpha = 1
            else
                local base = math.clamp(1 - aimbotSmoothness * 0.95, 0.05, 1)
                alpha = math.clamp(base * (dt * 60), 0.05, 1)
            end
            cam.CFrame = cam.CFrame:Lerp(desired, alpha)
        end
    end

    local center = getFovCenter()
    local color = getFovColor()
    if aimbotEnabled then
        local c = ensureCircle("AimbotFOV")
        local size = math.max(math.floor(aimbotFOV * 2), 40)
        c.Position = UDim2.new(0, center.X, 0, center.Y)
        c.Size     = UDim2.new(0, size, 0, size)
        c.Visible  = true
        local s = c:FindFirstChild("FOVStroke")
        if s then s.Color = color; s.Thickness = fovThickness end
    elseif fovCircles.AimbotFOV then
        fovCircles.AimbotFOV.Visible = false
    end
end)

-- =========================================================
-- TRIGGER BOT
-- =========================================================
RunService.Heartbeat:Connect(function()
    if destroyed or not triggerBotEnabled then return end
    local char = player.Character
    if not char then return end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if not tool then return end

    local now = tick()
    if now - lastTriggerTime < (triggerBotDelay / 1000) then return end

    local target, screenDist = findTargetMulti(triggerBotParts, triggerBotRange, triggerBotTeam)
    if not target then return end
    if screenDist > triggerBotTolerance then return end

    lastTriggerTime = now

    if mouse1click then
        pcall(function() mouse1click() end)
    elseif mouse1press and mouse1release then
        pcall(function() mouse1press() end)
        task.wait(0.01)
        pcall(function() mouse1release() end)
    else
        local cam = workspace.CurrentCamera
        if cam then
            local inset = GuiService:GetGuiInset()
            local sx = math.floor(cam.ViewportSize.X / 2)
            local sy = math.floor(cam.ViewportSize.Y / 2 + inset.Y)
            VirtualInputManager:SendMouseButtonEvent(sx, sy, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(sx, sy, 0, false, game, 0)
        end
    end
end)

-- =========================================================
-- AUTO RELOAD
-- =========================================================
task.spawn(function()
    while not destroyed do
        task.wait(0.1)
        if not autoReloadEnabled then continue end
        local char = player.Character
        if not char then continue end
        local tool = char:FindFirstChildWhichIsA("Tool")
        if not tool then continue end
        local ammo = readHudAmmo()
        if ammo == nil then continue end
        local now = tick()
        if ammo <= autoReloadThreshold and now - lastReloadTime > 0.5 then
            lastReloadTime = now
            pressReload()
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
        task.wait(0.1)
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
            if pad.price <= cash then target = pad; break end
        end
        if not target then continue end
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
    pcall(function() val = troopDropdownOption.Value end)
    if type(val) ~= "table" then return {} end
    local out = {}
    for k, v in pairs(val) do
        if type(k) == "string" and v == true then table.insert(out, k)
        elseif type(k) == "number" and type(v) == "string" then table.insert(out, v) end
    end
    local ordered = {}
    for _, t in ipairs(ALL_TROOPS) do
        for _, s in ipairs(out) do
            if s == t then table.insert(ordered, t); break end
        end
    end
    return ordered
end

-- =========================================================
-- AUTO UPGRADE  (pending new game system)
-- =========================================================
local function tryUpgradeRemote(arg)
    if ChooseBarrackRemote then pcall(function() ChooseBarrackRemote:FireServer(arg) end) end
    task.wait(0.5)
    if UpgradeBarrackRemote then pcall(function() UpgradeBarrackRemote:FireServer(arg) end) end
end

local function tryUpgradeUI(name)
    local panel = findBarrackPanel()
    if not panel then return false end
    local card = findTroopCard(name)
    if card then clickUIButton(card); task.wait(0.3) end
    local gb = findGreenButton()
    if not gb then return false end
    clickUIButton(gb)
    return true
end

task.spawn(function()
    while not destroyed do
        task.wait(0.5)
        if not autoUpgradeEnabled then continue end
        if not getMainUi() then waitForMainUi(30) end
        local sel = getSelectedTroops()
        if #sel == 0 then continue end
        local now = tick()
        if now - lastUpgradeTime < upgradeCooldown then continue end
        lastUpgradeTime = now
        local t = sel[1]
        if not t then continue end
        local arg = troopToRemoteFormat(t)
        local before = getCash()
        tryUpgradeRemote(arg)
        task.wait(2)
        if getCash() < before then
            -- success
        else
            tryUpgradeUI(t)
        end
    end
end)

-- =========================================================
-- AUTO REBIRTH
-- =========================================================
local rebirthPrompt = nil

local function findRebirthPrompt()
    if rebirthPrompt and rebirthPrompt.Parent then return rebirthPrompt end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local at = (obj.ActionText or ""):lower()
            local ot = (obj.ObjectText or ""):lower()
            if at:find("rebirth") or ot:find("rebirth") then
                rebirthPrompt = obj
                return obj
            end
        end
    end
    return nil
end

local function tryRebirthUI()
    local mainUi = getMainUi()
    if mainUi then
        for _, obj in ipairs(mainUi:GetDescendants()) do
            if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
                local txt = ((obj.Text or obj.Name) or ""):lower()
                if txt:find("rebirth") and not txt:find("cost") and not txt:find("info") then
                    clickUIButton(obj)
                    return true
                end
            end
        end
    end
    local prompt = findRebirthPrompt()
    if prompt and fireproximityprompt then
        pcall(function() fireproximityprompt(prompt) end)
        return true
    end
    return false
end

task.spawn(function()
    while not destroyed do
        task.wait(1)
        if not autoRebirthEnabled then continue end

        if not getMainUi() then
            waitForMainUi(30)
            if not getMainUi() then continue end
        end

        local now = tick()
        if now - lastRebirthCheck < rebirthCheckDelay then continue end
        lastRebirthCheck = now

        local cash = getCash()
        local cost = getRebirthInfo()

        if cash >= cost then
            local fired = false
            if RebirthRemote then
                pcall(function() RebirthRemote:FireServer() end)
                fired = true
            end
            if not fired then
                tryRebirthUI()
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
        local myId = tostring(player.UserId)
        local others = {}
        for _, atm in ipairs(atms) do
            if tostring(atm.ownerId) ~= myId then table.insert(others, atm) end
        end
        if #others == 0 then continue end
        for _, t in ipairs(sortByDist(others, hrp.Position)) do
            if destroyed or not autoStealEnabled then break end
            stealFromATM(t.part, ATM_STEAL_DELAY)
            task.wait(ATM_GAP_DELAY)
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
local origSpyNamecall

local function startSpy()
    if spyEnabled then return end
    spyEnabled = true
    origSpyNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and (self == UpgradeBarrackRemote
            or self == ChooseBarrackRemote or self == BuyChosenBarrackRm
            or self == RebirthRemote) then
            print("[SPY] " .. self.Name .. " (" .. select("#", ...) .. " args)")
        end
        return origSpyNamecall(self, ...)
    end))
end

local function stopSpy()
    if not spyEnabled then return end
    spyEnabled = false
    if origSpyNamecall then
        pcall(function() hookmetamethod(game, "__namecall", origSpyNamecall) end)
        origSpyNamecall = nil
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
        local char = player.Character
        if not cam or not char then return end
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
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
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
    Callback = function(v) autoCollectEnabled = v; if v then lastCollectTime = 0 end end,
})
CollectGroup:AddSlider("CollectCooldown", {
    Text = "Cooldown", Default = 1, Min = 1, Max = 10, Rounding = 1, Suffix = "s",
    Callback = function(v) collectCooldown = v end,
})

local BuyGroup = Tabs.Tycoon:AddLeftGroupbox("Auto Buy")
BuyGroup:AddToggle("AutoBuy", {
    Text = "Auto Buy", Default = false,
    Callback = function(v) autoBuyEnabled = v; if v then lastBuyTime = 0 end end,
})
BuyGroup:AddSlider("BuyCooldown", {
    Text = "Cooldown", Default = 0.5, Min = 0.5, Max = 10, Rounding = 1, Suffix = "s",
    Callback = function(v) buyCooldown = v end,
})

local UpgradeGroup = Tabs.Tycoon:AddRightGroupbox("Auto Upgrade")
UpgradeGroup:AddToggle("AutoUpgrade", {
    Text = "Auto Upgrade", Default = false,
    Callback = function(v) autoUpgradeEnabled = v; if v then lastUpgradeTime = 0 end end,
})
UpgradeGroup:AddSlider("UpgradeCooldown", {
    Text = "Cooldown", Default = 3, Min = 1, Max = 10, Rounding = 1, Suffix = "s",
    Callback = function(v) upgradeCooldown = v end,
})

troopDropdownOption = UpgradeGroup:AddDropdown("TroopPriority", {
    Text = "Priority troops", Values = ALL_TROOPS, Multi = true, Default = {},
    Callback = function(sel) end,
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
    Callback = function(v) autoRebirthEnabled = v; if v then lastRebirthCheck = 0 end end,
})
RebirthGroup:AddSlider("RebirthCheckDelay", {
    Text = "Check delay", Default = 5, Min = 1, Max = 30, Rounding = 0, Suffix = "s",
    Callback = function(v) rebirthCheckDelay = v end,
})

local StealGroup = Tabs.Tycoon:AddLeftGroupbox("Auto Steal")
StealGroup:AddToggle("AutoSteal", {
    Text = "Auto Steal", Default = false,
    Callback = function(v) autoStealEnabled = v; if v then lastStealTime = 0 end end,
})
StealGroup:AddSlider("StealCooldown", {
    Text = "Cooldown", Default = 120, Min = 120, Max = 300, Rounding = 0, Suffix = "s",
    Callback = function(v) stealCooldown = v end,
})

-- =========================================================
-- COMBAT TAB
-- =========================================================
local AimbotGroup = Tabs.Combat:AddLeftGroupbox("Aimbot")

AimbotGroup:AddToggle("AimbotEnabled", {
    Text = "Enable Aimbot", Default = false,
    Tooltip = "Rotates camera to target",
    Callback = function(v) aimbotEnabled = v end,
})

AimbotGroup:AddDropdown("AimbotKey", {
    Text = "Aimbot Key",
    Values = {"C", "V", "F", "E", "Q", "X", "Z", "LeftAlt"},
    Default = "V",
    Multi = false,
    Callback = function(v)
        if type(v) == "table" then v = v[1] end
        local map = {
            C = Enum.KeyCode.C, V = Enum.KeyCode.V, F = Enum.KeyCode.F,
            E = Enum.KeyCode.E, Q = Enum.KeyCode.Q, X = Enum.KeyCode.X,
            Z = Enum.KeyCode.Z, LeftAlt = Enum.KeyCode.LeftAlt,
        }
        aimbotKey = map[v] or Enum.KeyCode.V
    end,
})

AimbotGroup:AddDropdown("AimbotMode", {
    Text = "Aim Mode", Values = {"Toggle", "Hold"}, Default = "Toggle", Multi = false,
    Callback = function(v) if type(v) == "table" then v = v[1] end; aimbotMode = v end,
})

AimbotGroup:AddDropdown("AimbotHitbox", {
    Text = "Hitbox", Values = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, Default = "Head", Multi = false,
    Callback = function(v) if type(v) == "table" then v = v[1] end; aimbotHitbox = v end,
})

AimbotGroup:AddSlider("AimbotFOV", {
    Text = "Aimbot FOV", Default = 150, Min = 20, Max = 800, Rounding = 0, Suffix = "",
    Callback = function(v) aimbotFOV = v end,
})

AimbotGroup:AddSlider("AimbotSmoothness", {
    Text = "Smoothness", Default = 0.15, Min = 0, Max = 1, Rounding = 2, Suffix = "",
    Tooltip = "0 = instant snap, 1 = very slow",
    Callback = function(v) aimbotSmoothness = v end,
})

AimbotGroup:AddSlider("AimbotMaxDist", {
    Text = "Max Distance", Default = 1500, Min = 50, Max = 5000, Rounding = 0, Suffix = "",
    Callback = function(v) aimbotMaxDist = v end,
})

AimbotGroup:AddToggle("AimbotWall", {
    Text = "Wall Check", Default = false,
    Callback = function(v) aimbotWall = v end,
})

AimbotGroup:AddToggle("AimbotTeam", {
    Text = "Team Check", Default = true,
    Tooltip = "Won't target your own troops or same-team players",
    Callback = function(v) aimbotTeam = v end,
})

AimbotGroup:AddInput("FriendlyKeyword", {
    Text = "Friendly Keyword",
    Default = "",
    Placeholder = "name/folder that marks your troops",
    Tooltip = "Anything whose name or ancestor folder contains this is ignored",
    Callback = function(v) friendlyKeyword = v; ownUnitCache = setmetatable({}, {__mode="k"}) end,
})

-- FOV CIRCLE SETTINGS
local FovGroup = Tabs.Combat:AddRightGroupbox("FOV Circle")

FovGroup:AddSlider("FovThickness", {
    Text = "Thickness", Default = 2, Min = 1, Max = 10, Rounding = 0, Suffix = "px",
    Callback = function(v) fovThickness = v end,
})

FovGroup:AddToggle("FovRainbow", {
    Text = "Rainbow Mode", Default = false,
    Callback = function(v) fovRainbow = v end,
})

FovGroup:AddSlider("FovRainbowSpeed", {
    Text = "Rainbow Speed", Default = 1, Min = 0.1, Max = 5, Rounding = 1, Suffix = "x",
    Callback = function(v) fovRainbowSpeed = v end,
})

FovGroup:AddSlider("FovColorR", {
    Text = "Color R", Default = 255, Min = 0, Max = 255, Rounding = 0, Suffix = "",
    Callback = function(v) fovColorR = v end,
})

FovGroup:AddSlider("FovColorG", {
    Text = "Color G", Default = 60, Min = 0, Max = 255, Rounding = 0, Suffix = "",
    Callback = function(v) fovColorG = v end,
})

FovGroup:AddSlider("FovColorB", {
    Text = "Color B", Default = 60, Min = 0, Max = 255, Rounding = 0, Suffix = "",
    Callback = function(v) fovColorB = v end,
})

-- TRIGGER BOT
local TriggerGroup = Tabs.Combat:AddRightGroupbox("Trigger Bot")

TriggerGroup:AddToggle("TriggerEnabled", {
    Text = "Enable Trigger Bot", Default = false,
    Tooltip = "Fires only when crosshair is on a selected body part",
    Callback = function(v) triggerBotEnabled = v end,
})

TriggerGroup:AddDropdown("TriggerParts", {
    Text = "Target Parts",
    Values = triggerBotAllParts,
    Default = {"Head"},
    Multi = true,
    Callback = function(v)
        local out = {}
        if type(v) == "table" then
            for k, val in pairs(v) do
                if type(k) == "string" and val == true then table.insert(out, k)
                elseif type(k) == "number" and type(val) == "string" then table.insert(out, val) end
            end
        end
        local ordered = {}
        for _, name in ipairs(triggerBotAllParts) do
            for _, sel in ipairs(out) do
                if sel == name then table.insert(ordered, name); break end
            end
        end
        if #ordered > 0 then triggerBotParts = ordered end
    end,
})

TriggerGroup:AddSlider("TriggerDelay", {
    Text = "Trigger Delay", Default = 100, Min = 10, Max = 1000, Rounding = 0, Suffix = "ms",
    Callback = function(v) triggerBotDelay = v end,
})

TriggerGroup:AddSlider("TriggerRange", {
    Text = "Trigger Range", Default = 500, Min = 50, Max = 2000, Rounding = 0, Suffix = "",
    Callback = function(v) triggerBotRange = v end,
})

TriggerGroup:AddSlider("TriggerTolerance", {
    Text = "Crosshair Tolerance", Default = 20, Min = 2, Max = 100, Rounding = 0, Suffix = "px",
    Tooltip = "How close to screen-center counts as 'aiming at' the target",
    Callback = function(v) triggerBotTolerance = v end,
})

TriggerGroup:AddToggle("TriggerTeam", {
    Text = "Team Check", Default = true,
    Tooltip = "Won't fire at your own troops or same-team players",
    Callback = function(v) triggerBotTeam = v end,
})

-- AMMO
local AmmoGroup = Tabs.Combat:AddLeftGroupbox("Ammo")
AmmoGroup:AddToggle("AutoReload", {
    Text = "Auto Reload", Default = false,
    Callback = function(v) autoReloadEnabled = v; if not v then forceReleaseR() end end,
})
AmmoGroup:AddSlider("AutoReloadThreshold", {
    Text = "Auto Reload below",
    Default = 10, Min = 0, Max = 100, Rounding = 0, Suffix = "",
    Callback = function(v) autoReloadThreshold = v end,
})

-- =========================================================
-- DEBUG TAB
-- =========================================================
local DebugGroup = Tabs.Debug:AddLeftGroupbox("Debug")

DebugGroup:AddButton("Scan Hostiles", function()
    local count = 0
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model ~= player.Character then
            if isHostile(model, true) then
                count = count + 1
                print("  HOSTILE: " .. model:GetFullName())
            end
        end
    end
    print("[TEST] Total hostile: " .. count)
end)

DebugGroup:AddButton("Scan Own Units", function()
    local count = 0
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model ~= player.Character then
            if isOwnUnit(model) then
                count = count + 1
                if count <= 15 then
                    print("  OWN: " .. model:GetFullName())
                end
            end
        end
    end
    print("[TEST] Total own units detected: " .. count)
end)

DebugGroup:AddButton("Dump ALL Humanoids (full)", function()
    print("=== ALL Humanoid Models in Workspace ===")
    local n = 0
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and m ~= player.Character then
            n = n + 1
            local hum = m:FindFirstChildOfClass("Humanoid")
            local chain = {}
            local p = m.Parent
            while p and p ~= game do
                table.insert(chain, 1, p.Name)
                p = p.Parent
            end
            local path = table.concat(chain, ".") .. "." .. m.Name
            local tags = table.concat(CollectionService:GetTags(m), ",")
            local attrs = {}
            for _, a in ipairs(m:GetAttributes()) do
                local ok, v = pcall(function() return m:GetAttribute(a) end)
                if ok then table.insert(attrs, a .. "=" .. tostring(v)) end
            end
            local hrp = m:FindFirstChild("HumanoidRootPart")
            local posStr = hrp and string.format("(%.0f,%.0f,%.0f)",
                hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "no HRP"
            print(string.format("[%d] %s", n, path))
            print(string.format("     HP=%d pos=%s tags={%s}", hum.Health, posStr, tags))
            if #attrs > 0 then print("     attrs={" .. table.concat(attrs, ", ") .. "}") end
            print(string.format("     isOwn=%s  isHostile=%s",
                tostring(isOwnUnit(m)), tostring(isHostile(m, true))))
        end
    end
    print(string.format("=== Total humanoids: %d ===", n))
end)

DebugGroup:AddButton("Dump Remotes", function()
    print("[DEBUG] RebirthRemote = " .. tostring(RebirthRemote and RebirthRemote:GetFullName()))
    print("[DEBUG] UpgradeBarrackRemote = " .. tostring(UpgradeBarrackRemote and UpgradeBarrackRemote:GetFullName()))
    print("[DEBUG] ChooseBarrackRemote = " .. tostring(ChooseBarrackRemote and ChooseBarrackRemote:GetFullName()))
    print("[DEBUG] BuyChosenBarrackRm = " .. tostring(BuyChosenBarrackRm and BuyChosenBarrackRm:GetFullName()))
end)

local DebugGroup2 = Tabs.Debug:AddRightGroupbox("Spy")
DebugGroup2:AddToggle("Spy", {
    Text = "Enable Upgrade Spy", Default = false,
    Callback = function(v) if v then startSpy() else stopSpy() end end,
})

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
                    if part:IsA("BasePart") then part.CanCollide = true end
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
    autoReloadEnabled = false
    aimbotEnabled = false
    triggerBotEnabled = false
    stopSpy()
    forceReleaseR()
    spaceWasDown = false
    speedValue = 16
    jumpPowerValue = 50
    fovValue = 70

    pcall(function() RunService:UnbindFromRenderStep("NullWaveAimbot") end)

    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = {}

    pcall(function()
        if Library and Library.Toggles then
            for _, flag in ipairs({
                "InfJump", "Noclip", "AFKEnabled", "AimbotTeam",
                "AutoCollect", "AutoBuy", "AutoUpgrade", "AutoRebirth", "AutoSteal",
                "AutoReload", "AimbotEnabled", "TriggerEnabled", "TriggerTeam", "Spy"
            }) do
                if Library.Toggles[flag] then Library.Toggles[flag]:SetValue(false) end
            end
        end
    end)

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
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
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
            if part:IsA("BasePart") then pcall(function() part.CanCollide = true end) end
        end
    end

    pcall(function() if fovGui then fovGui:Destroy() end end)

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

print("[NullWave] Military Army Tycoon loaded — by discord: zetronixxx61")
print("[NullWave] Menu: RightShift")
