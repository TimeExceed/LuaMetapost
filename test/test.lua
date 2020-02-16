local testa = require 'testa'
local luamp = require 'luamp'
local table = require 'table'
local stream = require 'stream'

local helpers = {}

helpers.min = testa.eq(
    function(...)
        return luamp.min(...)
    end,
    function(...)
        local xs = table.pack(...)
        table.sort(xs)
        return xs[1]
    end,
    function(verifier)
        for i = 1, 3 do
            for j = 1,3 do
                for k = 1,3 do
                    local ok, msg = verifier(i, j, k)
                    if not ok then
                        return false, msg
                    end
                end
            end
        end
        return true
    end
)

helpers.max = testa.eq(
    function(...)
        return luamp.max(...)
    end,
    function(...)
        local xs = table.pack(...)
        table.sort(xs)
        return xs[#xs]
    end,
    function(verifier)
        for i = 1, 3 do
            for j = 1,3 do
                for k = 1,3 do
                    local ok, msg = verifier(i, j, k)
                    if not ok then
                        return false, msg
                    end
                end
            end
        end
        return true
    end
)

local figure = {}

figure.empty = testa.is(
    function ()
        return luamp.figure()
    end,
    [[beginfig(0);
endfig;
end]])

figure.circle = testa.is(
    function()
        return luamp.figure(luamp.circle(luamp.point(0,0), 1))
    end,
    [[verbatimtex
%&latex
\documentclass{article}
\usepackage{amsmath}
\begin{document}
\footnotesize
etex
beginfig(0);
draw fullcircle scaled 2.00cm shifted (0.00cm,0.00cm);
endfig;
end]])

local function draw(shape)
    local res = {}
    shape:_draw(res)
    return table.concat(res, '\n')
end

local circle = {}

circle.draw = testa.is(
    function()
        return draw(luamp.circle(luamp.point(0, 0), 1))
    end,
    'draw fullcircle scaled 2.00cm shifted (0.00cm,0.00cm);')

circle.pen_color = testa.is(
    function()
        return draw(luamp.circle(
		    luamp.point(0, 0), 1,
		    {pen_color=luamp.colors.red}))
    end,
    'draw fullcircle scaled 2.00cm shifted (0.00cm,0.00cm) withcolor (1.00,0.00,0.00);')

circle.brush_color = testa.is(
    function()
        return draw(luamp.circle(
		    luamp.point(0, 0), 1,
		    {pen_color=luamp.colors.invisible,
		     brush_color=luamp.colors.red}))
    end,
    'fill fullcircle scaled 2.00cm shifted (0.00cm,0.00cm) withcolor (1.00,0.00,0.00);')

circle.pen_and_brush = testa.is(
    function()
        return draw(luamp.circle(
		    luamp.point(0, 0), 1,
		    {pen_color=luamp.colors.red,
		     brush_color=luamp.colors.green}))
    end,
    [[fill fullcircle scaled 2.00cm shifted (0.00cm,0.00cm) withcolor (0.00,1.00,0.00);
draw fullcircle scaled 2.00cm shifted (0.00cm,0.00cm) withcolor (1.00,0.00,0.00);]])

circle.dashed = testa.is(
    function()
        local shape = luamp.circle(
            luamp.point(1, 2),
            1,
            {line_style=luamp.line_styles.dashed})
        return draw(shape)
    end,
    'draw fullcircle scaled 2.00cm shifted (1.00cm,2.00cm) dashed evenly;')

circle.invisible = testa.is(
    function()
        return draw(luamp.circle(
            luamp.point(0, 0), 1,
            {pen_color=luamp.colors.invisible}))
    end,
    '')

local text = {}

text.center = testa.is(
    function()
        return draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.center,
            '$\\ast$'))
    end,
    'label(btex $\\ast$ etex, (0.00cm,0.00cm));')

text.left = testa.is(
    function()
        return draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.left,
            '$\\leftarrow$'))
    end,
    'label.lft(btex $\\leftarrow$ etex, (0.00cm,0.00cm));')

text.right = testa.is(
    function()
        return draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.right,
            '$\\rightarrow$'))
    end,
    'label.rt(btex $\\rightarrow$ etex, (0.00cm,0.00cm));')

