shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float grain_strength; 

float pseudo(vec2 v) {
	v = fract(v / 128.0) * 128.0 + vec2(-64.340622, -72.465622);
	return fract(dot(v.xyx * v.xyy, vec3(20.390625, 60.703125, 2.4281209)));
}

float HashPosition(vec2 position) {
	return pseudo(position * vec2(TIME, TIME + 4.0));
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	float offset = HashPosition(SCREEN_UV);
	color -=  grain_strength * vec3(offset) / 255.0;
	COLOR.rgb = color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
