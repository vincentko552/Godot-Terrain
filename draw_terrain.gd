@tool
class_name DrawTerrainMesh extends CompositorEffect


## Regenerate mesh data and recompile shaders
@export var regenerate : bool = true

@export_group("Mesh Settings")
## Number of vertices in the plane mesh, quad count per row is thus  [code]side_length - 1[/code]
@export_range(2, 1000) var side_length : int = 200

## Distance between vertices
@export_range(0.01, 1.0) var mesh_scale : float = 1.0

## Render mesh wireframe
@export var wireframe : bool = false

@export_group("Noise Settings")

## Seed for the noise, change for instant gratification
@export var noise_seed : int = 0

## Horizontal scale of the noise
@export_range(0, 400) var zoom : float = 100.0

## Horizontal scroll through the noise,  [code]y[/code] component adjusts height of plane
@export var offset : Vector3 = Vector3.ZERO

## Rotates the gradient vectors used to calculate perlin noise
@export_range(-180.0, 180.0) var gradient_rotation : float = 0.0

## How many layers of noise to sum. More octaves give more detail.
@export_range(1, 32) var octave_count : int = 10

@export_subgroup("Octave Settings")
## Amount of rotation (in degrees) to apply each octave iteration
@export_range(-180.0, 180.0) var rotation : float = 30.0

## Random adjustment to rotation per octave, adjustment is generated between this range
@export var angular_variance : Vector2 = Vector2.ZERO

## Amplitude of the first noise octave
@export_range(0.01, 2.0) var initial_amplitude : float = 0.5

## Value to multiply with amplitude each octave iteration, lower values will reduce the impact of each subsequent octave.
@export_range(0.01, 1.0) var amplitude_decay : float = 0.45

## Self similarity of each octave
@export_range(0.01, 3.0) var initial_frequency : float = 2.0

## Random adjustment to frequency per octave, adjustment is generated between this range
@export var frequency_variance : Vector2 = Vector2.ZERO

## Multiplies with final noise result to adjust terrain height
@export_range(0.0, 300.0) var height_scale : float = 50.0

@export_group("Material Settings")

## Scales the slope to make slope blending easier
@export var slope_damping : float = 0.2

## If the slope is less than the low threshold, outputs  [code]low_slope_color[/code]. If the slope is greater than the upper threshold, outputs  [code]high_slope_color[/code]. If inbetween, blend between the colors.
@export var slope_threshold : Vector2 = Vector2(0.9, 0.98)

## Color of flatter areas of terrain
@export var low_slope_color : Color = Color(0.83, 0.88, 0.94)

## Color of steeper areas of terrain
@export var high_slope_color : Color = Color(0.16, 0.1, 0.1)

@export_group("Light Settings")
## Additive light adjustment
@export var ambient_light : Color = Color.DIM_GRAY
var normal_strength : float = 2.0

var transform : Transform3D
var light : DirectionalLight3D

var rd : RenderingDevice
var p_framebuffer : RID

var p_render_pipeline : RID
var p_render_pipeline_uniform_set : RID
var p_wire_render_pipeline : RID
var p_vertex_buffer : RID
var p_vertex_array : RID
var p_index_buffer : RID
var p_index_array : RID
var p_wire_index_buffer : RID
var p_wire_index_array : RID
var p_shader : RID
var p_wire_shader : RID
var clear_colors := PackedColorArray([Color.DARK_BLUE])

func _init():
	effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	
	rd = RenderingServer.get_rendering_device()

	var tree := Engine.get_main_loop() as SceneTree
	var root : Node = tree.edited_scene_root if Engine.is_editor_hint() else tree.current_scene
	light = root.get_node_or_null('DirectionalLight3D')

func compile_shader(vertex_shader : String, fragment_shader : String) -> RID:
	var src := RDShaderSource.new()
	src.source_vertex = vertex_shader
	src.source_fragment = fragment_shader
	
	var shader_spirv : RDShaderSPIRV = rd.shader_compile_spirv_from_source(src)
	
	var err = shader_spirv.get_stage_compile_error(RenderingDevice.SHADER_STAGE_VERTEX)
	if err: push_error(err)
	err = shader_spirv.get_stage_compile_error(RenderingDevice.SHADER_STAGE_FRAGMENT)
	if err: push_error(err)
	
	var shader : RID = rd.shader_create_from_spirv(shader_spirv)
	
	return shader

