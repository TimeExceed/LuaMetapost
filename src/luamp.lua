-- The MIT License (MIT)

-- Copyright (c) 2015 TimeExceed, https://github.com/TimeExceed/LuaMetapost

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

local table = require 'table'
local string = require 'string'
local math = require 'math'
local stream = require 'stream'

local luamp = {}
luamp.ext = {}

-- helper functions

local function clone_table(tbl)
    local clone = {}
    for k, v in pairs(tbl) do
        clone[k] = v
    end
    return clone
end

luamp.ext.clone_table = clone_table

local function min(a, b)
    if a < b then
        return a
    else
        return b
    end
end

function luamp.min(...)
    assert(... ~= nil)
    local xs = table.pack(...)
    return stream.from_list(xs)
        :accumulate(min)
        :last()
end

local function max(a, b)
    if a < b then
        return b
    else
        return a
    end
end

function luamp.max(...)
    assert(... ~= nil)
    local xs = table.pack(...)
    return stream.from_list(xs)
        :accumulate(max)
        :last()
end

local function sqr(x)
    return x * x
end

local function fill_options(opts)
    assert(opts == nil or type(opts) == 'table')

    local new_opts
    if not opts then
        new_opts = {}
    else
        new_opts = clone_table(opts)
    end

    if not new_opts.pen_color then
        new_opts.pen_color = luamp.colors.default
    end
    if not new_opts.brush_color then
        new_opts.brush_color = luamp.colors.invisible
    end
    if not new_opts.line_style then
        new_opts.line_style = luamp.line_styles.solid
    end

    return new_opts
end

local Base = {}

luamp.ext.Base = Base

function Base.__index(this, key)
    local mt = getmetatable(this)
    assert(mt, string.format('no metatable is found on "%s"', this))
    local method = rawget(mt, key)
    assert(method, string.format('method "%s" is required on "%s"', key, this))
    return method
end

function Base.__newindex()
    error('cannot be modified')
end

function Base.center(this)
    local vs = this:vertices()
    return luamp.centroid(table.unpack(vs))
end

-- geometry

local Point = clone_table(Base)

function Point.__add(p0, p1)
    return luamp.point(p0.x + p1.x, p0.y + p1.y)
end

function Point.__sub(p0, p1)
    return luamp.point(p0.x - p1.x, p0.y - p1.y)
end

function Point.__eq(p0, p1)
    return p0.x == p1.x and p0.y == p1.y
end

function Point.__tostring(p)
    return string.format('(%.2fcm,%.2fcm)', p.x, p.y)
end

function Point._draw(this, outs)
end

function Point.center(this)
    return this
end

function luamp.point(x, y)
    local res = {
        x = x,
        y = y,
    }
    return setmetatable(res, Point)
end

luamp.origin = luamp.point(0, 0)

function luamp.centroid(...)
    assert(... ~= nil)
    local vargs = table.pack(...)
    for i = 1, #vargs do
        assert(getmetatable(vargs[i]) == Point,
            string.format('Point is required but "%s".', vargs[i]))
    end
    local sump = stream.from_list(vargs)
        :accumulate(function(last, x)
            return last + x
        end)
        :last()
    return luamp.point(sump.x / #vargs, sump.y / #vargs)
end

local function distance(p0, p1)
    assert(getmetatable(p0) == Point,
        string.format('Point is required but "%s"', p0))
    assert(getmetatable(p1) == Point,
        string.format('Point is required but "%s"', p1))
    return math.sqrt(sqr(p0.x - p1.x) + sqr(p0.y - p1.y))
end

local function within_line(pt, line)
    local p0, p1 = table.unpack(line)
    local c = distance(p0, p1)
    local a = distance(pt, p0)
    local b = distance(pt, p1)
    if a == 0 or b == 0 then
        return true
    else
        return (a*a + b*b - c*c) / (2 * a * b) < 0
    end
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

function Base._intersect_line(this, target)
    local center = this:center()
    local vertices = this:vertices()
    local target = target - center
    local corners = stream.from_list(vertices)
        :map(function(x)
            return x - center
        end)
        :collect()

    local edges = stream
        .zip(
            stream.from_list(corners),
            stream.from_list(corners)
                :chain(stream.from_list(corners))
                :drop(1))
        :collect()
    for i = 1, #edges do
        local pt = intersect_lines(edges[i], target)
        if pt and within_line(pt, edges[i]) then
            return pt + center
        end
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
                     '\\usepackage{amsmath}',
                     '\\begin{document}',
                     '\\footnotesize',
                     'etex',
                     'beginfig(0);'}
        for i = 1, #vargs do
            vargs[i]:_draw(res)
        end
        table.insert(res, 'endfig;')
        table.insert(res, 'end')
        return table.concat(res, '\n')
    end
