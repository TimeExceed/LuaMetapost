local testa = require 'testa'
local luamp = require 'luamp'
local table = require 'table'

local testFigure = {}

testFigure.empty = testa.is(
    function ()
        return luamp.figure()
    end,
    [[beginfig(0);
endfig;
end]])

testFigure.circle = testa.is(
    function()
        return luamp.figure(luamp.circle(luamp.point(0,0), 1))
    end,
    [[beginfig(0);
draw fullcircle scaled 2.00cm shifted (0.00cm,0.00cm);
endfig;
end]])


local testCircle = {}

testCircle.draw = testa.is(
    function()
        return luamp.draw(luamp.circle(luamp.point(0, 0), 1))
    end,
    'draw fullcircle scaled 2.00cm shifted (0.00cm,0.00cm);')

testCircle.pen_color = testa.is(
    function()
        return luamp.draw(
	    luamp.circle(
		luamp.point(0, 0), 1,
		{pen_color=luamp.colors.red}))
    end,
    'draw fullcircle scaled 2.00cm shifted (0.00cm,0.00cm) withcolor (1.00,0.00,0.00);')

testCircle.brush_color = testa.is(
    function()
        return luamp.draw(
	    luamp.circle(
		luamp.point(0, 0), 1,
		{pen_color=luamp.colors.invisible,
		 brush_color=luamp.colors.red}))
    end,
    'fill fullcircle scaled 2.00cm shifted (0.00cm,0.00cm) withcolor (1.00,0.00,0.00);')

testCircle.pen_and_brush = testa.is(
    function()
        return luamp.draw(
	    luamp.circle(
		luamp.point(0, 0), 1,
		{pen_color=luamp.colors.red,
		 brush_color=luamp.colors.green}))
    end,
    [[fill fullcircle scaled 2.00cm shifted (0.00cm,0.00cm) withcolor (0.00,1.00,0.00);
draw fullcircle scaled 2.00cm shifted (0.00cm,0.00cm) withcolor (1.00,0.00,0.00);]])

testCircle.invisible = testa.is(
    function()
        return luamp.draw(
	    luamp.circle(
		luamp.point(0, 0), 1,
		{pen_color=luamp.colors.invisible}))
    end,
    nil)

local testText = {}

testText.center = testa.is(
    function()
        return luamp.draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.center,
            '$\\ast$'))
    end,
    'label(btex $\\ast$ etex, (0.00cm,0.00cm));')

testText.left = testa.is(
    function()
        return luamp.draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.left,
            '$\\leftarrow$'))
    end,
    'label.lft(btex $\\leftarrow$ etex, (0.00cm,0.00cm));')

testText.right = testa.is(
    function()
        return luamp.draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.right,
            '$\\rightarrow$'))
    end,
    'label.rt(btex $\\rightarrow$ etex, (0.00cm,0.00cm));')

testText.top = testa.is(
    function()
        return luamp.draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.top,
            '$\\uparrow$'))
    end,
    'label.top(btex $\\uparrow$ etex, (0.00cm,0.00cm));')

testText.bottom = testa.is(
    function()
        return luamp.draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.bottom,
            '$\\downarrow$'))
    end,
    'label.bot(btex $\\downarrow$ etex, (0.00cm,0.00cm));')

testText.top_right = testa.is(
    function()
        return luamp.draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.top_right,
            '$\\nearrow$'))
    end,
    'label.urt(btex $\\nearrow$ etex, (0.00cm,0.00cm));')

testText.top_left = testa.is(
    function()
        return luamp.draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.top_left,
            '$\\nwarrow$'))
    end,
    'label.ulft(btex $\\nwarrow$ etex, (0.00cm,0.00cm));')

testText.bottom_left = testa.is(
    function()
        return luamp.draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.bottom_left,
            '$\\swarrow$'))
    end,
    'label.llft(btex $\\swarrow$ etex, (0.00cm,0.00cm));')

