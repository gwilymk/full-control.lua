# Full control.lua

This is a reimagining of the [full control](http://fullcontrolgcode.com/) project.
It aims to give you full access to all the capabilities of your 3d printer.

You can write a simple lua script (see the examples) to directly control your 3d printer to make exactly the moves you want.

Be careful, as this gives full control over your 3d printer, it is very possible to produce gcode that can break it in some way.
Always check the preview in some gcode previewer before sending this to your printer. You have been warned.

# Examples

Note that this is designed to work with lua 5.1 or luajit (recommended). 
Run the example with `luajit full-control.lua examples/box.lua > box.gcode`.
You can then execute the gcode directly on your 3d printer.

Simple square vase

```lua
extrusion_width(0.4)
extrusion_height(0.3)

go {
    final = {100, 100, 0.3}
}

for i = 1, 20 do
    line { relative = { 20, 0, 0 } }
    line { relative = { 0, 20, 0 } }
    line { relative = { -20, 0, 0 } }
    line { relative = { 0, -20, 0 } }
    line { relative = { 0, 0, 0.3 } }
end
```

See the examples directory for more

# Limitations

I wrote this in 1 evening, so please be aware that this:

1. Only works on a Prusa MK3S (you'll have to change the start and end gcode for other printers)
2. Might cause your printer to explode
3. Only supports simple lines
4. Has no tests
5. Has no documentation
6. Will probably crash

# Licence

Code for full control is under MPL-2.0, contents of the examples directory in the public domain