end

-- colors

local DefaultColor = {
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(c)
        return 'default'
    end,
    _draw = function(c)
        return ''
    end,
}

local Invisible = {
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(c)
        return 'invisible'
    end,
    _draw = function(c)
        return nil
    end,
}

local Color = clone_table(Base)

function Color.__tostring(c)
    return string.format(
        '(Color r=$.2f g=%.2f b=%.2f)',
        c.m_red, c.m_green, c.m_blue)
end

function Color._draw(c)
    return string.format(
        ' withcolor (%.2f,%.2f,%.2f)',
        c.m_red, c.m_green, c.m_blue)
end

function luamp.color(red, green, blue)
    local res = {
        m_red = red,
        m_green = green,
        m_blue = blue,
    }
    return setmetatable(res, Color)
end

luamp.colors = {
    default = DefaultColor,
    invisible = Invisible,
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

luamp.line_styles = {}

luamp.line_styles.solid = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(s)
        return 'solid'
    end,
    _draw = function(s)
        return ''
    end,
}

luamp.line_styles.dashed = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(s)
        return 'dashed'
    end,
    _draw = function(s)
        return ' dashed evenly'
    end,
}

luamp.line_styles.dotted = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(s)
        return 'dotted'
    end,
    _draw = function(s)
        return ' dashed withdots'
    end,
}

-- shapes

local Circle = clone_table(Base)

function Circle.__tostring(this)
    return string.format(
        '(Circle center=%s radius=%.2f)',
        this.m_center, this.m_radius)
end

function Circle.center(this)
    return this.m_center
end

function Circle._draw(this, outs)
    local brush = this.m_opts.brush_color:_draw()
    if brush then
        local shape = string.format(
            'fill fullcircle scaled %.2fcm shifted %s%s;',
            2 * this.m_radius,
            this.m_center,
            brush)
        table.insert(outs, shape)
    end

    local pen = this.m_opts.pen_color:_draw()
    if pen then
        local line_style = this.m_opts.line_style:_draw()
        local shape = string.format(
            'draw fullcircle scaled %.2fcm shifted %s%s%s;',
            2 * this.m_radius,
            this.m_center,
            pen,
            line_style)
        table.insert(outs, shape)
    end
end

function Circle._intersect_line(this, target)
    local c = this.m_center
    local r = this.m_radius
    local p0 = target - c
    local l = distance(luamp.origin, p0)
    assert(l > 0, 'target must be a point outside the circle.')
    local x1 = p0.x * r / l
    local y1 = p0.y * r / l
    return c + luamp.point(x1, y1)
end

function luamp.circle(center, radius, opts)
    assert(getmetatable(center) == Point)
    assert(type(radius) == 'number')
    local opts = fill_options(opts)
    local res = {
        m_center = center,
        m_radius = radius,
        m_opts = fill_options(opts),
    }
    return setmetatable(res, Circle)
end

-- text

luamp.directions = {}

luamp.directions.center = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'center'
    end,
    _draw = function(_)
        return 'label'
    end,
}

luamp.directions.left = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'left'
    end,
    _draw = function(_)
        return 'label.lft'
    end,
}

luamp.directions.right = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'right'
    end,
    _draw = function(_)
        return 'label.rt'
    end,
}

luamp.directions.top = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'top'
    end,
    _draw = function(_)
        return 'label.top'
    end,
}

luamp.directions.bottom = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'bottom'
    end,
    _draw = function(_)
        return 'label.bot'
    end,
}

luamp.directions.top_right = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'top-right'
    end,
    _draw = function(_)
        return 'label.urt'
    end,
}

luamp.directions.top_left = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'top-left'
    end,
    _draw = function(_)
        return 'label.ulft'
    end,
}

luamp.directions.bottom_left = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'bottom-left'
    end,
    _draw = function(_)
        return 'label.llft'
    end,
}

luamp.directions.bottom_right = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function()
        return 'bottom-right'
    end,
    _draw = function(_)
        return 'label.lrt'
    end,
}