func initialize_render(framebuffer_format : int):
	p_shader = compile_shader(source_vertex, source_fragment)
	p_wire_shader = compile_shader(source_vertex, source_wire_fragment)

	var vertex_buffer := PackedFloat32Array([])
	var half_length = side_length / 2

	for x in side_length:
		for z in side_length:
			var xz : Vector2 = Vector2(x - half_length, z - half_length) * mesh_scale

			var pos : Vector3 = Vector3(xz.x, 0, xz.y)
			var color : Vector4 = Vector4(randf(), randf(), randf(), 1)

			for i in 3: vertex_buffer.push_back(pos[i])
			for i in 4: vertex_buffer.push_back(color[i])


	var vertex_count = vertex_buffer.size() / 7
	print("Vertex Count: " + str(vertex_count))

	# for i in vertex_count:
	#     var j = i * 7
	#     var pos = Vector3()

	#     pos.x = vertex_buffer[j]
	#     pos.y = vertex_buffer[j + 1]
	#     pos.z = vertex_buffer[j + 2]

	#     var color = Vector4()

	#     color.x = vertex_buffer[j + 3]
	#     color.y = vertex_buffer[j + 4]
	#     color.z = vertex_buffer[j + 5]
	#     color.w = vertex_buffer[j + 6]

	#     print("Vertex " + str(i) + " ---")
	#     print("Position: " + str(pos))
	#     print("Color: " + str(color))



	var index_buffer := PackedInt32Array([])
	var wire_index_buffer := PackedInt32Array([])

	for row in range(0, side_length * side_length - side_length, side_length):
		for i in side_length - 1:
			var v = i + row # shift to row we're actively triangulating

			var v0 = v
			var v1 = v + side_length
			var v2 = v + side_length + 1
			var v3 = v + 1

			index_buffer.append_array([v0, v1, v3, v1, v2, v3])
			wire_index_buffer.append_array([v0, v1, v0, v3, v1, v3, v1, v2, v2, v3])

	print("Triangle Count: " + str(index_buffer.size() / 3))

	
	var vertex_buffer_bytes : PackedByteArray = vertex_buffer.to_byte_array()
	p_vertex_buffer = rd.vertex_buffer_create(vertex_buffer_bytes.size(), vertex_buffer_bytes)
	
	var vertex_buffers := [p_vertex_buffer, p_vertex_buffer]
	
	var sizeof_float := 4
	var stride := 7
	
	var vertex_attrs = [RDVertexAttribute.new(), RDVertexAttribute.new()]
	vertex_attrs[0].format = rd.DATA_FORMAT_R32G32B32_SFLOAT
	vertex_attrs[0].location = 0
	vertex_attrs[0].offset = 0
	vertex_attrs[0].stride = stride * sizeof_float

	vertex_attrs[1].format = rd.DATA_FORMAT_R32G32B32A32_SFLOAT
	vertex_attrs[1].location = 1
	vertex_attrs[1].offset = 3 * sizeof_float
	vertex_attrs[1].stride = stride * sizeof_float

	var vertex_format = rd.vertex_format_create(vertex_attrs)
	
	p_vertex_array = rd.vertex_array_create(vertex_buffer.size() / stride, vertex_format, vertex_buffers)

	var index_buffer_bytes : PackedByteArray = index_buffer.to_byte_array()
	p_index_buffer = rd.index_buffer_create(index_buffer.size(), rd.INDEX_BUFFER_FORMAT_UINT32, index_buffer_bytes)
	
	var wire_index_buffer_bytes : PackedByteArray = wire_index_buffer.to_byte_array()
	p_wire_index_buffer = rd.index_buffer_create(wire_index_buffer.size(), rd.INDEX_BUFFER_FORMAT_UINT32, wire_index_buffer_bytes)

	p_index_array = rd.index_array_create(p_index_buffer, 0, index_buffer.size())
	p_wire_index_array = rd.index_array_create(p_wire_index_buffer, 0, wire_index_buffer.size())
	
	var raster_state = RDPipelineRasterizationState.new()
	
	raster_state.cull_mode = RenderingDevice.POLYGON_CULL_BACK
	
	var depth_state = RDPipelineDepthStencilState.new()
	
	depth_state.enable_depth_write = true
	depth_state.enable_depth_test = true
	depth_state.depth_compare_operator = RenderingDevice.COMPARE_OP_GREATER
	
	var blend = RDPipelineColorBlendState.new()
	
	blend.attachments.push_back(RDPipelineColorBlendStateAttachment.new())
	
	p_render_pipeline = rd.render_pipeline_create(p_shader, framebuffer_format, vertex_format, rd.RENDER_PRIMITIVE_TRIANGLES, raster_state, RDPipelineMultisampleState.new(), depth_state, blend)
	p_wire_render_pipeline = rd.render_pipeline_create(p_wire_shader, framebuffer_format, vertex_format, rd.RENDER_PRIMITIVE_LINES, raster_state, RDPipelineMultisampleState.new(), depth_state, blend)


