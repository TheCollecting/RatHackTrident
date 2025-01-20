local players = {}

local SleepAnimationId = "rbxassetid://13280887764"

local lighting = game:GetService("Lighting")

local playerList = {}

function isPlayer (Model)
    return Model.ClassName == "Model" and Model:FindFirstChild("Torso") and Model.PrimaryPart ~= nil
end

function getTableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
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

-- function isOre(Model)
--     return Model.ClassName == "Model" and Model:FindFirstChild("Part") and Model.PrimaryPart ~= nil and Model:FindFirstChild("Part").Color == Color3.fromRGB(105, 102, 92)
-- end
-- function isOre(Model)
--     if Model.ClassName == "Model" and Model:FindFirstChild("Part") and Model.PrimaryPart ~= nil then
--         if Model.Part.Color = Color3.FromRGB(105, 102, 92) then
--             print(Model.Position)
--         end
--     end
-- end

-- for i, v in pairs(workspace:GetChildren()) do
--     if isOre(v) then
--         print(v.Part.Position)
--     end
-- end

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

--local children = workspace:GetChildren()
function initPlayerText()
    clearPlayerText()
    --for i = 0, #playerList do
    for i = 0, 500 do
        local player = Drawing.new("Text")
        player.Visible = false
        table.insert(players, player)
    end
end
-- for i, v in ipairs(playerList) do
--     if v.PrimaryPart then
--         print("blah")
--         print(v.PrimaryPart.Position)
--     end
-- end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalSizes = {}
for i, v in pairs(ReplicatedStorage.Shared.entities.Player.Model:GetChildren()) do
    if v:IsA("BasePart") then
        OriginalSizes[v.Name] = v.Size
    end
end

local esp = {
    enabled = true,
    color = Color3.fromHex('ff89a4'),
    -- color = Library.AccentColor, -- Doesnt work unless you have opened a version of the cheat that doesnt have this in the same roblox instance
    distance = 500,
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

function fullbrightfunc()
    if visuals.fullbright.enabled then
    -- if true then
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

initPlayerList()
initPlayerText()

local CurrentCamera = workspace.CurrentCamera

function SetFOV()
    if visuals.FOV.enabled and not visuals.Zoom.enabled then
        CurrentCamera.FieldOfView = visuals.FOV.FOV
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

local screenCenter = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y / 2)

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

function Zoom()
    if visuals.Zoom.enabled then
    -- CurrentCamera.FieldOfView = visuals.Zoom.zoomToFov
        CurrentCamera.FieldOfView = visuals.Zoom.zoomToFov
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

local ESPLoop = game:GetService("RunService").RenderStepped:Connect(function()
    -- initPlayerText()
    Zoom()
    SetFOV()
    -- Having these two in the render loop is retared (✿◠‿◠)
    hideAllPlayerText()
    initPlayerList()

    for i, v in pairs(playerList) do
        player = players[i]
        if esp.enabled then
            if player ~= nil then
                if isPlayer(v) and not isSleeping(v) then
                    if v.PrimaryPart then
                        if math.floor(((CurrentCamera.CFrame.p - v.PrimaryPart.Position).Magnitude) / 3.157) < esp.distance then
                            --print(v.PrimaryPart.Position)
                            local Vector, OnScreen = CurrentCamera:WorldToViewportPoint(v.PrimaryPart.Position)
                            if OnScreen then
                                player.Color = esp.color
                                player.Position = Vector2.new(Vector.x, Vector.y)
                                player.Text = tostring(math.floor(((CurrentCamera.CFrame.p - v.PrimaryPart.Position).Magnitude) / 3.157) .. 'm')
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

-- local player = Drawing.new("Text")
-- local ESPLoop = game:GetService("RunService").RenderStepped:Connect(function()
--     for i, v in pairs(workspace:GetChildren()) do
--         if esp.enabled then
--             if isPlayer(v) then
--                 if v.PrimaryPart then
--                     --print(v.PrimaryPart.Position)
--                     player.Color = esp.color
--                     local Vector, OnScreen = CurrentCamera:WorldToViewportPoint(v.PrimaryPart.Position)
--                     player.Position = Vector2.new(Vector.x, Vector.y)
--                     player.Text = "player"
--                     if OnScreen then
--                         player.Visible = true
--                     else
--                         player.Visible = false
--                     end
--                 end
--             end
--         else
--             player.Visible = false
--         end
--     end
-- end)

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    -- Set Center to true if you want the menu to appear in the center
    -- Set AutoShow to true if you want the menu to appear when it is created
    -- Position and Size are also valid options here
    -- but you do not need to define them unless you are changing them :)

    Title = 'RatHack b1.0 pink now!',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- CALLBACK NOTE:
