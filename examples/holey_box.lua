-- WARNING: This doesn't work as expected. Ends up making a pile of spaghetti but the
-- preview looks cool

extrusion_width(0.4)
extrusion_height(0.3)

go { final = { 50, 50, 0.3 } }

local BOX_SIDE = 50
local Z_HOP = 3

line { relative = {  BOX_SIDE, 0, 0 } }
line { relative = { 0,  BOX_SIDE, 0 } }
line { relative = { -BOX_SIDE, 0, 0 } }
line { relative = { 0, -BOX_SIDE, 0 } }

local function bouncy_line(x_distance, y_distance, is_even_layer)
    local steps = math.ceil(math.sqrt(x_distance * x_distance + y_distance * y_distance) / Z_HOP / 2)
    local hops = steps

    if is_even_layer then
        hops = steps - 1
        go {
            relative = { x_distance / steps / 2, y_distance / steps / 2, 0 }
        }
    end

    for i = 1, hops do
        line {
            relative = {
                x_distance / steps / 2,
                y_distance / steps / 2,
                Z_HOP
            },
            speed = 5 * 60,
        }

        line {
            relative = {
                x_distance / steps / 2,
                y_distance / steps / 2,
                -Z_HOP
            },
            speed = 5 * 60
        }
    end

    if is_even_layer then
        go {
            relative = { x_distance / steps / 2, y_distance / steps / 2, 0 }
        }
    end
end

fan { amount = 255 }

for i = 1, 10 do
    local is_even_layer = i % 2 == 0

    bouncy_line( BOX_SIDE, 0, is_even_layer)
    bouncy_line(0,  BOX_SIDE, is_even_layer)
    bouncy_line(-BOX_SIDE, 0, is_even_layer)
    bouncy_line(0, -BOX_SIDE, is_even_layer)

    go { relative = { 0, 0, Z_HOP / 3 } }
end