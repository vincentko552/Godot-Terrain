shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float grain_strength = 1.0;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float film_grain(vec2 uv, float time_offset) {
    vec2 grain_uv = uv * vec2(640.0, 360.0);
    grain_uv += vec2(time_offset);
    return hash(grain_uv);
}

void fragment() {
    vec3 color = texture(screen_texture, SCREEN_UV).rgb;

    float t = TIME * 0.5;
    float grain = film_grain(SCREEN_UV, t) - 0.5;

    color += vec3(grain) * (grain_strength / 255.0);

    COLOR.rgb = color;
}
