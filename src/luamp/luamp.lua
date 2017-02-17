-- The MIT License (MIT)

-- Copyright (c) 2015 TimeExceed

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local luamp = {}
local table = require 'table'
local string = require 'string'
local math = require 'math'

-- helper functions

local function cloneTable(tbl)
    local clone = {}
    for k, v in pairs(tbl) do
        clone[k] = v
    end
    return clone
end

local function min(a, b)
    if a < b then
        return a
    else
        return b
    end
end

local function max(a, b)
    if a < b then
        return b
    else
        return a
    end
end

local function sqr(x)
    return x * x
end

local function map(f, list)
    local res = {}
    for i = 1, #list do
        table.insert(res, f(list[i]))
    end
    return res
end

local function fillOptions(opts)
    assert(opts == nil or type(opts) == 'table')

    local newOpts
    if not opts then
        newOpts = {}
    else
        newOpts = cloneTable(opts)
    end
    
    if not newOpts.pen_color then
        newOpts.pen_color = luamp.colors.default
    end
    if not newOpts.brush_color then
        newOpts.brush_color = luamp.colors.invisible
    end
    if not newOpts.line_style then
        newOpts.line_style = luamp.line_styles.solid
    end

    return newOpts
end

-- geometry

local Point = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __add = function(p0, p1)
        return luamp.point(p0.x + p1.x, p0.y + p1.y)
    end,
    __sub = function(p0, p1)
        return luamp.point(p0.x - p1.x, p0.y - p1.y)
    end,
    __eq = function(p0, p1)
        return p0.x == p1.x and p0.y == p1.y
    end,
    __tostring = function(p)
        return string.format('(Point x=%.2f y=%.2f)', p.x, p.y)
    end,
    __draw__ = function(p)
        return string.format('(%.2fcm,%.2fcm)', p.x, p.y)
    end,
    __center__ = function(p)
        return p
    end,
}

function luamp.point(x, y)
    local res = {
        x = x,
        y = y,
    }
    return setmetatable(res, Point)
end

luamp.origin = luamp.point(0, 0)

local function intersect_line(shape, target)
    assert(getmetatable(target) == Point)
    local mt = getmetatable(shape)
    assert(mt)
    assert(mt.__intersect_line__)
    return mt.__intersect_line__(shape, target)
end

local function centroid(...)
    assert(... ~= nil)
    local vargs = table.pack(...)
    for i = 1, #vargs do
        assert(getmetatable(vargs[i]) == Point)
    end
    local sumx = 0
    local sumy = 0
    for i = 1, #vargs do
        sumx = sumx + vargs[i].x
        sumy = sumy + vargs[i].y
    end
    return luamp.point(sumx / #vargs, sumy / #vargs)
end

local function distance(p0, p1)
    assert(getmetatable(p0) == Point)
    assert(getmetatable(p1) == Point)
    return math.sqrt(sqr(p0.x - p1.x) + sqr(p0.y - p1.y))
end

local function within_line(pt, line)
    local p0, p1 = table.unpack(line)
    local dp0 = pt - p0
    local dx0 = dp0.x
    local dy0 = dp0.y
    local dp1 = p1 - p0
    local dx1 = dp1.x
    local dy1 = dp1.y
    return dx0 * dx1 >= 0 and dy0 * dy1 >= 0
end

local function intersect_lines(line, target)
    local p0, p1 = table.unpack(line)
    local x0 = p0.x
    local y0 = p0.y
    local x1 = p1.x
    local y1 = p1.y
    local x2 = target.x
    local y2 = target.y
    local xx = x1 - x0
    local yy = y1 - y0
    local res
    if xx * y2 == x2 * yy then
        return nil -- parallel
    elseif y1 * xx == x1 * yy then
        res = luamp.origin
    else
        local a = (y1 - y0) / (x0 * y1 - x1 * y0)
        local b = (x1 - x0) / (x1 * y0 - x0 * y1)
        if x2 == 0 then
            res = luamp.point(0, 1 / b)
        else
            local c = y2 / x2
            local x = 1 / (b * c + a)
            local y = x * c
            res = luamp.point(x, y)
        end
    end
    if within_line(res, {luamp.origin, target}) then
        return res
    else
        return nil
    end
end


-- APIs

function luamp.figure(...)
    if not ... then
        return 'beginfig(0);\nendfig;\nend'
    else
        local vargs = table.pack(...)
        local res = {'verbatimtex',
                     '%&latex',
                     '\\documentclass{article}',
                     '\\begin{document}',
                     'etex',
                     'beginfig(0);'}
        for i = 1, #vargs do
            table.insert(res, luamp.draw(vargs[i]))
        end
        table.insert(res, 'endfig;')
        table.insert(res, 'end')
        return table.concat(res, '\n')
    end
end

function luamp.draw(shape)
    assert(shape)
    local mt = getmetatable(shape)
    assert(mt)
    assert(mt.__draw__)
    return mt.__draw__(shape)
end

function luamp.center(shape)
    local mt = getmetatable(shape)
    assert(mt)
    assert(mt.__center__)
    return mt.__center__(shape)
end

function luamp.vertices(shape)
    local mt = getmetatable(shape)
    assert(mt)
    assert(mt.__vertices__)
    return mt.__vertices__(shape)
end

-- colors

local DefaultColor = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(c)
        return 'default'
    end,
    __draw__ = function(c)
        return ''
    end,
}