func _render_callback(_effect_callback_type : int, render_data : RenderData):
	if _effect_callback_type != effect_callback_type: return
	
	var render_scene_buffers : RenderSceneBuffersRD = render_data.get_render_scene_buffers()
	var render_scene_data : RenderSceneData = render_data.get_render_scene_data()
	
	if not render_scene_buffers: return

	if regenerate:
		_notification(NOTIFICATION_PREDELETE)
		p_framebuffer = FramebufferCacheRD.get_cache_multipass([render_scene_buffers.get_color_texture(), render_scene_buffers.get_depth_texture()], [], 1)
		initialize_render(rd.framebuffer_get_format(p_framebuffer))
		regenerate = false
	
	
	# var buffer := PackedFloat32Array()
	var buffer = Array()
	
	var projection = render_scene_data.get_view_projection(0)
	var view = render_scene_data.get_cam_transform().inverse()
	var model = transform

	var model_view = Projection(view * model)
	var MVP = projection * model_view;
	
	
	for i in range(0,16):
		buffer.push_back(MVP[i / 4][i % 4])

	var light_direction = Vector3(0, 1, 0)
	if not light:
		var tree := Engine.get_main_loop() as SceneTree
		var root : Node = tree.edited_scene_root if Engine.is_editor_hint() else tree.current_scene
		light = root.get_node_or_null('DirectionalLight3D')
		if not light:
			push_error("No light source detected please put a DirectionalLight3D into the scene thank you")
	else:
		light_direction = light.transform.basis.z.normalized()

	buffer.push_back(light_direction.x)
	buffer.push_back(light_direction.y)
	buffer.push_back(light_direction.z)
	buffer.push_back(gradient_rotation)

	buffer.push_back(rotation)
	buffer.push_back(height_scale)
	buffer.push_back(angular_variance.x)
	buffer.push_back(angular_variance.y)
	buffer.push_back(zoom)
	buffer.push_back(octave_count)
	buffer.push_back(amplitude_decay)
	buffer.push_back(normal_strength)

	buffer.push_back(offset.x)
	buffer.push_back(offset.y)
	buffer.push_back(offset.z)
	buffer.push_back(noise_seed)
	buffer.push_back(initial_amplitude)
	buffer.push_back(initial_frequency)
	buffer.push_back(slope_threshold.x)
	buffer.push_back(slope_threshold.y)
	buffer.push_back(low_slope_color.r)
	buffer.push_back(low_slope_color.g)
	buffer.push_back(low_slope_color.b)
	buffer.push_back(1.0)
	buffer.push_back(high_slope_color.r)
	buffer.push_back(high_slope_color.g)
	buffer.push_back(high_slope_color.b)
	buffer.push_back(1.0)
	buffer.push_back(frequency_variance.x)
	buffer.push_back(frequency_variance.y)
	buffer.push_back(slope_damping)
	buffer.push_back(1.0)
	buffer.push_back(ambient_light.r)
	buffer.push_back(ambient_light.g)
	buffer.push_back(ambient_light.b)
	buffer.push_back(1.0)
	

	var buffer_bytes : PackedByteArray = PackedFloat32Array(buffer).to_byte_array()
	var p_uniform_buffer : RID = rd.uniform_buffer_create(buffer_bytes.size(), buffer_bytes)
	
	var uniforms = []
	var uniform := RDUniform.new()
	
	uniform.binding = 0
	uniform.uniform_type = rd.UNIFORM_TYPE_UNIFORM_BUFFER
	uniform.add_id(p_uniform_buffer)
	uniforms.push_back(uniform)
	
	if p_render_pipeline_uniform_set.is_valid():
		rd.free_rid(p_render_pipeline_uniform_set)
	
	p_render_pipeline_uniform_set = rd.uniform_set_create(uniforms, p_shader, 0)

	rd.draw_command_begin_label("Terrain Mesh", Color(1.0, 1.0, 1.0, 1.0))

	var draw_list = rd.draw_list_begin(p_framebuffer, rd.DRAW_IGNORE_ALL, clear_colors, 1.0,  0,  Rect2(), 0)

	if wireframe:
		rd.draw_list_bind_render_pipeline(draw_list, p_wire_render_pipeline)
	else:
		rd.draw_list_bind_render_pipeline(draw_list, p_render_pipeline)
		
	rd.draw_list_bind_vertex_array(draw_list, p_vertex_array)

	if wireframe:
		rd.draw_list_bind_index_array(draw_list, p_wire_index_array)
	else:
		rd.draw_list_bind_index_array(draw_list, p_index_array)

	rd.draw_list_bind_uniform_set(draw_list, p_render_pipeline_uniform_set, 0)
	rd.draw_list_draw(draw_list, true, 1)
	rd.draw_list_end()
	
	rd.draw_command_end_label()


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if p_render_pipeline.is_valid():
			rd.free_rid(p_render_pipeline)
		if p_wire_render_pipeline.is_valid():
			rd.free_rid(p_wire_render_pipeline)
		if p_vertex_array.is_valid():
			rd.free_rid(p_vertex_array)
		if p_vertex_buffer.is_valid():
			rd.free_rid(p_vertex_buffer)
		if p_index_array.is_valid():
			rd.free_rid(p_index_array)
		if p_index_buffer.is_valid():
			rd.free_rid(p_index_buffer)
		if p_wire_index_array.is_valid():
			rd.free_rid(p_wire_index_array)
		if p_wire_index_buffer.is_valid():
			rd.free_rid(p_wire_index_buffer)
		if p_framebuffer.is_valid():
			rd.free_rid(p_framebuffer)



