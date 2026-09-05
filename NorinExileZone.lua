--------------------------------------------------------
-- Norin Exile Zone

-- Optional automation for Pie's 4, 6, and 8-Player Tables
-- https://steamcommunity.com/profiles/76561197968157267/myworkshopfiles/

-- Written by Patty
-- https://steamcommunity.com/id/Patty42/
--------------------------------------------------------

local NORIN = ""
local INSIDE = false
local DIRECTION = 1
local trackedGUIDs = {}
local PLAYZONE_GUIDS = {"129eaa", "56cd9d", "c20e3f", "8b3401"}

local CREATED_ZONE_GUIDS = {}

local ZONE_TRACKING = true

-- Using White as base reference
local ZONE_SETUP = {
	coords = {
		exile_zone = {x=40.7, y=1, z=-14.6},
		command_zone_1 = {x=39.46, y=1, z=-8.35},
		command_zone_2 = {x=42, y=1, z=-8.35}
	},
	 scale = {x=2.4,y=5.6,z=3.3},
	 offsets = {
		White =  {x=1  ,y=1 ,z=1},
		Red =    {x=-1 ,y=1 ,z=1},
		Yellow = {x=-1 ,y=1 ,z=-1},
		Blue =   {x=1  ,y=1 ,z=-1}
	}
}

-- === Norin Handling ===

function ejectNorin()
    for _, containedObject in ipairs(self.getObjects()) do
        if INSIDE then
            rot = self.getRotation()
            move = Vector(3 * DIRECTION,0,0)
            move:rotateOver('y', rot.y)
            local takenObject = self.takeObject()
            Wait.frames(function()
                    pos = self.getPosition()
                    takenObject.setPositionSmooth(pos + move)
                end,
                1
            )
        end
    end
    setOutside()
end

function insertNorin()
    if NORIN == "" then return end
    local obj = getObjectFromGUID(NORIN)
    if obj == nil then return end
    self.putObject(obj)
end

function setOutside()
    self.highlightOff()
    INSIDE = false
    registerContextMenu()
end

function setInside()
    self.highlightOn({1,0,0})
    INSIDE = true
    registerContextMenu()
end

-- === Errors ===

function objectNotSetWarning(player_color)
    NORIN = ""
    broadcastToColor("Error: Object Not Set — Place object in bag to register", player_color, {r=1,g=0,b=0})
end

-- ===== Context Menu =====

function registerContextMenu()
    if NORIN == "" then return end
    self.clearContextMenu()

    if INSIDE then
        self.addContextMenuItem("Return", ejectNorin)
    else
        self.addContextMenuItem("Exile", insertNorin)
    end

	self.addContextMenuItem("Toggle Direction", toggleSide)
	self.addContextMenuItem("Toggle Zone Tracker", toggleZoneTracking)
end

function toggleSide()
    DIRECTION = DIRECTION * -1
end

function toggleZoneTracking(player_color)
	ZONE_TRACKING = not ZONE_TRACKING
	
	local enabled_str = ""
	if ZONE_TRACKING then enabled_str = "Enabled" else enabled_str = "Disabled" end
	broadcastToColor("Zone Tracking: " .. enabled_str, player_color, {r=1,g=1,b=1})
end

-- ===== Button =====

function flipState(_, player_color)
    if NORIN == "" or (INSIDE == false and getObjectFromGUID(NORIN)) == nil then objectNotSetWarning(player_color) return end

    if INSIDE then ejectNorin() else insertNorin() end
end

-- ===== Events =====

function onLoad()
    self.createButton({
        click_function = 'flipState',
        function_owner = self,
        color = {r=0,g=0,b=0,a=0},
        scale = {x=3,y=0.5,z=1}
    })
	
	-- If spawned with contents, remove object and set GUID
	contained_objects = self.getObjects()
	if contained_objects ~= nil then
		if #contained_objects == 1 then
            local takenObject = self.takeObject()
            Wait.frames(function()
                    takenObject.setPositionSmooth(self.getPosition())
					NORIN = takenObject.getGUID()
                end,
                1
            )
        end
    end
	
	-- Setup more zones to check objects have left the battlefield
	for _,coord in pairs(ZONE_SETUP.coords) do
		for _,offset in pairs(ZONE_SETUP.offsets) do

			spawnObject({
				type = "ScriptingTrigger",
				position =  multVecs(coord, offset),
				scale = ZONE_SETUP.scale,
				sound = false,
				callback_function = function(spawned_object)
					table.insert(CREATED_ZONE_GUIDS, spawned_object.getGUID())
				end
			})
		end
	end
			
end

function onDestroy()
	-- Clear created scripting zones
	for _, obj in ipairs(CREATED_ZONE_GUIDS) do
		getObjectFromGUID(obj).destroy()
	end
end

function onObjectEnterContainer(cont, obj)
	if (cont == nil or obj == nil) then return end
	if cont ~= self then return end
	
	-- Register Norin
	if NORIN == "" then
		NORIN = obj.getGUID()
		table.insert(trackedGUIDs, objGuid)
	end
	
    if obj.getGUID() == NORIN then
		setInside()
	end
end

function onObjectLeaveContainer(cont, obj)
	if (cont == nil or obj == nil) then return end

    if (cont == self and obj.getGUID() == NORIN) then
        setOutside()
    end
end

function onObjectEnterZone(zone, obj)
	if (zone == nil or obj == nil) then return end
	if obj.type ~= "Card" or not validType(obj) then return end
	
	if ZONE_TRACKING then
		local objGuid = obj.getGUID()
		if not listContains(PLAYZONE_GUIDS, zone.getGUID()) then
			if listContains(trackedGUIDs, objGuid) then
				removeElement(trackedGUIDs, objGuid)
			end
		else
			if not listContains(trackedGUIDs, objGuid) and not obj.isSmoothMoving() then
				table.insert(trackedGUIDs, objGuid)
				insertNorin()
			end
		end
	end
end

function onPlayerTurn()
    ejectNorin()
end

-- ===== Helper Functions =====

function listContains(list, value)
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

function removeElement(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            table.remove(tbl, i)
            return true
        end
    end

    return false
end

function validType(card)
    if card == nil or card.type ~= "Card" then return false end

    local name = card.getName() or ""

    local typeLine = name:match("\n([^\n]+)") or name
    return typeLine:lower():find("land") == nil and 
		typeLine:lower():find("token") == nil and
		typeLine:lower():find("card") == nil
end

function multVecs(vec1, vec2)
	return {vec1.x * vec2.x, vec1.y * vec2.y, vec1.z * vec2.z}
end