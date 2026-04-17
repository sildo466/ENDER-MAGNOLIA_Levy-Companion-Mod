local UEHelpers = require("UEHelpers")

local LevyPath   = "/Game/_Zion/Characters/n7010_Levy/BP_n7010_Levy.BP_n7010_Levy_C"
local ActiveLevy = nil
local LevyState  = "none"
local AnimCooldown = 0
local LevyEnabled = false

local FOLLOW_DISTANCE = 250
local STOP_DISTANCE   = 200
local TICK_MS         = 16
local WALK_SPEED      = 1.0
local RUN_SPEED       = 1.8
local DASH_SPEED      = 2.2
local RUN_ENTER       = 500
local RUN_LEAVE       = 350
local DASH_ENTER      = 1200
local DASH_LEAVE      = 900
local LERP_Y          = 0.25
local LERP_Z          = 0.08

local function GetOrLoad(path)
    local obj = StaticFindObject(path)
    if not obj:IsValid() then obj = LoadAsset(path) end
    return obj
end

local function SetLevyAnim(newState)
    if LevyState == newState then return end
    if not ActiveLevy or not ActiveLevy:IsValid() then return end
    if AnimCooldown > 0 then return end

    local SAC = ActiveLevy.SpineAnimationComponent
    if not SAC or not SAC:IsValid() then return end

    local animMap = {
        idle      = { name = "idle_a",    loop = true  },
        walk      = { name = "walk_a",    loop = true  },
        run       = { name = "walk_a",    loop = true  },
        dash      = { name = "walk_a",    loop = true  },
        run_stop  = { name = "idle_a",    loop = true  },
        dash_stop = { name = "idle_a",    loop = true  },
    }

    local entry = animMap[newState]
    if not entry then return end

    local currentAnim = ""
    if LevyState == "idle" or LevyState == "none" then
        currentAnim = "idle_a"
    else
        currentAnim = "walk_a"
    end

    local needSwitch = (currentAnim ~= entry.name)

    if needSwitch then
        local ok = pcall(function()
            SAC:SetAnimation(0, entry.name, entry.loop)
        end)
        if not ok then return end
    end

    LevyState = newState
    if needSwitch then
        AnimCooldown = 31
    end
end

local function SpawnLevy()
    local PC = UEHelpers:GetPlayerController()
    if not PC or not PC:IsValid() then return false end

    local Player = PC.Pawn
    if not Player or not Player:IsValid() then
        Player = FindFirstOf("Character")
    end
    if not Player or not Player:IsValid() then return false end

    local Class = GetOrLoad(LevyPath)
    if not Class or not Class:IsValid() then return false end

    if ActiveLevy and ActiveLevy:IsValid() then
        ActiveLevy:K2_DestroyActor()
        ActiveLevy = nil
        LevyState  = "none"
    end

    local Loc = Player:K2_GetActorLocation()
    ActiveLevy = PC:GetWorld():SpawnActor(Class,
        { X = Loc.X, Y = Loc.Y + 200.0, Z = Loc.Z },
        { Pitch = 0.0, Yaw = 90.0, Roll = 0.0 })

    if not ActiveLevy or not ActiveLevy:IsValid() then
        ActiveLevy = nil
        return false
    end

    if ActiveLevy.SpineAnimatorComponent:IsValid() then
        ActiveLevy.SpineAnimatorComponent.bUpdateLocomotion = false
    end

    LevyState    = "none"
    AnimCooldown = 0
    SetLevyAnim("idle")
    print("[Spawn] Levy spawned")
    return true
end

RegisterKeyBind(Key.EIGHT, { ModifierKey.ALT }, function()
    ExecuteInGameThread(function()
        if LevyEnabled then
            LevyEnabled = false
            if ActiveLevy and ActiveLevy:IsValid() then
                ActiveLevy:K2_DestroyActor()
                ActiveLevy = nil
                LevyState  = "none"
            end
            print("[Toggle] Levy DISABLED")
        else
            LevyEnabled = true
            print("[Toggle] Levy ENABLED")
            SpawnLevy()
        end
    end)
end)

RegisterKeyBind(Key.F1, { ModifierKey.ALT }, function()
    ExecuteInGameThread(function()
        if not ActiveLevy or not ActiveLevy:IsValid() then return end
        local PC = UEHelpers:GetPlayerController()
        if not PC or not PC:IsValid() then return end
        local Player = PC.Pawn
        if not Player or not Player:IsValid() then
            Player = FindFirstOf("Character")
        end
        if not Player or not Player:IsValid() then return end
        local Loc = Player:K2_GetActorLocation()
        ActiveLevy:K2_SetActorLocation(
            { X = Loc.X, Y = Loc.Y + 200.0, Z = Loc.Z },
            false, {}, false)
        LevyState    = "none"
        AnimCooldown = 0
        SetLevyAnim("idle")
        print("[Teleport] Done")
    end)
end)