local Invisible = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(c)
        return 'invisible'
    end,
    __draw__ = function(c)
        return nil
    end,
}

local Color = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(c)
        return string.format(
            '(Color r=$.2f g=%.2f b=%.2f)',
            c.red, c.green, c.blue)
    end,
    __draw__ = function(c)
        return string.format(
            ' withcolor (%.2f,%.2f,%.2f)',
            c.red, c.green, c.blue)
    end,
}

function luamp.color(red, green, blue)
    local res = {
        red = red,
        green = green,
        blue = blue,
    }
    return setmetatable(res, Color)
end

luamp.colors = {
    default = setmetatable({}, DefaultColor),
    invisible = setmetatable({}, Invisible),
    black = luamp.color(0,0,0),
    white = luamp.color(1,1,1),
    red = luamp.color(1,0,0),
    green = luamp.color(0,1,0),
    blue = luamp.color(0,0,1),
    yellow = luamp.color(1,1,0),
    purple = luamp.color(1,0,1),
    brown = luamp.color(0.5,0.5,0),
    magenta = luamp.color(0.5,0,0.5),
    cyan = luamp.color(0,0.5,0.5),
    gray = luamp.color(0.5,0.5,0.5),
    orange = luamp.color(1,0.5,0),
}

-- line styles

local Solid = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(s)
        return 'solid'
    end,
    __draw__ = function(s)
        return ''
    end,
}

local Dashed = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(s)
        return 'dashed'
    end,
    __draw__ = function(s)
        return ' dashed evenly'
    end,
}

local Dotted = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(s)
        return 'dotted'
    end,
    __draw__ = function(s)
        return ' dashed withdots'
    end,
}

luamp.line_styles = {
    solid = setmetatable({}, Solid),
    dashed = setmetatable({}, Dashed),
    dotted = setmetatable({}, Dotted),
}

-- shapes

local Circle = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(c)
        return string.format('(Circle center=%s radius=%.2f)', tostring(c.center), c.radius)
    end,
    __draw__ = function(c)
        local res = {}
        local shape = ' fullcircle scaled %.2fcm shifted %s'
        
        local brush = luamp.draw(c.brush_color)
        if brush then
            local format = 'fill' .. shape .. brush .. ';'
            table.insert(res, string.format(format, 2 * c.radius, luamp.draw(c.center)))
        end
        
        local pen = luamp.draw(c.pen_color)
        if pen then
            local format = 'draw' .. shape .. pen .. ';'
            table.insert(res, string.format(format, 2 * c.radius, luamp.draw(c.center)))
        end

        if #res == 0 then
            return nil
        else
            return table.concat(res, '\n')
        end
    end,
    __intersect_line__ = function(circle, target)
        local c = circle.center
        local r = circle.radius
        local p0 = target - c
        local l = distance(luamp.origin, p0)
        local x1 = p0.x * r / l
        local y1 = p0.y * r / l
        return c + luamp.point(x1, y1)
    end,
}

function luamp.circle(center, radius, opts)
    assert(getmetatable(center) == Point)
    assert(type(radius) == 'number')
    local opts = fillOptions(opts)
    local res = {
        center = center,
        radius = radius,
        pen_color = opts.pen_color,
        brush_color = opts.brush_color,
    }
    return setmetatable(res, Circle)
end

local Center = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'center'
    end,
    __draw__ = function(_)
        return 'label'
    end,
}

local Left = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'left'
    end,
    __draw__ = function(_)
        return 'label.lft'
    end,
}

local Right = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'right'
    end,
    __draw__ = function(_)
        return 'label.rt'
    end,
}

local Top = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'top'
    end,
    __draw__ = function(_)
        return 'label.top'
    end,
}

