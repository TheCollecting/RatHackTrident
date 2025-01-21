local SleepAnimationId = "rbxassetid://13280887764"

local lighting = game:GetService("Lighting")
local CurrentCamera = workspace.CurrentCamera
local screenCenter = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y / 2)

local players = {} -- Text
local playerList = {} -- Player instance?

local ores = {} -- Text
local oreList = {} -- Ore instance?

local esp = {
    enabled = true,
    color = Color3.fromHex('ff89a4'),
    distance = 500,
    ore = {
        enabled = true,
        color = Color3.fromHex('ff89a4'),
        distance = 500,
        oresToShow = {},
    }
}

local visuals = {
    fullbright = {
        enabled = false,
        color = Color3.fromHex('ff89a4'),
        brightness = 1,
    },
    FOV = {
        enabled = true,
        FOV = 70,
    },
    Zoom = {
        enabled = false,
        bindheld = false,
        key = 'B',
        zoomToFov = 20,
    }
}

local hitBox = {
    enabled = false,
    size = 5,
    Part = "Head",
    Transparency = 0.7,
}

function isPlayer (Model)
    return Model.ClassName == "Model" and Model:FindFirstChild("Torso") and Model.PrimaryPart ~= nil
end

function isSleeping(Player)
    local Animations = Player.AnimationController:GetPlayingAnimationTracks()
    for i, v in pairs(Animations) do
        if (v.IsPlaying and v.Animation.AnimationId == SleepAnimationId) then
            return true
        end
    end
    return false
end

function isOre(Model)
    return Model.ClassName == "Model" and Model:FindFirstChild("Part") and Model.PrimaryPart ~= nil and Model:FindFirstChild("Part").Color == Color3.fromRGB(105, 102, 92)
end

function clearOreText()
    for _, i in ores do
        i:Remove()
    end
end

function initOreList()
    table.clear(oreList)
    for i, v in pairs(workspace:GetChildren()) do
        if isOre(v) then
            table.insert(oreList, v)
        end
    end
end

function initOreText()
    clearOreText()
    for i = 0, 500 do
        local ore = Drawing.new("Text")
        ore.Center = true
        ore.Visible = false
        table.insert(ores, ore)
    end
end

function hideAllOreText()
    for _, i in ores do
        i.Visible = false
    end
end

function initPlayerList()
    table.clear(playerList)
    for i, v in pairs(workspace:GetChildren()) do
        if isPlayer(v) then
            table.insert(playerList, v)
        end
    end
end

function hideAllPlayerText()
    for _, i in players do
        i.Visible = false
    end
end

function clearPlayerText()
    for _, i in players do
        i:Remove()
    end
end

function initPlayerText()
    clearPlayerText()
    for i = 0, 500 do
        local player = Drawing.new("Text")
        player.Center = true
        player.Visible = false
        table.insert(players, player)
    end
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalSizes = {}
for i, v in pairs(ReplicatedStorage.Shared.entities.Player.Model:GetChildren()) do
    if v:IsA("BasePart") then
        OriginalSizes[v.Name] = v.Size
    end
end

function fullbrightfunc()
    if visuals.fullbright.enabled then
        if lighting.GlobalShadows then
            lighting.GlobalShadows = false
        end
        lighting.Brightness = visuals.fullbright.brightness
        lighting.Ambient = visuals.fullbright.color
    else
        if not lighting.GlobalShadows then
            lighting.GlobalShadows = true
        end
    end
end

function hitBoxExpander(Model, Size)
    if (hitBox.enabled) then
        local Part = Model[hitBox.Part]
        Part.Size = Vector3.new(Size, Size, Size)
        Part.Transparency = hitBox.Transparency
        Part.CanCollide = false
    else
        local Part = Model[hitBox.Part]
        Part.Size = OriginalSizes[hitBox.Part]
        Part.Transparency = 0
        Part.CanCollide = true
    end
end

local crosshair = {
    enabled = true,
    x = Drawing.new("Line"),
    y = Drawing.new("Line"),
}

