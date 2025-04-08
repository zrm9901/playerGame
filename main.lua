require "Util"
Camera = require "camera"
DK = require 'dkjson/dkjson'
GenGrid = require 'grid'

function love.load()
    MazeCols, MazeRows = 10,10
    CellSize = 50
    Maze = InitMaze(10,10,10)
    Content = ReadFile("test.json")
    Data = DK.decode(Content)
    Layers = CreateMaps(Data)
    PlacedPlayer = nil
    Transition({{name = "target", value = {x=1,y=1}}, player = "bottom"})
    Cam = Camera()
    Cam:zoomTo(5) 
    State = 1
    CanWJ = false
    HasDJ = false
    HasDash = false
    Map = false
    Current = {x=1,y=1}
    JoyStickMode = false
    if JoyStickMode then
        Joystick = love.joystick.getJoysticks()[1]
    end
end

function love.keypressed(key)
    if key == "tab" then
        Map = not Map
    end
end

function love.update(dt)
    if not Map then
        if PlacedPlayer then
            Timer = Timer + dt
            DJTimer = DJTimer + dt
            DCooldown = DCooldown + dt
            Gravity(Player,dt)
            if Collisions(Player, dt) then
                return
            end
            MovePlayer(Player, 10, 5, 50,dt)
            Dash(Player, 10, dt)
            Move(Player, dt)
            Push(Player)
            Cam:lookAt(Player[1]:center())
        end
    end
end

function love.draw()
    if not Map then
        love.graphics.clear(Rgb(0, 0, 255))
        Cam:attach()
        if PlacedPlayer then
            DrawTable(Player, "line")
        end
        DrawTable(Tables, "fill")
        Cam:detach()
    else
        for y = 1, MazeRows do
            for x = 1, MazeCols do
                local bool = false
                if Current.x == x and Current.y == y then
                    bool = true
                end
                DrawCell(Maze[y][x], CellSize, bool)
            end
        end
    end
end

function Dash(player, force, dt) 
    local lx, ly = JoystickVector()
    if (lx and ly and HasDash and Joystick:isGamepadDown("x") and DCooldown > 1 and JoyStickMode) then
        MoveObject(player[1], lx * force, 0, dt)
        DD = math.sign(lx)
        DCooldown = 0
    elseif not JoyStickMode and (love.keyboard.isDown("lshift") and DCooldown > 1) then
        local x = 0
        if love.keyboard.isDown("d") then
            x = x + 10
        end
        if love.keyboard.isDown("a") then
            x = x - 10
        end
        if x ~= 0 then
            MoveObject(player[1], math.sign(x) * force, 0, dt)
            DCooldown = 0
            DD = math.sign(x)
        end
    elseif DCooldown < 0.25 then
        MoveObject(player[1], DD * force, 0, dt)
    else
        DD = 0
    end
end

function Push(player) 
    for i, _ in pairs(player) do
        local collisions = HC.collisions(player[i])
        for shape, delta in pairs(collisions) do
            if (shape.id == "ceiling") or (shape.id == "solid") then
                player[i]:move(delta.x, delta.y + 0.1)
            elseif (shape.id == "wall") then
                player[i]:move((delta.x - math.sign(delta.x) * 0.1), delta.y - 0.1)
            end
        end
    end
end



function Gravity(player, dt)
    for i, _ in pairs(player) do
        player[i].vy = player[i].vy or 0
        if Wall and math.sign(player[i].vy) == 1 then
            MoveObject(player[i], 0, player[i].vy * 0.25, dt, 0.25)
        else 
            MoveObject(player[i], 0, player[i].vy, dt, 0.25)
        end
    end
end

function Move(player, dt)
    for i, _ in pairs(player) do
        if Sliding then
            MoveObject(player[i], player[i].vx, player[i].vy, dt, 0.1)
        else 
            MoveObject(player[i], player[i].vx, 0, dt)
        end
        player[i].vx = player[i].vx * 0.8
    end
end


function Transition(goal)
    WallJump = 0
    JumpForce = 10
    Timer = 5
    DJTimer = 5
    DCooldown = 5
    HasJump = true
    Sliding = false
    CanDash = false
    Wall = false
    PlacedPlayer = false
    local polygons = nil

    DD = 0
    if Tables then
        for _, shape in pairs(Tables) do
            HC.remove(shape)  -- Removes objects from physics engine
        end
    end
    if Player then
        for _, shape in pairs(Player) do
            HC.remove(shape)  -- Removes objects from physics engine
        end
    end
    local target = goal.target

    if not target then
        target = {x=1,y=1}
    end
    Current = target
    Player = nil
    Tables = nil
    GetCell(Maze,target.x,target.y).visited = true
    polygons = GetPolygons(Layers, target.x,target.y)
    Tables = CreatePolygons(polygons, goal.player)
end

