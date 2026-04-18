local function GetScriptDir()
    local modPath = debug.getinfo(1, "S").source
    modPath = modPath:gsub("^@", "")
    modPath = modPath:gsub("[/\\][^/\\]+$", "/")
    return modPath
end

local function LoadConfig()
    local scriptDir = GetScriptDir()
    local paths = {
        scriptDir .. "../config.ini",
        scriptDir .. "config.ini",
    }
    for _, configPath in ipairs(paths) do
        local f = io.open(configPath, "r")
        if f then
            print("[LevyAI] Config loaded from: " .. configPath)
            local config = {}
            for line in f:lines() do
                if not line:match("^%s*[;#]")
                   and not line:match("^%s*%[")
                   and line:match("=") then
                    local key, value = line:match("^%s*(.-)%s*=%s*(.-)%s*$")
                    if key and value and value ~= "" then
                        config[key] = value
                    end
                end
            end
            f:close()
            return config
        end
    end
    print("[LevyAI] config.ini not found")
    return {}
end

local CFG = LoadConfig()

local function GetDataPath()
    local data_path = nil
    if CFG then
        data_path = CFG["data_path"]
    end
    if not data_path or data_path == "" then
        data_path = GetScriptDir() .. "../../../../../../LevyAI/data/"
    end
    data_path = data_path:gsub("\\", "/")
    if not data_path:match("/$") then
        data_path = data_path .. "/"
    end
    return data_path
end

local function GetPostPyPath()
    local post_py = nil
    if CFG then
        post_py = CFG["post_py"]
    end
    if not post_py or post_py == "" then
        post_py = GetScriptDir() .. "../../../../../../LevyAI/post.py"
    end
    post_py = post_py:gsub("\\", "/")
    return post_py
end

local function GetInputFilePath()
    return GetDataPath() .. "input.txt"
end

local function GetOutputFilePath()
    return GetDataPath() .. "output.txt"
end

local isWaitingReply = false
local isDialogShown = false

local function fix_encoding(str)
    if not str then return "" end
    if str:sub(1, 3) == "\239\187\191" then
        str = str:sub(4)
    end
    return str
end

local MOOD_ANIM_MAP = {
    idle      = "idle_a",
    happy     = "greeting_loop",
    sad       = "think_loop",
    shy       = "kick",
    sulk      = "think_loop",
    frighten  = "frighten_loop",
    think     = "think_loop",
    greet     = "greeting_loop",
}

local function ParseAIReply(rawReply)
    local mood = "idle"
    local text = rawReply
    
    local moodMatch = rawReply:match("^%[([%w_]+)%]%s*(.+)$")
    if moodMatch then
        mood = moodMatch
        text = rawReply:gsub("^%[[%w_]+%]%s*", "")
    end
    
    if not MOOD_ANIM_MAP[mood] then
        mood = "idle"
    end
    
    if text == "" or text == mood then
        text = rawReply:gsub("^%[[%w_]+%]%s*", "")
    end
    
    return mood, text
end

local function ReadOutput()
    local OUTPUT_FILE = GetOutputFilePath()
    local f = io.open(OUTPUT_FILE, "rb")
    if f then
        local content = f:read("*a")
        f:close()
        if content then
            content = fix_encoding(content)
            content = content:match("^%s*(.-)%s*$") or ""
            if content ~= "" then
                if not content:match("%[%w+%]") then
                    return ""
                end
                if #content < 10 then
                    return ""
                end
            end
            return content
        end
    end
    return ""
end

local function ClearOutput()
    local OUTPUT_FILE = GetOutputFilePath()
    local f = io.open(OUTPUT_FILE, "w")
    if f then
        f:write("")
        f:close()
    end
end

local function ReadInput()
    local INPUT_FILE = GetInputFilePath()
    local f = io.open(INPUT_FILE, "rb")
    if f then
        local content = f:read("*a")
        f:close()
        if content then
            content = fix_encoding(content)
            content = content:match("^%s*(.-)%s*$") or ""
        end
        return content or ""
    end
    return ""
end