testText.bottom_right = testa.is(
    function()
        return luamp.draw(luamp.text(
            luamp.point(0, 0),
            luamp.directions.bottom_right,
            '$\\searrow$'))
    end,
    'label.lrt(btex $\\searrow$ etex, (0.00cm,0.00cm));')

testText.invisible = testa.is(
    function()
        return luamp.draw(
	    luamp.text(
		luamp.point(0, 0),
		luamp.directions.center,
		'$\\ast$',
		{pen_color=luamp.colors.invisible}))
    end,
    nil)

testText.withcolor = testa.is(
    function()
        return luamp.draw(
	    luamp.text(
		luamp.point(0, 0),
		luamp.directions.center,
		'$\\ast$',
		{pen_color=luamp.colors.red}))
    end,
    'label(btex $\\ast$ etex, (0.00cm,0.00cm)) withcolor (1.00,0.00,0.00);')

local testLine = {}

testLine.horizontal_draw = testa.is(
    function()
        return luamp.draw(luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 0)))
    end,
    'draw (0.00cm,0.00cm)--(1.00cm,0.00cm);')

testLine.horizontal_center = testa.is(
    function()
        return tostring(luamp.center(luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 0))))
    end,
    '(Point x=0.50 y=0.00)')

local function showList(list)
    local res = {}
    for i = 1, #list do
        table.insert(res, tostring(list[i]))
    end
    return table.concat(res, ', ')
end

testLine.horizontal_vertices = testa.is(
    function()
        return showList(luamp.vertices(luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 0))))
    end,
    '(Point x=0.00 y=0.00), (Point x=1.00 y=0.00)')

testLine.slope_center = testa.is(
    function()
        return tostring(luamp.center(luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 1))))
    end,
    '(Point x=0.50 y=0.50)')

testLine.dashed_line = testa.is(
    function()
        return luamp.draw(luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 0),
            {line_style=luamp.line_styles.dashed}))
    end,
    'draw (0.00cm,0.00cm)--(1.00cm,0.00cm) dashed evenly;')
    
testLine.dotted_line = testa.is(
    function()
        return luamp.draw(luamp.line(
            luamp.point(0, 0),
            luamp.point(1, 0),
            {line_style=luamp.line_styles.dotted}))
    end,
    'draw (0.00cm,0.00cm)--(1.00cm,0.00cm) dashed withdots;')

testLine.horizontal_from_circle = testa.is(
    function()
        return showList(luamp.vertices(luamp.line(
            luamp.circle(luamp.point(0, 0), 1),
            luamp.point(2, 0))))
    end,
    '(Point x=1.00 y=0.00), (Point x=2.00 y=0.00)')

testLine.vertical_from_circle = testa.is(
    function()
        return showList(luamp.vertices(luamp.line(
            luamp.circle(luamp.point(0, 0), 1),
            luamp.point(0, 2))))
    end,
    '(Point x=0.00 y=1.00), (Point x=0.00 y=2.00)')

testLine.slope_from_circle = testa.is(
    function()
        return showList(luamp.vertices(luamp.line(
            luamp.circle(luamp.point(0, 0), 5),
            luamp.point(6, 8))))
    end,
    '(Point x=3.00 y=4.00), (Point x=6.00 y=8.00)')

testLine.horizontal_to_circle = testa.is(
    function()
        return showList(luamp.vertices(luamp.line(
            luamp.point(2, 0),
            luamp.circle(luamp.point(0, 0), 1))))
    end,
    '(Point x=2.00 y=0.00), (Point x=1.00 y=0.00)')

testLine.vertical_to_circle = testa.is(
    function()
        return showList(luamp.vertices(luamp.line(
            luamp.point(0, 2),
            luamp.circle(luamp.point(0, 0), 1))))
    end,
    '(Point x=0.00 y=2.00), (Point x=0.00 y=1.00)')

testLine.slope_to_circle = testa.is(
    function()
        return showList(luamp.vertices(luamp.line(
            luamp.point(6, 8),
            luamp.circle(luamp.point(0, 0), 5))))
    end,
    '(Point x=6.00 y=8.00), (Point x=3.00 y=4.00)')