function CreatePolygons(polygons, landing)
    local tables = {}
        for j, k in pairs(polygons) do
            if k.id == "player" and not PlacedPlayer and k.landing == landing then
                Player = CreateLine(k.x + 5, k.y + 5, 1)
                PlacedPlayer = true
            elseif k.id == "player" then
            else
                if k.id == "" then
                    k.id = "solid"
                end
                local polygon = CreatePolygon(k.points, {id = k.id, type = k.type, player = k.player, target = k.target})
                tables[j] = polygon
            end       
        end
    return tables
end

function CreateMaps(data)
    local maps = {}
    local base
    for _, i in pairs(data.layers) do
        if i.name == "base" then
            print("found base")
            base = i
        end
    end
    for h,k in pairs(Maze) do
        for i,_ in pairs(k) do
        local layer = {x = Maze[h][i].x, y = Maze[h][i].y}
        layer.objects = {}
        for _, j in pairs(base.objects) do
            local mj = DeepCopy(j)
            if mj.name == "goal" then
                local dir = {
                    top = {x=0,y=-1},
                    right = {x=1,y=0},
                    bottom = {x=0,y=1},
                    left = {x=-1,y=0}
                }
                for _, l in pairs(mj.properties) do
                    if l.name == "target" then
                        local direction = l.value
                        if not Maze[h][i].walls[direction] then
                            for m, n in pairs(dir) do
                                if m == direction then
                                    l.value = {
                                        x = layer.x + n.x,
                                        y = layer.y + n.y
                                    }
                                end
                            end
                        else 
                            goto continue
                        end
                    end 
                end
            end
            table.insert(layer.objects, mj)
             ::continue::
       
        end
        table.insert(maps, layer)
        end
    end
    return maps
end

function GetPolygons(data, x, y)
    local temp = {}
    for _, i in pairs(data) do
        if i.x == x and i.y == y then
            for _, j in pairs(i.objects) do
                if j.polygon then
                    local polygon = {points = {}}
                    for _, k in ipairs(j.polygon) do
                        table.insert(polygon.points, (k.x + j.x) )
                        table.insert(polygon.points, (k.y + j.y))
                    end
                    polygon.id = j.name
                    polygon.visible = j.visible
                    polygon.x, polygon.y = j.x, j.y
                    if j.type ~= "" then
                        polygon.type = j.type
                    end
                    if j.properties then
                        for _, k in pairs(j.properties) do
                            if k.name == "player" then
                                polygon.player = k.value
                            end
                            if k.name == "landing" then
                                polygon.landing = k.value
                            end
                            if k.name == "target" then
                                polygon.target = k.value
                            end
                        end
                    end
                    table.insert(temp, polygon)
                end
            end
        end
    end
    return temp
end




function DrawTable(temp, mode)
    mode = mode or "fill"
    for _, j in pairs(temp) do
        local default = true
        local colors = {
            wall = {
                r = 0,
                g = 0,
                b = 150
            },
            solid = {
                r = 200,
                g = 0,
                b = 0
            },
            ceiling = {
                r = 200,
                g = 0,
                b = 200
            },
            goal = {
                r = 0,
                g = 255,
                b = 0
            },
            slope = {
                r = 150,
                g = 200,
                b = 0
            },
            shadow = {
                r = 0,
                g = 0,
                b = 0,
                a = 0.5
            }

        }
        love.graphics.push()
        for k, l in pairs(colors) do
            if k == j.id then
                love.graphics.setColor(Rgb(l.r,l.g,l.b, l.a))
                default = false
            end
        end
        if default then
            love.graphics.setColor(1,1,1)
        end
        j:draw(mode)
        love.graphics.pop()
    end
end

function CreateLine(x, y, i)
    local temp = {}
    temp[1] = CreateCollider("circle", 9, 9, x, y - ((i -1) * 9), "player")
    return temp
end


function MovePlayer(player, gravity, mvy, mvx, dt)
    local moveSpeed = 2.5
    for i, _ in pairs(player) do
        player[i].vx = player[i].vx or 0
        player[i].vy = player[i].vy or 0
    end
    
    if not IsGrounded then
        player[1].vy = player[1].vy + gravity * dt
    end
   
    if math.abs(player[1].vy) > mvy then
        player[1].vy = math.sign(player[1].vy) * mvy
    end
    if math.abs(player[1].vx) > mvx then
        player[1].vx = math.sign(player[1].vx) * mvx
    end

    local left, right = GetKeys("left"), GetKeys("right")
    local x, y = 0, 0
    if (not Sliding) then
        if Jump() and IsGrounded and HasJump then
            HasJump = false
            y = -JumpForce
            DJTimer = 0
        elseif Jump() and DJ and DJTimer > 0.5 then
            DJ = false
            y = -JumpForce
        end
        if WallJump == 0 or Timer > 0.5 then
            if right then
                x = x + moveSpeed
            end
            if left then
                x = x - moveSpeed
            end
        elseif WallJump == -1 then
            if right then
                x = x + moveSpeed
            end
        elseif WallJump == 1 then
            if left then
                x = x - moveSpeed
            end
        end
    end
    
    player[1].vx = player[1].vx + x
    player[1].vy = player[1].vy + y 
    
    