local function ClearInput()
    local INPUT_FILE = GetInputFilePath()
    local f = io.open(INPUT_FILE, "w")
    if f then
        f:write("")
        f:close()
    end
end

local function OpenInputWindow()
    local POST_PY = GetPostPyPath()
    local INPUT_FILE = GetInputFilePath()
    local cmd = string.format(
        'start "" /B pythonw "%s" "%s"',
        POST_PY:gsub("/", "\\"),
        INPUT_FILE:gsub("/", "\\")
    )
    os.execute(cmd)
    print("[LevyAI] Input window opened")
end

local function ShowDialog(bodyText, speakerName)
    local ok, tbs = pcall(function() return FindAllOf("TextBlock") end)
    if not ok or not tbs then
        return false
    end

    local lineBlock = nil
    local speakerBlock = nil

    for _, tb in ipairs(tbs) do
        local ok2, valid = pcall(function() return tb:IsValid() end)
        if not ok2 or not valid then goto skip end
        local ok3, fn = pcall(function() return tb:GetFullName() end)
        if not ok3 then goto skip end

        if type(fn) ~= "string" then goto skip end

        if fn:find("Transient") and fn:find("WBP_Event_C") then
            if not fn:find("RestMenu") and not fn:find("GameMenu")
               and not fn:find("Footer") and not fn:find("Button")
               and not fn:find("RestPoint") and not fn:find("Area")
               and not fn:find("EventBanner") then
                if fn:find("LineText") and not fn:find("Choice") then
                    lineBlock = tb
                elseif fn:find("SpeakerName") and not fn:find("Choice") then
                    speakerBlock = tb
                end
            end
        end
        ::skip::
    end

    if not lineBlock then
        return false
    end

    pcall(function()
        lineBlock:SetText(FText(bodyText))
    end)
    
    if speakerBlock then
        pcall(function()
            speakerBlock:SetText(FText(speakerName or "露薇"))
        end)
    end

    local ok4, widgets = pcall(function() return FindAllOf("WBP_Event_C") end)
    if ok4 and widgets then
        for _, w in ipairs(widgets) do
            local ok5, fn = pcall(function() return w:GetFullName() end)
            if ok5 and fn and type(fn) == "string" and fn:find("Transient") then
                local ok6, inViewport = pcall(function()
                    return w:IsInViewport()
                end)
                if not ok6 or not inViewport then
                    pcall(function() w:AddToViewport(100) end)
                end
                pcall(function() w:SetVisibility(0) end)
                pcall(function() w:SetIsFocusable(false) end)
            end
        end
    end

    local ok7, overlays = pcall(function() return FindAllOf("Overlay") end)
    if ok7 and overlays then
        for _, ov in ipairs(overlays) do
            local ok8, fn = pcall(function() return ov:GetFullName() end)
            if ok8 and fn and type(fn) == "string" and fn:find("Transient")
               and fn:find("Overlay_LineDisplay")
               and fn:find("WBP_Event_C") then
                pcall(function() ov:SetVisibility(0) end)
            end
        end
    end

    local ok9, pc = pcall(function() return FindFirstOf("PlayerController") end)
    if ok9 and pc and pc:IsValid() then
        pcall(function() pc:SetInputMode_GameOnly() end)
        pcall(function() pc:SetInputModeGameOnly() end)
        pcall(function() pc:FlushPressedKeys() end)
    end

    isDialogShown = true
    return true
end

local function HideDialog()
    local ok, widgets = pcall(function() return FindAllOf("WBP_Event_C") end)
    if ok and widgets then
        for _, w in ipairs(widgets) do
            local ok2, fn = pcall(function() return w:GetFullName() end)
            if ok2 and fn and type(fn) == "string" and fn:find("Transient") then
                pcall(function() w:SetVisibility(1) end)
            end
        end
    end

    local ok3, overlays = pcall(function() return FindAllOf("Overlay") end)
    if ok3 and overlays then
        for _, ov in ipairs(overlays) do
            local ok4, fn = pcall(function() return ov:GetFullName() end)
            if ok4 and fn and type(fn) == "string" and fn:find("Transient")
               and fn:find("Overlay_LineDisplay")
               and fn:find("WBP_Event_C") then
                pcall(function() ov:SetVisibility(1) end)
            end
        end
    end

    local ok5, pc = pcall(function() return FindFirstOf("PlayerController") end)
    if ok5 and pc and pc:IsValid() then
        pcall(function() pc:SetInputMode_GameOnly() end)
        pcall(function() pc:SetInputModeGameOnly() end)
    end

    isDialogShown = false