testLine.from_rectangle_right = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(2, 0))
        return tostring(l.from)
    end,
    '(Point x=1.00 y=0.00)')

testLine.from_rectangle_bottom = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(0, -2))
        return tostring(l.from)
    end,
    '(Point x=0.00 y=-1.00)')

testLine.from_rectangle_left = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(-2, 0))
        return tostring(l.from)
    end,
    '(Point x=-1.00 y=0.00)')

testLine.from_rectangle_top = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(0, 2))
        return tostring(l.from)
    end,
    '(Point x=0.00 y=1.00)')

testLine.from_rectangle_top_right = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(2, 2))
        return tostring(l.from)
    end,
    '(Point x=1.00 y=1.00)')

testLine.from_rectangle_bottom_right = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(2, -2))
        return tostring(l.from)
    end,
    '(Point x=1.00 y=-1.00)')

testLine.from_rectangle_bottom_left = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(-2, -2))
        return tostring(l.from)
    end,
    '(Point x=-1.00 y=-1.00)')

testLine.from_rectangle_top_left = testa.is(
    function()
        local l = luamp.line(
            luamp.rectangle(luamp.point(0, 0), 2, 2),
            luamp.point(-2, 2))
        return tostring(l.from)
    end,
    '(Point x=-1.00 y=1.00)')

testLine.invisible = testa.is(
    function()
        return luamp.draw(
	    luamp.line(
		luamp.point(0, 0),
		luamp.point(1, 0),
		{pen_color=luamp.colors.invisible}))
    end,
    nil)

testLine.withcolor = testa.is(
    function()
        return luamp.draw(
	    luamp.line(
		luamp.point(0, 0),
		luamp.point(1, 0),
		{pen_color=luamp.colors.red}))
    end,
    'draw (0.00cm,0.00cm)--(1.00cm,0.00cm) withcolor (1.00,0.00,0.00);')

testArrow = {}

testArrow.arrow = testa.is(
    function()
        return luamp.draw(luamp.arrow(
            luamp.point(0, 0), luamp.point(1, 0)))
    end,
    'drawarrow (0.00cm,0.00cm)--(1.00cm,0.00cm);')

testArrow.dblarrow = testa.is(
    function()
        return luamp.draw(luamp.dblarrow(
            luamp.point(0, 0), luamp.point(1, 0)))
    end,
    'drawdblarrow (0.00cm,0.00cm)--(1.00cm,0.00cm);')

testRectangle = {}

testRectangle.center = testa.is(
    function()
        return tostring(luamp.center(luamp.rectangle(
            luamp.point(1, 2),
            4, 8)))
    end,
    '(Point x=1.00 y=2.00)')

testRectangle.length = testa.is(
    function()
        return luamp.length(luamp.rectangle(
            luamp.point(1, 2),
            4, 8))
    end,
    4)

testRectangle.height = testa.is(
    function()
        return luamp.height(luamp.rectangle(
            luamp.point(1, 2),
            4, 8))
    end,
    8)

testRectangle.vertices = testa.is(
    function()
        return showList(luamp.vertices(luamp.rectangle(
            luamp.point(1, 2),
            4, 8)))
    end,
    '(Point x=-1.00 y=6.00), (Point x=3.00 y=6.00), (Point x=3.00 y=-2.00), (Point x=-1.00 y=-2.00)')

testRectangle.draw = testa.is(
    function()
        return luamp.draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8))
    end,
    'draw (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle;')

testRectangle.dashed = testa.is(
    function()
        return luamp.draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8,
            {line_style=luamp.line_styles.dashed}))
    end,
    'draw (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle dashed evenly;')

testRectangle.dotted = testa.is(
    function()
        return luamp.draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8,
            {line_style=luamp.line_styles.dotted}))
    end,
    'draw (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle dashed withdots;')

testRectangle.pen_color = testa.is(
    function()
        return luamp.draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8,
	    {pen_color=luamp.colors.red}))
    end,
    'draw (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle withcolor (1.00,0.00,0.00);')

