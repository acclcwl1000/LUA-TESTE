-- TRAINER X — Advanced Aimbot, ESP, Movement & More
-- Fixed & Optimized Version by Manus
-- Enhanced with Professional Anti-Detection Aimbot, Advanced FOV & Stealth God Mode/Heal
-- [Controls: F1 (Menu), V (Speed), B (Noclip), N (Fly), G (Protection), H (Heal), J (Ammo), K (Debug), U (Auto Heal), I (Revive)]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ===== CONFIGURATION =====
local CONF = {
    menuKey = Enum.KeyCode.F1,
    guiName = "TrainerX_Fixed",
    persistKey = "TRAINER_X_SAVED_V9", -- Updated version key
    ui = {
        bg = Color3.fromRGB(30, 30, 32),
        panel = Color3.fromRGB(42, 42, 48),
        accent = Color3.fromRGB(0, 170, 255),
        text = Color3.fromRGB(235, 235, 240),
        bad = Color3.fromRGB(255, 80, 100),
        ok = Color3.fromRGB(90, 220, 130),
        subtle = Color3.fromRGB(150, 150, 155),
    },
    -- Aimbot
    aimbotEnabled = true,
    aimPart = "Head",
    aimPriority = "Crosshair",
    aimSmoothMin = 0.08,      -- Minimum smoothness
    aimSmoothMax = 0.15,      -- Maximum smoothness
    showFOV = true,
    gravityComp = true,
    -- Advanced Aimbot Settings
    aimActivationRadius = 100, -- Activation radius in pixels
    aimStopDistance = 5,      -- Stop distance before target
    missChance = 0.05,        -- Chance to miss
    maxMissAngle = 5,         -- Maximum miss angle in degrees
    aimPreparationTime = 0.1, -- Preparation time before aiming
    aimDecayRate = 0.02,      -- Accuracy decay rate
    debugMode = false,        -- Debug mode
    -- Professional Anti-Detection Settings
    humanReactionTime = 0.15, -- Human reaction time simulation
    aimJitterAmount = 0.5,    -- Amount of aim jitter
    aimSpikeChance = 0.1,     -- Chance of aim spiking
    aimCurveVariation = 3,    -- Curve variation amount
    microCorrections = true,   -- Enable micro corrections
    recoilSimulation = true,   -- Simulate recoil control
    adaptiveSmoothness = true, -- Adaptive smoothness based on distance
    targetSwitchingDelay = 0.2, -- Delay when switching targets
    aimAssistMode = true,      -- Aim assist instead of full aimbot
    randomAimPoints = true,   -- Use random aim points on target
    -- Advanced FOV Settings
    aimFov = {
        enabled = true,
        shape = "circle",      -- circle, square, rounded
        size = 180,
        innerSize = 30,
        dynamicSize = true,    -- Changes based on target distance
        color = Color3.fromRGB(0, 170, 255),
        transparency = 0.5,
        thickness = 1.5,
        filled = false,
        adaptiveColor = true,  -- Changes color based on target health
        showDistance = true,   -- Show target distance inside FOV
        targetHighlight = true, -- Highlight target inside FOV
        smoothTransition = true, -- Smooth transition when changing size
    },
    -- Anti-Detection Settings
    antiDetection = {
        stealthMode = true,
        randomizeHealAmount = true,
        randomizeHealDelay = true,
        simulateDamageReaction = true,
        healthOscillation = true,
        healAmountRange = {min = 5, max = 25},
        healDelayRange = {min = 0.1, max = 0.5},
        healthOscillationRange = {min = 95, max = 100},
        maxHealsPerSecond = 3,
        damageReactionDelay = {min = 0.05, max = 0.2},
        healthRegenRate = 0.5,
        godModeCooldown = 300
    },
    -- ESP
    esp = {
        enabled = true,
        boxes = true,
        names = true,
        distances = true,
        healthbar = true,
        enemiesOnly = true,
        tracers = true,
        tracerThickness = 1.5,
        tracerMaxDistance = 5000,
    },
    -- Movement
    speedBoost = 100,
    flySpeed = 80,
}

-- Load saved config
local function loadConfig()
    local raw = LocalPlayer:GetAttribute(CONF.persistKey)
    if raw then
        local success, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if success and type(data) == "table" then
            for k, v in pairs(data) do
                if CONF[k] ~= nil then
                    if type(v) == "table" then
                        for k2, v2 in pairs(v) do
                            if CONF[k][k2] ~= nil then
                                CONF[k][k2] = v2
                            end
                        end
                    else
                        CONF[k] = v
                    end
                end
            end
        end
    end
end

local function saveConfig()
    local data = {}
    for k, v in pairs(CONF) do
        if type(v) == "table" then
            data[k] = {}
            for k2, v2 in pairs(v) do
                data[k][k2] = v2
            end
        else
            data[k] = v
        end
    end
    LocalPlayer:SetAttribute(CONF.persistKey, HttpService:JSONEncode(data))
end

loadConfig()

-- ===== UTILITIES =====
local function notify(msg, duration)
    -- Hidden notifications to avoid detection
    StarterGui:SetCore("SendNotification", {
        Title = "System", -- Generic title instead of "TRAINER X"
        Text = msg,
        Duration = duration or 1.5, -- Shorter duration
        Icon = "" -- No icon
    })
end

local function isEnemy(player)
    if not player or not player.Parent then return false end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    return player ~= LocalPlayer
end

-- ===== AIMBOT ENHANCEMENTS =====
-- Advanced Bezier curve calculation with multiple control points
local function calculateAdvancedBezierPoint(points, t)
    if #points == 1 then return points[1] end
    
    local newPoints = {}
    for i = 1, #points - 1 do
        newPoints[i] = points[i]:Lerp(points[i + 1], t)
    end
    
    return calculateAdvancedBezierPoint(newPoints, t)
end