text.top = testa.is(
    function()
        return draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.top,
            '$\\uparrow$'))
    end,
    'label.top(btex $\\uparrow$ etex, (0.00cm,0.00cm));')

text.bottom = testa.is(
    function()
        return draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.bottom,
            '$\\downarrow$'))
    end,
    'label.bot(btex $\\downarrow$ etex, (0.00cm,0.00cm));')

text.top_right = testa.is(
    function()
        return draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.top_right,
            '$\\nearrow$'))
    end,
    'label.urt(btex $\\nearrow$ etex, (0.00cm,0.00cm));')

text.top_left = testa.is(
    function()
        return draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.top_left,
            '$\\nwarrow$'))
    end,
    'label.ulft(btex $\\nwarrow$ etex, (0.00cm,0.00cm));')

text.bottom_left = testa.is(
    function()
        return draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.bottom_left,
            '$\\swarrow$'))
    end,
    'label.llft(btex $\\swarrow$ etex, (0.00cm,0.00cm));')

text.bottom_right = testa.is(
    function()
        return draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.bottom_right,
            '$\\searrow$'))
    end,
    'label.lrt(btex $\\searrow$ etex, (0.00cm,0.00cm));')

text.invisible = testa.is(
    function()
        return draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.center,
            '$\\ast$',
            {pen_color=luamp.colors.invisible}))
    end,
    '')

text.withcolor = testa.is(
    function()
        return draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.center,
            '$\\ast$',
            {pen_color=luamp.colors.red}))
    end,
    'label(btex $\\ast$ etex, (0.00cm,0.00cm)) withcolor (1.00,0.00,0.00);')

local line = {}

line.horizontal_draw = testa.is(
    function()
        return draw(luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 0)))
    end,
    'draw (0.00cm,0.00cm)--(1.00cm,0.00cm);')

line.horizontal_center = testa.is(
    function()
        local s = luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 0))
        return tostring(s:center())
    end,
    '(0.50cm,0.00cm)')

local function show_list(list)
    local res = stream.from_list(list)
        :map(tostring)
        :collect()
    return table.concat(res, ', ')
end

line.horizontal_vertices = testa.is(
    function()
        local s = luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 0))
        return show_list(s:vertices())
    end,
    '(0.00cm,0.00cm), (1.00cm,0.00cm)')

line.slope_center = testa.is(
    function()
        local s = luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 1))
        return tostring(s:center())
    end,
    '(0.50cm,0.50cm)')

line.dashed_line = testa.is(
    function()
        return draw(luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 0),
            {line_style=luamp.line_styles.dashed}))
    end,
    'draw (0.00cm,0.00cm)--(1.00cm,0.00cm) dashed evenly;')

line.dotted_line = testa.is(
    function()
        return draw(luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 0),
            {line_style=luamp.line_styles.dotted}))
    end,
    'draw (0.00cm,0.00cm)--(1.00cm,0.00cm) dashed withdots;')

line.horizontal_from_circle = testa.is(
    function()
        local s = luamp.line(
            luamp.circle(luamp.point(0, 0), 1),
            luamp.point(2, 0))
        return show_list(s:vertices())
    end,
    '(1.00cm,0.00cm), (2.00cm,0.00cm)')

line.vertical_from_circle = testa.is(
    function()
        local s = luamp.line(
            luamp.circle(luamp.point(0, 0), 1),
            luamp.point(0, 2))
        return show_list(s:vertices())
    end,
    '(0.00cm,1.00cm), (0.00cm,2.00cm)')

line.slope_from_circle = testa.is(
    function()
        local s = luamp.line(
            luamp.circle(luamp.point(0, 0), 5),
            luamp.point(6, 8))
        return show_list(s:vertices())
    end,
    '(3.00cm,4.00cm), (6.00cm,8.00cm)')

line.horizontal_to_circle = testa.is(
    function()
        local s = luamp.line(
            luamp.point(2, 0),
            luamp.circle(luamp.point(0, 0), 1))
        return show_list(s:vertices())
    end,
    '(2.00cm,0.00cm), (1.00cm,0.00cm)')

