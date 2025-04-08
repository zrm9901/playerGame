
HC = require "HC"

function CreateCollider(type, width, height, x, y, id)
    local collider
    if type == "rect" then
        collider = HC.rectangle(x, y, width, height)
    elseif type == "circle" then
        local radius = (width + height) / 4
        collider = HC.circle(x + radius, y + radius, radius)
    end
    collider.id = id
    return collider
end

function CreatePolygon(points, temp)
    local polygon
        polygon = HC.polygon(unpack(points))
        for i, j in pairs(temp) do
            polygon[i] = j
    end
    
    return polygon
end



function StoreVar(key, value, object, place)
    local temp = object or {}
    place = place or "self"
    if place == "self" then
        temp[key] = value

    else 
        local target = temp[place]
        if target == nil then
            target = {}
            temp[place] = target  -- Assign the new table to temp[place]
        end
        if target and target[key] == nil then
            target[key] = value
        end
    end
    return temp
end

function DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function StoreVars(temp, vars)
    local result = temp
    if type(vars) ~= "table" then
        return result
    end
    for key, triple in ipairs(vars) do
        if NilCheck({triple[1], triple[2]}) then
            triple[3] = triple[3] or "self"
            result = StoreVar(triple[1], triple[2], result, triple[3])
        end
    end
    return result
end

function Lerp(a, b, t)
    return a + (b - a) * t
end

function Length(temp)
    local len = 0
    for i, j in pairs(temp) do
        len = len + 1
    end
    return len
end

function math.sign(num)
    return (num > 0 and 1) or (num < 0 and -1) or 0
end

function NilCheck(...)
    for _, i in pairs(...) do
        if i == nil then
            return false
        end
    end
    return true
end
function Rgb(r, g, b, a)
    return r/255, g/255, b/255, a
end

function ReadFile(filename)
    local file = io.open(filename, "r")
    local content
    if file then
        content = file:read("*a")
        file:close()
    end
   
    return content
end


function GetKeys(direction)
    local down = false
    local lx, ly = JoystickVector()
    local moves  = {
        left = {
            love.keyboard.isDown("a"),
            love.keyboard.isDown("left"),
            
        },
        right = {
            love.keyboard.isDown("d"),
            love.keyboard.isDown("right"),
            
        },
        up = {
            love.keyboard.isDown("w"),
            love.keyboard.isDown("up"),
            
        }, 
        down = { 
            love.keyboard.isDown("s"),
            love.keyboard.isDown("down"),
            
        }
    }
    
    if not JoyStickMode then
        for h, i in pairs(moves) do
            if h == direction then
                for _, j in pairs(i) do
                    if j then
                        down = true
                    end
                end
            end
        end
    end

    if lx ~= nil and ly ~= nil and Joystick ~= nil then
        local jMoves = {
            left = {
                (lx == -1),
                (Joystick:isGamepadDown("dpleft"))
            },
            right = {
                (lx == 1),
                (Joystick:isGamepadDown("dpright"))
            },
            up = {
                (ly == -1),
                (Joystick:isGamepadDown("dpup"))
            }, 
            down = { 
                (ly == 1),
                (Joystick:isGamepadDown("dpdown"))
            }
        }
        if JoyStickMode then
            for h, i in pairs(jMoves) do
                if h == direction then
                    for _, j in pairs(i) do
                        if j then
                            down = true
                        end
                    end
                end
            end
        end
    end
    return down
end

function JoystickVector()
    
    if Joystick ~= nil then
        local lx, ly
        
        lx = Joystick:getGamepadAxis("leftx")
        ly = Joystick:getGamepadAxis("lefty")
        
        if lx > -0.5 and lx < 0.5 then
            lx = 0
        end
        if ly > -0.5 and ly < 0.5 then
            ly = 0
        end
        return math.sign(lx), math.sign(ly)
    end
    return nil, nil
end

function MoveObjectTo(object, x, y, dt, lerpFactor)
    local cx, cy = object:center()
    lerpFactor = lerpFactor or math.min(1, 10 * dt)

    -- Compute interpolated position
    local newX = Lerp(cx, x, lerpFactor)
    local newY = Lerp(cy, y, lerpFactor)

    -- Move the object towards the target
    if newX == newX and newY == newY then
        object:moveTo(newX, newY)
    else 
        print("newX or newY is NaN")
    end
    

    -- Check if the object is close enough to stop moving
    if math.abs(newX - x) < 5 and math.abs(newY - y) < 5 then
        if x == x and y == y then
            object:moveTo(x, y) -- Snap to final position
        else
            print("x or y is NaN")
        end
    end
end

function MoveObject(object, x, y, dt, lerpFactor)
    local cx, cy = object:center()
    lerpFactor = lerpFactor or math.min(1, 10 * dt)
    local dx, dy = cx + x, cy + y
    -- Compute interpolated position
    local newX = Lerp(cx, dx, lerpFactor)
    local newY = Lerp(cy, dy, lerpFactor)

    -- Move the object towards the target
    object:moveTo(newX, newY)

end