testRectangle.brush_color = testa.is(
    function()
        return luamp.draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8,
	    {pen_color=luamp.colors.invisible,
	     brush_color=luamp.colors.green}))
    end,
    'fill (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle withcolor (0.00,1.00,0.00);')

testRectangle.pen_and_brush = testa.is(
    function()
        return luamp.draw(luamp.rectangle(
            luamp.point(1, 2),
            4, 8,
	    {pen_color=luamp.colors.red,
	     brush_color=luamp.colors.green}))
    end,
    [[fill (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle withcolor (0.00,1.00,0.00);
draw (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle withcolor (1.00,0.00,0.00);]])

testRectangle.invisible = testa.is(
    function()
        return luamp.draw(
	    luamp.rectangle(
		luamp.point(1, 2),
		4, 8,
		{pen_color=luamp.colors.invisible}))
    end,
    nil)

testRectangle.withcolor = testa.is(
    function()
        return luamp.draw(
	    luamp.rectangle(
		luamp.point(1, 2),
		4, 8,
		{pen_color=luamp.colors.red}))
    end,
    'draw (-1.00cm,6.00cm)--(3.00cm,6.00cm)--(3.00cm,-2.00cm)--(-1.00cm,-2.00cm)--cycle withcolor (1.00,0.00,0.00);')

testBullet = {}

testBullet.draw = testa.is(
    function()
	local bullet = luamp.bullet(luamp.point(0, 0))
	local res = {
	    luamp.draw(bullet),
	    luamp.draw(luamp.arrow(luamp.point(1, 0), bullet)),
	}
	return table.concat(res, '\n')
    end,
    [[fill fullcircle scaled 0.20cm shifted (0.00cm,0.00cm);
drawarrow (1.00cm,0.00cm)--(0.11cm,0.00cm);]])

testLayouts = {}

testLayouts.matrix1_1 = testa.is(
    function()
        return luamp.draw(luamp.layouts.matrix(
            luamp.point(0, 0), 1, 1,
            {{function(p) return luamp.circle(p, 1) end}}))
    end,
    'draw fullcircle scaled 2.00cm shifted (0.00cm,0.00cm);')

testLayouts.matrix2_3 = testa.is(
    function()
        return luamp.draw(luamp.layouts.matrix(
            luamp.point(0, 0), 1, 2,
            {{function(p) return luamp.circle(p, 0.1) end,
              function(p) return luamp.circle(p, 0.2) end,
              function(p) return luamp.circle(p, 0.3) end},
             {function(p) return luamp.circle(p, 0.4) end,
              function(p) return luamp.circle(p, 0.5) end,
              function(p) return luamp.circle(p, 0.6) end}}))
    end,
    [[draw fullcircle scaled 0.20cm shifted (-2.00cm,0.50cm);
draw fullcircle scaled 0.40cm shifted (0.00cm,0.50cm);
draw fullcircle scaled 0.60cm shifted (2.00cm,0.50cm);
draw fullcircle scaled 0.80cm shifted (-2.00cm,-0.50cm);
draw fullcircle scaled 1.00cm shifted (0.00cm,-0.50cm);
draw fullcircle scaled 1.20cm shifted (2.00cm,-0.50cm);]])
 
testLayouts.matrix2_3_holes = testa.is(
    function()
        return luamp.draw(luamp.layouts.matrix(
            luamp.point(0, 0), 1, 2,
            {{function(p) return luamp.circle(p, 0.1) end,
              false,
              function(p) return luamp.circle(p, 0.3) end},
             {false,
              function(p) return luamp.circle(p, 0.5) end,
              false}}))
    end,
    [[draw fullcircle scaled 0.20cm shifted (-2.00cm,0.50cm);
draw fullcircle scaled 0.60cm shifted (2.00cm,0.50cm);
draw fullcircle scaled 1.00cm shifted (0.00cm,-0.50cm);]])

local function circle(c)
    return luamp.circle(c, 0.01)
end

testLayouts.tree1 = testa.is(
    function()
        return luamp.draw(luamp.layouts.tree(
            luamp.point(0, 0), 2, 2,
            {circle,
             {circle}}))
    end,
    [[draw fullcircle scaled 0.02cm shifted (0.00cm,1.00cm);
draw fullcircle scaled 0.02cm shifted (0.00cm,-1.00cm);]])

testLayouts.tree2 = testa.is(
    function()
        return luamp.draw(luamp.layouts.tree(
            luamp.point(0, 0), 2, 2,
            {circle,
             {circle},
             {circle}}))
    end,
    [[draw fullcircle scaled 0.02cm shifted (0.00cm,1.00cm);
draw fullcircle scaled 0.02cm shifted (-1.00cm,-1.00cm);
draw fullcircle scaled 0.02cm shifted (1.00cm,-1.00cm);]])

testLayouts.tree3 = testa.is(
    function()
        return luamp.draw(luamp.layouts.tree(
            luamp.point(0, 0), 2, 2,
            {circle,
             {circle},
             {circle,
              {circle},
              {circle}},
             {circle}}))
    end,
    [[draw fullcircle scaled 0.02cm shifted (0.00cm,2.00cm);
draw fullcircle scaled 0.02cm shifted (-3.00cm,0.00cm);
draw fullcircle scaled 0.02cm shifted (0.00cm,0.00cm);
draw fullcircle scaled 0.02cm shifted (-1.00cm,-2.00cm);
draw fullcircle scaled 0.02cm shifted (1.00cm,-2.00cm);
draw fullcircle scaled 0.02cm shifted (3.00cm,0.00cm);]])

testLayouts.tree4 = testa.is(
    function()
        return luamp.draw(luamp.layouts.tree(
            luamp.point(0, 0), 2, 2,
            {circle,
             {circle,
              {circle},
              {circle},
              {circle}},
             {circle},
             {circle,
              {circle},
              {circle},
              {circle}}}))
    end,
    [[draw fullcircle scaled 0.02cm shifted (0.00cm,2.00cm);
draw fullcircle scaled 0.02cm shifted (-4.00cm,0.00cm);
draw fullcircle scaled 0.02cm shifted (-6.00cm,-2.00cm);
draw fullcircle scaled 0.02cm shifted (-4.00cm,-2.00cm);
draw fullcircle scaled 0.02cm shifted (-2.00cm,-2.00cm);
draw fullcircle scaled 0.02cm shifted (0.00cm,0.00cm);
draw fullcircle scaled 0.02cm shifted (4.00cm,0.00cm);
draw fullcircle scaled 0.02cm shifted (2.00cm,-2.00cm);
draw fullcircle scaled 0.02cm shifted (4.00cm,-2.00cm);
draw fullcircle scaled 0.02cm shifted (6.00cm,-2.00cm);]])

testLayouts.tree5 = testa.is(
    function()
        return luamp.draw(luamp.layouts.tree(
            luamp.point(0, 0), 2, 2,
            {circle,
             {circle},
             {circle,
              {circle},
              {circle},
              {circle},
              {circle}}}))
    end,
    [[draw fullcircle scaled 0.02cm shifted (-1.50cm,2.00cm);
draw fullcircle scaled 0.02cm shifted (-4.00cm,0.00cm);
draw fullcircle scaled 0.02cm shifted (1.00cm,0.00cm);
draw fullcircle scaled 0.02cm shifted (-2.00cm,-2.00cm);
draw fullcircle scaled 0.02cm shifted (0.00cm,-2.00cm);
draw fullcircle scaled 0.02cm shifted (2.00cm,-2.00cm);
draw fullcircle scaled 0.02cm shifted (4.00cm,-2.00cm);]])

testa.main({
    figure = testFigure,

    circle = testCircle,
    text = testText,
    line = testLine,
    arrow = testArrow,
    rectangle = testRectangle,
    bullet = testBullet,

    layouts = testLayouts,
})