local Bottom = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'bottom'
    end,
    __draw__ = function(_)
        return 'label.bot'
    end,
}

local TopRight = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'top-right'
    end,
    __draw__ = function(_)
        return 'label.urt'
    end,
}

local TopLeft = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'top-left'
    end,
    __draw__ = function(_)
        return 'label.ulft'
    end,
}

local BottomLeft = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'bottom-left'
    end,
    __draw__ = function(_)
        return 'label.llft'
    end,
}

local BottomRight = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'bottom-right'
    end,
    __draw__ = function(_)
        return 'label.lrt'
    end,
}

luamp.directions = {
    center = setmetatable({}, Center),
    left = setmetatable({}, Left),
    right = setmetatable({}, Right),
    top = setmetatable({}, Top),
    bottom = setmetatable({}, Bottom),
    top_right = setmetatable({}, TopRight),
    top_left = setmetatable({}, TopLeft),
    bottom_left = setmetatable({}, BottomLeft),
    bottom_right = setmetatable({}, BottomRight),
}

local Text = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(t)
        return string.format('(Text direction=%s text=%s)', tostring(t.direction), t.text)
    end,
    __draw__ = function(t)
        local pen_color = luamp.draw(t.pen_color)
        if not pen_color then
            return nil
        end
        local command = luamp.draw(t.direction)
        local format = command .. '(btex %s etex, %s)' .. pen_color .. ';'
        return string.format(
            format,
            t.text, luamp.draw(t.center))
    end,
}

function luamp.text(center, direction, text, opts)
    assert(getmetatable(center) == Point)
    assert(direction == luamp.directions.center
        or direction == luamp.directions.left
        or direction == luamp.directions.right
        or direction == luamp.directions.top
        or direction == luamp.directions.bottom
        or direction == luamp.directions.top_right
        or direction == luamp.directions.top_left
        or direction == luamp.directions.bottom_left
        or direction == luamp.directions.bottom_right)
    assert(type(text) == 'string')
    local opts = fillOptions(opts)
    local res = {
        center = center,
        direction = direction,
        text = text,
        pen_color = opts.pen_color,
    }
    return setmetatable(res, Text)
end

local NoArrow = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(s)
        return 'no_arrow'
    end,
    __draw__ = function(_)
        return 'draw'
    end,
}

local SingleArrow = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(s)
        return 'single_arrow'
    end,
    __draw__ = function(_)
        return 'drawarrow'
    end,
}

local DoubleArrow = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(s)
        return 'double_arrow'
    end,
    __draw__ = function(_)
        return 'drawdblarrow'
    end,
}

local arrow_styles = {
    no = setmetatable({}, NoArrow),
    single = setmetatable({}, SingleArrow),
    double = setmetatable({}, DoubleArrow),
}

local Line = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(l)
        return string.format(
            '(Line from=%s to=%s)',
            tostring(l.from),
            tostring(l.to))
    end,
    __draw__ = function(l)
        local pen_color = luamp.draw(l.pen_color)
        if not pen_color then
            return nil
        end
        local line_style = luamp.draw(l.line_style)
        local command = luamp.draw(l.arrow)
        local format = command .. ' %s--%s' .. line_style .. pen_color .. ';'
        return string.format(
            format,
            luamp.draw(l.from),
            luamp.draw(l.to))
    end,
    __center__ = function(l)
        return centroid(l.from, l.to)
    end,
    __vertices__ = function(l)
        return {l.from, l.to}
    end
}

local function line_object(from, to, opts)
    local function line_point(s0, s1)
        if getmetatable(s0) == Point then
            return s0
        else
            return intersect_line(s0, luamp.center(s1))
        end
    end

    local opts = fillOptions(opts)
    local res = {
        from = line_point(from, to),
        to = line_point(to, from),
        line_style = opts.line_style,
        pen_color = opts.pen_color,
    }
    return setmetatable(res, Line)
end

function luamp.line(from, to, opts)
    local res = line_object(from, to, opts)
    return rawset(res, 'arrow', arrow_styles.no)
end

function luamp.arrow(from, to, opts)
    local res = line_object(from, to, opts)
    return rawset(res, 'arrow', arrow_styles.single)
end

function luamp.dblarrow(from, to, opts)
    local res = line_object(from, to, opts)
    return rawset(res, 'arrow', arrow_styles.double)
end


