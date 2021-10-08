extrusion_width(0.4)
extrusion_height(0.3)

go {
    final = {100, 100, 0.3}
}

for i = 0.3, 5, 0.3 do
    line {
        relative = { 20, 0, 0 },
    }

    line {
        relative = { 0, 20, 0 },
    }

    line {
        relative = { -20, 0, 0 },
    }

    line {
        relative = { 0, -20, 0 },
    }

    line {
        relative = { 0, 0, 0.3 },
    }
end