shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform bool use_banding;
uniform bool use_dithering;
uniform mat4 dither_matrix;
uniform int banding_steps;

void fragment() {
    vec3 color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
		
	if (use_dithering) {
        vec2 screen_pos = SCREEN_UV * (1.0 / SCREEN_PIXEL_SIZE);
        ivec2 pos = ivec2(mod(floor(screen_pos), 4.0));
        float dither = dither_matrix[pos.y][pos.x] / 17.0;
        color += dither * (1.0 / float(banding_steps));
    }
	
	if (use_banding)
    	color = floor(color * 255.0 / 8.0) * (8.0 / 255.0);

    COLOR.rgb = color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