line.vertical_to_circle = testa.is(
    function()
        local s = luamp.line(
            luamp.point(0, 2),
            luamp.circle(luamp.point(0, 0), 1))
        return show_list(s:vertices())
    end,
    '(0.00cm,2.00cm), (0.00cm,1.00cm)')

line.slope_to_circle = testa.is(
    function()
        local s = luamp.line(
            luamp.point(6, 8),
            luamp.circle(luamp.point(0, 0), 5))
        return show_list(s:vertices())
    end,
    '(6.00cm,8.00cm), (3.00cm,4.00cm)')

line.from_rectangle_right = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(2, 0))
        return tostring(l.m_from)
    end,
    '(1.00cm,0.00cm)')

line.from_rectangle_bottom = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(0, -2))
        return tostring(l.m_from)
    end,
    '(0.00cm,-1.00cm)')

line.from_rectangle_left = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(-2, 0))
        return tostring(l.m_from)
    end,
    '(-1.00cm,0.00cm)')

line.from_rectangle_top = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(0, 2))
        return tostring(l.m_from)
    end,
    '(0.00cm,1.00cm)')

line.from_rectangle_top_right = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(2, 2))
        return tostring(l.m_from)
    end,
    '(1.00cm,1.00cm)')

line.from_rectangle_bottom_right = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(2, -2))
        return tostring(l.m_from)
    end,
    '(1.00cm,-1.00cm)')

line.from_rectangle_bottom_left = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(-2, -2))
        return tostring(l.m_from)
    end,
    '(-1.00cm,-1.00cm)')

line.from_rectangle_top_left = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(-2, 2))
        return tostring(l.m_from)
    end,
    '(-1.00cm,1.00cm)')

line.invisible = testa.is(
    function()
        return draw(luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 0),
            {pen_color=luamp.colors.invisible}))
    end,
    '')

line.withcolor = testa.is(
    function()
        return draw(luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 0),
            {pen_color=luamp.colors.red}))
    end,
    'draw (0.00cm,0.00cm)--(1.00cm,0.00cm) withcolor (1.00,0.00,0.00);')

local arrow = {}

arrow.arrow = testa.is(
    function()
        return draw(luamp.arrow(
            luamp.point(0, 0), luamp.point(1, 0)))
    end,
    'drawarrow (0.00cm,0.00cm)--(1.00cm,0.00cm);')

arrow.dblarrow = testa.is(
    function()
        return draw(luamp.dblarrow(
            luamp.point(0, 0), luamp.point(1, 0)))
    end,
    'drawdblarrow (0.00cm,0.00cm)--(1.00cm,0.00cm);')

local rectangle = {}

rectangle.center = testa.is(
    function()
        local s = luamp.rectangle(
            luamp.point(1, 2),
            4, 8)
        return tostring(s:center())
    end,
    '(1.00cm,2.00cm)')

rectangle.width = testa.is(
    function()
        local s = luamp.rectangle(
            luamp.point(1, 2),
            4, 8)
        return s:width()
    end,
    4)

rectangle.height = testa.is(
    function()
        local s = luamp.rectangle(
            luamp.point(1, 2),
            4, 8)
        return s:height()
    end,
    8)

rectangle.vertices = testa.is(
    function()
        local s = luamp.rectangle(
            luamp.point(1, 2),
            4, 8)
        return show_list(s:vertices())
    end,
    '(-1.00cm,6.00cm), (3.00cm,6.00cm), (3.00cm,-2.00cm), (-1.00cm,-2.00cm)')

rectangle.draw = testa.is(
    function()
        return draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8))
    end,
    'draw (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle;')

rectangle.dashed = testa.is(
    function()
        return draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8,
            {line_style=luamp.line_styles.dashed}))
    end,
    'draw (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle dashed evenly;')

rectangle.dotted = testa.is(
    function()
        return draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8,
            {line_style=luamp.line_styles.dotted}))
    end,
    'draw (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle dashed withdots;')