local Rectangle = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(r)
        return string.format(
            '(Rectangle center=%s length=%.2f height=%.2f)',
            tostring(r.center),
            r.half_length * 2,
            r.half_height * 2)
    end,
    __draw__ = function(r)
        local res = {}
        local shape = ' %s--%s--%s--%s--cycle' .. luamp.draw(r.line_style)

        local brush = luamp.draw(r.brush_color)
        if brush then
            local format = 'fill' .. shape .. brush .. ';'
            table.insert(
                res,
                string.format(
                    format,
                    table.unpack(map(luamp.draw, luamp.vertices(r)))))
        end
        
        local pen = luamp.draw(r.pen_color)
        if pen then
            local format = 'draw' .. shape .. pen .. ';'
            table.insert(
                res,
                string.format(
                    format,
                    table.unpack(map(luamp.draw, luamp.vertices(r)))))
        end

        if #res == 0 then
            return nil
        else
            return table.concat(res, '\n')
        end
    end,
    __center__ = function(r)
        return r.center
    end,
    __vertices__ = function(r)
        return {
            luamp.point(r.center.x - r.half_length, r.center.y + r.half_height),
            luamp.point(r.center.x + r.half_length, r.center.y + r.half_height),
            luamp.point(r.center.x + r.half_length, r.center.y - r.half_height),
            luamp.point(r.center.x - r.half_length, r.center.y - r.half_height),
        }
    end,
    __intersect_line__ = function(rec, target)
        local target = target - rec.center
        local corners = {
            luamp.point(rec.half_length, rec.half_height),
            luamp.point(rec.half_length, -rec.half_height),
            luamp.point(-rec.half_length, -rec.half_height),
            luamp.point(-rec.half_length, rec.half_height),
        }
        local edges = {
            {corners[1], corners[2]},
            {corners[2], corners[3]},
            {corners[3], corners[4]},
            {corners[4], corners[1]},
        }
        for i = 1, #edges do
            local pt = intersect_lines(edges[i], target)
            if pt and within_line(pt, edges[i]) then
                return pt
            end
        end
    end,
}

function luamp.rectangle(center, length, height, opts)
    assert(getmetatable(center) == Point)
    assert(type(length) == 'number')
    assert(length > 0)
    assert(type(height) == 'number')
    assert(height > 0)
    local opts = fillOptions(opts)
    local res = {
        center = center,
        half_length = length / 2,
        half_height = height / 2,
        line_style = opts.line_style,
        pen_color = opts.pen_color,
        brush_color = opts.brush_color,
    }
    return setmetatable(res, Rectangle)
end

function luamp.length(rec)
    assert(getmetatable(rec) == Rectangle)
    return rec.half_length * 2
end

function luamp.height(rec)
    assert(getmetatable(rec) == Rectangle)
    return rec.half_height * 2
end

local Bullet = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(c)
        return string.format('(Bullet center=%s)', tostring(c.center))
    end,
    __draw__ = function(c)
        return luamp.draw(
            luamp.circle(
                c.center,
                c.inner_radius,
                {pen_color=luamp.colors.invisible,
                 brush_color=c.brush_color}))
    end,
    __intersect_line__ = function(c, target)
        return intersect_line(luamp.circle(c.center, c.border_radius), target)
    end,
    __center__ = function(c)
        return c.center
    end,
}

function luamp.bullet(center, opts)
    assert(getmetatable(center) == Point)
    assert(opts == nil or type(opts) == 'table')

    if not opts then
        opts = {}
    else
        opts = cloneTable(opts)
    end
    
    if not opts.brush_color then
        opts.brush_color = luamp.colors.default
    end
    
    local res = {
        center = center,
        inner_radius = 0.1,
        border_radius = 0.11,
        brush_color = opts.brush_color,
    }
    return setmetatable(res, Bullet)
end


-- layouts

luamp.layouts = {}

local Matrix = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(m)
        return string.format(
            '(Matrix)')
    end,
    __draw__ = function(m)
        local instructions = {}
        for i = 1, #m.shapes do
            for j = 1, #(m.shapes[i]) do
                local s = m.shapes[i][j]
                if s then
                    table.insert(instructions, luamp.draw(s))
                end
            end
        end
        return table.concat(instructions, '\n')
    end,
    __center__ = function(m)
        return m.center
    end,
}