const source_vertex = "
		#version 450

		layout(set = 0, binding = 0, std140) uniform UniformBufferObject {
			mat4 MVP; // 64 -> 0
			vec3 _LightDirection; // 16 -> 64
			float _Debug;
			float _Theta; // 4 -> 80
			float _Amplitude; // 4 -> 84
			vec2 _AngularVariance; // 8 -> 88
			float _Frequency; // 4 -> 96
			float _Octaves; // 4 -> 100
			float _AmplitudeDecay; // 4 -> 104
			float _NormalStrength; // 4  -> 108
			vec3 _Offset; // 16 -> 112 -> 128
			float _Seed;
			float _InitialAmplitude;
			float _InitialFrequency;
			vec2 _SlopeRange;
			vec4 _LowSlopeColor;
			vec4 _HighSlopeColor;
			float _FrequencyVarianceLowerBound;
			float _FrequencyVarianceUpperBound;
			float _SlopeDamping;
			vec4 _AmbientLight;
		};
		
		layout(location = 0) in vec3 a_Position;
		layout(location = 1) in vec4 a_Color;

		layout(location = 2) out vec4 v_Color;
		layout(location = 3) out vec3 pos;

		#define MAX_INT 4294967296.0
		#define PI 3.141592653589793238462
		
		// UE4's PseudoRandom function
		// https://github.com/EpicGames/UnrealEngine/blob/release/Engine/Shaders/Private/Random.ush
		float pseudo(vec2 v) {
			v = fract(v/128.)*128. + vec2(-64.340622, -72.465622);
			return fract(dot(v.xyx * v.xyy, vec3(20.390625, 60.703125, 2.4281209)));
		}

		float HashPosition(vec2 pos) {
			int s = 2309 * int(pos.x) + int(_Seed) + 47 * int(pos.y) + int(_Seed) + 1669;
			return pseudo(pos);
		}

		vec2 RandVector(float seed) {
			float theta = seed * 360 * 2 - 360;
			theta += _Debug;
			theta = theta * PI / 180.0;
			return normalize(vec2(cos(theta), sin(theta)));
		}

		vec2 quinticInterpolation(vec2 t) {
			return t * t * t * (t * (t * vec2(6) - vec2(15)) + vec2(10));
		}

		vec2 quinticDerivative(vec2 t) {
			return vec2(30) * t * t * (t * (t - vec2(2)) + vec2(1));
		}


		// Random unit sphere gradients and quintic interpolation
		vec3 ImprovedPerlinNoise(vec2 pos) {
			vec2 latticeMin = floor(pos);
			vec2 latticeMax = ceil(pos);

			vec2 remainder = fract(pos);

			// Lattice Corners
			vec2 c00 = latticeMin;
			vec2 c10 = vec2(latticeMax.x, latticeMin.y);
			vec2 c01 = vec2(latticeMin.x, latticeMax.y);
			vec2 c11 = latticeMax;

			// Gradient Vectors assigned to each corner
			vec2 g00 = RandVector(HashPosition(c00));
			vec2 g10 = RandVector(HashPosition(c10));
			vec2 g01 = RandVector(HashPosition(c01));
			vec2 g11 = RandVector(HashPosition(c11));

			// Directions to position from lattice corners
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

			// Expanded interpolation freaks of nature from https://iquilezles.org/articles/gradientnoise/
			float noise = a + u.x * (b - a) + u.y * (c - a) + u.x * u.y * (a - b - c + d);

			vec2 gradient = g00 + u.x * (g10 - g00) + u.y * (g01 - g00) + u.x * u.y * (g00 - g10 - g01 + g11) + du * (u.yx * (a - b - c + d) + vec2(b, c) - a);
			return vec3(noise, gradient);
		}

		vec3 fbm(vec2 pos, int octaves, float amplitude_decay, float lacunarity) {
			float frequency = _InitialFrequency;
			float height = 0.0;
			float amplitude = _InitialAmplitude;

			vec2 grad = vec2(0.0);
			mat2 m = mat2(1.0, 0.0,
						  0.0, 1.0);

			float angle_variance = mix(_AngularVariance.x, _AngularVariance.y, HashPosition(vec2(_Seed, 827)));
			float theta = (_Theta + angle_variance) * PI / 180.0;

			mat2 m2 = mat2(cos(theta), -sin(theta),
					  	   sin(theta),  cos(theta));
				
			mat2 m2i = inverse(m2);

			vec2 origin_offset = _Offset.xz / _Frequency;

			for(int i = 0; i < octaves; ++i) {
				vec3 n = ImprovedPerlinNoise(pos);
				
				height += amplitude * n.x;	
				
				grad += amplitude * m * n.yz;
				
				amplitude *= amplitude_decay;
				
				angle_variance = mix(_AngularVariance.x, _AngularVariance.y, HashPosition(vec2(i * 419, _Seed)));
				theta = (_Theta + angle_variance) * PI / 180.0;

				m2 = mat2(cos(theta), -sin(theta),
					  	  sin(theta),  cos(theta));
				
				m2i = inverse(m2);

				float freq_variance = mix(_FrequencyVarianceLowerBound, _FrequencyVarianceUpperBound, HashPosition(vec2(i * 422, _Seed)));
				pos = (frequency + freq_variance) * m2 * pos;
				m = (frequency + freq_variance) * m2i * m;
			}

			return vec3(height, grad);
		}
		
		void main() {
			v_Color = a_Color;
			v_Color = vec4(0.25, 0.16, 0.1, 1.0);

			vec3 p = a_Position;
			pos = (p + vec3(_Offset.x, 0, _Offset.z)) / _Frequency;

			vec3 n = fbm(pos.xz, int(_Octaves), _AmplitudeDecay, 1);
			p.y += _Amplitude * n.x + _Amplitude - _Offset.y;
			
			gl_Position = MVP * vec4(p, 1);
		}
		"


