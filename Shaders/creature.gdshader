shader_type spatial;

uniform vec3 ripple_center = vec3(0.0, 0.0, 0.0);
uniform float ripple_strength = 0.3;
uniform float ripple_frequency = 8.0;
uniform float scale = 1.0;

uniform sampler2D noise_tex;
uniform float time_scale = 1.0;

void vertex() {
	vec3 to_center = VERTEX - ripple_center;
	float dist = length(to_center);

	float vertex_noise = texture(noise_tex, VERTEX.xz).r;
	float local_time = TIME * time_scale * mix(0.5, 2.0, vertex_noise);
	float wave = sin(dist * ripple_frequency - local_time);
	float attenuation = exp(-dist * 0.5);

	VERTEX += NORMAL * wave * ripple_strength * attenuation * scale;
}


void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = COLOR.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
