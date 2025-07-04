shader_type spatial;

uniform vec3 ripple_center = vec3(0.0, 0.0, 0.0);
uniform float ripple_strength = 0.3;
uniform float ripple_frequency = 8.0;
uniform float threshold = 1.0;

uniform sampler2D noise_tex; // provide a noise texture
uniform float time_scale = 1.0;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 to_center = VERTEX - ripple_center;
	float dist = length(to_center);

	// Get a "random" per-vertex factor using a noise texture
	float vertex_noise = texture(noise_tex, VERTEX.xz * 0.2).r; // vary scaling to taste

	// Each vertex gets its own ripple speed based on vertex_noise
	float local_time = TIME * time_scale * mix(0.5, 2.0, vertex_noise); // 0.5–2x speed variation

	// Compute ripple wave
	float wave = sin(dist * ripple_frequency - local_time);

	// Optional fade
	float attenuation = exp(-dist * 0.5);

	// Displace along normal
	VERTEX += NORMAL * wave * ripple_strength * attenuation;
}


void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = COLOR.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
