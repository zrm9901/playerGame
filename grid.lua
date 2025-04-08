-- Config
require "Util"
local cols, rows
local loops
local grid = {}
local walls = {}
local parent = {}

-- Cell with wall setup
local function createCell(x, y)
    return {
        x = x,
        y = y,
        walls = { top = true, right = true, bottom = true, left = true },
        visited = false,
        type = "base"
    }
end

-- Grid init
local function initGrid()
    for y = 1, rows do
        grid[y] = {}
        for x = 1, cols do
            local cell = createCell(x, y)
            grid[y][x] = cell
            parent[cell] = cell -- each cell is its own parent
        end
    end
end

-- Union-Find
local function find(cell)
    if parent[cell] ~= cell then
        parent[cell] = find(parent[cell]) -- path compression
    end
    return parent[cell]
end

local function union(a, b)
    local rootA = find(a)
    local rootB = find(b)
    if rootA ~= rootB then
        parent[rootB] = rootA
    end
end

-- Generate all walls (right and bottom only to avoid duplicates)
local function generateWalls()
    for y = 1, rows do
        for x = 1, cols do
            local current = grid[y][x]
            if x < cols then
                table.insert(walls, { a = current, b = grid[y][x+1], dir = "right" })
            end
            if y < rows then
                table.insert(walls, { a = current, b = grid[y+1][x], dir = "bottom" })
            end
        end
    end
end

-- Wall removal
local function removeWall(a, b, dir)
    if dir == "right" then
        a.walls.right = false
        b.walls.left = false
    elseif dir == "bottom" then
        a.walls.bottom = false
        b.walls.top = false
    end
end

-- Fisher-Yates shuffle
local function shuffle(t)
    for i = #t, 2, -1 do
        local j = love.math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

-- Kruskal’s algorithm
local function generateMaze()
    shuffle(walls)
    for _, wall in ipairs(walls) do
        local a, b = wall.a, wall.b
        if find(a) ~= find(b) then
            removeWall(a, b, wall.dir)
            union(a, b)
        end
    end
end

-- Draw cells
function DrawCell(cell, cellSize)
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
        love.graphics.setColor(1, 1, 1)
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
    end
    
end

function InitMaze(numcolumns, numrows, numloops)
    cols, rows, loops = numcolumns, numrows, numloops
    initGrid()
    generateWalls()
    generateMaze()
    for _ = 1, loops do
        local wall = walls[math.random(1, #walls)]
        local a, b = wall.a, wall.b
        removeWall(a,b,wall.dir)
    end
    return grid
end

function GetCell(maze, x, y)
    return maze[y][x]
end