local Text = clone_table(Base)

function Text.__tostring(t)
    return string.format('(Text direction=%s text=%s)', t.m_direction, t.m_text)
end

function Text.center(this)
    return this.m_center
end

function Text._draw(this, outs)
    local pen_color = this.m_opts.pen_color:_draw()
    if not pen_color then
        return
    end
    local command = this.m_direction:_draw()
    local res = string.format(
        '%s(btex %s etex, %s)%s;',
        command,
        this.m_text,
        this.m_center,
        pen_color)
    table.insert(outs, res)
end

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
    local res = {
        m_center = center,
        m_direction = direction,
        m_text = text,
        m_opts = fill_options(opts),
    }
    return setmetatable(res, Text)
end

-- line, arrow

local arrow_styles = {}

arrow_styles.none = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(s)
        return 'no_arrow'
    end,
    _draw = function(_)
        return 'draw'
    end,
}

arrow_styles.single = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(s)
        return 'single_arrow'
    end,
    _draw = function(_)
        return 'drawarrow'
    end,
}

arrow_styles.double = {
    __index = function()
        error('cannot be indexed')
    end,
    __newindex = function()
        error('cannot be modified')
    end,
    __tostring = function(s)
        return 'double_arrow'
    end,
    _draw = function(_)
        return 'drawdblarrow'
    end,
}

local Line = clone_table(Base)

function Line.__tostring(this)
    return string.format(
        '(Line from=%s to=%s)',
        this.m_from,
        this.m_to)
end

function Line._draw(this, outs)
    local pen_color = this.m_opts.pen_color:_draw()
    if not pen_color then
        return
    end
    local line_style = this.m_opts.line_style:_draw()
    local command = this.m_arrow:_draw()
    local res = string.format(
        '%s %s--%s%s%s;',
        command,
        this.m_from,
        this.m_to,
        line_style,
        pen_color)
    table.insert(outs, res)
end

function Line.vertices(this)
    return {this.m_from, this.m_to}
end

local function line_object(from, to, opts)
    assert(from)
    assert(to)
    local function line_point(s0, s1)
        if getmetatable(s0) == Point then
            return s0
        else
            return s0:_intersect_line(s1:center())
        end
    end

    local res = {
        m_from = line_point(from, to),
        m_to = line_point(to, from),
        m_opts = fill_options(opts),
    }
    assert(res.m_from)
    assert(res.m_to)
    return setmetatable(res, Line)
end

function luamp.line(from, to, opts)
    local res = line_object(from, to, opts)
    return rawset(res, 'm_arrow', arrow_styles.none)
end

function luamp.arrow(from, to, opts)
    local res = line_object(from, to, opts)
    return rawset(res, 'm_arrow', arrow_styles.single)
end

function luamp.dblarrow(from, to, opts)
    local res = line_object(from, to, opts)
    return rawset(res, 'm_arrow', arrow_styles.double)
end

-- rectangle

local Rectangle = clone_table(Base)

function Rectangle.__tostring(this)
    local center = luamp.centroid(table.unpack(this.m_vertices))
    local width = (this.m_vertices[2] - this.m_vertices[1]).x
    local height = (this.m_vertices[2] - this.m_vertices[3]).y
    return string.format(
        '(Rectangle center=%s length=%.2f height=%.2f)',
        center,
        width,
        height)
end

function Rectangle._draw(this, outs)
    local shape = string.format(
        '%s--%s--%s--%s--cycle',
        table.unpack(this:vertices()))

    local brush = this.m_opts.brush_color:_draw()
    if brush then
        local shape = string.format(
            'fill %s%s;',
            shape,
            brush)
        table.insert(outs, shape)
    end

    local pen = this.m_opts.pen_color:_draw()
    if pen then
        local line_style = this.m_opts.line_style:_draw()
        local shape = string.format(
            'draw %s%s%s;',
            shape,
            line_style,
            pen)
        table.insert(outs, shape)
    end
end

function Rectangle.vertices(this)
    return this.m_vertices
end

function Rectangle.width(this)
    assert(getmetatable(this) == Rectangle)
    return (this.m_vertices[2] - this.m_vertices[1]).x
end

function Rectangle.height(this)
    assert(getmetatable(this) == Rectangle)
    return (this.m_vertices[2] - this.m_vertices[3]).y
end