function luamp.layouts.matrix(center, rowSep, colSep, shapes)
    assert(getmetatable(center) == Point)
    assert(type(rowSep) == 'number')
    assert(type(colSep) == 'number')
    assert(type(shapes) == 'table')
    local nRow = #shapes
    assert(nRow > 0)
    local nCol = #(shapes[1])
    for i = 2, nRow do
        if #(shapes[i]) > nCol then
            nCol = #(shapes[i])
        end
    end
    for i = 1, nRow do
        local col = shapes[i]
        for j = 1, #col do
            local s = col[j]
            assert(not s or type(s) == 'function', type(s))
        end
    end

    local offset = center - luamp.point(colSep * (nCol - 1) / 2, rowSep * (nRow - 1) / 2)
    local realShapes = {}
    for i = 1, nRow do
        local cols = {}
        table.insert(realShapes, cols)
        for j = 1, nCol do
            local s = shapes[i][j]
            if s then
                local c = luamp.point(colSep * (j - 1), rowSep * (nRow - i)) + offset
                local x = s(c)
                table.insert(cols, x)
            else
                table.insert(cols, false) -- cannot insert nil
            end
        end
    end

    local res = {
        center = center,
        shapes = realShapes,
    }
    return setmetatable(res, Matrix)
end

local Tree = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(t)
        return string.format(
            '(Tree)')
    end,
    __draw__ = function(t)
        local instructions = {}
        local function recurDraw(t)
            assert(#t > 0)
            if t[1] then
               table.insert(instructions, luamp.draw(t[1]))
            end
            for i = 2, #t do
                recurDraw(t[i])
            end
        end

        recurDraw(t.shapes)
        return table.concat(instructions, '\n')
    end,
    __center__ = function(m)
        return m.center
    end,
}

function luamp.layouts.tree(center, rowSep, colSep, shapes)
    assert(getmetatable(center) == Point)
    assert(type(rowSep) == 'number')
    assert(type(colSep) == 'number')
    assert(type(shapes) == 'table')
    assert(#shapes > 0)

    local function downwards(tree, incx)
	assert(#tree > 0)
	tree[1].x = tree[1].x + incx
	for i = 2, #tree do
	    downwards(tree, incx)
	end
    end

    local lastX = {}
    
    local function upwards(tree, level)
        assert(#tree > 0)

	if #lastX < level then
	    table.insert(lastX, -colSep)
	end

        local minx, maxx
	local subtrees = {}
        for i = 2, #tree do
            local subtree = upwards(tree[i], level + 1)
	    table.insert(subtrees, subtree)
            if i == 2 then
                minx = subtree[1].x
            end
            if i == #tree then
                maxx = subtree[1].x
            end
        end
        assert((minx == nil) == (#subtrees == 0),
            string.format('minx=%s maxx=%s', tostring(minxx), tostring(#subtrees)))
        assert((maxx == nil) == (#subtrees == 0),
            string.format('minx=%s maxx=%s', tostring(minxx), tostring(#subtrees)))

        local x
        if #subtrees == 0 then
	    x = 0
	else
	    x = (minx + maxx) / 2
	end
        
	local xx = max(x, lastX[level] + colSep)
	local incx = xx - x
	x = xx
	lastX[level] = x

	if #subtrees > 0 then
	    local sep = (maxx - minx) / (#subtrees - 1)
	    for i = 1, #subtrees do
		local realIncX = incx + minx + sep * (i - 1) - subtrees[i][1].x
		if realIncX > 0 then
		    downwards(subtrees[i], realIncX)
		end
	    end
	end

	local res = {}
	table.insert(res, luamp.point(x, -rowSep * (level - 1)))
	for i = 1, #subtrees do
	    table.insert(res, subtrees[i])
	end
	return res
    end
    local function arrange(shapes)
        return upwards(shapes, 1)
    end
    local positions = arrange(shapes)

    local function computeBottomRight(tree)
        assert(#tree > 0)
        local maxx = tree[1].x
        local miny = tree[1].y
        for i = 2, #tree do
            local x, y = computeBottomRight(tree[i])
            maxx = max(x, maxx)
            miny = min(y, miny)
        end
        return maxx, miny
    end
    local function computeOffset()
        local x, y = computeBottomRight(positions)
        return center - luamp.point(x / 2, y / 2)
    end
    local offset = computeOffset()

    local function makeShapes(shapes, positions)
        assert(#shapes > 0, tostring(#shapes))
        assert(#shapes == #positions,
            string.format('#shapes=%d #positions=%d', #shapes, #positions))
        local tree = {}
        if shapes[1] then
            table.insert(tree, (shapes[1])(positions[1] + offset))
        else
            table.insert(tree, false)
        end
        for i = 2, #shapes do
            local subtree = makeShapes(shapes[i], positions[i])
            table.insert(tree, subtree)
        end
        return tree
    end
    local realShapes = makeShapes(shapes, positions)

    local res = {
        center = center,
        shapes = realShapes,
    }
    return setmetatable(res, Tree)
end

return luamp

