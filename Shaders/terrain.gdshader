shader_type spatial;
render_mode cull_disabled;

// -----------------------
// Noise Settings
// -----------------------
uniform float _Seed;
uniform float _GradientRotation;
uniform float _NoiseRotation;
uniform vec3 _Offset;
uniform float _Scale;

// -----------------------
// Octave Settings
// -----------------------
uniform float _Octaves;                     // octave_count
uniform vec2 _AngularVariance;              // angular_variance
uniform float _InitialAmplitude;            // initial_amplitude
uniform float _AmplitudeDecay;              // amplitude_decay
uniform float _Lacunarity;                  // lacunarity
uniform float _FrequencyVarianceLowerBound; // frequency_variance.x
uniform float _FrequencyVarianceUpperBound; // frequency_variance.y

// -----------------------
// Terrain
// -----------------------
uniform float _TerrainHeight;
uniform float _TerrainThreshold;
uniform float _FalloffThreshold;
uniform float _FalloffSpeed;
uniform float _MaxFalloff;

uniform float _DerivativesEpsilon;

// -----------------------
// Material Settings
// -----------------------
uniform vec2 _SlopeRange;                   // slope_threshold
uniform float _SlopeDamping;                // slope_damping
uniform sampler2D ground_texture;
uniform sampler2D rock_texture;

uniform bool debug;

float pseudo(vec2 v) {
	v = fract(v / 128.0) * 128.0 + vec2(-64.340622, -72.465622);
	return fract(dot(v.xyx * v.xyy, vec3(20.390625, 60.703125, 2.4281209)));
}

float HashPosition(vec2 position) {
	return pseudo(position * vec2(_Seed, _Seed + 4.0));
}

vec2 RandVector(float seed) {
	float theta = seed * 360.0 * 2.0 - 360.0;
	theta += _GradientRotation;
	theta *= PI / 180.0;
	return normalize(vec2(cos(theta), sin(theta)));
}

vec2 quinticInterpolation(vec2 t) {
	return t * t * t * (t * (t * vec2(6.0) - vec2(15.0)) + vec2(10.0));
}

vec2 quinticDerivative(vec2 t) {
	return 30.0 * t * t * (t * (t - 2.0) + 1.0);
}

vec3 perlin_noise2D(vec2 position) {
	vec2 latticeMin = floor(position);
	vec2 latticeMax = ceil(position);
	vec2 remainder = fract(position);

	vec2 c00 = latticeMin;
	vec2 c10 = vec2(latticeMax.x, latticeMin.y);
	vec2 c01 = vec2(latticeMin.x, latticeMax.y);
	vec2 c11 = latticeMax;

	vec2 g00 = RandVector(HashPosition(c00));
	vec2 g10 = RandVector(HashPosition(c10));
	vec2 g01 = RandVector(HashPosition(c01));
	vec2 g11 = RandVector(HashPosition(c11));

	vec2 p0 = remainder;
	vec2 p1 = p0 - vec2(1.0);

	vec2 p00 = p0;
	vec2 p10 = vec2(p1.x, p0.y);
	vec2 p01 = vec2(p0.x, p1.y);
	vec2 p11 = p1;

	vec2 u = quinticInterpolation(remainder);
	vec2 du = quinticDerivative(remainder);

	float a = dot(g00, p00);
	float b = dot(g10, p10);
	float c = dot(g01, p01);
	float d = dot(g11, p11);

	float noise = a + u.x * (b - a) + u.y * (c - a) + u.x * u.y * (a - b - c + d);

	vec2 gradient = g00 + u.x * (g10 - g00) + u.y * (g01 - g00) + u.x * u.y * (g00 - g10 - g01 + g11)
		+ du * (u.yx * (a - b - c + d) + vec2(b, c) - a);
		
	return vec3(noise, gradient);
}

vec3 fbm(vec2 position) {
	float lacunarity = _Lacunarity;
	float amplitude = _InitialAmplitude;
	float height = 0.0;
	vec2 grad = vec2(0.0);
	mat2 m = mat2(1.0);

	float angle_variance = mix(_AngularVariance.x, _AngularVariance.y, HashPosition(vec2(_Seed, 827.0)));
	float theta = (_NoiseRotation + angle_variance) * PI / 180.0;
	mat2 m2 = mat2(vec2(cos(theta), -sin(theta)), vec2(sin(theta), cos(theta)));
	mat2 m2i = inverse(m2);

	for (int i = 0; i < int(_Octaves); ++i) {
		vec3 n = perlin_noise2D(position);
		height += amplitude * n.x;
		grad += amplitude * m * n.yz;

		amplitude *= _AmplitudeDecay;

		angle_variance = mix(_AngularVariance.x, _AngularVariance.y, HashPosition(vec2(float(i) * 419.0, _Seed)));
		theta = (_NoiseRotation + angle_variance) * PI / 180.0;
		m2 = mat2(vec2(cos(theta), -sin(theta)), vec2(sin(theta), cos(theta)));
		m2i = inverse(m2);

		float freq_variance = mix(_FrequencyVarianceLowerBound, _FrequencyVarianceUpperBound, HashPosition(vec2(float(i) * 422.0, _Seed)));
		position = (lacunarity + freq_variance) * m2 * position;
		m = (lacunarity + freq_variance) * m2i * m;
	}
	return vec3(height, grad);
}

varying vec3 pos;
varying float before_max_pos;

void vertex() {
	vec3 noise_pos = (VERTEX + vec3(_Offset.x, 0.0, _Offset.z)) / _Scale;
	vec3 n = fbm(noise_pos.xz);
	
	before_max_pos = _TerrainHeight * n.x + _TerrainHeight - _Offset.y + VERTEX.y;
	VERTEX.y = max(_TerrainHeight * n.x + _TerrainHeight - _Offset.y + VERTEX.y, _TerrainThreshold);
	
	float distance_from_center = length(vec2(VERTEX.xz));
	if (distance_from_center > _FalloffThreshold) {
		VERTEX.y -= min(_MaxFalloff, _FalloffSpeed * (distance_from_center - _FalloffThreshold) * (distance_from_center - _FalloffThreshold));
	}
	pos = VERTEX;
}

void fragment() {
	vec3 noise_pos = (pos + vec3(_Offset.x, 0.0, _Offset.z)) / _Scale;
	vec4 ground_color = texture(ground_texture, noise_pos.xz);
	vec4 rock_color = texture(rock_texture, noise_pos.xz);
	vec3 n = _TerrainHeight * fbm(noise_pos.xz);

	vec3 slope_normal = normalize(vec3(-n.y, 1.0, -n.z) * vec3(_SlopeDamping, 1.0, _SlopeDamping));
	float blend_factor = smoothstep(_SlopeRange.x, _SlopeRange.y, 1.0 - slope_normal.y);
	vec4 albedo = mix(ground_color, rock_color, vec4(blend_factor));

	if (debug && before_max_pos <= _TerrainThreshold)
		ALBEDO = vec3(1.0f);
	else ALBEDO = albedo.rgb;
	
}