function drawCrosshair()
    if crosshair.enabled then
        crosshair.x.Visible = true
        crosshair.x.From = Vector2.new(screenCenter.X - 6, screenCenter.Y)
        crosshair.x.To = Vector2.new(screenCenter.X + 7, screenCenter.Y)
        crosshair.x.Color = Color3.fromHex('ff89a4')
        crosshair.x.Thickness = 2
        crosshair.x.Transparency = 1

        crosshair.y.Visible = true
        crosshair.y.From = Vector2.new(screenCenter.X, screenCenter.Y - 6)
        crosshair.y.To = Vector2.new(screenCenter.X, screenCenter.Y + 7)
        crosshair.y.Color = Color3.fromHex('ff89a4')
        crosshair.y.Thickness = 2
        crosshair.y.Transparency = 1
    else
        crosshair.x.Visible = false
        crosshair.y.Visible = false
    end
end

local GameLoop = game:GetService("RunService").Heartbeat:Connect(function()
    drawCrosshair()
    fullbrightfunc()
    for i, v in pairs(workspace:GetChildren()) do
        if isPlayer(v) then
            hitBoxExpander(v, hitBox.size)
        end
    end
end)

-- TODO: Make this somewhat readable
local ESPLoop = game:GetService("RunService").RenderStepped:Connect(function()
    -------------- Gotta be a better performing way to do this (✿◠‿◠)
    hideAllPlayerText()
    hideAllOreText()
    initPlayerList()
    initOreList()
    --------------

    if visuals.Zoom.enabled then
        visuals.Zoom.bindheld = Options.ZoomKeyPicker:GetState()
        if visuals.Zoom.bindheld then
            CurrentCamera.FieldOfView = visuals.Zoom.zoomToFov
        end
    end

    if visuals.FOV.enabled and not visuals.Zoom.bindheld then
        CurrentCamera.FieldOfView = visuals.FOV.FOV
    end

    -- Fucking headache
    -- Stole most of this from zopac
    for i, v in pairs(oreList) do
        ore = ores[i]
        if esp.ore.enabled then
            if ore ~= nil then 
                if isOre(v) then
                    if v.PrimaryPart then
                        if math.floor(((CurrentCamera.CFrame.p - v.Part.Position).Magnitude) / 3.157) < esp.ore.distance then
                            local Vector, OnScreen = CurrentCamera:WorldToViewportPoint(v.Part.Position)
                            if OnScreen then
                                ore.Color = esp.ore.color
                                ore.Position = Vector2.new(Vector.x, Vector.y)
                                ore.Visible = true
                                if v.PrimaryPart.Color == Color3.fromRGB(248, 248, 248) then
                                    ore.Text = string.format("Nitrate [%sm]", math.floor(((CurrentCamera.CFrame.p - v.Part.Position).Magnitude) / 3.157))
                                    if not esp.ore.oresToShow["Nitrate"] then
                                        ore.Visible = false
                                    end
                                elseif v.PrimaryPart.Color == Color3.fromRGB(199, 172, 120) then
                                    ore.Text = string.format("Iron [%sm]", math.floor(((CurrentCamera.CFrame.p - v.Part.Position).Magnitude) / 3.157))
                                    if not esp.ore.oresToShow["Iron"] then
                                        ore.Visible = false
                                    end
                                elseif v.PrimaryPart.Color == Color3.fromRGB(105, 102, 92) then
                                    ore.Text = string.format("Stone [%sm]", math.floor(((CurrentCamera.CFrame.p - v.Part.Position).Magnitude) / 3.157))
                                    if not esp.ore.oresToShow["Stone"] then
                                        ore.Visible = false
                                    end
                                end
                            else
                                ore.Visible = false
                            end
                        else
                            ore.Visible = false
                        end
                    else
                        ore.Visible = false
                    end
                else
                    ore.Visible = false
                end
            end
        else
            ore.Visible = false
        end
    end
    -- Another fucking headache
    for i, v in pairs(playerList) do
        player = players[i]
        if esp.enabled then
            if player ~= nil then
                if isPlayer(v) and not isSleeping(v) then
                    if v.PrimaryPart then
                        if math.floor(((CurrentCamera.CFrame.p - v.PrimaryPart.Position).Magnitude) / 3.157) < esp.distance then
                            local Vector, OnScreen = CurrentCamera:WorldToViewportPoint(Vector3.new(v.PrimaryPart.Position.X, v.PrimaryPart.Position.Y - 4, v.PrimaryPart.Position.Z))
                            if OnScreen then
                                player.Color = esp.color
                                player.Position = Vector2.new(Vector.x, Vector.y)
                                player.Text = string.format("Player [%sm]", tostring(math.floor(((CurrentCamera.CFrame.p - v.PrimaryPart.Position).Magnitude) / 3.157)))
                                player.Visible = true
                            else
                                player.Visible = false
                            end
                        else
                            player.Visible = false
                        end
                    else
                        player.Visible = false
                    end
                else
                    player.Visible = false
                end
            end
        else
            player.Visible = false
        end
    end
end)