end


function Collisions(player, dt)
    Sliding = false
    IsGrounded = false
    Wall = false
    CanDash = false
    for i, _ in pairs(player) do
        player[i].vx, player[i].vy = player[i].vx or 0, player[i].vy or 0
        for shape, delta in pairs(HC.collisions(player[i])) do
            if shape.type == "1" then
                if shape.id == "solid" and i == 1 then
                    player[i]:move(delta.x,delta.y)
                    HasJump = true
                    IsGrounded = true
                    WallJump = 0
                    if HasDJ then
                        DJ = true
                    end
                    if HasDash then
                        CanDash = true
                    end
                elseif (shape.id == "solid" and i ~= 1) or shape.id == "ceiling"  then
                    player[i]:move(delta.x,delta.y)
                    if shape.id == "ceiling" then
                        player[i].vy = 0
                    end
                elseif shape.id == "wall" and i == 1 then
                    player[i]:move(delta.x,delta.y)
                    if CanWJ then
                        Wall = true
                        if (WallJump == 0 or WallJump == math.sign(delta.x)) then
                            if Jump() then
                                if WallJump == 0 then
                                    WallJump = math.sign(delta.x)
                                end
                                if math.sign(player[1].vy) == -1 then
                                    player[1].vy = player[1].vy -JumpForce
                                else
                                    player[1].vy =  -JumpForce
                                end
                                player[1].vx =  WallJump * 25
                                WallJump = -WallJump
                                Timer = 0
                                MoveObject(Player[1], player[1].vx, player[1].vy, dt, 0.01)
                            end
                        end 
                    end

                elseif shape.id == "slope" and i == 1 then
                    Sliding = true
                    local deltaLength = math.sqrt(delta.x * delta.x + delta.y * delta.y)
                    local dx, dy = delta.x / deltaLength, delta.y / deltaLength

                    local gravityDirection = {x = 0, y = -1}

                    local dot = -dy
                    local px, py = dx - dot * gravityDirection.x, dy - dot * gravityDirection.y

                    local pl = math.sqrt(px * px + py * py)
                    px, py = px / pl, py / pl

                    local slopeSteepness = math.abs(dy)
                    local maxSpeedBase = 100
                    local maxSpeed = maxSpeedBase * (1 - slopeSteepness)
                    local vx, vy = px * maxSpeed, py * maxSpeed

                    local friction = 0.95 
                    player[1].vx = player[1].vx * friction + vx * (1 - friction)
                    player[1].vy = player[1].vy * friction + vy * (1 - friction)

                    for shape1, delta1 in pairs(HC.collisions(shape)) do
                        if shape1.id == "player" then
                            shape1:move(-delta1.x, -delta1.y)
                        end
                    end
                end
            elseif shape.type == "2" then
                if shape.id == "goal" and i == 1 then
                    Transition(shape)
                    return true
                end
            end
        end
    end
end

function Jump()
    local j
    if Joystick ~= nil then
        j = Joystick:isGamepadDown("a") or Joystick:isGamepadDown("b")
    end
    return (not JoyStickMode and love.keyboard.isDown("space")) or (JoyStickMode and j)
end

function DrawCell(cell, cellSize, current)
    local x = (cell.x - 1) * cellSize
    local y = (cell.y - 1) * cellSize
    local w = cellSize
    if cell.visited then
        love.graphics.push()
        local roomColors = {
            base = {
                r = 0,
                g = 0, 
                b = 255
            }
        }
        for i, j in pairs(roomColors) do
            if i == cell.type then
                love.graphics.setColor(Rgb(j.r,j.g,j.b))
            end
        end
        love.graphics.rectangle("fill", x, y, cellSize, cellSize)
        love.graphics.pop()
        love.graphics.push()
        if current then
            love.graphics.setColor(0,0,0)
            love.graphics.rectangle("fill", x+cellSize/3,y+cellSize/3,cellSize/3,cellSize/3)
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.pop()
        love.graphics.push()
        love.graphics.setColor(1,1,1)
        if cell.walls.top then
            love.graphics.rectangle("fill", x -2, y -2, w +2, 5)
        end
        if cell.walls.right then
            love.graphics.rectangle("fill", x + w -2, y-2, 5, w + 2)
        end
        if cell.walls.bottom then
            love.graphics.rectangle("fill", x -2, y +w -2, w +2, 5)
        end
        if cell.walls.left then
            love.graphics.rectangle("fill", x -2, y-2, 5, w + 2)
        end
        love.graphics.pop()
    end
end