rectangle.pen_color = testa.is(
    function()
        return draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8,
	    {pen_color=luamp.colors.red}))
    end,
    'draw (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle withcolor (1.00,0.00,0.00);')

rectangle.brush_color = testa.is(
    function()
        return draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8,
	    {pen_color=luamp.colors.invisible,
	     brush_color=luamp.colors.green}))
    end,
    'fill (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle withcolor (0.00,1.00,0.00);')

rectangle.pen_and_brush = testa.is(
    function()
        return draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8,
	    {pen_color=luamp.colors.red,
	     brush_color=luamp.colors.green}))
    end,
    [[fill (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle withcolor (0.00,1.00,0.00);
draw (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle withcolor (1.00,0.00,0.00);]])

rectangle.invisible = testa.is(
    function()
        return draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8,
            {pen_color=luamp.colors.invisible}))
    end,
    '')

rectangle.withcolor = testa.is(
    function()
        return draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8,
            {pen_color=luamp.colors.red}))
    end,
    'draw (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle withcolor (1.00,0.00,0.00);')

local bullet = {}

bullet.draw = testa.is(
    function()
	    return draw(luamp.bullet(luamp.point(1, 2)))
    end,
    'fill fullcircle scaled 0.10cm shifted (1.00cm,2.00cm);')

bullet.arrow = testa.is(
    function()
        local bullet = luamp.bullet(luamp.point(0, 0))
        return draw(luamp.arrow(luamp.point(1, 0), bullet))
    end,
    'drawarrow (1.00cm,0.00cm)--(0.06cm,0.00cm);')

local triangle = {}

triangle.draw = testa.is(
    function()
        return draw(luamp.triangle(luamp.point(1, 1), 2, 3))
    end,
    'draw (0.00cm,0.00cm)--(1.00cm,3.00cm)--(2.00cm,0.00cm)--cycle;')

triangle.center = testa.is(
    function()
        local s = luamp.triangle(luamp.point(1, 1), 2, 3)
        return s:center()
    end,
    luamp.point(1, 1))

triangle.arrows = testa.is(
    function()
        local shape = luamp.triangle(luamp.point(1, 1), 2, 3)
        local pts = {
            luamp.point(2, 1),
            luamp.point(0, 1),
            luamp.point(1, -1)}
        local pts = stream.from_list(pts)
            :map(function(x)
                return tostring(shape:_intersect_line(x))
            end)
            :collect()
        return table.concat(pts, '\n')
    end,
    [[(1.67cm,1.00cm)
(0.33cm,1.00cm)
(1.00cm,0.00cm)]])

local matrix = {}

matrix.x1_1 = testa.is(
    function()
        local shapes = luamp.layouts.matrix(
            luamp.point(0, 0), 1, 1,
            {{function(p) return luamp.circle(p, 1) end}})
        local shapes = stream.from_list(shapes)
            :map(stream.from_list)
            :flatten()
            :map(draw)
            :collect()
        return table.concat(shapes, '\n')
    end,
    'draw fullcircle scaled 2.00cm shifted (0.00cm,0.00cm);')

matrix.x2_3 = testa.is(
    function()
        local shapes = luamp.layouts.matrix(
            luamp.point(0, 0), 1, 2,
            {{function(p) return luamp.circle(p, 0.1) end,
              function(p) return luamp.circle(p, 0.2) end,
              function(p) return luamp.circle(p, 0.3) end},
             {function(p) return luamp.circle(p, 0.4) end,
              function(p) return luamp.circle(p, 0.5) end,
              function(p) return luamp.circle(p, 0.6) end}})
        local shapes = stream.from_list(shapes)
            :map(stream.from_list)
            :flatten()
            :map(draw)
            :collect()
        return table.concat(shapes, '\n')
    end,
    [[draw fullcircle scaled 0.20cm shifted (-2.00cm,0.50cm);
draw fullcircle scaled 0.40cm shifted (0.00cm,0.50cm);
draw fullcircle scaled 0.60cm shifted (2.00cm,0.50cm);
draw fullcircle scaled 0.80cm shifted (-2.00cm,-0.50cm);
draw fullcircle scaled 1.00cm shifted (0.00cm,-0.50cm);
draw fullcircle scaled 1.20cm shifted (2.00cm,-0.50cm);]])

