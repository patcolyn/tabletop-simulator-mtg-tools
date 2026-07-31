-- Norin's Automated Exile Zone

--[[ Description
	Place a Norin the Wary into the bag to tie it to the exile zone.
	Click the Exile text to automatically place Norin in exile.
	Whenever a turn ends, Norin will automatically leave exile.
]]

local Norin = ""
local inside = false
local direction = 1


function toggleSide()
    direction = direction * -1
    registerContextMenu()
end

function eject()
    for _, containedObject in ipairs(self.getObjects()) do
        if inside then
            rot = self.getRotation()
            move = Vector(10 * direction,0,0)
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
    leave()
end

function insert()
    self.putObject(getObjectFromGUID(Norin))
end

function leave()
    self.highlightOff()
    inside = false
    registerContextMenu()
end

function enter()
    self.highlightOn({1,0,0})
    inside = true
    registerContextMenu()
end

function flipState(_, player_color)
    if Norin == "" or (inside == false and getObjectFromGUID(Norin)) == nil then objectNotSetWarning(player_color) return end

    if inside then eject() else insert() end
end

function objectNotSetWarning(player_color)
    Norin = ""
    broadcastToColor("Place object in zone to register.", player_color, {r=1,g=0,b=0})
end

function registerContextMenu()
    if Norin == "" then return end
    self.clearContextMenu()

    if inside then
        self.addContextMenuItem("Return", eject)
    else
        self.addContextMenuItem("Exile", insert)
    end

    if direction == 1 then
        self.addContextMenuItem("Toggle Direction (Left)", toggleSide)
    else
        self.addContextMenuItem("Toggle Direction (Right)", toggleSide)
    end
end

-- ===== Events =====

function onLoad()
    self.createButton({
        click_function = 'flipState',
        function_owner = self,
        color = {r=0,g=0,b=0,a=0},
        scale = {x=3,y=0.5,z=1}
    })
end

function onObjectEnterContainer(cont, obj)
    if (cont == self and Norin == "") then
        Norin = obj.guid
    end

    if (cont == self and obj.guid == Norin) then
        enter()
    end
end

function onObjectLeaveContainer(cont, obj)
    if (cont == self and obj.guid == Norin) then
        leave()
    end
end

function onPlayerTurn()
    eject()
end