RegisterKeyBind(Key.SIX, { ModifierKey.ALT }, function()
    ExecuteInGameThread(function()
        WALK_SPEED = WALK_SPEED + 1.0
        RUN_SPEED  = RUN_SPEED  + 1.0
        DASH_SPEED = DASH_SPEED + 1.0
        print(string.format("[Speed] +1 | W=%.1f R=%.1f D=%.1f", WALK_SPEED, RUN_SPEED, DASH_SPEED))
    end)
end)

RegisterKeyBind(Key.SEVEN, { ModifierKey.ALT }, function()
    ExecuteInGameThread(function()
        WALK_SPEED = math.max(0.1, WALK_SPEED - 1.0)
        RUN_SPEED  = math.max(0.1, RUN_SPEED  - 1.0)
        DASH_SPEED = math.max(0.1, DASH_SPEED - 1.0)
        print(string.format("[Speed] -1 | W=%.1f R=%.1f D=%.1f", WALK_SPEED, RUN_SPEED, DASH_SPEED))
    end)
end)

local respawnCooldown = 0

LoopAsync(500, function()
    if not LevyEnabled then return false end
    local levyGone = (ActiveLevy == nil) or not ActiveLevy:IsValid()
    if levyGone then
        if respawnCooldown > 0 then
            respawnCooldown = respawnCooldown - 500
            return false
        end
        ExecuteInGameThread(function()
            local ok = SpawnLevy()
            respawnCooldown = ok and 2000 or 1000
        end)
    end
    return false
end)

local function PlaySequence(steps)
    if not ActiveLevy or not ActiveLevy:IsValid() then return end
    local SAC = ActiveLevy.SpineAnimationComponent
    if not SAC or not SAC:IsValid() then return end

    LevyState = "interact"
    AnimCooldown = 0

    for _, step in ipairs(steps) do
        if step.delay == 0 then
            pcall(function() SAC:SetAnimation(0, step.anim, step.loop) end)
        else
            LoopAsync(step.delay, function()
                ExecuteInGameThread(function()
                    if not ActiveLevy or not ActiveLevy:IsValid() then return end
                    if step.anim == "IDLE" then
                        LevyState = "none"
                        SetLevyAnim("idle")
                    else
                        pcall(function() SAC:SetAnimation(0, step.anim, step.loop) end)
                    end
                end)
                return true
            end)
        end
    end
end

RegisterKeyBind(Key.ONE, { ModifierKey.ALT }, function()
    ExecuteInGameThread(function()
        print("[Interact] Greeting")
        PlaySequence({
            { delay = 0,    anim = "greeting_start", loop = false },
            { delay = 1000, anim = "greeting_loop",  loop = true  },
            { delay = 3000, anim = "greeting_end",   loop = false },
            { delay = 4500, anim = "IDLE",           loop = true  },
        })
    end)
end)

RegisterKeyBind(Key.TWO, { ModifierKey.ALT }, function()
    ExecuteInGameThread(function()
        print("[Interact] Give")
        PlaySequence({
            { delay = 0,    anim = "give_start", loop = false },
            { delay = 1000, anim = "give_loop",  loop = true  },
            { delay = 3000, anim = "give_end",   loop = false },
            { delay = 4500, anim = "IDLE",       loop = true  },
        })
    end)
end)

RegisterKeyBind(Key.THREE, { ModifierKey.ALT }, function()
    ExecuteInGameThread(function()
        print("[Interact] Talk")
        PlaySequence({
            { delay = 0,    anim = "talk_start", loop = false },
            { delay = 800,  anim = "talk_loop",  loop = true  },
            { delay = 3500, anim = "talk_end",   loop = false },
            { delay = 5000, anim = "IDLE",       loop = true  },
        })
    end)
end)

RegisterKeyBind(Key.FOUR, { ModifierKey.ALT }, function()
    ExecuteInGameThread(function()
        print("[Interact] Frighten")
        PlaySequence({
            { delay = 0,    anim = "frighten_start", loop = false },
            { delay = 800,  anim = "frighten_loop",  loop = true  },
            { delay = 3000, anim = "frighten_end",   loop = false },
            { delay = 4500, anim = "IDLE",           loop = true  },
        })
    end)
end)

