--------------------------------------------------------
-- Pinger
-- For Pie's 4, 6, and 8-Player Tables
-- https://steamcommunity.com/profiles/76561197968157267/myworkshopfiles/

-- Written by Patty
-- https://steamcommunity.com/id/Patty42/
--------------------------------------------------------

local DAMAGE_AMOUNT = 1
local MODE = 1
-- 1 = All
-- 2 = Enemies
-- 3 = Self
-- 4 = Extort
-- 5 = Drain

function onLoad()
    createUI()
	self.max_typed_number = 99
end

-- --------------------------------------------------------
-- UI
-- --------------------------------------------------------

function createUI()
	self.createButton({
        label=tostring(DAMAGE_AMOUNT),
        click_function="null",
        function_owner=self,
        position={-0.03,0.1,0.08},
        width=0,
        height=0,
        font_size=350,
		font_color = {0,0,0,0.75}
    })

    self.createButton({
        label=tostring(DAMAGE_AMOUNT),
        click_function="null",
        function_owner=self,
        position={0,0.1,0.05},
        width=0,
        height=0,
        font_size=350,
		font_color = {1,1,1}
    })


    self.createButton({
        click_function="changeDamage",
        function_owner=self,
        position={0,0.12,0},
        width=400,
        height=400,
        color = {0,0,0,0}
    })

    self.createButton({
        label="All",
        click_function="toggleMode",
        function_owner=self,
        position={0,0,0.8},
        width=600,
        height=250,
        font_size=140
    })

    self.createButton({
        label="BANG",
        click_function="damagePlayers",
        function_owner=self,
        position={0,0,-0.8},
        width=500,
        height=250,
        font_size=150,
		color = {0.521,0.141,0.141}
    })
end

-- --------------------------------------------------------
-- Buttons
-- --------------------------------------------------------

function updateUI()
    self.editButton({
        index=0,
        label=tostring(DAMAGE_AMOUNT)
    })
	
	self.editButton({
        index=1,
        label=tostring(DAMAGE_AMOUNT)
    })

    local MODEText =
        (MODE == 1 and "All")
        or (MODE == 2 and "Enemies")
        or (MODE == 3 and "Self")
        or (MODE == 4 and "Extort")
        or "Drain"

    self.editButton({
        index=3,
        label=MODEText
    })
end

function changeDamage(obj, _, alt)
	if alt then
		setDamage(DAMAGE_AMOUNT - 1)
	else
		setDamage(DAMAGE_AMOUNT + 1)
	end
    updateUI()
end

function setDamage(num)
	DAMAGE_AMOUNT = math.max(1, math.min(99, num))
	updateUI()
end

function toggleMode()
    MODE = MODE + 1
    if MODE > 5 then MODE = 1 end
    updateUI()
end

function onNumberTyped(playerColor, number)
	setDamage(number)
	return true
end

function null() end

-- --------------------------------------------------------
-- Damage
-- --------------------------------------------------------
function loseLife(playerColor, amount)
    for _, obj in pairs(getAllObjects()) do
        if obj.getName() == "Life Tracker" and obj.getDescription() == playerColor then
            for i = 1, amount do
                obj.call("valueChange2", obj, playerColor, false)
            end
        end
    end
end

function gainLife(playerColor, amount)
    for _, obj in pairs(getAllObjects()) do
        if obj.getName() == "Life Tracker" and obj.getDescription() == playerColor then
            for i = 1, amount do
                obj.call("valueChange1", obj, playerColor, false)
            end
        end
    end
end

function damagePlayers(obj, player_color)
    local playerObj = Player[player_color]
    if not playerObj then return end

    local identity = playerObj.steam_name or "Player"

    local extortGain = 0
    local drainTriggered = false

    for _, obj in pairs(getAllObjects()) do
        if obj.getName() == "Life Tracker" then

            local p = obj.getDescription()

            if p and p ~= "" then

                if MODE == 1 then
                    loseLife(p, DAMAGE_AMOUNT)

                elseif MODE == 2 then
                    if p ~= player_color then
                        loseLife(p, DAMAGE_AMOUNT)
                    end

                elseif MODE == 3 then
                    if p == player_color then
                        loseLife(p, DAMAGE_AMOUNT)
                    end

                elseif MODE == 4 then
                    if p ~= player_color then
                        loseLife(p, DAMAGE_AMOUNT)
                        extortGain = extortGain + DAMAGE_AMOUNT
                    end

                elseif MODE == 5 then
                    if p ~= player_color then
                        loseLife(p, DAMAGE_AMOUNT)
                        drainTriggered = true
                    end
                end

            end
        end
    end

    if MODE == 4 then
        gainLife(player_color, extortGain)
    elseif MODE == 5 and drainTriggered then
        gainLife(player_color, DAMAGE_AMOUNT)
    end

-- --------------------------------------------------------
-- Chat
-- --------------------------------------------------------
    local message = ""

    if MODE == 1 then
        message = identity .. " deals " .. DAMAGE_AMOUNT .. " damage to each player."

    elseif MODE == 2 then
        message = identity .. " deals " .. DAMAGE_AMOUNT .. " damage to each opponent."

    elseif MODE == 3 then
        message = identity .. " deals " .. DAMAGE_AMOUNT .. " damage to themselves."

    elseif MODE == 4 then
        message = identity ..
        " — Extort — Each opponent loses " .. extortGain ..
        " life. " .. identity .. " gains life equal to the life lost this way."

    elseif MODE == 5 then
        message = identity ..
        " — Drain — Each opponent loses " .. DAMAGE_AMOUNT ..
        " life. " .. identity .. " gains 1 life."
    end

    broadcastToAll(message, playerObj.color)
end