matrix.x2_3_holes = testa.is(
    function()
        local shapes = luamp.layouts.matrix(
            luamp.point(0, 0), 1, 2,
            {{function(p) return luamp.circle(p, 0.1) end,
              false,
              function(p) return luamp.circle(p, 0.3) end},
             {false,
              function(p) return luamp.circle(p, 0.5) end,
              false}})
        local shapes = stream.from_list(shapes)
            :map(stream.from_list)
            :flatten()
            :map(draw)
            :filter(function(x)
                return string.len(x) > 0
            end)
            :collect()
        return table.concat(shapes, '\n')
    end,
    [[draw fullcircle scaled 0.20cm shifted (-2.00cm,0.50cm);
draw fullcircle scaled 0.60cm shifted (2.00cm,0.50cm);
draw fullcircle scaled 1.00cm shifted (0.00cm,-0.50cm);]])

local tree = {}

local function _traverse(t)
    assert(#t > 0)
    coroutine.yield(t[1])
    for i = 2, #t do
        _traverse(t[i])
    end
end

local function traverse_tree(t)
    local res = {
        _stream = function()
            _traverse(t)
        end
    }
    return setmetatable(res, stream.Stream)
end

local function draw_tree(t)
    local xs = traverse_tree(t)
        :map(draw)
        :filter(function(x)
            return string.len(x) > 0
        end)
        :collect()
    return table.concat(xs, '\n')
end

tree.first = testa.is(
    function()
        local t = luamp.layouts.tree(
            luamp.point(0, 0), 2, 2,
            {luamp.bullet,
             {luamp.bullet}})
        return draw_tree(t)
    end,
    [[fill fullcircle scaled 0.10cm shifted (0.00cm,1.00cm);
fill fullcircle scaled 0.10cm shifted (0.00cm,-1.00cm);]])

tree.second = testa.is(
    function()
        local t = luamp.layouts.tree(
            luamp.point(0, 0), 2, 2,
            {luamp.bullet,
             {luamp.bullet},
             {luamp.bullet}})
        return draw_tree(t)
     end,
    [[fill fullcircle scaled 0.10cm shifted (0.00cm,1.00cm);
fill fullcircle scaled 0.10cm shifted (-1.00cm,-1.00cm);
fill fullcircle scaled 0.10cm shifted (1.00cm,-1.00cm);]])

tree.third = testa.is(
    function()
        local t = luamp.layouts.tree(
            luamp.point(0, 0), 2, 2,
            {luamp.bullet,
             {luamp.bullet},
             {luamp.bullet,
              {luamp.bullet},
              {luamp.bullet}},
             {luamp.bullet}})
        return draw_tree(t)
    end,
    [[fill fullcircle scaled 0.10cm shifted (0.00cm,2.00cm);
fill fullcircle scaled 0.10cm shifted (-2.00cm,0.00cm);
fill fullcircle scaled 0.10cm shifted (0.00cm,0.00cm);
fill fullcircle scaled 0.10cm shifted (-1.00cm,-2.00cm);
fill fullcircle scaled 0.10cm shifted (1.00cm,-2.00cm);
fill fullcircle scaled 0.10cm shifted (2.00cm,0.00cm);]])

tree.fourth = testa.is(
    function()
        local t = luamp.layouts.tree(
            luamp.point(0, 0), 2, 2,
            {luamp.bullet,
             {luamp.bullet,
              {luamp.bullet},
              {luamp.bullet},
              {luamp.bullet}},
             {luamp.bullet},
             {luamp.bullet,
              {luamp.bullet},
              {luamp.bullet},
              {luamp.bullet}}})
        return draw_tree(t)
    end,
    [[fill fullcircle scaled 0.10cm shifted (0.00cm,2.00cm);
fill fullcircle scaled 0.10cm shifted (-3.00cm,0.00cm);
fill fullcircle scaled 0.10cm shifted (-5.00cm,-2.00cm);
fill fullcircle scaled 0.10cm shifted (-3.00cm,-2.00cm);
fill fullcircle scaled 0.10cm shifted (-1.00cm,-2.00cm);
fill fullcircle scaled 0.10cm shifted (0.00cm,0.00cm);
fill fullcircle scaled 0.10cm shifted (3.00cm,0.00cm);
fill fullcircle scaled 0.10cm shifted (1.00cm,-2.00cm);
fill fullcircle scaled 0.10cm shifted (3.00cm,-2.00cm);
fill fullcircle scaled 0.10cm shifted (5.00cm,-2.00cm);]])

tree.fifth = testa.is(
    function()
        local t = luamp.layouts.tree(
            luamp.point(0, 0), 2, 2,
            {luamp.bullet,
             {luamp.bullet},
             {luamp.bullet,
              {luamp.bullet},
              {luamp.bullet},
              {luamp.bullet},
              {luamp.bullet}}})
        return draw_tree(t)
    end,
    [[fill fullcircle scaled 0.10cm shifted (-1.50cm,2.00cm);
fill fullcircle scaled 0.10cm shifted (-3.00cm,0.00cm);
fill fullcircle scaled 0.10cm shifted (0.00cm,0.00cm);
fill fullcircle scaled 0.10cm shifted (-3.00cm,-2.00cm);
fill fullcircle scaled 0.10cm shifted (-1.00cm,-2.00cm);
fill fullcircle scaled 0.10cm shifted (1.00cm,-2.00cm);
fill fullcircle scaled 0.10cm shifted (3.00cm,-2.00cm);]])

tree.sixth = testa.is(
    function()
        local t = luamp.layouts.tree(
            luamp.point(0, 0), 2, 2,
            {luamp.bullet,
                {luamp.bullet},
                {luamp.bullet,
                    {luamp.bullet}}})
        return draw_tree(t)
    end,
    [[fill fullcircle scaled 0.10cm shifted (0.00cm,2.00cm);
fill fullcircle scaled 0.10cm shifted (-1.00cm,0.00cm);
fill fullcircle scaled 0.10cm shifted (1.00cm,0.00cm);
fill fullcircle scaled 0.10cm shifted (1.00cm,-2.00cm);]])

local polygon = {}

polygon.draw = testa.is(
    function()
        local shape = luamp.polygon({luamp.origin, luamp.point(1, 0), luamp.point(0, 1)})
        return draw(shape)
    end,
    'draw (0.00cm,0.00cm)--(1.00cm,0.00cm)--(0.00cm,1.00cm)--cycle;')
polygon.brush = testa.is(
    function()
        local shape = luamp.polygon(
            {luamp.origin, luamp.point(1, 0), luamp.point(0, 1)},
            {pen_color=luamp.colors.invisible, brush_color=luamp.colors.red})
        return draw(shape)
    end,
    'fill (0.00cm,0.00cm)--(1.00cm,0.00cm)--(0.00cm,1.00cm)--cycle withcolor (1.00,0.00,0.00);')
polygon.center = testa.is(
    function()
        local shape = luamp.polygon({
            luamp.point(-1, -1),
            luamp.point(-1, 1),
            luamp.point(1, 1),
            luamp.point(1, -1)})
        return tostring(shape:center())
    end,
    '(0.00cm,0.00cm)')
polygon.arrows = testa.is(
    function()
        local shape = luamp.polygon({
            luamp.origin,
            luamp.point(2, 0),
            luamp.point(1, 3)})
        local pts = {
            luamp.point(2, 1),
            luamp.point(0, 1),
            luamp.point(1, -1)}
        local pts = stream.from_list(pts)
            :map(function(x)
                return tostring(shape:_intersect_line(x))
            end)
            :collect()
        return table.concat(pts, '\n')
    end,
    [[(1.67cm,1.00cm)
(0.33cm,1.00cm)
(1.00cm,0.00cm)]])

testa.main({
    figure = figure,

    -- helpers
    helpers = helpers,

    -- shapes
    circle = circle,
    text = text,
    line = line,
    arrow = arrow,
    rectangle = rectangle,
    bullet = bullet,
    triangle = triangle,
    polygon = polygon,

    -- layouts
    matrix = matrix,
    tree = tree,
})