local shyToggle = true
RegisterKeyBind(Key.FIVE, { ModifierKey.ALT }, function()
    ExecuteInGameThread(function()
        if shyToggle then
            print("[Interact] Shy (kick)")
            PlaySequence({
                { delay = 0,    anim = "kick",     loop = true  },
                { delay = 3000, anim = "IDLE",     loop = true  },
            })
        else
            print("[Interact] Sulk (think)")
            PlaySequence({
                { delay = 0,    anim = "think_start", loop = false },
                { delay = 500,  anim = "think_loop",  loop = true  },
                { delay = 3000, anim = "IDLE",        loop = true  },
            })
        end
        shyToggle = not shyToggle
    end)
end)

RegisterKeyBind(Key.NINE, { ModifierKey.ALT }, function()
    ExecuteInGameThread(function()
        print("[Interact] Look-up greeting")
        PlaySequence({
            { delay = 0,    anim = "look_up_start",           loop = false },
            { delay = 500,  anim = "greeting_start_look_up",  loop = false },
            { delay = 1500, anim = "greeting_loop_look_up",   loop = true  },
            { delay = 3500, anim = "greeting_end_look_up",    loop = false },
            { delay = 4500, anim = "look_up_end",             loop = false },
            { delay = 5500, anim = "IDLE",                    loop = true  },
        })
    end)
end)

LoopAsync(16, function()
    if not ActiveLevy or not ActiveLevy:IsValid() then
        return false
    end

    ExecuteInGameThread(function()
        if AnimCooldown > 0 then
            AnimCooldown = AnimCooldown - 1
        end

        if LevyState == "interact" then return end

        local PC = UEHelpers:GetPlayerController()
        if not PC or not PC:IsValid() then return end

        local Player = PC.Pawn
        if not Player or not Player:IsValid() then
            Player = FindFirstOf("Character")
        end
        if not Player or not Player:IsValid() then return end

        local PLoc     = Player:K2_GetActorLocation()
        local LLoc     = ActiveLevy:K2_GetActorLocation()
        local DistY    = PLoc.Y - LLoc.Y
        local DistZ    = PLoc.Z - LLoc.Z
        local AbsDistY = math.abs(DistY)

        if AbsDistY < STOP_DISTANCE then
            if math.abs(DistZ) > 2 then
                ActiveLevy:K2_SetActorLocation(
                    { X = PLoc.X, Y = LLoc.Y, Z = LLoc.Z + (DistZ * LERP_Z) },
                    false, {}, false)
            end
            if LevyState == "walk" or LevyState == "run" or LevyState == "dash" then
                SetLevyAnim("idle")
            end
            return
        end

        if AbsDistY > FOLLOW_DISTANCE then
            local DirY = (DistY > 0) and 1 or -1
            local Speed = WALK_SPEED
            local Anim = "walk"

            if AbsDistY > DASH_ENTER then
                Speed = DASH_SPEED
                Anim = "dash"
            elseif AbsDistY > RUN_ENTER then
                Speed = RUN_SPEED
                Anim = "run"
            end

            local MoveY = (PLoc.Y - LLoc.Y) * LERP_Y
            if math.abs(MoveY) > Speed then
                MoveY = DirY * Speed
            end

            ActiveLevy:K2_SetActorLocation(
                { X = PLoc.X, Y = LLoc.Y + MoveY, Z = LLoc.Z + (DistZ * LERP_Z) },
                false, {}, false)

            ActiveLevy:K2_SetActorRotation(
                { Pitch = 0.0, Yaw = (DirY > 0) and 90.0 or -90.0, Roll = 0.0 },
                false)

            if LevyState == "idle" or LevyState == "none" then
                SetLevyAnim(Anim)
            end
            return
        end

        if math.abs(DistZ) > 2 then
            ActiveLevy:K2_SetActorLocation(
                { X = PLoc.X, Y = LLoc.Y, Z = LLoc.Z + (DistZ * LERP_Z) },
                false, {}, false)
        end
    end)

    return false
end)

print("[System] Levy Final v2 loaded.")
print("[System] Alt+8   = Toggle ON/OFF")
print("[System] Alt+F1  = Teleport")
print("[System] Alt+6/7 = Speed +/-")
print("[System] Alt+1   = Greeting")
print("[System] Alt+2   = Give item")
print("[System] Alt+3   = Talk")
print("[System] Alt+4   = Frighten")
print("[System] Alt+5   = Shy / Sulk")
print("[System] Alt+9   = Look-up greeting")