function luamp.rectangle(center, width, height, opts)
    assert(getmetatable(center) == Point)
    assert(type(width) == 'number')
    assert(width > 0)
    assert(type(height) == 'number')
    assert(height > 0)

    local half_width = width / 2
    local half_height = height / 2

    local corners = {
        luamp.point(-half_width, half_height),
        luamp.point(half_width, half_height),
        luamp.point(half_width, -half_height),
        luamp.point(-half_width, -half_height),
    }
    local vertices = stream.from_list(corners)
        :map(function(x)
            return x + center
        end)
        :collect()

    local res = {
        m_vertices = vertices,
        m_opts = fill_options(opts),
    }
    return setmetatable(res, Rectangle)
end

-- bullet

local Bullet = clone_table(Base)

function Bullet.__tostring(this)
    return string.format('(Bullet center=%s)', this.m_center)
end

function Bullet._draw(this, outs)
    local x = luamp.circle(
        this:center(),
        this.m_inner_radius,
        this.m_opts)
    x:_draw(outs)
end

function Bullet.center(this)
    return this.m_center
end

function Bullet._intersect_line(c, target)
    return luamp.circle(c:center(), c.m_border_radius)
        :_intersect_line(target)
end


function luamp.bullet(center, opts)
    assert(getmetatable(center) == Point)

    local filled_opts = fill_options(opts)
    if not opts or not opts.brush_color then
        filled_opts.brush_color = luamp.colors.default
    end
    if not opts or not opts.pen_color then
        filled_opts.pen_color = luamp.colors.invisible
    end

    local res = {
        m_center = center,
        m_opts = filled_opts,
        m_inner_radius = 0.05,
        m_border_radius = 0.06,
    }
    return setmetatable(res, Bullet)
end

-- triangle

local Triangle = clone_table(Base)

function Triangle.__tostring(this)
    return string.format(
        '(Triangle left=%s top=%s right=%s)',
        this.m_left,
        this.m_top,
        this.m_right)
end

function Triangle._draw(this, outs)
    local shape = string.format(
        '%s--%s--%s--cycle',
        table.unpack(this:vertices()))

    local pen = this.m_opts.pen_color:_draw()
    if pen then
        local shape = string.format(
            'draw %s%s%s;',
            shape,
            this.m_opts.line_style:_draw(),
            pen)
        table.insert(outs, shape)
    end

    local brush = this.m_opts.brush_color:_draw()
    if brush then
        local shape = string.format(
            'fill %s%s;',
            shape,
            brush)
        table.insert(outs, shape)
    end
end

function Triangle.vertices(this)
    return {this.m_left, this.m_top, this.m_right}
end

function luamp.triangle(center, width, height, opts)
    assert(getmetatable(center) == Point)
    assert(type(width) == 'number')
    assert(width > 0)
    assert(type(height) == 'number')
    assert(height > 0)
    local res = {
        m_left = center + luamp.point(-width/2, -height/3),
        m_top = center + luamp.point(0, height*2/3),
        m_right = center + luamp.point(width/2, -height/3),
        m_opts = fill_options(opts),
    }
    return setmetatable(res, Triangle)
end

-- layouts

luamp.layouts = {}

function luamp.layouts.matrix(center, row_sep, col_sep, shapes)
    assert(getmetatable(center) == Point)
    assert(type(row_sep) == 'number')
    assert(type(col_sep) == 'number')
    assert(type(shapes) == 'table')
    local n_row = #shapes
    local n_col = stream.from_list(shapes)
        :map(function(x)
            return #x
        end)
        :accumulate(max)
        :last()
    for i = 1, n_row do
        local col = shapes[i]
        for j = 1, #col do
            local s = col[j]
            assert(not s or type(s) == 'function', type(s))
        end
    end

    local offset = luamp.point(
        col_sep * (n_col - 1) / 2,
        row_sep * (n_row - 1) / 2)
    offset = center - offset
    local real_shapes = {}
    for i = 1, n_row do
        local cols = {}
        table.insert(real_shapes, cols)
        for j = 1, n_col do
            local s = shapes[i][j]
            local c = offset + luamp.point(
                col_sep * (j - 1),
                row_sep * (n_row - i))
            if s then
                local x = s(c)
                table.insert(cols, x)
            else
                table.insert(cols, c)
            end
        end
    end

    return real_shapes
end

