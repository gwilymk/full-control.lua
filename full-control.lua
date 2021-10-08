local GCode = require('gcode')

local default_config = {
    first_layer_temperature = 215,
    first_layer_bed_temperature = 60,
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
]]

local function get_env_with_gcode(gcode)
    return {
        first_layer_bed_temperature = function (temp)
            gcode:set_config_option('first_layer_bed_temperature', temp)
        end,

        first_layer_temperature = function (temp)
            gcode:set_config_option('first_layer_temperature', temp)
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

    gcode:print()
end

return main(arg)