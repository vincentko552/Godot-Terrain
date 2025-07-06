shader_type spatial;

uniform float speed;
uniform float amplitudes[10];
uniform float wavelengths[10]; // freq: 2 / wavelength, phase: speed * 2 / wavelength

uniform vec3 water_color;
uniform float height_factor;
uniform vec3 height_color;
uniform float stutter_coeff;

varying vec3 position;

vec3 hsv2rgb(vec3 c) {
	float h = c.x;
	float s = c.y;
	float v = c.z;

	vec3 rgb = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return v * mix(vec3(1.0), rgb, s);
}

void vertex() {
	for (int i = 0; i < amplitudes.length(); i++) {
		if (wavelengths[i] == 0.0) continue;

		float freq = 2.0 / wavelengths[i];
		float phase = speed * freq;
		VERTEX.y += amplitudes[i] * sin(freq * dot(VERTEX.xz, VERTEX.xz) + phase * TIME);
		VERTEX.y = round(VERTEX.y * stutter_coeff) / stutter_coeff;
	}
	position = VERTEX;
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = hsv2rgb(water_color) + position.y * height_factor * hsv2rgb(height_color);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