-- End of logic. Rest of code is just ui

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'RatHack b1.0 pink now!',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    ['ESP'] = Window:AddTab('Visuals'),
    ['MISC'] = Window:AddTab('MISC'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local EspSettings = Tabs.ESP:AddLeftGroupbox('ESP')
EspSettings:AddToggle('ESP', {
    Text = 'Toggle ESP',
    Default = esp.enabled,
    Tooltip = 'u stupid',
    Callback = function(Value)
        esp.enabled = Value
    end
}):AddColorPicker('ColorPicker', {
    Default = esp.color,
    Title = 'ESP color blahhh',
    Transparency = 0,
    Callback = function(Value)
        esp.color = Value
    end
})
EspSettings:AddSlider('ESP Distance', {
    Text = 'Esp Distance',
    Default = esp.distance,
    Tooltip = 'u stupid again',
    Min = 50,
    Max = 1000,
    Rounding = 1,
    Callback = function(Value)
        esp.distance = Value
    end
})

local OreEspSettings = Tabs.ESP:AddLeftGroupbox('Ore ESP')
OreEspSettings:AddToggle('Toggle Ore ESP', {
    Text = 'Toggle Ore ESP',
    Default = esp.ore.enabled,
    Callback = function(Value)
        esp.ore.enabled = Value
    end
})
OreEspSettings:AddSlider('Ore ESP Distance', {
    Text = 'Ore Esp Distance',
    Default = esp.ore.distance,
    Tooltip = 'u stupid again',
    Min = 50,
    Max = 1000,
    Rounding = 1,
    Callback = function(Value)
        esp.ore.distance = Value
    end
})
OreEspSettings:AddDropdown('Ores', {
    Values = { 'Stone', 'Iron', 'Nitrate' },
    Default = 0,
    Multi = true,
    Text = 'Ores',
    Tooltip = 'i hate you i hate everything leave me alone',
    Callback = function(Value)
        esp.ore.oresToShow = Value
    end
})

local VisualsMiscSettings = Tabs.ESP:AddRightGroupbox('MISC')
VisualsMiscSettings:AddSlider('FOV', {
    Text = 'FOV',
    Default = visuals.FOV.FOV,
    Tooltip = 'changes da fov',
    Min = 40,
    Max = 120,
    Rounding = 1,
    Callback = function(Value)
        visuals.FOV.FOV = Value
    end
})
VisualsMiscSettings:AddDivider()
VisualsMiscSettings:AddLabel('Zoom Key'):AddKeyPicker('ZoomKeyPicker', {
    Default = visuals.Zoom.key,
    Mode = 'Toggle',
    Text = 'Zoom',
    Callback = function(Value)
        visuals.Zoom.enabled = Value
    end,
    ChangedCallback = function(Key)
        visuals.Zoom.key = Key
    end,
})
VisualsMiscSettings:AddSlider('Zoom', {
    Text = 'Zoom',
    Default = visuals.Zoom.zoomToFov,
    Tooltip = 'What fov the zoom zooms too :D',
    Min = 1,
    Max = 70,
    Rounding = 1,
    Callback = function(Value)
        visuals.Zoom.zoomToFov = Value
    end
})

local WorldSettings = Tabs.ESP:AddLeftGroupbox('World settings')
WorldSettings:AddToggle('Fullbright', {
    Text = 'Fullbright',
    Default = visuals.fullbright.enabled,
    Tooltip = 'removes shadows',
    Callback = function(Value)
        visuals.fullbright.enabled = Value
    end
}):AddColorPicker('ColorPicker', {
    Default = visuals.fullbright.color,
    Title = 'Fullbright Color',
    Transparency = 0,
    Callback = function(Value)
        visuals.fullbright.color = Value
    end
})
WorldSettings:AddSlider('Fullbright Brightness',{
    Text = 'Fullbright brightness',
    Default = visuals.fullbright.brightness,
    Tooltip = 'aaaaa',
    Min = 0,
    Max = 2,
    Rounding = 1,
    Callback = function(Value)
        visuals.fullbright.brightness = Value
    end
})

local MiscSettings = Tabs.MISC:AddLeftGroupbox('Risky')
MiscSettings:AddToggle('HitBox expander', {
    Text = 'Toggle HitBox expander',
    Default = hitBox.enabled,
    Tooltip = 'u stupid round 3 also u cant turn this off :3',
    Callback = function(Value)
        hitBox.enabled = Value
    end
})
MiscSettings:AddDropdown('Part', {
    Values = { 'Head', 'Torso', 'LowerTorso', 'RightUpperArm', 'LeftupperArm', 'RightLowerArm', 'LeftLowerArm', 'RightHand', 'LeftHand', 'RightUpperLeg', 'LeftUpperLeg', 'RightLowerLeg', 'LeftLowerLeg', 'RightFoot', 'LeftFoot' },
    Default = 1,
    Multi = false,
    Text = 'Expander part',
    Tooltip = 'i hate you i hate everything leave me alone', -- Information shown when you hover over the dropdown
    Callback = function(Value)
        hitBox.Part = Value
    end
})
MiscSettings:AddSlider('HitBox size', {
    Text = 'HitBox expander size',
    Default = hitBox.size,
    Tooltip = 'do i even gotta say it',
    Min = 2,
    Max = 15,
    Rounding = 1,
    Callback = function(Value)
        hitBox.size = Value
    end
})
MiscSettings:AddSlider('HitBox opacity', {
    Text = 'HitBox jang transparency',
    Default = hitBox.Transparency,
    Tooltip = 'fuck you',
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(Value)
        hitBox.Transparency = Value
    end
})

Library:SetWatermarkVisibility(Watermark)
local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;
local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1;
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter;
        FrameTimer = tick();
        FrameCounter = 0;
    end;
    Library:SetWatermark(('RatHack b.1.0 | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ));
end);

Library.KeybindFrame.Visible = false;

Library:OnUnload(function()
    WatermarkConnection:Disconnect()

    ESPLoop:Disconnect()
    ESPLoop = nil

    visuals.GlobalShadows = true
    visuals.fullbright.enabled = false

    GameLoop:Disconnect()
    GameLoop = nil

    crosshair.x:Remove()
    crosshair.y:Remove()

    for _, i in players do
        i:Remove()
    end
    for _, i in ores do
        i:Remove()
    end

    print('Unloaded!')
    Library.Unloaded = true
end)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddButton('Dex Explorer', function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'Comma', NoUI = true, Text = 'Menu keybind' })

local uiToggles = Tabs['UI Settings']:AddRightGroupbox('UI Toggles')
uiToggles:AddToggle('Keybinds', {
    Text = 'Show keybinds',
    Default = Library.KeybindFrame.Visible,
    Tooltil = 'ill fucking kill you dude STOP',
    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end
})
uiToggles:AddToggle('Watermark', {
    Text = 'Show Watermark',
    Default = true,
    Tooltip = 'DUDE NO',

    Callback = function(Value)
    end
})
uiToggles:AddToggle('Crosshair', {
    Text = 'Show Crosshair',
    Default = not crosshair.enabled,
    Tooltip = 'im crying',

    Callback = function(Value)
        crosshair.enabled = Value
    end
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

writefile('RatHack/themes/RatHack.json', '{"MainColor":"171717","AccentColor":"ff89a4","OutlineColor":"373737","BackgroundColor":"131313","FontColor":"ff89a4"}') -- Could really find a different way to do this
if not isfile('RatHack/themes/default.txt') then
    writefile('RatHack/themes/default.txt', 'RatHack.json')
end

ThemeManager:SetFolder('RatHack')
SaveManager:SetFolder('RatHack/Trident')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()