-- Smart target part selection with random aim points
local function getSmarterTargetPart(character)
    if not CONF.randomAimPoints then
        local parts = {}
        if character:FindFirstChild("Head") then table.insert(parts, character.Head) end
        if character:FindFirstChild("UpperTorso") then table.insert(parts, character.UpperTorso) end
        if character:FindFirstChild("HumanoidRootPart") then table.insert(parts, character.HumanoidRootPart) end
        
        if math.random() < 0.7 and #parts > 0 then
            return parts[math.random(1, math.min(2, #parts))]
        else
            return parts[math.random(1, #parts)]
        end
    else
        -- Random aim points on target
        local targetPart = character:FindFirstChild("Head") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
        if targetPart then
            -- Create a random point within the target part
            local size = targetPart.Size
            local randomOffset = Vector3.new(
                math.random(-size.X/2, size.X/2),
                math.random(-size.Y/2, size.Y/2),
                math.random(-size.Z/2, size.Z/2)
            )
            local randomPoint = Instance.new("Part")
            randomPoint.Size = Vector3.new(0.1, 0.1, 0.1)
            randomPoint.CanCollide = false
            randomPoint.Anchored = true
            randomPoint.Transparency = 1
            randomPoint.CFrame = targetPart.CFrame * CFrame.new(randomOffset)
            randomPoint.Parent = workspace
            Debris:AddItem(randomPoint, 0.1)
            return randomPoint
        end
    end
    return character:FindFirstChild("Head")
end

-- Advanced prediction with acceleration and deceleration
local function predictPositionAdvanced(player, part)
    local BULLET_SPEED = 2000
    local GRAVITY = Workspace.Gravity
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return part.Position end

    -- Get position history for better prediction
    local history = aimbot.positionHistory[player] or {}
    if #history < 2 then
        -- Not enough history, use simple prediction
        aimbot.positionHistory[player] = {rootPart.Position, tick()}
        return part.Position + (rootPart.Velocity * 0.1)
    end
    
    -- Calculate velocity and acceleration
    local pos1, time1 = history[1], history[2]
    local pos2, time2 = rootPart.Position, tick()
    local timeDiff = time2 - time1
    
    if timeDiff > 0.5 then
        -- Too much time passed, reset history
        aimbot.positionHistory[player] = {rootPart.Position, tick()}
        return part.Position + (rootPart.Velocity * 0.1)
    end
    
    local velocity = (pos2 - pos1) / timeDiff
    local acceleration = (velocity - (aimbot.lastVelocity[player] or Vector3.new(0, 0, 0))) / timeDiff
    
    -- Update history
    table.insert(aimbot.positionHistory[player], 1, rootPart.Position)
    table.insert(aimbot.positionHistory[player], 1, tick())
    if #aimbot.positionHistory[player] > 10 then
        table.remove(aimbot.positionHistory[player])
        table.remove(aimbot.positionHistory[player])
    end
    
    aimbot.lastVelocity[player] = velocity
    
    -- Predict position with acceleration
    local origin = Camera.CFrame.Position
    local distance = (part.Position - origin).Magnitude
    if BULLET_SPEED <= 0 then return part.Position end
    local timeToTarget = distance / BULLET_SPEED
    
    -- Use quadratic prediction with acceleration
    local predictedPos = part.Position + (velocity * timeToTarget) + (0.5 * acceleration * timeToTarget^2)
    
    if CONF.gravityComp and BULLET_SPEED < 10000 then
        local drop = 0.5 * GRAVITY * timeToTarget^2
        predictedPos = predictedPos + Vector3.new(0, drop, 0)
    end
    
    return predictedPos
end

-- ===== INFINITE AMMO =====
local function refillAll()
    local function refillTool(tool)
        for _, v in ipairs(tool:GetDescendants()) do
            if (v:IsA("IntValue") or v:IsA("NumberValue")) and (v.Name:lower():find("ammo") or v.Name:lower():find("clip")) then
                if v.MaxValue then
                    v.Value = v.MaxValue
                else
                    v.Value = 9999
                end
            end
        end
    end

    if LocalPlayer.Character then
        for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                refillTool(tool)
            end
        end
    end

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                refillTool(tool)
            end
        end
    end
end

-- ===== MOVEMENT FEATURES =====
local movement = {
    speed = { enabled = false, original = 16, connection = nil },
    noclip = { enabled = false, connection = nil },
    fly = { enabled = false, bodyVelocity = nil, connection = nil }
}
local godMode = { enabled = false, connection = nil }

-- Fix speed feature with character respawn handling
local function toggleSpeed(enable)
    movement.speed.enabled = enable
    
    -- Clean up existing connection
    if movement.speed.connection then
        movement.speed.connection:Disconnect()
        movement.speed.connection = nil
    end
    
    -- Create a new connection to handle character changes
    movement.speed.connection = LocalPlayer.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        if enable then
            humanoid.WalkSpeed = CONF.speedBoost
        else
            humanoid.WalkSpeed = movement.speed.original
        end
    end)
    
    -- Apply to current character
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if enable then
                movement.speed.original = humanoid.WalkSpeed
                humanoid.WalkSpeed = CONF.speedBoost
            else
                humanoid.WalkSpeed = movement.speed.original
            end
        end
    end
    
    notify("Speed " .. (enable and "ON" or "OFF"))
end

local function toggleNoclip(enable)
    movement.noclip.enabled = enable
    if enable then
        movement.noclip.connection = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    elseif movement.noclip.connection then
        movement.noclip.connection:Disconnect()
        movement.noclip.connection = nil
    end
    notify("Noclip " .. (enable and "ON" or "OFF"))
end

local function toggleFly(enable)
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    if enable then
        if movement.fly.bodyVelocity then movement.fly.bodyVelocity:Destroy() end
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = rootPart
        movement.fly.bodyVelocity = bv
        movement.fly.connection = RunService.Heartbeat:Connect(function()
            if not movement.fly.bodyVelocity or not movement.fly.bodyVelocity.Parent then return end
            local moveVector = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector = moveVector - Vector3.new(0, 1, 0) end
            movement.fly.bodyVelocity.Velocity = moveVector.Magnitude > 0 and moveVector.Unit * CONF.flySpeed or Vector3.new(0, 0, 0)
        end)
    else
        if movement.fly.connection then movement.fly.connection:Disconnect(); movement.fly.connection = nil end
        if movement.fly.bodyVelocity then movement.fly.bodyVelocity:Destroy(); movement.fly.bodyVelocity = nil end
    end
    movement.fly.enabled = enable
    notify("Fly " .. (enable and "ON" or "OFF"))
end

-- ===== ADVANCED ANTI-DETECTION SYSTEM =====
local antiDetection = CONF.antiDetection

-- Tracking variables
local healTracking = {
    lastHealTime = 0,
    healsThisSecond = 0,
    secondStartTime = tick(),
    godModeDisabledTime = 0
}

-- ===== STEALTH GOD MODE =====
local function toggleGodMode(enable)
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Check cooldown
    if enable and healTracking.godModeDisabledTime > 0 and 
       (tick() - healTracking.godModeDisabledTime) < antiDetection.godModeCooldown then
        notify("Protection on cooldown")
        return
    end

    godMode.enabled = enable
    if enable then
        -- Restore health naturally (avoid sudden increase)
        if humanoid.Health < humanoid.MaxHealth then
            local healthDiff = humanoid.MaxHealth - humanoid.Health
            local healSteps = math.ceil(healthDiff / 10)
            local healAmount = healthDiff / healSteps
            
            local healStep = 0
            local healConnection
            healConnection = RunService.Heartbeat:Connect(function(deltaTime)
                healStep = healStep + deltaTime
                
                if healStep >= 0.1 and humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
                    healStep = 0
                    
                    if humanoid.Health >= humanoid.MaxHealth then
                        healConnection:Disconnect()
                    end
                end
            end)
        end
        
        -- Advanced protection with stealth
        godMode.connection = humanoid.HealthChanged:Connect(function(newHealth)
            if not godMode.enabled then return end
            
            -- Simulate natural response to damage
            if antiDetection.simulateDamageReaction and newHealth < humanoid.MaxHealth then
                -- Random delay before healing
                local delay = math.random(
                    antiDetection.damageReactionDelay.min * 1000, 
                    antiDetection.damageReactionDelay.max * 1000
                ) / 1000
                
                task.spawn(function()
                    task.wait(delay)
                    
                    if godMode.enabled and humanoid.Health < humanoid.MaxHealth then
                        -- Partial healing with randomness
                        local healAmount = antiDetection.randomizeHealAmount and 
                            math.random(antiDetection.healAmountRange.min, antiDetection.healAmountRange.max) or 
                            20
                        
                        humanoid.Health = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
                        
                        -- Health oscillation for stealth
                        if antiDetection.healthOscillation and humanoid.Health >= humanoid.MaxHealth * 0.95 then
                            local oscillation = math.random(
                                antiDetection.healthOscillationRange.min, 
                                antiDetection.healthOscillationRange.max
                            ) / 100
                            humanoid.Health = humanoid.MaxHealth * oscillation
                        end
                    end
                end)
            end
        end)
        
        -- Additional protection against environmental damage with stealth
        local function protectFromEnvironment()
            -- Protection against falling (with stealth)
            if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                -- Wait a bit before changing (stealth)
                task.spawn(function()
                    task.wait(math.random(0.1, 0.3))
                    if godMode.enabled and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end)
            end
            
            -- Protection against drowning (with stealth)
            if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
                local head = character:FindFirstChild("Head")
                if head then
                    local waterSensor = head:FindFirstChild("WaterSensor") or Instance.new("BoolValue", head)
                    waterSensor.Name = "WaterSensor"
                    waterSensor.Value = false
                end
            end
        end
        
        -- Apply protection periodically with randomness
        local protectionLoop
        protectionLoop = RunService.Heartbeat:Connect(function(deltaTime)
            if not godMode.enabled then
                protectionLoop:Disconnect()
                return
            end
            
            -- Execute protection non-uniformly
            if math.random() < 0.1 then -- 10% chance each frame
                protectFromEnvironment()
            end
        end)
        
        notify("Protection Enabled")
    else
        if godMode.connection then 
            godMode.connection:Disconnect() 
            godMode.connection = nil 
        end
        
        -- Record disable time for stealth
        healTracking.godModeDisabledTime = tick()
        
        notify("Protection Disabled")
    end
end

-- ===== STEALTH HEAL SYSTEM =====
local function stealthHeal(amount, instant)
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Check healing limits
    local currentTime = tick()
    
    -- Reset counter every second
    if currentTime - healTracking.secondStartTime >= 1 then
        healTracking.healsThisSecond = 0
        healTracking.secondStartTime = currentTime
    end
    
    -- Check max heals per second
    if healTracking.healsThisSecond >= antiDetection.maxHealsPerSecond then
        -- Wait until next second
        local waitTime = 1 - (currentTime - healTracking.secondStartTime)
        task.spawn(function()
            task.wait(waitTime)
            stealthHeal(amount, instant)
        end)
        return
    end
    
    -- Increment heal counter
    healTracking.healsThisSecond = healTracking.healsThisSecond + 1
    
    -- Determine heal amount
    local healAmount = amount
    if antiDetection.randomizeHealAmount then
        healAmount = math.random(antiDetection.healAmountRange.min, antiDetection.healAmountRange.max)
    end
    
    if instant then
        -- Instant healing with stealth
        if humanoid.Health < humanoid.MaxHealth then
            -- Split healing into small steps
            local steps = math.ceil(healAmount / 5)
            local stepAmount = healAmount / steps
            local stepDelay = antiDetection.randomizeHealDelay and 
                math.random(antiDetection.healDelayRange.min, antiDetection.healDelayRange.max) or 
                0.1
            
            local currentStep = 0
            local healConnection
            healConnection = RunService.Heartbeat:Connect(function(deltaTime)
                currentStep = currentStep + deltaTime
                
                if currentStep >= stepDelay and humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = math.min(humanoid.Health + stepAmount, humanoid.MaxHealth)
                    currentStep = 0
                    
                    if humanoid.Health >= humanoid.MaxHealth then
                        healConnection:Disconnect()
                    end
                end
            end)
        end
    else
        -- Gradual healing with randomness
        local healInterval = antiDetection.randomizeHealDelay and 
            math.random(antiDetection.healDelayRange.min, antiDetection.healDelayRange.max) or 
            0.2
        
        local healSteps = 0
        local healConnection
        healConnection = RunService.Heartbeat:Connect(function(deltaTime)
            healSteps = healSteps + deltaTime
            
            if healSteps >= healInterval and humanoid.Health < humanoid.MaxHealth then
                humanoid.Health = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
                healSteps = 0
                
                -- Stop when reaching full health
                if humanoid.Health >= humanoid.MaxHealth then
                    healConnection:Disconnect()
                end
            end
        end)
    end
    
    -- Remove negative effects stealthily
    task.spawn(function()
        task.wait(math.random(0.1, 0.3)) -- Random delay
        
        for _, effect in pairs(character:GetChildren()) do
            if effect:IsA("BoolValue") and (effect.Name:find("Debuff") or effect.Name:find("Poison") or effect.Name:find("Slow")) then
                -- Hide removal
                effect.Parent = nil
                Debris:AddItem(effect, 0)
            end
        end
        
        -- Remove humanoid effects stealthily
        for _, effect in pairs(humanoid:GetChildren()) do
            if effect:IsA("NumberValue") and effect.Name:find("Effect") then
                -- Hide removal
                effect.Parent = nil
                Debris:AddItem(effect, 0)
            end
        end
        
        -- Restore energy stealthily
        for _, stamina in pairs(character:GetChildren()) do
            if stamina:IsA("NumberValue") and stamina.Name:find("Stamina") then
                local maxStamina = stamina.MaxValue or 100
                local currentStamina = stamina.Value
                
                if currentStamina < maxStamina then
                    -- Gradual energy restoration
                    local restoreAmount = math.min(5, maxStamina - currentStamina)
                    stamina.Value = currentStamina + restoreAmount
                end
            end
        end
    end)
end

-- ===== ENHANCED HEAL BUTTON =====
local function enhancedHeal()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Calculate needed health
    local healthNeeded = humanoid.MaxHealth - humanoid.Health
    if healthNeeded <= 0 then
        notify("Health already full")
        return
    end
    
    -- Stealth healing
    stealthHeal(healthNeeded, false)
    
    notify("Healing in progress...")
end

-- ===== STEALTH AUTO HEAL =====
local autoHeal = {
    enabled = false,
    threshold = 0.7, -- Health percentage for auto heal
    connection = nil,
    cooldown = 10, -- Cooldown between auto heals
    lastAutoHealTime = 0,
    randomizeThreshold = true, -- Randomize heal threshold
    thresholdRange = {min = 0.5, max = 0.8} -- Random threshold range
}

local function toggleAutoHeal(enable)
    autoHeal.enabled = enable
    
    if enable then
        autoHeal.connection = RunService.Heartbeat:Connect(function()
            if not autoHeal.enabled then
                autoHeal.connection:Disconnect()
                return
            end
            
            local character = LocalPlayer.Character
            if not character then return end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            
            local currentTime = tick()
            local currentHealthPercent = humanoid.Health / humanoid.MaxHealth
            
            -- Determine heal threshold (with randomness)
            local healThreshold = autoHeal.threshold
            if autoHeal.randomizeThreshold then
                healThreshold = math.random(
                    autoHeal.thresholdRange.min * 100, 
                    autoHeal.thresholdRange.max * 100
                ) / 100
            end
            
            -- Auto heal when health drops below threshold
            if currentHealthPercent < healThreshold and 
               (currentTime - autoHeal.lastAutoHealTime) > autoHeal.cooldown then
                
                -- Random heal amount
                local healAmount = math.random(
                    antiDetection.healAmountRange.min, 
                    antiDetection.healAmountRange.max
                )
                
                stealthHeal(healAmount, false)
                autoHeal.lastAutoHealTime = currentTime
                
                -- Silent notification (less suspicious)
                if math.random() < 0.3 then -- 30% chance only
                    notify("Auto recovery")
                end
            end
        end)
        
        notify("Auto recovery enabled")
    else
        if autoHeal.connection then
            autoHeal.connection:Disconnect()
            autoHeal.connection = nil
        end
        notify("Auto recovery disabled")
    end
end

-- ===== STEALTH REVIVE =====
local function stealthRevive()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- If player is dead
    if humanoid.Health <= 0 then
        -- Random wait before revive (stealth)
        task.wait(math.random(0.5, 2.0))
        
        -- Recreate character
        character:BreakJoints()
        
        -- Wait for character recreation
        LocalPlayer.CharacterAdded:Wait()
        task.wait(math.random(0.5, 1.0)) -- Additional delay for stealth
        
        character = LocalPlayer.Character
        humanoid = character:WaitForChild("Humanoid")
        
        -- Restore health gradually (stealth)
        local healthRestore = humanoid.MaxHealth / 10
        for i = 1, 10 do
            humanoid.Health = humanoid.Health + healthRestore
            task.wait(math.random(0.05, 0.15)) -- Random delay
        end
        
        notify("Revived")
    else
        -- If player is alive, just full heal with stealth
        enhancedHeal()
    end
end

-- ===== AIMBOT =====
local aimbot = { 
    lastPositions = {},
    consecutiveHits = 0,
    currentAccuracy = 1.0,
    positionHistory = {},
    lastVelocity = {},
    lastTargetTime = 0,
    lastTarget = nil,
    isAiming = false,
    aimStartTime = 0,
    recoilPattern = {},
    currentRecoilIndex = 1,
    currentTarget = nil
}

-- Generate realistic recoil pattern
local function generateRecoilPattern()
    local pattern = {}
    local angle = 0
    for i = 1, 20 do
        angle = angle + math.rad(math.random(5, 15))
        local radius = math.random(1, 3) * (i / 20)
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        table.insert(pattern, Vector2.new(x, y))
    end
    return pattern
end

-- Initialize recoil pattern
aimbot.recoilPattern = generateRecoilPattern()

local function getTargetPart(character)
    return getSmarterTargetPart(character)
end

local function isVisible(targetPart)
    local character = LocalPlayer.Character
    if not character or not targetPart then return false end
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local direction = (targetPos - origin).Unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character, Camera, targetPart.Parent}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(origin, direction * (targetPos - origin).Magnitude, raycastParams)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function predictPosition(player, part)
    return predictPositionAdvanced(player, part)
end

local function getTargets()
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and isEnemy(player) then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local targetPart = getTargetPart(player.Character)
            if humanoid and humanoid.Health > 0 and targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen and isVisible(targetPart) then
                    table.insert(targets, {
                        player = player,
                        part = targetPart,
                        humanoid = humanoid,
                        screenPos = Vector2.new(screenPos.X, screenPos.Y),
                        distance = (targetPart.Position - Camera.CFrame.Position).Magnitude
                    })
                end
            end
        end
    end
    return targets
end

local function findBestTarget(targets)
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestTarget, bestScore = nil, math.huge
    
    -- Add target switching delay
    if aimbot.lastTarget and aimbot.lastTargetTime and (tick() - aimbot.lastTargetTime) < CONF.targetSwitchingDelay then
        -- Check if last target is still valid
        for _, target in ipairs(targets) do
            if target.player == aimbot.lastTarget then
                aimbot.currentTarget = target
                return target
            end
        end
    end
    
    for _, target in ipairs(targets) do
        local distanceToCenter = (target.screenPos - center).Magnitude
        
        -- Only activate if target is near crosshair and within FOV
        if distanceToCenter <= CONF.aimFov.size and distanceToCenter <= CONF.aimActivationRadius then
            local score = CONF.aimPriority == "LowHealth" and target.humanoid.Health or distanceToCenter
            
            -- Add randomness to avoid patterns
            score = score + math.random(-5, 5)
            
            if score < bestScore then
                bestScore = score
                bestTarget = target
            end
        end
    end
    
    if bestTarget then
        aimbot.lastTarget = bestTarget.player
        aimbot.lastTargetTime = tick()
        aimbot.currentTarget = bestTarget
    else
        aimbot.currentTarget = nil
    end
    
    return bestTarget
end

-- ===== ESP =====
local esp = { objects = {}, drawing = pcall(function() return Drawing.new end) }

local function cleanupESP()
    for player, data in pairs(esp.objects) do
        for _, obj in pairs(data) do
            if typeof(obj) == "Instance" then obj:Destroy()
            elseif type(obj) == "table" and obj.gui then obj.gui:Destroy()
            elseif data.tracer and data.tracer.Remove then data.tracer:Remove() end
        end
    end
    esp.objects = {}
end

local function updateESP()
    if not CONF.esp.enabled then if next(esp.objects) then cleanupESP() end; return end

    local validPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and isEnemy(player) then
            validPlayers[player] = true
            local data = esp.objects[player]
            if not data then
                data = {}
                esp.objects[player] = data
                local head = player.Character:WaitForChild("Head")
                
                if CONF.esp.boxes then
                    data.box = Instance.new("SelectionBox", Camera)
                    data.box.LineThickness = 0.04
                    data.box.Color3 = CONF.ui.bad
                end

                data.billboard = Instance.new("BillboardGui", Camera)
                data.billboard.AlwaysOnTop = true
                data.billboard.Size = UDim2.new(0, 200, 0, 50)
                data.billboard.StudsOffset = Vector3.new(0, 2.5, 0)

                local frame = Instance.new("Frame", data.billboard)
                frame.BackgroundTransparency = 1
                frame.Size = UDim2.new(1, 0, 1, 0)

                if CONF.esp.names then
                    data.nameLabel = Instance.new("TextLabel", frame)
                    data.nameLabel.Font = Enum.Font.GothamBold
                    data.nameLabel.TextSize = 14
                    data.nameLabel.TextColor3 = CONF.ui.text
                    data.nameLabel.BackgroundTransparency = 1
                    data.nameLabel.Size = UDim2.new(1, 0, 0, 18)
                end

                if CONF.esp.distances then
                    data.distanceLabel = Instance.new("TextLabel", frame)
                    data.distanceLabel.Font = Enum.Font.Gotham
                    data.distanceLabel.TextSize = 12
                    data.distanceLabel.TextColor3 = CONF.ui.subtle
                    data.distanceLabel.BackgroundTransparency = 1
                    data.distanceLabel.Size = UDim2.new(1, 0, 0, 16)
                    data.distanceLabel.Position = UDim2.new(0, 0, 0, 18)
                end

                if CONF.esp.healthbar then
                    local healthBarBG = Instance.new("Frame", frame)
                    healthBarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                    healthBarBG.Size = UDim2.new(1, 0, 0, 4)
                    healthBarBG.Position = UDim2.new(0, 0, 1, -4)
                    data.healthFill = Instance.new("Frame", healthBarBG)
                    data.healthFill.BackgroundColor3 = CONF.ui.ok
                    data.healthFill.Size = UDim2.new(1, 0, 1, 0)
                end

                if CONF.esp.tracers and esp.drawing then
                    data.tracer = Drawing.new("Line")
                    data.tracer.Thickness = CONF.esp.tracerThickness
                    data.tracer.Color = CONF.ui.accent
                    data.tracer.Transparency = 0.5
                end
            end

            local character = player.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local head = character:FindFirstChild("Head")
            if not humanoid or not head then continue end

            if data.box then data.box.Adornee = character; data.box.Visible = CONF.esp.boxes end
            if data.billboard then data.billboard.Adornee = head; data.billboard.Enabled = true end
            if data.nameLabel then data.nameLabel.Text = player.DisplayName; data.nameLabel.Visible = CONF.esp.names end
            if data.distanceLabel then
                local dist = (head.Position - Camera.CFrame.Position).Magnitude
                data.distanceLabel.Text = string.format("[%.0fm]", dist)
                data.distanceLabel.Visible = CONF.esp.distances
            end
            if data.healthFill then
                local hp = humanoid.Health / humanoid.MaxHealth
                data.healthFill.Size = UDim2.new(hp, 0, 1, 0)
                data.healthFill.BackgroundColor3 = Color3.fromHSV(hp * 0.33, 1, 1)
                data.healthFill.Parent.Visible = CONF.esp.healthbar
            end
            if data.tracer then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                data.tracer.Visible = CONF.esp.tracers and onScreen
                if onScreen then
                    data.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    data.tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                end
            end
        end
    end

    for player, data in pairs(esp.objects) do
        if not validPlayers[player] then
            for _, obj in pairs(data) do
                if typeof(obj) == "Instance" then obj:Destroy()
                elseif type(obj) == "table" and obj.gui then obj.gui:Destroy()
                elseif data.tracer and data.tracer.Remove then data.tracer:Remove() end
            end
            esp.objects[player] = nil
        end
    end
end

-- ===== FOV CIRCLE =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = CONF.guiName
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100

local fovCircle = Instance.new("Frame", screenGui)
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.ZIndex = 10
local circleStroke = Instance.new("UIStroke", fovCircle)
circleStroke.Thickness = 1.5
circleStroke.LineJoinMode = Enum.LineJoinMode.Round
circleStroke.Transparency = 0.5
circleStroke.Color = CONF.aimFov.color
local circleCorner = Instance.new("UICorner", fovCircle)
circleCorner.CornerRadius = UDim.new(1, 0)

-- Function to center the FOV circle
local function centerFOVCircle()
    if fovCircle and fovCircle.Parent then
        fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    end
end

-- Center the FOV circle initially
centerFOVCircle()

-- Update FOV circle position when viewport size changes
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(centerFOVCircle)

-- Also update in render loop for smoothness
RunService.RenderStepped:Connect(centerFOVCircle)

local function updateFOVCircle()
    if not CONF.aimFov.enabled then
        fovCircle.Visible = false
        return
    end
    
    fovCircle.Visible = CONF.showFOV and CONF.aimbotEnabled
    
    -- Update dynamic size
    local currentFovSize = CONF.aimFov.size
    if CONF.aimFov.dynamicSize and aimbot.currentTarget then
        local distance = aimbot.currentTarget.distance
        -- Smaller FOV for closer targets, larger for distant targets
        local distanceFactor = math.min(distance / 1000, 1)
        currentFovSize = CONF.aimFov.innerSize + (CONF.aimFov.size - CONF.aimFov.innerSize) * distanceFactor
    end
    
    -- Apply size
    fovCircle.Size = UDim2.new(0, currentFovSize * 2, 0, currentFovSize * 2)
    
    -- Update shape
    if CONF.aimFov.shape == "circle" then
        circleCorner.CornerRadius = UDim.new(1, 0)
    elseif CONF.aimFov.shape == "square" then
        circleCorner.CornerRadius = UDim.new(0, 0)
    elseif CONF.aimFov.shape == "rounded" then
        circleCorner.CornerRadius = UDim.new(0.2, 0)
    end
    
    -- Update adaptive color
    if CONF.aimFov.adaptiveColor and aimbot.currentTarget then
        local healthPercent = aimbot.currentTarget.humanoid.Health / aimbot.currentTarget.humanoid.MaxHealth
        local hue = healthPercent * 0.33 -- From red (0) to green (0.33)
        circleStroke.Color = Color3.fromHSV(hue, 1, 1)
    else
        circleStroke.Color = CONF.aimFov.color
    end
    
    -- Update transparency and thickness
    circleStroke.Transparency = CONF.aimFov.transparency
    circleStroke.Thickness = CONF.aimFov.thickness
    
    -- Update fill
    if CONF.aimFov.filled then
        fovCircle.BackgroundColor3 = circleStroke.Color
        fovCircle.BackgroundTransparency = 0.8
    else
        fovCircle.BackgroundTransparency = 1
    end
    
    -- Show target distance
    if CONF.aimFov.showDistance and aimbot.currentTarget then
        local distanceLabel = fovCircle:FindFirstChild("DistanceLabel") or Instance.new("TextLabel", fovCircle)
        distanceLabel.Name = "DistanceLabel"
        distanceLabel.Text = math.floor(aimbot.currentTarget.distance) .. "m"
        distanceLabel.Font = Enum.Font.GothamBold
        distanceLabel.TextSize = 14
        distanceLabel.TextColor3 = Color3.new(1, 1, 1)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Size = UDim2.new(0, 50, 0, 20)
        distanceLabel.Position = UDim2.new(0.5, -25, 0, 5)
        distanceLabel.Visible = true
        distanceLabel.ZIndex = 11
    elseif fovCircle:FindFirstChild("DistanceLabel") then
        fovCircle.DistanceLabel.Visible = false
    end
    
    -- Target highlight
    if CONF.aimFov.targetHighlight and aimbot.currentTarget then
        local highlight = fovCircle:FindFirstChild("TargetHighlight") or Instance.new("Frame", fovCircle)
        highlight.Name = "TargetHighlight"
        highlight.BackgroundColor3 = Color3.new(1, 0, 0)
        highlight.BackgroundTransparency = 0.7
        highlight.Size = UDim2.new(0, 10, 0, 10)
        highlight.Position = UDim2.new(0.5, -5, 0.5, -5)
        highlight.Visible = true
        highlight.ZIndex = 11
        
        -- Move highlight towards target
        local targetScreenPos = aimbot.currentTarget.screenPos
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local relativePos = (targetScreenPos - center) / currentFovSize
        highlight.Position = UDim2.new(0.5 + relativePos.X - 0.0125, 0, 0.5 + relativePos.Y - 0.0125, 0)
    elseif fovCircle:FindFirstChild("TargetHighlight") then
        fovCircle.TargetHighlight.Visible = false
    end
end

-- ===== ADVANCED ANTI-DETECTION FOR HEALTH CHANGES =====
local function hideHealthChanges()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Monitor health changes
    local originalHealth = humanoid.Health
    local lastChangeTime = tick()
    
    humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        local currentTime = tick()
        local timeSinceLastChange = currentTime - lastChangeTime
        
        -- If change is too fast (suspicious)
        if timeSinceLastChange < 0.1 and math.abs(humanoid.Health - originalHealth) > 10 then
            -- Hide change through gradual transition
            local targetHealth = humanoid.Health
            local steps = 5
            local stepAmount = (targetHealth - originalHealth) / steps
            
            for i = 1, steps do
                humanoid.Health = originalHealth + (stepAmount * i)
                task.wait(0.05)
            end
        end
        
        originalHealth = humanoid.Health
        lastChangeTime = currentTime
    end)
end

-- Apply anti-detection system
hideHealthChanges()

-- ===== KEY BINDINGS =====
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.V then
        toggleSpeed(not movement.speed.enabled)
    elseif input.KeyCode == Enum.KeyCode.B then
        toggleNoclip(not movement.noclip.enabled)
    elseif input.KeyCode == Enum.KeyCode.N then
        toggleFly(not movement.fly.enabled)
    elseif input.KeyCode == Enum.KeyCode.G then
        toggleGodMode(not godMode.enabled)
    elseif input.KeyCode == Enum.KeyCode.H then
        enhancedHeal()
    elseif input.KeyCode == Enum.KeyCode.J then
        refillAll()
    elseif input.KeyCode == Enum.KeyCode.U then
        toggleAutoHeal(not autoHeal.enabled)
    elseif input.KeyCode == Enum.KeyCode.I then
        stealthRevive()
    end
end)

-- ===== UI MENU CREATION =====
local function createMenu()
    -- Create main menu frame
    local menuFrame = Instance.new("Frame")
    menuFrame.Name = "TrainerXMenu"
    menuFrame.Size = UDim2.new(0, 300, 0, 400)
    menuFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
    menuFrame.BackgroundColor3 = CONF.ui.panel
    menuFrame.BorderSizePixel = 0
    menuFrame.Parent = screenGui
    menuFrame.Visible = false
    menuFrame.ZIndex = 100
    
    -- Add corner rounding
    local menuCorner = Instance.new("UICorner", menuFrame)
    menuCorner.CornerRadius = UDim.new(0, 10)
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "TRAINER X"
    titleLabel.TextColor3 = CONF.ui.accent
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = menuFrame
    titleLabel.ZIndex = 101
    
    -- Add close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -30, 0, 0)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "X"
    closeButton.TextColor3 = CONF.ui.bad
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = menuFrame
    closeButton.ZIndex = 101
    
    closeButton.MouseButton1Click:Connect(function()
        menuFrame.Visible = false
    end)
    
    -- Add tabs container
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Name = "TabsContainer"
    tabsContainer.Size = UDim2.new(1, 0, 0, 40)
    tabsContainer.Position = UDim2.new(0, 0, 0, 30)
    tabsContainer.BackgroundColor3 = CONF.ui.bg
    tabsContainer.BorderSizePixel = 0
    tabsContainer.Parent = menuFrame
    tabsContainer.ZIndex = 101
    
    -- Add tabs
    local tabs = {"Aimbot", "ESP", "Movement", "Protection"}
    local tabButtons = {}
    local tabContents = {}
    
    for i, tabName in ipairs(tabs) do
        -- Tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "Tab"
        tabButton.Size = UDim2.new(0, 75, 1, 0)
        tabButton.Position = UDim2.new(0, (i-1) * 75, 0, 0)
        tabButton.BackgroundTransparency = 1
        tabButton.Text = tabName
        tabButton.TextColor3 = CONF.ui.text
        tabButton.TextSize = 14
        tabButton.Font = Enum.Font.Gotham
        tabButton.Parent = tabsContainer
        tabButton.ZIndex = 102
        
        tabButtons[tabName] = tabButton
        
        -- Tab content
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = tabName .. "Content"
        tabContent.Size = UDim2.new(1, -10, 1, -50)
        tabContent.Position = UDim2.new(0, 5, 0, 80)
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.ScrollBarThickness = 5
        tabContent.Visible = i == 1
        tabContent.Parent = menuFrame
        tabContent.ZIndex = 101
        
        tabContents[tabName] = tabContent
        
        -- Tab button click event
        tabButton.MouseButton1Click:Connect(function()
            for _, content in pairs(tabContents) do
                content.Visible = false
            end
            tabContent.Visible = true
            
            for _, button in pairs(tabButtons) do
                button.TextColor3 = CONF.ui.text
            end
            tabButton.TextColor3 = CONF.ui.accent
        end)
    end
    
    -- Set first tab as active
    tabButtons[tabs[1]].TextColor3 = CONF.ui.accent
    
    -- ===== AIMBOT TAB =====
    local aimbotContent = tabContents["Aimbot"]
    
    -- Aimbot toggle
    local aimbotToggle = Instance.new("TextButton")
    aimbotToggle.Name = "AimbotToggle"
    aimbotToggle.Size = UDim2.new(1, -10, 0, 30)
    aimbotToggle.Position = UDim2.new(0, 5, 0, 5)
    aimbotToggle.BackgroundColor3 = CONF.ui.bg
    aimbotToggle.BorderSizePixel = 0
    aimbotToggle.Text = "Aimbot: " .. (CONF.aimbotEnabled and "ON" or "OFF")
    aimbotToggle.TextColor3 = CONF.aimbotEnabled and CONF.ui.ok or CONF.ui.bad
    aimbotToggle.TextSize = 14
    aimbotToggle.Font = Enum.Font.Gotham
    aimbotToggle.Parent = aimbotContent
    aimbotToggle.ZIndex = 102
    
    local aimbotCorner = Instance.new("UICorner", aimbotToggle)
    aimbotCorner.CornerRadius = UDim.new(0, 5)
    
    aimbotToggle.MouseButton1Click:Connect(function()
        CONF.aimbotEnabled = not CONF.aimbotEnabled
        aimbotToggle.Text = "Aimbot: " .. (CONF.aimbotEnabled and "ON" or "OFF")
        aimbotToggle.TextColor3 = CONF.aimbotEnabled and CONF.ui.ok or CONF.ui.bad
        saveConfig()
    end)
    
    -- Aim Part dropdown
    local aimPartLabel = Instance.new("TextLabel")
    aimPartLabel.Name = "AimPartLabel"
    aimPartLabel.Size = UDim2.new(1, -10, 0, 20)
    aimPartLabel.Position = UDim2.new(0, 5, 0, 40)
    aimPartLabel.BackgroundTransparency = 1
    aimPartLabel.Text = "Aim Part: " .. CONF.aimPart
    aimPartLabel.TextColor3 = CONF.ui.text
    aimPartLabel.TextSize = 14
    aimPartLabel.Font = Enum.Font.Gotham
    aimPartLabel.TextXAlignment = Enum.TextXAlignment.Left
    aimPartLabel.Parent = aimbotContent
    aimPartLabel.ZIndex = 102
    
    local aimPartDropdown = Instance.new("TextButton")
    aimPartDropdown.Name = "AimPartDropdown"
    aimPartDropdown.Size = UDim2.new(1, -10, 0, 30)
    aimPartDropdown.Position = UDim2.new(0, 5, 0, 60)
    aimPartDropdown.BackgroundColor3 = CONF.ui.bg
    aimPartDropdown.BorderSizePixel = 0
    aimPartDropdown.Text = CONF.aimPart
    aimPartDropdown.TextColor3 = CONF.ui.text
    aimPartDropdown.TextSize = 14
    aimPartDropdown.Font = Enum.Font.Gotham
    aimPartDropdown.Parent = aimbotContent
    aimPartDropdown.ZIndex = 102
    
    local aimPartCorner = Instance.new("UICorner", aimPartDropdown)
    aimPartCorner.CornerRadius = UDim.new(0, 5)
    
    local aimParts = {"Head", "UpperTorso", "HumanoidRootPart"}
    local aimPartDropdownOpen = false
    
    aimPartDropdown.MouseButton1Click:Connect(function()
        aimPartDropdownOpen = not aimPartDropdownOpen
        
        if aimPartDropdownOpen then
            -- Create dropdown options
            for i, part in ipairs(aimParts) do
                local option = Instance.new("TextButton")
                option.Name = part .. "Option"
                option.Size = UDim2.new(1, -10, 0, 30)
                option.Position = UDim2.new(0, 5, 0, 60 + (i * 30))
                option.BackgroundColor3 = CONF.ui.bg
                option.BorderSizePixel = 0
                option.Text = part
                option.TextColor3 = CONF.ui.text
                option.TextSize = 14
                option.Font = Enum.Font.Gotham
                option.Parent = aimbotContent
                option.ZIndex = 103
                
                local optionCorner = Instance.new("UICorner", option)
                optionCorner.CornerRadius = UDim.new(0, 5)
                
                option.MouseButton1Click:Connect(function()
                    CONF.aimPart = part
                    aimPartDropdown.Text = part
                    aimPartLabel.Text = "Aim Part: " .. part
                    
                    -- Remove all options
                    for _, child in ipairs(aimbotContent:GetChildren()) do
                        if child.Name:find("Option") then
                            child:Destroy()
                        end
                    end
                    
                    aimPartDropdownOpen = false
                    saveConfig()
                end)
            end
        else
            -- Remove all options
            for _, child in ipairs(aimbotContent:GetChildren()) do
                if child.Name:find("Option") then
                    child:Destroy()
                end
            end
        end
    end)
    
    -- FOV Slider
    local fovLabel = Instance.new("TextLabel")
    fovLabel.Name = "FovLabel"
    fovLabel.Size = UDim2.new(1, -10, 0, 20)
    fovLabel.Position = UDim2.new(0, 5, 0, 150)
    fovLabel.BackgroundTransparency = 1
    fovLabel.Text = "FOV Size: " .. CONF.aimFov.size
    fovLabel.TextColor3 = CONF.ui.text
    fovLabel.TextSize = 14
    fovLabel.Font = Enum.Font.Gotham
    fovLabel.TextXAlignment = Enum.TextXAlignment.Left
    fovLabel.Parent = aimbotContent
    fovLabel.ZIndex = 102
    
    local fovSlider = Instance.new("Frame")
    fovSlider.Name = "FovSlider"
    fovSlider.Size = UDim2.new(1, -10, 0, 10)
    fovSlider.Position = UDim2.new(0, 5, 0, 170)
    fovSlider.BackgroundColor3 = CONF.ui.bg
    fovSlider.BorderSizePixel = 0
    fovSlider.Parent = aimbotContent
    fovSlider.ZIndex = 102
    
    local fovSliderCorner = Instance.new("UICorner", fovSlider)
    fovSliderCorner.CornerRadius = UDim.new(0, 5)
    
    local fovSliderFill = Instance.new("Frame")
    fovSliderFill.Name = "FovSliderFill"
    fovSliderFill.Size = UDim2.new(CONF.aimFov.size / 300, 0, 1, 0)
    fovSliderFill.Position = UDim2.new(0, 0, 0, 0)
    fovSliderFill.BackgroundColor3 = CONF.ui.accent
    fovSliderFill.BorderSizePixel = 0
    fovSliderFill.Parent = fovSlider
    fovSliderFill.ZIndex = 103
    
    local fovSliderCornerFill = Instance.new("UICorner", fovSliderFill)
    fovSliderCornerFill.CornerRadius = UDim.new(0, 5)
    
    local fovSliderButton = Instance.new("TextButton")
    fovSliderButton.Name = "FovSliderButton"
    fovSliderButton.Size = UDim2.new(0, 20, 0, 20)
    fovSliderButton.Position = UDim2.new(CONF.aimFov.size / 300, -10, 0, -5)
    fovSliderButton.BackgroundColor3 = CONF.ui.text
    fovSliderButton.BorderSizePixel = 0
    fovSliderButton.Text = ""
    fovSliderButton.Parent = fovSlider
    fovSliderButton.ZIndex = 104
    
    local fovSliderButtonCorner = Instance.new("UICorner", fovSliderButton)
    fovSliderButtonCorner.CornerRadius = UDim.new(0, 10)
    
    local fovDragging = false
    
    fovSliderButton.MouseButton1Down:Connect(function()
        fovDragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            fovDragging = false
            saveConfig()
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if fovDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = fovSlider.AbsolutePosition
            local sliderSize = fovSlider.AbsoluteSize
            
            local percent = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
            local value = math.floor(percent * 300)
            
            CONF.aimFov.size = value
            fovLabel.Text = "FOV Size: " .. value
            fovSliderFill.Size = UDim2.new(percent, 0, 1, 0)
            fovSliderButton.Position = UDim2.new(percent, -10, 0, -5)
        end
    end)
    
    -- ===== ESP TAB =====
    local espContent = tabContents["ESP"]
    
    -- ESP toggle
    local espToggle = Instance.new("TextButton")
    espToggle.Name = "EspToggle"
    espToggle.Size = UDim2.new(1, -10, 0, 30)
    espToggle.Position = UDim2.new(0, 5, 0, 5)
    espToggle.BackgroundColor3 = CONF.ui.bg
    espToggle.BorderSizePixel = 0
    espToggle.Text = "ESP: " .. (CONF.esp.enabled and "ON" or "OFF")
    espToggle.TextColor3 = CONF.esp.enabled and CONF.ui.ok or CONF.ui.bad
    espToggle.TextSize = 14
    espToggle.Font = Enum.Font.Gotham
    espToggle.Parent = espContent
    espToggle.ZIndex = 102
    
    local espCorner = Instance.new("UICorner", espToggle)
    espCorner.CornerRadius = UDim.new(0, 5)
    
    espToggle.MouseButton1Click:Connect(function()
        CONF.esp.enabled = not CONF.esp.enabled
        espToggle.Text = "ESP: " .. (CONF.esp.enabled and "ON" or "OFF")
        espToggle.TextColor3 = CONF.esp.enabled and CONF.ui.ok or CONF.ui.bad
        saveConfig()
    end)
    
    -- ESP options
    local espOptions = {
        {name = "Boxes", var = "boxes"},
        {name = "Names", var = "names"},
        {name = "Distances", var = "distances"},
        {name = "Healthbar", var = "healthbar"},
        {name = "Tracers", var = "tracers"},
        {name = "Enemies Only", var = "enemiesOnly"}
    }
    
    for i, option in ipairs(espOptions) do
        local optionToggle = Instance.new("TextButton")
        optionToggle.Name = option.var .. "Toggle"
        optionToggle.Size = UDim2.new(1, -10, 0, 30)
        optionToggle.Position = UDim2.new(0, 5, 0, 5 + (i * 35))
        optionToggle.BackgroundColor3 = CONF.ui.bg
        optionToggle.BorderSizePixel = 0
        optionToggle.Text = option.name .. ": " .. (CONF.esp[option.var] and "ON" or "OFF")
        optionToggle.TextColor3 = CONF.esp[option.var] and CONF.ui.ok or CONF.ui.bad
        optionToggle.TextSize = 14
        optionToggle.Font = Enum.Font.Gotham
        optionToggle.Parent = espContent
        optionToggle.ZIndex = 102
        
        local optionCorner = Instance.new("UICorner", optionToggle)
        optionCorner.CornerRadius = UDim.new(0, 5)
        
        optionToggle.MouseButton1Click:Connect(function()
            CONF.esp[option.var] = not CONF.esp[option.var]
            optionToggle.Text = option.name .. ": " .. (CONF.esp[option.var] and "ON" or "OFF")
            optionToggle.TextColor3 = CONF.esp[option.var] and CONF.ui.ok or CONF.ui.bad
            saveConfig()
        end)
    end
    
    -- ===== MOVEMENT TAB =====
    local movementContent = tabContents["Movement"]
    
    -- Speed toggle
    local speedToggle = Instance.new("TextButton")
    speedToggle.Name = "SpeedToggle"
    speedToggle.Size = UDim2.new(1, -10, 0, 30)
    speedToggle.Position = UDim2.new(0, 5, 0, 5)
    speedToggle.BackgroundColor3 = CONF.ui.bg
    speedToggle.BorderSizePixel = 0
    speedToggle.Text = "Speed: " .. (movement.speed.enabled and "ON" or "OFF")
    speedToggle.TextColor3 = movement.speed.enabled and CONF.ui.ok or CONF.ui.bad
    speedToggle.TextSize = 14
    speedToggle.Font = Enum.Font.Gotham
    speedToggle.Parent = movementContent
    speedToggle.ZIndex = 102
    
    local speedCorner = Instance.new("UICorner", speedToggle)
    speedCorner.CornerRadius = UDim.new(0, 5)
    
    speedToggle.MouseButton1Click:Connect(function()
        toggleSpeed(not movement.speed.enabled)
        speedToggle.Text = "Speed: " .. (movement.speed.enabled and "ON" or "OFF")
        speedToggle.TextColor3 = movement.speed.enabled and CONF.ui.ok or CONF.ui.bad
    end)
    
    -- Noclip toggle
    local noclipToggle = Instance.new("TextButton")
    noclipToggle.Name = "NoclipToggle"
    noclipToggle.Size = UDim2.new(1, -10, 0, 30)
    noclipToggle.Position = UDim2.new(0, 5, 0, 40)
    noclipToggle.BackgroundColor3 = CONF.ui.bg
    noclipToggle.BorderSizePixel = 0
    noclipToggle.Text = "Noclip: " .. (movement.noclip.enabled and "ON" or "OFF")
    noclipToggle.TextColor3 = movement.noclip.enabled and CONF.ui.ok or CONF.ui.bad
    noclipToggle.TextSize = 14
    noclipToggle.Font = Enum.Font.Gotham
    noclipToggle.Parent = movementContent
    noclipToggle.ZIndex = 102
    
    local noclipCorner = Instance.new("UICorner", noclipToggle)
    noclipCorner.CornerRadius = UDim.new(0, 5)
    
    noclipToggle.MouseButton1Click:Connect(function()
        toggleNoclip(not movement.noclip.enabled)
        noclipToggle.Text = "Noclip: " .. (movement.noclip.enabled and "ON" or "OFF")
        noclipToggle.TextColor3 = movement.noclip.enabled and CONF.ui.ok or CONF.ui.bad
    end)
    
    -- Fly toggle
    local flyToggle = Instance.new("TextButton")
    flyToggle.Name = "FlyToggle"
    flyToggle.Size = UDim2.new(1, -10, 0, 30)
    flyToggle.Position = UDim2.new(0, 5, 0, 75)
    flyToggle.BackgroundColor3 = CONF.ui.bg
    flyToggle.BorderSizePixel = 0
    flyToggle.Text = "Fly: " .. (movement.fly.enabled and "ON" or "OFF")
    flyToggle.TextColor3 = movement.fly.enabled and CONF.ui.ok or CONF.ui.bad
    flyToggle.TextSize = 14
    flyToggle.Font = Enum.Font.Gotham
    flyToggle.Parent = movementContent
    flyToggle.ZIndex = 102
    
    local flyCorner = Instance.new("UICorner", flyToggle)
    flyCorner.CornerRadius = UDim.new(0, 5)
    
    flyToggle.MouseButton1Click:Connect(function()
        toggleFly(not movement.fly.enabled)
        flyToggle.Text = "Fly: " .. (movement.fly.enabled and "ON" or "OFF")
        flyToggle.TextColor3 = movement.fly.enabled and CONF.ui.ok or CONF.ui.bad
    end)
    
    -- Speed slider
    local speedBoostLabel = Instance.new("TextLabel")
    speedBoostLabel.Name = "SpeedBoostLabel"
    speedBoostLabel.Size = UDim2.new(1, -10, 0, 20)
    speedBoostLabel.Position = UDim2.new(0, 5, 0, 110)
    speedBoostLabel.BackgroundTransparency = 1
    speedBoostLabel.Text = "Speed Boost: " .. CONF.speedBoost
    speedBoostLabel.TextColor3 = CONF.ui.text
    speedBoostLabel.TextSize = 14
    speedBoostLabel.Font = Enum.Font.Gotham
    speedBoostLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedBoostLabel.Parent = movementContent
    speedBoostLabel.ZIndex = 102
    
    local speedBoostSlider = Instance.new("Frame")
    speedBoostSlider.Name = "SpeedBoostSlider"
    speedBoostSlider.Size = UDim2.new(1, -10, 0, 10)
    speedBoostSlider.Position = UDim2.new(0, 5, 0, 130)
    speedBoostSlider.BackgroundColor3 = CONF.ui.bg
    speedBoostSlider.BorderSizePixel = 0
    speedBoostSlider.Parent = movementContent
    speedBoostSlider.ZIndex = 102
    
    local speedBoostSliderCorner = Instance.new("UICorner", speedBoostSlider)
    speedBoostSliderCorner.CornerRadius = UDim.new(0, 5)
    
    local speedBoostSliderFill = Instance.new("Frame")
    speedBoostSliderFill.Name = "SpeedBoostSliderFill"
    speedBoostSliderFill.Size = UDim2.new(CONF.speedBoost / 200, 0, 1, 0)
    speedBoostSliderFill.Position = UDim2.new(0, 0, 0, 0)
    speedBoostSliderFill.BackgroundColor3 = CONF.ui.accent
    speedBoostSliderFill.BorderSizePixel = 0
    speedBoostSliderFill.Parent = speedBoostSlider
    speedBoostSliderFill.ZIndex = 103
    
    local speedBoostSliderCornerFill = Instance.new("UICorner", speedBoostSliderFill)
    speedBoostSliderCornerFill.CornerRadius = UDim.new(0, 5)
    
    local speedBoostSliderButton = Instance.new("TextButton")
    speedBoostSliderButton.Name = "SpeedBoostSliderButton"
    speedBoostSliderButton.Size = UDim2.new(0, 20, 0, 20)
    speedBoostSliderButton.Position = UDim2.new(CONF.speedBoost / 200, -10, 0, -5)
    speedBoostSliderButton.BackgroundColor3 = CONF.ui.text
    speedBoostSliderButton.BorderSizePixel = 0
    speedBoostSliderButton.Text = ""
    speedBoostSliderButton.Parent = speedBoostSlider
    speedBoostSliderButton.ZIndex = 104
    
    local speedBoostSliderButtonCorner = Instance.new("UICorner", speedBoostSliderButton)
    speedBoostSliderButtonCorner.CornerRadius = UDim.new(0, 10)
    
    local speedBoostDragging = false
    
    speedBoostSliderButton.MouseButton1Down:Connect(function()
        speedBoostDragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            speedBoostDragging = false
            saveConfig()
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if speedBoostDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = speedBoostSlider.AbsolutePosition
            local sliderSize = speedBoostSlider.AbsoluteSize
            
            local percent = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
            local value = math.floor(percent * 200)
            
            CONF.speedBoost = value
            speedBoostLabel.Text = "Speed Boost: " .. value
            speedBoostSliderFill.Size = UDim2.new(percent, 0, 1, 0)
            speedBoostSliderButton.Position = UDim2.new(percent, -10, 0, -5)
            
            -- Update speed if enabled
            if movement.speed.enabled then
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = CONF.speedBoost
                end
            end
        end
    end)
    
    -- ===== PROTECTION TAB =====
    local protectionContent = tabContents["Protection"]
    
    -- God mode toggle
    local godModeToggle = Instance.new("TextButton")
    godModeToggle.Name = "GodModeToggle"
    godModeToggle.Size = UDim2.new(1, -10, 0, 30)
    godModeToggle.Position = UDim2.new(0, 5, 0, 5)
    godModeToggle.BackgroundColor3 = CONF.ui.bg
    godModeToggle.BorderSizePixel = 0
    godModeToggle.Text = "Protection: " .. (godMode.enabled and "ON" or "OFF")
    godModeToggle.TextColor3 = godMode.enabled and CONF.ui.ok or CONF.ui.bad
    godModeToggle.TextSize = 14
    godModeToggle.Font = Enum.Font.Gotham
    godModeToggle.Parent = protectionContent
    godModeToggle.ZIndex = 102
    
    local godModeCorner = Instance.new("UICorner", godModeToggle)
    godModeCorner.CornerRadius = UDim.new(0, 5)
    
    godModeToggle.MouseButton1Click:Connect(function()
        toggleGodMode(not godMode.enabled)
        godModeToggle.Text = "Protection: " .. (godMode.enabled and "ON" or "OFF")
        godModeToggle.TextColor3 = godMode.enabled and CONF.ui.ok or CONF.ui.bad
    end)
    
    -- Auto Heal toggle
    local autoHealToggle = Instance.new("TextButton")
    autoHealToggle.Name = "AutoHealToggle"
    autoHealToggle.Size = UDim2.new(1, -10, 0, 30)
    autoHealToggle.Position = UDim2.new(0, 5, 0, 40)
    autoHealToggle.BackgroundColor3 = CONF.ui.bg
    autoHealToggle.BorderSizePixel = 0
    autoHealToggle.Text = "Auto Heal: " .. (autoHeal.enabled and "ON" or "OFF")
    autoHealToggle.TextColor3 = autoHeal.enabled and CONF.ui.ok or CONF.ui.bad
    autoHealToggle.TextSize = 14
    autoHealToggle.Font = Enum.Font.Gotham
    autoHealToggle.Parent = protectionContent
    autoHealToggle.ZIndex = 102
    
    local autoHealCorner = Instance.new("UICorner", autoHealToggle)
    autoHealCorner.CornerRadius = UDim.new(0, 5)
    
    autoHealToggle.MouseButton1Click:Connect(function()
        toggleAutoHeal(not autoHeal.enabled)
        autoHealToggle.Text = "Auto Heal: " .. (autoHeal.enabled and "ON" or "OFF")
        autoHealToggle.TextColor3 = autoHeal.enabled and CONF.ui.ok or CONF.ui.bad
    end)
    
    -- Heal button
    local healButton = Instance.new("TextButton")
    healButton.Name = "HealButton"
    healButton.Size = UDim2.new(1, -10, 0, 30)
    healButton.Position = UDim2.new(0, 5, 0, 75)
    healButton.BackgroundColor3 = CONF.ui.bg
    healButton.BorderSizePixel = 0
    healButton.Text = "Heal"
    healButton.TextColor3 = CONF.ui.ok
    healButton.TextSize = 14
    healButton.Font = Enum.Font.Gotham
    healButton.Parent = protectionContent
    healButton.ZIndex = 102
    
    local healCorner = Instance.new("UICorner", healButton)
    healCorner.CornerRadius = UDim.new(0, 5)
    
    healButton.MouseButton1Click:Connect(function()
        enhancedHeal()
    end)
    
    -- Revive button
    local reviveButton = Instance.new("TextButton")
    reviveButton.Name = "ReviveButton"
    reviveButton.Size = UDim2.new(1, -10, 0, 30)
    reviveButton.Position = UDim2.new(0, 5, 0, 110)
    reviveButton.BackgroundColor3 = CONF.ui.bg
    reviveButton.BorderSizePixel = 0
    reviveButton.Text = "Revive"
    reviveButton.TextColor3 = CONF.ui.ok
    reviveButton.TextSize = 14
    reviveButton.Font = Enum.Font.Gotham
    reviveButton.Parent = protectionContent
    reviveButton.ZIndex = 102
    
    local reviveCorner = Instance.new("UICorner", reviveButton)
    reviveCorner.CornerRadius = UDim.new(0, 5)
    
    reviveButton.MouseButton1Click:Connect(function()
        stealthRevive()
    end)
    
    -- Ammo button
    local ammoButton = Instance.new("TextButton")
    ammoButton.Name = "AmmoButton"
    ammoButton.Size = UDim2.new(1, -10, 0, 30)
    ammoButton.Position = UDim2.new(0, 5, 0, 145)
    ammoButton.BackgroundColor3 = CONF.ui.bg
    ammoButton.BorderSizePixel = 0
    ammoButton.Text = "Refill Ammo"
    ammoButton.TextColor3 = CONF.ui.ok
    ammoButton.TextSize = 14
    ammoButton.Font = Enum.Font.Gotham
    ammoButton.Parent = protectionContent
    ammoButton.ZIndex = 102
    
    local ammoCorner = Instance.new("UICorner", ammoButton)
    ammoCorner.CornerRadius = UDim.new(0, 5)
    
    ammoButton.MouseButton1Click:Connect(function()
        refillAll()
    end)
    
    -- Anti-detection settings
    local antiDetectionLabel = Instance.new("TextLabel")
    antiDetectionLabel.Name = "AntiDetectionLabel"
    antiDetectionLabel.Size = UDim2.new(1, -10, 0, 20)
    antiDetectionLabel.Position = UDim2.new(0, 5, 0, 180)
    antiDetectionLabel.BackgroundTransparency = 1
    antiDetectionLabel.Text = "Anti-Detection Settings"
    antiDetectionLabel.TextColor3 = CONF.ui.accent
    antiDetectionLabel.TextSize = 16
    antiDetectionLabel.Font = Enum.Font.GothamBold
    antiDetectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    antiDetectionLabel.Parent = protectionContent
    antiDetectionLabel.ZIndex = 102
    
    -- Stealth mode toggle
    local stealthModeToggle = Instance.new("TextButton")
    stealthModeToggle.Name = "StealthModeToggle"
    stealthModeToggle.Size = UDim2.new(1, -10, 0, 30)
    stealthModeToggle.Position = UDim2.new(0, 5, 0, 205)
    stealthModeToggle.BackgroundColor3 = CONF.ui.bg
    stealthModeToggle.BorderSizePixel = 0
    stealthModeToggle.Text = "Stealth Mode: " .. (antiDetection.stealthMode and "ON" or "OFF")
    stealthModeToggle.TextColor3 = antiDetection.stealthMode and CONF.ui.ok or CONF.ui.bad
    stealthModeToggle.TextSize = 14
    stealthModeToggle.Font = Enum.Font.Gotham
    stealthModeToggle.Parent = protectionContent
    stealthModeToggle.ZIndex = 102
    
    local stealthModeCorner = Instance.new("UICorner", stealthModeToggle)
    stealthModeCorner.CornerRadius = UDim.new(0, 5)
    
    stealthModeToggle.MouseButton1Click:Connect(function()
        antiDetection.stealthMode = not antiDetection.stealthMode
        stealthModeToggle.Text = "Stealth Mode: " .. (antiDetection.stealthMode and "ON" or "OFF")
        stealthModeToggle.TextColor3 = antiDetection.stealthMode and CONF.ui.ok or CONF.ui.bad
        saveConfig()
    end)
    
    -- Randomize heal amount toggle
    local randomizeHealAmountToggle = Instance.new("TextButton")
    randomizeHealAmountToggle.Name = "RandomizeHealAmountToggle"
    randomizeHealAmountToggle.Size = UDim2.new(1, -10, 0, 30)
    randomizeHealAmountToggle.Position = UDim2.new(0, 5, 0, 240)
    randomizeHealAmountToggle.BackgroundColor3 = CONF.ui.bg
    randomizeHealAmountToggle.BorderSizePixel = 0
    randomizeHealAmountToggle.Text = "Random Heal Amount: " .. (antiDetection.randomizeHealAmount and "ON" or "OFF")
    randomizeHealAmountToggle.TextColor3 = antiDetection.randomizeHealAmount and CONF.ui.ok or CONF.ui.bad
    randomizeHealAmountToggle.TextSize = 14
    randomizeHealAmountToggle.Font = Enum.Font.Gotham
    randomizeHealAmountToggle.Parent = protectionContent
    randomizeHealAmountToggle.ZIndex = 102
    
    local randomizeHealAmountCorner = Instance.new("UICorner", randomizeHealAmountToggle)
    randomizeHealAmountCorner.CornerRadius = UDim.new(0, 5)
    
    randomizeHealAmountToggle.MouseButton1Click:Connect(function()
        antiDetection.randomizeHealAmount = not antiDetection.randomizeHealAmount
        randomizeHealAmountToggle.Text = "Random Heal Amount: " .. (antiDetection.randomizeHealAmount and "ON" or "OFF")
        randomizeHealAmountToggle.TextColor3 = antiDetection.randomizeHealAmount and CONF.ui.ok or CONF.ui.bad
        saveConfig()
    end)
    
    -- Health oscillation toggle
    local healthOscillationToggle = Instance.new("TextButton")
    healthOscillationToggle.Name = "HealthOscillationToggle"
    healthOscillationToggle.Size = UDim2.new(1, -10, 0, 30)
    healthOscillationToggle.Position = UDim2.new(0, 5, 0, 275)
    healthOscillationToggle.BackgroundColor3 = CONF.ui.bg
    healthOscillationToggle.BorderSizePixel = 0
    healthOscillationToggle.Text = "Health Oscillation: " .. (antiDetection.healthOscillation and "ON" or "OFF")
    healthOscillationToggle.TextColor3 = antiDetection.healthOscillation and CONF.ui.ok or CONF.ui.bad
    healthOscillationToggle.TextSize = 14
    healthOscillationToggle.Font = Enum.Font.Gotham
    healthOscillationToggle.Parent = protectionContent
    healthOscillationToggle.ZIndex = 102
    
    local healthOscillationCorner = Instance.new("UICorner", healthOscillationToggle)
    healthOscillationCorner.CornerRadius = UDim.new(0, 5)
    
    healthOscillationToggle.MouseButton1Click:Connect(function()
        antiDetection.healthOscillation = not antiDetection.healthOscillation
        healthOscillationToggle.Text = "Health Oscillation: " .. (antiDetection.healthOscillation and "ON" or "OFF")
        healthOscillationToggle.TextColor3 = antiDetection.healthOscillation and CONF.ui.ok or CONF.ui.bad
        saveConfig()
    end)
    
    -- Cooldown display
    local cooldownLabel = Instance.new("TextLabel")
    cooldownLabel.Name = "CooldownLabel"
    cooldownLabel.Size = UDim2.new(1, -10, 0, 20)
    cooldownLabel.Position = UDim2.new(0, 5, 0, 310)
    cooldownLabel.BackgroundTransparency = 1
    cooldownLabel.Text = "Protection Cooldown: " .. (healTracking.godModeDisabledTime > 0 and 
        math.max(0, antiDetection.godModeCooldown - (tick() - healTracking.godModeDisabledTime)) .. "s" or "Ready")
    cooldownLabel.TextColor3 = healTracking.godModeDisabledTime > 0 and 
        (tick() - healTracking.godModeDisabledTime < antiDetection.godModeCooldown and CONF.ui.bad or CONF.ui.ok) or CONF.ui.ok
    cooldownLabel.TextSize = 14
    cooldownLabel.Font = Enum.Font.Gotham
    cooldownLabel.TextXAlignment = Enum.TextXAlignment.Left
    cooldownLabel.Parent = protectionContent
    cooldownLabel.ZIndex = 102
    
    -- Update cooldown display
    RunService.Heartbeat:Connect(function()
        if healTracking.godModeDisabledTime > 0 then
            local remaining = math.max(0, antiDetection.godModeCooldown - (tick() - healTracking.godModeDisabledTime))
            cooldownLabel.Text = "Protection Cooldown: " .. (remaining > 0 and remaining .. "s" or "Ready")
            cooldownLabel.TextColor3 = remaining > 0 and CONF.ui.bad or CONF.ui.ok
        else
            cooldownLabel.Text = "Protection Cooldown: Ready"
            cooldownLabel.TextColor3 = CONF.ui.ok
        end
    end)
    
    -- Make menu draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    menuFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and input.Position.Y < menuFrame.AbsolutePosition.Y + 40 then
            dragging = true
            dragStart = input.Position
            startPos = menuFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            menuFrame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Toggle menu with F1
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == CONF.menuKey then
            menuFrame.Visible = not menuFrame.Visible
        end
    end)
    
    return menuFrame