const source_fragment = "
		#version 450

		layout(set = 0, binding = 0, std140) uniform UniformBufferObject {
			mat4 MVP; // 64 -> 0
			vec3 _LightDirection; // 16 -> 64
			float _Debug;
			float _Theta; // 4 -> 80
			float _Amplitude; // 4 -> 84
			vec2 _AngularVariance; // 8 -> 88
			float _Frequency; // 4 -> 96
			float _Octaves; // 4 -> 100
			float _AmplitudeDecay; // 4 -> 104
			float _NormalStrength; // 4  -> 108
			vec3 _Offset; // 16 -> 112 -> 128
			float _Seed;
			float _InitialAmplitude;
			float _InitialFrequency;
			vec2 _SlopeRange;
			vec4 _LowSlopeColor;
			vec4 _HighSlopeColor;
			float _FrequencyVarianceLowerBound;
			float _FrequencyVarianceUpperBound;
			float _SlopeDamping;
			vec4 _AmbientLight;
		};
		
		layout(location = 2) in vec4 a_Color;
		layout(location = 3) in vec3 pos;
		
		layout(location = 0) out vec4 frag_color;

		#define MAX_INT 4294967296.0
		#define PI 3.141592653589793238462
		
		// UE4's PseudoRandom function
		// https://github.com/EpicGames/UnrealEngine/blob/release/Engine/Shaders/Private/Random.ush
		float pseudo(vec2 v) {
			v = fract(v/128.)*128. + vec2(-64.340622, -72.465622);
			return fract(dot(v.xyx * v.xyy, vec3(20.390625, 60.703125, 2.4281209)));
		}

		float HashPosition(vec2 pos) {
			int s = 2309 * int(pos.x) + int(_Seed) + 47 * int(pos.y) + int(_Seed) + 1669;
			return pseudo(pos);
		}

		vec2 RandVector(float seed) {
			float theta = seed * 360 * 2 - 360;
			theta += _Debug;
			theta = theta * PI / 180.0;
			return normalize(vec2(cos(theta), sin(theta)));
		}

		vec2 quinticInterpolation(vec2 t) {
			return t * t * t * (t * (t * vec2(6) - vec2(15)) + vec2(10));
		}

		vec2 quinticDerivative(vec2 t) {
			return vec2(30) * t * t * (t * (t - vec2(2)) + vec2(1));
		}


		// Random unit sphere gradients and quintic interpolation
		vec3 ImprovedPerlinNoise(vec2 pos) {
			vec2 latticeMin = floor(pos);
			vec2 latticeMax = ceil(pos);

			vec2 remainder = fract(pos);

			// Lattice Corners
			vec2 c00 = latticeMin;
			vec2 c10 = vec2(latticeMax.x, latticeMin.y);
			vec2 c01 = vec2(latticeMin.x, latticeMax.y);
			vec2 c11 = latticeMax;

			// Gradient Vectors assigned to each corner
			vec2 g00 = RandVector(HashPosition(c00));
			vec2 g10 = RandVector(HashPosition(c10));
			vec2 g01 = RandVector(HashPosition(c01));
			vec2 g11 = RandVector(HashPosition(c11));

			// Directions to position from lattice corners
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

			// Expanded interpolation freaks of nature from https://iquilezles.org/articles/gradientnoise/
			float noise = a + u.x * (b - a) + u.y * (c - a) + u.x * u.y * (a - b - c + d);

			vec2 gradient = g00 + u.x * (g10 - g00) + u.y * (g01 - g00) + u.x * u.y * (g00 - g10 - g01 + g11) + du * (u.yx * (a - b - c + d) + vec2(b, c) - a);
			return vec3(noise, gradient);
		}

		vec3 fbm(vec2 pos, int octaves, float amplitude_decay, float lacunarity) {
			float frequency = _InitialFrequency;
			float height = 0.0;
			float amplitude = _InitialAmplitude;

			vec2 grad = vec2(0.0);
			mat2 m = mat2(1.0, 0.0,
						  0.0, 1.0);

			float angle_variance = mix(_AngularVariance.x, _AngularVariance.y, HashPosition(vec2(_Seed, 827)));
			float theta = (_Theta + angle_variance) * PI / 180.0;

			mat2 m2 = mat2(cos(theta), -sin(theta),
					  	   sin(theta),  cos(theta));
				
			mat2 m2i = inverse(m2);

			for(int i = 0; i < octaves; ++i) {
				vec3 n = ImprovedPerlinNoise(pos);
				
				height += amplitude * n.x;	
				
				grad += amplitude * m * n.yz;
				
				amplitude *= amplitude_decay;
				
				angle_variance = mix(_AngularVariance.x, _AngularVariance.y, HashPosition(vec2(i * 419, _Seed)));
				theta = (_Theta + angle_variance) * PI / 180.0;

				m2 = mat2(cos(theta), -sin(theta),
					  	  sin(theta),  cos(theta));
				
				m2i = inverse(m2);

				float freq_variance = mix(_FrequencyVarianceLowerBound, _FrequencyVarianceUpperBound, HashPosition(vec2(i * 422, _Seed)));
				pos = (frequency + freq_variance) * m2 * pos;
				m = (frequency + freq_variance) * m2i * m;
			}

			return vec3(height, grad);
		}
		
		void main() {
			vec3 n = _Amplitude * fbm(pos.xz, int(_Octaves), _AmplitudeDecay, 1);

			vec3 slope_normal = normalize(vec3(-n.y, 1, -n.z) * vec3(_SlopeDamping, 1, _SlopeDamping));

			float material_blend_factor = smoothstep(_SlopeRange.x, _SlopeRange.y, 1 - slope_normal.y);

			vec4 albedo = mix(_LowSlopeColor, _HighSlopeColor, vec4(material_blend_factor));

			vec3 normal = normalize(vec3(-n.y, 1, -n.z));

			float ndotl = clamp(dot(_LightDirection, normal), 0, 1);

			vec4 direct_light = albedo * ndotl;
			vec4 ambient_light = albedo * _AmbientLight;

			vec4 lit = clamp(direct_light + ambient_light, vec4(0), vec4(1));

			frag_color = pow(lit, vec4(2.2));
		}
		"

const source_wire_fragment = "
		#version 450

		layout(set = 0, binding = 0, std140) uniform UniformBufferObject {
			mat4 MVP; // 64 -> 0
			vec3 _LightDirection; // 16 -> 64
			float _Debug;
			float _Theta; // 4 -> 80
			float _Amplitude; // 4 -> 84
			vec2 _AngularVariance; // 8 -> 88
			float _Frequency; // 4 -> 96
			float _Octaves; // 4 -> 100
			float _AmplitudeDecay; // 4 -> 104
			float _NormalStrength; // 4  -> 108
			vec3 _Offset; // 16 -> 112 -> 128
			float _Seed;
			float _InitialAmplitude;
			float _InitialFrequency;
			vec2 _SlopeRange;
			vec4 _LowSlopeColor;
			vec4 _HighSlopeColor;
			float _FrequencyVarianceLowerBound;
			float _FrequencyVarianceUpperBound;
			float _SlopeDamping;
			vec4 _AmbientLight;
		};
		
		layout(location = 2) in vec4 a_Color;
		
		layout(location = 0) out vec4 frag_color; // Bound to buffer index 0
		
		void main(){
			frag_color = vec4(1, 0, 0, 1);
		}
		"