end

local function SetLevyTalkAnim(animName)
    local ok, levys = pcall(function() return FindAllOf("BP_n7010_Levy_C") end)
    if not ok or not levys then
        return
    end

    for _, levy in ipairs(levys) do
        local ok2, valid = pcall(function() return levy:IsValid() end)
        if ok2 and valid then
            pcall(function()
                if levy.SpineAnimatorComponent then
                    levy.SpineAnimatorComponent.bUpdateLocomotion = false
                end
                if levy.SpineAnimationComponent then
                    levy.SpineAnimationComponent:SetAnimation(0, animName, true)
                end
            end)
        end
    end
end

local function WaitForInputAndSend()
    if isWaitingReply then
        print("[LevyAI] Still waiting for previous reply")
        return
    end

    ClearOutput()
    OpenInputWindow()

    local waitCount = 0
    local gotInput = false

    LoopAsync(200, function()
        waitCount = waitCount + 1

        if waitCount > 300 then
            print("[LevyAI] Input timeout")
            return true
        end

        ExecuteInGameThread(function()
            local msg = ReadInput()
            if msg == "" or msg == "STATUS:THINKING" then return end

            gotInput = true
            print("[LevyAI] Got input: " .. msg)

            isWaitingReply = true
            local replyHandled = false

            ShowDialog("......", "露薇")
            SetLevyTalkAnim("talk_start")

            local pollCount = 0

            LoopAsync(300, function()
                pollCount = pollCount + 1

                if pollCount > 133 then
                    ExecuteInGameThread(function()
                        if replyHandled then return end
                        replyHandled = true
                        isWaitingReply = false
                        print("[LevyAI] AI timeout")
                        HideDialog()
                        SetLevyTalkAnim("idle_a")
                    end)
                    return true
                end

                ExecuteInGameThread(function()
                    if replyHandled then return end

                    local reply = ReadOutput()
                    if reply == "" or reply == "STATUS:THINKING" then
                        return
                    end

                    replyHandled = true
                    isWaitingReply = false
                    ClearOutput()

                    local mood, replyText = ParseAIReply(reply)

                    local shown = ShowDialog(replyText, "露薇")

                    if shown then
                        local anim = MOOD_ANIM_MAP[mood] or "talk_loop"
                        SetLevyTalkAnim(anim)
                        
                        LoopAsync(5000, function()
                            ExecuteInGameThread(function()
                                HideDialog()
                                SetLevyTalkAnim("idle_a")
                            end)
                            return true
                        end)
                    else
                        print("[LevyAI] Dialog not shown, resetting")
                        LoopAsync(1000, function()
                            ExecuteInGameThread(function()
                                isWaitingReply = false
                                HideDialog()
                                SetLevyTalkAnim("idle_a")
                            end)
                            return true
                        end)
                    end
                end)

                if replyHandled then return true end
                return false
            end)
        end)

        if gotInput then return true end
        return false
    end)
end

RegisterKeyBind(Key.F, { ModifierKey.ALT }, function()
    ExecuteInGameThread(function()
        WaitForInputAndSend()
    end)
end)

RegisterKeyBind(Key.F12, { ModifierKey.ALT }, function()
    ExecuteInGameThread(function()
        HideDialog()
        SetLevyTalkAnim("idle_a")
        isWaitingReply = false
        print("[LevyAI] Force closed")
    end)
end)

print("[LevyAI] Loaded")
print("[LevyAI] Alt+F = Talk to Levy")
print("[LevyAI] Alt+F12 = Force close dialog")
