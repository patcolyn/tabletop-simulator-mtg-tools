--------------------------------------------------------
-- Multiplayer Mill button
-- For Pie's 4, 6, and 8-Player Tables
-- https://steamcommunity.com/profiles/76561197968157267/myworkshopfiles/

-- Hooks into Global.mill1

-- Written by Patty
-- https://steamcommunity.com/id/Patty42/
--------------------------------------------------------

local PLAYERS = {}
local LIFE_COUNTERS = {}
local PLAYER_POSITION_OFFSETS = {}
local ACTIVE_PLAYERS = {}

local BUTTON_TEMPLATE = {
    width      = 500,
    height     = 500,
    font_color = {0, 0, 0, 1},
    vert_pos   = 1.2,
    hori_pos   = 1.2,
    lat_pos    = 0.0,
}

local MILL_DELAY = 0.1

local PLAYER_BUTTONS = {}

--------------------------------------------------------
-- Buttons
--------------------------------------------------------

local function captureButtonIndex(color)
    local buttons = self.getButtons()
    PLAYER_BUTTONS[color] = buttons[#buttons].index
end

local function createPlayerButton(color)
    local offset = PLAYER_POSITION_OFFSETS[color]

    self.createButton({
        click_function = "toggle" .. color,
        function_owner = self,
        position = {
            offset.hori * BUTTON_TEMPLATE.hori_pos,
            BUTTON_TEMPLATE.lat_pos,
            offset.vert * BUTTON_TEMPLATE.vert_pos,
        },
        width       = BUTTON_TEMPLATE.width,
        height      = BUTTON_TEMPLATE.height,
        color       = buttonColor(color, false),
        hover_color = buttonColor(color, false),
        tooltip     = "Toggle " .. color,
    })
    captureButtonIndex(color)
end

function createButtons()

    -- Mill (index 0)
    self.createButton({
        click_function = "millSelected",
        function_owner = self,
        position = {0, 0.2, 0},
        width = 650,
        height = 650,
        color = {0, 0, 0, 0},
        font_color = BUTTON_TEMPLATE.font_color,
        tooltip = "      [b]Mill Selected Players[/b]\n       [i]left click[/i] for 1 card\n     [i]right click[/i] for 3 cards\nor [i]type[/i] the desired amount"
    })

    -- Toggle Buttons (index 1+)
    for _, color in ipairs(PLAYERS) do
        createPlayerButton(color)
    end
end

function updatePlayerButton(player_color, color)
    local buttonIndex = PLAYER_BUTTONS[player_color]

    if buttonIndex == nil then return end

    self.editButton({
        index = buttonIndex,
        color = color,
        hover_color = color,
    })
end

function flipButtons()
    local buttons = self.getButtons()
    for k, button in ipairs(buttons) do
        self.editButton({
            index = k - 1,
            position = {
                -button.position.x,
                button.position.y,
                -button.position.z,
            }
        })
    end
end

function buttonColor(name, on)
    local c = Color.fromString(name)
    local m = on and 1 or 0.5
    return { c.r * m, c.g * m, c.b * m, 1 }
end

--------------------------------------------------------
-- Player Toggle
--------------------------------------------------------

local function togglePlayer(color)
    syncActivePlayers()

    ACTIVE_PLAYERS[color] = not ACTIVE_PLAYERS[color]
    if not playerActive(color) then
        ACTIVE_PLAYERS[color] = false
    end

    updatePlayerButton(color, buttonColor(color, ACTIVE_PLAYERS[color]))
end

function createToggleFunctions()
    for _, color in ipairs(PLAYERS) do
        _G["toggle" .. color] = function()
            togglePlayer(color)
        end
    end
end

function syncActivePlayers()
    for _, color in ipairs(PLAYERS) do
        if not playerActive(color) then
            ACTIVE_PLAYERS[color] = false
            updatePlayerButton(color, buttonColor(color, false))
        end
    end
end

function playerActive(color)
    local obj = LIFE_COUNTERS[color]
    if obj == nil then
        return false
    end

    local buttons = obj.getButtons()
    if buttons == nil or buttons[1] == nil then
        return false
    end

    local fc = buttons[1].font_color
    return fc ~= nil and fc.a == 100
end

function getLifecounters(PLAYERS)
    LIFE_COUNTERS = {}

    for _, obj in ipairs(getObjects()) do
        if obj.getName() == "Life Tracker" then
            local color = obj.getDescription()

            for _, player in ipairs(PLAYERS) do
                if player == color then
                    LIFE_COUNTERS[color] = obj
                    break
                end
            end
        end
    end
end

--------------------------------------------------------
-- Mill
--------------------------------------------------------

function millSelected(_, playerColor, alt_click)
    if alt_click then
        millPlayers(3)
    else
        millPlayers(1)
    end
end

function onNumberTyped(playerColor, number)
    local count = tonumber(number)

    if count == nil then return true end
    if count < 1 then return true end

    millPlayers(count)
    return true
end

function millPlayers(count)
    syncActivePlayers()

    for _, color in ipairs(PLAYERS) do
        if ACTIVE_PLAYERS[color] then
            for i = 1, count do
                local delay = (i - 1) * MILL_DELAY
                Wait.time(function()
                    Global.call("mill1", color)
                end, delay)
            end
        end
    end
end

--------------------------------------------------------
-- Events
--------------------------------------------------------

function onLoad()
    local tableName = Info.name
	local validTable
	
    if tableName == "MTG EDH 4-player (π)" then
        validTable = true

        PLAYERS = { "White", "Red", "Blue", "Yellow" }
        PLAYER_POSITION_OFFSETS = {
            White  = { hori =  1, vert =  1 },
            Red    = { hori = -1, vert =  1 },
            Blue   = { hori =  1, vert = -1 },
            Yellow = { hori = -1, vert = -1 },
        }

    elseif tableName == "MTG EDH 6-player (π)" then
        validTable = true

        PLAYERS = { "White", "Red", "Yellow", "Green", "Blue", "Purple" }
        PLAYER_POSITION_OFFSETS = {
            White  = { hori =  0.9, vert =  1.15 },
            Red    = { hori =  0, vert =  1.15 },
            Yellow = { hori = -0.9, vert =  1.15 },
            Green  = { hori = -0.9, vert = -1.15 },
            Blue   = { hori =  0, vert = -1.15 },
            Purple = { hori =  0.9, vert = -1.15 },
        }

    elseif tableName == "MTG EDH 8-player (π)" then
        validTable = true

        PLAYERS = { "White", "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink" }
        PLAYER_POSITION_OFFSETS = {
            White  = { hori = 0.42, vert = 1.25 },
            Red    = { hori = -0.42, vert = 1.25 },
            Orange = { hori = -1.25, vert = -0.42 },
            Yellow = { hori = -1.25, vert = 0.42 },
            Green  = { hori = -0.42, vert = -1.25 },
            Blue   = { hori = 0.42, vert = -1.25 },
            Purple = { hori = 1.25, vert = -0.42 },
            Pink   = { hori = 1.25, vert = 0.42 },
        }
    end

    if not validTable then
        print("MillPlayersButton: '" .. tostring(tableName) .. "' is not a recognized table. Skipping setup.")
        return
    end

    ACTIVE_PLAYERS = {}
    for _, color in ipairs(PLAYERS) do
        ACTIVE_PLAYERS[color] = false
    end

    getLifecounters(PLAYERS)
    createToggleFunctions()

    self.max_typed_number = 99
    createButtons()
    self.addContextMenuItem("Switch Table Side", flipButtons)
end
