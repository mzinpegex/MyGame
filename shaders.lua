local shaders = {}

shaders.whiteout = love.graphics.newShader[[
    extern number intensity;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        pixel.r += intensity;
        pixel.g += intensity;
        pixel.b += intensity;
        return pixel * color;
    }
]]

shaders.light = love.graphics.newShader[[
    extern vec2 center;
    extern number radius;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        float dist = length(screen_coords - center);

        float strength = clamp(1.0 - (dist / radius), 0.0, 1.0);
        float ambient = 0.25; // Minimum brightness outside the light radius
        float light = ambient + strength;
        
        pixel.rgb *= light;
        return pixel * color;
    }
]]

return shaders