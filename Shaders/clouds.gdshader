shader_type spatial;

uniform sampler2D noise;
uniform float scale;
uniform float time_scale;

varying vec3 pos;

void vertex() {
	// Called for every vertex the material is visible on.
	pos = VERTEX;
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALPHA = texture(noise, pos.xz * scale + TIME * time_scale).r;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
