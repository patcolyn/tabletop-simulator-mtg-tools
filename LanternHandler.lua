--------------------------------------------------------
-- Lantern Handler
-- For Pie's 4, 6, and 8-Player Tables
-- https://steamcommunity.com/profiles/76561197968157267/myworkshopfiles/

-- Written by Patty
-- https://steamcommunity.com/id/Patty42/
--------------------------------------------------------
local flipEnabled = false

local inFlight = {
    [1] = {},
    [2] = {},
    [3] = {},
    [4] = {}
}
local abortFlip = {
    [1] = false,
    [2] = false,
    [3] = false,
    [4] = false
}
local flipBlockedUntil = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0
}

-- === MODIFY THESE TO USE ON OTHER TABLES ===
local playerColors = {"White", "Red", "Yellow", "Blue"}
local libZones = {"166036", "2365d0", "033b34", "c04462"}
local scryZones = {"7295a1", "640235", "350f7f", "bb8c76"}


-- --------------------------------------------------------
-- Utility helpers
-- --------------------------------------------------------

function inTable(obj, tab)
-- Check if value is in table, return key
    for k, v in ipairs(tab) do
        if v == obj then
            return k
        end
    end
    return false
end


function getPlayerFromColor(col)
    for _, player in ipairs(Player.getPlayers()) do
        if player.color == col then
            return player
        end
    end
    return nil
end


function updateObjectColor()
    if flipEnabled then
        self.setColorTint({0, 1, 0})
    else
        self.setColorTint({1, 0, 0})
    end
end


function flipTopOfDeck(deckObj)
    local card = deckObj.takeObject()
    if card then
        card.flip()
    end
    return card
end


-- --------------------------------------------------------
-- Zone-specific actions
-- --------------------------------------------------------

--- Find a single deck inside a library zone and flip its top card
function flipDeckInZone(zoneKey)
    local zoneObj = getObjectFromGUID(libZones[zoneKey])
    if not zoneObj then return end

    local objects = zoneObj.getObjects() or {}
    local deckCount = 0
    local deck

    for _, obj in ipairs(objects) do
        if obj.type == "Deck" then
            deckCount = deckCount + 1
            deck = obj
        end
    end

    if deckCount == 1 and deck then
        flipTopOfDeck(deck)
    end
end


--- Find a face-down card inside a library zone and flip it upright
function unflipCardsInZone(zoneKey)
    local zoneObj = getObjectFromGUID(libZones[zoneKey])
    if not zoneObj then return end

    local objects = zoneObj.getObjects() or {}
    local cardCount = 0
    local deckCount = 0
    local card

    for _, obj in ipairs(objects) do
        if obj.type == "Deck" then
            deckCount = deckCount + 1
        elseif obj.type == "Card" then
            cardCount = cardCount + 1
            card = obj
        end
    end

    if deckCount == 1 and cardCount == 1 and card then
        card.flip()
    end
end


-- --------------------------------------------------------
-- Central safety gatekeeper
-- --------------------------------------------------------

--- Check safety conditions, then flip the top card of the deck
function tryFlipTop(zoneKey)
    if not flipEnabled then return false end
	
    if os.clock() < flipBlockedUntil[zoneKey] then return false end

	-- Consume abort flag
    if abortFlip[zoneKey] then
        abortFlip[zoneKey] = false
        return false
    end

    local zoneObj = getObjectFromGUID(libZones[zoneKey])
    if not zoneObj then return false end

    local objects = zoneObj.getObjects() or {}
    local deckCount = 0
    local deck

    for _, obj in ipairs(objects) do
        if obj.type == "Deck" then
            deckCount = deckCount + 1
            deck = obj
        end
    end

    -- BUG: Highlight Mat in zone, #objects always 1 higher than expected
    if #objects == 2 and deckCount == 1 and deck then
        flipTopOfDeck(deck)
    end
	return true
end


-- --------------------------------------------------------
-- Zone event handlers
-- --------------------------------------------------------

--- A card left a scry zone: Flip if the scry zone is empty
function handleScryZoneLeaving(zoneKey, zoneGUID)
    flipBlockedUntil[zoneKey] = os.clock() + 0.5

    Wait.time(function()
        local scryZone = getObjectFromGUID(zoneGUID)

        if scryZone then
            local objects = scryZone.getObjects() or {}

            -- Scry zone is empty after physics settles
            if #objects == 0 then
                flipBlockedUntil[zoneKey] = 0
                tryFlipTop(zoneKey)
            end
        end
    end, 0.5)
end


--- A card left a library: track it as in-flight, wait for it to
--- come to rest, then flip
function handleLibraryZoneLeaving(zoneKey, object)
    local guid = object.getGUID()

    inFlight[zoneKey][guid] = true

    Wait.condition(
        function()
            if inFlight[zoneKey] and inFlight[zoneKey][guid] then
                inFlight[zoneKey][guid] = nil

                if next(inFlight[zoneKey]) == nil then
                    tryFlipTop(zoneKey)
                end
            end
        end,
        function()
            local obj = getObjectFromGUID(guid)
            if not obj then
                return true
            end
            return obj.resting
        end
    )
end


--- A card entered a scry zone: abort any pending flip for whichever
--- library zone was tracking this object
function handleScryZoneEntering(object)
    local guid = object.getGUID()

    for zoneKey, objects in pairs(inFlight) do
        if objects[guid] then
            abortFlip[zoneKey] = true
            break
        end
    end
end


-- --------------------------------------------------------
-- Top-level events
-- --------------------------------------------------------

function toggleFlip(playerColor)
    if Info.name ~= "MTG EDH 4-player (π)" then
        broadcastToColor("Only useable on MTG EDH 4-player (π)", player_color, message_tint)
        return
    end

    flipEnabled = not flipEnabled
    updateObjectColor()

    if flipEnabled then
        printToColor("Auto Flip Enabled", playerColor, {0, 1, 0})

        for zoneKey, _ in ipairs(libZones) do
            flipDeckInZone(zoneKey)
        end
    else
        printToColor("Auto Flip Disabled", playerColor, {1, 0, 0})

        for zoneKey, _ in ipairs(libZones) do
            unflipCardsInZone(zoneKey)
        end
    end
end


function onLoad()
    self.addContextMenuItem("Toggle Flip", toggleFlip)
    updateObjectColor()
end


function onObjectLeaveZone(zoneObj, object)
    if not object then return end
    if object.type ~= "Card" then return end

    local zoneGUID = zoneObj.getGUID()

    local scryZoneKey = inTable(zoneGUID, scryZones)
    if scryZoneKey then
        handleScryZoneLeaving(scryZoneKey, zoneGUID)
        return
    end

    local libZoneKey = inTable(zoneGUID, libZones)
    if libZoneKey then
        handleLibraryZoneLeaving(libZoneKey, object)
    end
end


function onObjectEnterZone(zoneObj, object)
    if not object then return end

    if inTable(zoneObj.getGUID(), scryZones) then
        handleScryZoneEntering(object)
    end
end

function onObjectRotate(object, spin, flip, player_color, old_spin, old_flip)
	-- A card on top of a library is flipped: Block flipping, manual player override
	if not object then return end
	local zones = object.getZones()
	if object.type ~= "Card" then return end
	
	for _, zone in ipairs(zones) do
		local zoneKey = inTable(zone.getGUID(), libZones)
		print(zoneKey)
		if zoneKey then abortFlip[zoneKey] = true end
	end
end