end

-- Create the menu
local menu = createMenu()

-- ===== MAIN LOOP =====
-- Enhanced with professional anti-detection features and FOV
RunService.RenderStepped:Connect(function()
    -- Smooth FOV transition if enabled
    if CONF.aimFov.smoothTransition and aimbot.currentTarget then
        local targetSize = CONF.aimFov.size
        if CONF.aimFov.dynamicSize then
            local distance = aimbot.currentTarget.distance
            local distanceFactor = math.min(distance / 1000, 1)
            targetSize = CONF.aimFov.innerSize + (CONF.aimFov.size - CONF.aimFov.innerSize) * distanceFactor
        end
        
        local currentSize = fovCircle.Size.X.Offset / 2
        local newSize = currentSize + (targetSize - currentSize) * 0.1
        fovCircle.Size = UDim2.new(0, newSize * 2, 0, newSize * 2)
    end
    
    if CONF.aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local targets = getTargets()
        local bestTarget = findBestTarget(targets)
        
        if bestTarget then
            -- Start aiming if not already aiming
            if not aimbot.isAiming then
                aimbot.isAiming = true
                aimbot.aimStartTime = tick()
            end
            
            -- Simulate human reaction time
            if tick() - aimbot.aimStartTime < CONF.humanReactionTime then
                return
            end
            
            local predictedPos = predictPosition(bestTarget.player, bestTarget.part)
            
            -- Apply intentional misses
            if math.random() < CONF.missChance then
                local missAngle = math.random(-CONF.maxMissAngle, CONF.maxMissAngle)
                local rotationCFrame = CFrame.Angles(0, math.rad(missAngle), 0)
                predictedPos = predictedPos + rotationCFrame.LookVector * 5
                aimbot.consecutiveHits = 0
            else
                aimbot.consecutiveHits = aimbot.consecutiveHits + 1
            end
            
            -- Apply accuracy decay
            aimbot.currentAccuracy = math.max(0.7, 1.0 - (aimbot.consecutiveHits * CONF.aimDecayRate))
            
            -- Add random offset based on accuracy
            local randomOffset = Vector3.new(
                math.random(-1, 1) * (1 - aimbot.currentAccuracy),
                math.random(-1, 1) * (1 - aimbot.currentAccuracy),
                math.random(-1, 1) * (1 - aimbot.currentAccuracy)
            )
            predictedPos = predictedPos + randomOffset
            
            -- Apply aim jitter
            if CONF.aimJitterAmount > 0 then
                local jitter = Vector3.new(
                    math.random(-CONF.aimJitterAmount, CONF.aimJitterAmount),
                    math.random(-CONF.aimJitterAmount, CONF.aimJitterAmount),
                    math.random(-CONF.aimJitterAmount, CONF.aimJitterAmount)
                )
                predictedPos = predictedPos + jitter
            end
            
            -- Apply aim spike occasionally
            if math.random() < CONF.aimSpikeChance then
                local spikeAmount = math.random(2, 5)
                local spikeDirection = Vector3.new(
                    math.random(-1, 1),
                    math.random(-1, 1),
                    math.random(-1, 1)
                ).Unit
                predictedPos = predictedPos + spikeDirection * spikeAmount
            end
            
            -- Debug information
            if CONF.debugMode then
                print("Aimbot activated with accuracy:", aimbot.currentAccuracy)
                print("Target part:", bestTarget.part.Name)
                print("Distance to target:", bestTarget.distance)
            end
            
            -- Preparation phase
            local prepStart = tick()
            local prepConnection
            prepConnection = RunService.Heartbeat:Connect(function()
                if tick() - prepStart >= CONF.aimPreparationTime then
                    prepConnection:Disconnect()
                    
                    -- Start actual aiming with advanced curved motion
                    local startPos = Camera.CFrame.Position
                    
                    -- Create multiple control points for more natural curve
                    local controlPoints = {startPos}
                    local numControlPoints = math.random(2, 4)
                    
                    for i = 1, numControlPoints do
                        local t = i / (numControlPoints + 1)
                        local midPoint = startPos:Lerp(predictedPos, t)
                        local variation = Vector3.new(
                            math.random(-CONF.aimCurveVariation, CONF.aimCurveVariation),
                            math.random(-CONF.aimCurveVariation, CONF.aimCurveVariation),
                            math.random(-CONF.aimCurveVariation, CONF.aimCurveVariation)
                        )
                        midPoint = midPoint + variation
                        table.insert(controlPoints, midPoint)
                    end
                    
                    table.insert(controlPoints, predictedPos)
                    
                    -- Calculate smoothness based on distance
                    local smoothness = CONF.aimSmoothMin
                    if CONF.adaptiveSmoothness then
                        local distanceFactor = math.min(bestTarget.distance / 1000, 1)
                        smoothness = CONF.aimSmoothMin + (CONF.aimSmoothMax - CONF.aimSmoothMin) * distanceFactor
                    end
                    
                    -- Apply micro corrections
                    if CONF.microCorrections then
                        smoothness = smoothness + math.random(-0.01, 0.01)
                    end
                    
                    -- Calculate aim curve with Bezier
                    local curveProgress = 0
                    local aimConnection
                    aimConnection = RunService.RenderStepped:Connect(function(deltaTime)
                        curveProgress = math.min(1, curveProgress + deltaTime / smoothness)
                        
                        local currentPos = calculateAdvancedBezierPoint(controlPoints, curveProgress)
                        local lookAtCFrame = CFrame.new(Camera.CFrame.Position, currentPos)
                        
                        -- Apply recoil simulation
                        if CONF.recoilSimulation and aimbot.consecutiveHits > 2 then
                            local recoilIndex = (aimbot.currentRecoilIndex % #aimbot.recoilPattern) + 1
                            local recoil = aimbot.recoilPattern[recoilIndex]
                            aimbot.currentRecoilIndex = recoilIndex
                            
                            local recoilCFrame = CFrame.Angles(
                                math.rad(recoil.Y * 0.5),
                                math.rad(recoil.X * 0.5),
                                0
                            )
                            lookAtCFrame = lookAtCFrame * recoilCFrame
                        end
                        
                        Camera.CFrame = Camera.CFrame:Lerp(lookAtCFrame, deltaTime * 10)
                        
                        if curveProgress >= 1 then
                            aimConnection:Disconnect()
                        end
                    end)
                end
            end)
        else
            aimbot.isAiming = false
            aimbot.currentTarget = nil
        end
    else
        aimbot.isAiming = false
        aimbot.currentTarget = nil
    end
    
    -- Update ESP
    updateESP()
    
    -- Update FOV circle
    updateFOVCircle()
end)