function luamp.layouts.tree(center, row_sep, col_sep, shapes)
    assert(getmetatable(center) == Point)
    assert(type(row_sep) == 'number')
    assert(type(col_sep) == 'number')
    assert(type(shapes) == 'table')
    assert(#shapes > 0)

    local function shift(tree, diff)
        assert(#tree > 0)
        tree[1] = tree[1] + diff
        for i = 2, #tree do
            shift(tree[i], diff)
        end
    end

    local function init_pt_tree(shapes, level)
        local t = {luamp.point(0, -row_sep * level)}
        for i = 2, #shapes do
            local subt = init_pt_tree(shapes[i], level + 1)
            table.insert(t, subt)
        end
        return t
    end

    local pt_tree = init_pt_tree(shapes, 0)

    local function count_level(shapes)
        local subheights = stream.from_list(shapes)
            :drop(1)
            :map(count_level)
            :collect()
        if #subheights == 0 then
            return 1
        else
            return 1 + luamp.max(table.unpack(subheights))
        end
    end

    local max_level = count_level(shapes)
    local levelled_max_x = stream.repeated(-col_sep)
        :take(max_level)
        :collect()

    local function fix_levelled_max_x(t, level)
        levelled_max_x[level] = max(levelled_max_x[level], t[1].x)
        for i = 2, #t do
            fix_levelled_max_x(t[i], level + 1)
        end
    end

    local function arrange(t, level)
        if #t == 1 then
            local max_x = levelled_max_x[level]
            local x = max(t[1].x, max_x + col_sep)
            t[1].x = x
            fix_levelled_max_x(t, level)
            return x
        else
            local xs = stream.from_list(t)
                :drop(1)
                :map(function(x)
                    return arrange(x, level + 1)
                end)
                :collect()
            local min_x = luamp.min(table.unpack(xs))
            local max_x = luamp.max(table.unpack(xs))

            if #t > 3 then
                stream
                    .zip(
                        stream.range(2, #t + 1),
                        stream.range(#t, 1, -1))
                    :take_while(function(x)
                        return x[1] < x[2]
                    end)
                    :map(function(x)
                        local start = x[1]
                        local stop = x[2]
                        local n_sep = stop - start
                        local sep = (t[stop][1].x - t[start][1].x) / n_sep
                        for i = start + 1, stop - 1 do
                            local x = t[start][1].x + sep * (i - start)
                            if x > t[i][1].x then
                                local dp = luamp.point(x - t[i][1].x, 0)
                                shift(t[i], dp)
                            end
                        end
                        return true
                    end)
                    :collect()
            end

            local mid_x = (min_x + max_x) / 2
            t[1].x = mid_x
            local dx = t[1].x - mid_x
            if levelled_max_x[level] + col_sep > mid_x then
                local dp = luamp.point(levelled_max_x[level] + col_sep - mid_x, 0)
                shift(t, dp)
            end

            fix_levelled_max_x(t, level)
            return t[1].x
        end
    end

    arrange(pt_tree, 1)

    local function bbox(t)
        local min_x = t[1].x
        local min_y = t[1].y
        local max_x = t[1].x
        local max_y = t[1].y
        for i = 2, #t do
            local min_x_1, min_y_1, max_x_1, max_y_1 = bbox(t[i])
            min_x = luamp.min(min_x, min_x_1)
            min_y = luamp.min(min_y, min_y_1)
            max_x = luamp.max(max_x, max_x_1)
            max_y = luamp.max(max_y, max_y_1)
        end
        return min_x, min_y, max_x, max_y
    end

    local min_x, min_y, max_x, max_y = bbox(pt_tree)
    local dp = center - luamp.point((min_x + max_x) / 2, (min_y + max_y) / 2)
    shift(pt_tree, dp)

    local function make_shapes(shapes, pt_tree)
        assert(#shapes > 0, tostring(#shapes))
        assert(#shapes == #pt_tree,
               string.format('#shapes=%d #positions=%d', #shapes, #pt_tree))
        local tree = {}
        if shapes[1] then
            table.insert(tree, (shapes[1])(pt_tree[1]))
        else
            table.insert(tree, pt_tree[1])
        end
        for i = 2, #shapes do
            local subtree = make_shapes(shapes[i], pt_tree[i])
            table.insert(tree, subtree)
        end
        return tree
    end
    local real_shapes = make_shapes(shapes, pt_tree)

    return real_shapes
end

return luamp

