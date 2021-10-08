local GCode = require('gcode')

local default_config = {
    first_layer_temperature = 215,
    first_layer_bed_temperature = 60,

    travel_speed = 180 * 60,
    extrude_speed = 35 * 60,

    filament_diameter = 1.75,

    max_print_height = 205,
}

local preamble = [[
G90 ; use absolute coordinates
M83 ; extruder relative mode
M104 S[first_layer_temperature] ; set extruder temp
M140 S[first_layer_bed_temperature] ; set bed temp
M190 S[first_layer_bed_temperature] ; wait for bed temp
M109 S[first_layer_temperature] ; wait for extruder temp
G28 W ; home all without mesh bed level
G80 ; mesh bed leveling
G1 Y-3.0 F1000.0 ; go outside print area
G92 E0.0
G1 X60.0 E9.0 F1000.0 ; intro line
G1 X100.0 E12.5 F1000.0 ; intro line
G92 E0.0
M221 S100

M204 S800 ; set the acceleration (TODO: make this configurable)
]]

local function generate_ending(gcode)
    local basic = [[

G4 ; wait
M221 S100 ; reset flow
M900 K0 ; reset LA
M907 E538 ; reset extruder motor current
M104 S0 ; turn off temperature
M140 S0 ; turn off heatbed
M107 ; turn off fan
G1 Z%g ; Move print head up
G1 X0 Y200 F3000 ; home X axis
M84 ; disable motors
]]

    local finishing_pos = gcode:get_pos()
    local final_z = math.min(finishing_pos[3] + 30, default_config.max_print_height)

    gcode:append(string.format(basic, final_z))
end

local function calculate_extrusion(length, width, height)
    local cross_section = width * height
    local volume = length * cross_section -- estimate, hopefully good enough

    -- TODO: Allow customisable filament diameter
    local filament_cross_section = default_config.filament_diameter * default_config.filament_diameter * math.pi / 4

    local length_needed_for_volume = volume / filament_cross_section
    return length_needed_for_volume
end

local function add_coords(a, b)
    return {
        a[1] + b[1],
        a[2] + b[2],
        a[3] + b[3],
    }
end

local function sub_coords(a, b)
    return {
        a[1] - b[1],
        a[2] - b[2],
        a[3] - b[3],
    }
end

local function eq_coords(a, b)
    return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

local function cartesian_distance(start_pos, final_pos)
    local diff = sub_coords(start_pos, final_pos)
    
    return math.sqrt(diff[1] * diff[1] + diff[2] * diff[2] + diff[3] * diff[3])
end

local function get_extrusion(config, gcode, length)
    if config.travel then
        return 0, true
    end

    local width = config.width or gcode:get_config_option('extrusion_width') or error("must set width property")
    local height = config.height or gcode:get_config_option('extrusion_height') or error("must set height property")

    return calculate_extrusion(length, width, height), false
end

local function get_env_with_gcode(gcode)
    return {
        first_layer_bed_temperature = function (temp)
            gcode:set_config_option('first_layer_bed_temperature', temp)
        end,

        first_layer_temperature = function (temp)
            gcode:set_config_option('first_layer_temperature', temp)
        end,

        extrusion_width = function (width)
            gcode:set_config_option('extrusion_width', width)
        end,

        extrusion_height = function (height)
            gcode:set_config_option('extrusion_height', height)
        end,

        -- gcode commands
        line = function (config)
            local start_pos = config.start
            
            if start_pos == nil then
                start_pos = gcode:get_pos()
            end

            local final_pos = config.final
            
            if final_pos == nil then
                local relative = config.relative or error("need to define one of final or relative")

                final_pos = add_coords(start_pos, relative)
            end

            local distance = cartesian_distance(start_pos, final_pos)

            local extrusion, travel = get_extrusion(config, gcode, distance)

            local current_pos = gcode:get_pos()
            
            local travel_speed = gcode:get_config_option('travel_speed')
            local extrude_speed = gcode:get_config_option('extrude_speed')

            local speed = travel and travel_speed or extrude_speed

            if not eq_coords(current_pos, start_pos) then
                -- move to the new start position
                gcode:append(
                    string.format("G1 X%g Y%g Z%g E0 F%g", start_pos[1], start_pos[2], start_pos[3], travel_speed)
                )
            end

            gcode:append(
                string.format("G1 X%g Y%g Z%g E%g F%g", final_pos[1], final_pos[2], final_pos[3], extrusion, speed)
            )
            gcode:set_pos(final_pos)
        end,

        go = function (config)
            local target = config.final
            if target == nil then
                local relative = config.relative or error("need to define one of final or relative")
                target = add_coords(gcode:get_pos(), relative)
            end

            local travel_speed = gcode:get_config_option('travel_speed')

            gcode:append(
                string.format("G1 X%g Y%g Z%g E0 F%g", target[1], target[2], target[3], travel_speed)
            )
            gcode:set_pos(target)
        end,
    }
end

local function main(args)
    local script = args[1]
    local script_fn, err = loadfile(script)

    if script_fn == nil then
        print(err)
        return 1
    end

    local function run_with_env(env, fn)
        setfenv(fn, env)
        fn()
    end

    local gcode = GCode(default_config)

    gcode:append(preamble)

    local env = get_env_with_gcode(gcode)
    run_with_env(env, script_fn)

    generate_ending(gcode)

    gcode:print()
end

return main(arg)