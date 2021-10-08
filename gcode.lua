local GCode = {}

function GCode.new(default_config)
    local config_object = {}
    for k, v in pairs(default_config) do
        config_object[k] = v
    end

    return {
        current_snippets = {},
        config = config_object,

        current_pos = {0, 0, 0},
    }
end

local function replace_with_config(snippet, config)
    local replaced = string.gsub(snippet, "%[([%w_]+)%]", function (match) return config[match] end)
    return replaced
end

function GCode:print()
    for _, snippet in ipairs(self.current_snippets) do
        print(replace_with_config(snippet, self.config))
    end
end

function GCode:append(code)
    self.current_snippets[#self.current_snippets + 1] = code
end

function GCode:get_pos()
    return self.current_pos
end

function GCode:set_pos(new_pos)
    self.current_pos = new_pos
end

function GCode:set_config_option(option, value)
    self.config[option] = value
end

function GCode:get_config_option(option)
    return self.config[option]
end

local GCode_mt = {__index = GCode}
return function (default_config)
    return setmetatable(GCode.new(default_config), GCode_mt)
end