-- Passing in callback functions via the initial element parameters (i.e. Callback = function(Value)...) works
-- HOWEVER, using Toggles/Options.INDEX:OnChanged(function(Value) ... ) is the RECOMMENDED way to do this.
-- I strongly recommend decoupling UI code from logic code. i.e. Create your UI elements FIRST, and THEN setup :OnChanged functions later.

-- You do not have to set your tabs & groups up this way, just a prefrence.
local Tabs = {
    -- Creates a new tab titled Main
    --Main = Window:AddTab('Main'),
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

EspSettings:AddLabel('ESP Color'):AddColorPicker('ColorPicker', {
    Default = esp.color,
    Title = 'ESP color blahhh',
    Transparency = 0,

    Callback = function(Value)
        esp.color = Value
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
    --SyncToggleState = false,
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
})

WorldSettings:AddLabel('Fullbright Color'):AddColorPicker('ColorPicker', {
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
    Default = 1, -- number index of the value / string
    Multi = false, -- true / false, allows multiple choices to be selected

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

-- local hitBox = {
--     enabled = true,
--     size = 5,
--     Part = "Head",
--     Transparency = 0.7,
-- }


-- Groupbox and Tabbox inherit the same functions
-- except Tabboxes you have to call the functions on a tab (Tabbox:AddTab(name))

-- We can also get our Main tab via the following code:
-- local LeftGroupBox = Window.Tabs.Main:AddLeftGroupbox('Groupbox')

-- Tabboxes are a tiny bit different, but here's a basic example:
--[[

local TabBox = Tabs.Main:AddLeftTabbox() -- Add Tabbox on left side

local Tab1 = TabBox:AddTab('Tab 1')
local Tab2 = TabBox:AddTab('Tab 2')

-- You can now call AddToggle, etc on the tabs you added to the Tabbox
]]


-- Groupbox:AddToggle
-- Arguments: Index, Options


-- Library functions
-- Sets the watermark visibility
Library:SetWatermarkVisibility(Watermark)

-- Example of dynamically-updating watermark with common traits (fps and ping)
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
Library.KeybindFrame.Visible = false; -- todo: add a function for this

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

    print('Unloaded!')
    Library.Unloaded = true
end)

-- UI Settings
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

-- I set NoUI so it does not show up in the keybinds menu
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

Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu

-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- ThemeManager (Allows you to have a menu theme system)

-- Hand the library over to our managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- Adds our MenuKeybind to the ignore list
-- (do you want each config to have a different menu key? probably not.)
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
writefile('RatHack/themes/RatHack.json', '{"MainColor":"171717","AccentColor":"ff89a4","OutlineColor":"373737","BackgroundColor":"131313","FontColor":"ff89a4"}')
if not isfile('RatHack/themes/default.txt') then
    writefile('RatHack/themes/default.txt', 'RatHack.json')
end

ThemeManager:SetFolder('RatHack')
SaveManager:SetFolder('RatHack/Trident')

-- Builds our config menu on the right side of our tab
SaveManager:BuildConfigSection(Tabs['UI Settings'])

-- Builds our theme menu (with plenty of built in themes) on the left side
-- NOTE: you can also call ThemeManager:ApplyToGroupbox to add it to a specific groupbox
ThemeManager:ApplyToTab(Tabs['UI Settings'])

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()