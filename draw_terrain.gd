@tool
class_name DrawTerrainMesh extends CompositorEffect


@export var side_length : int = 2
@export var scale : float = 1.0
@export var regenerate : bool = true
@export var wireframe : bool = false
var transform : Transform3D

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

    # var _vertex_buffer := PackedFloat32Array([
    #     -0.5,-0.5,0, 1,0,0,1,
    #     0.5,-0.5,0, 0,1,0,1,
    #     0.5,0.5,0, 0,0,1,1,
    #     -0.5,0.5,0, 1,1,1,1
    #     ])

    var vertex_buffer := PackedFloat32Array([])

    for x in side_length:
        for z in side_length:
            var xz : Vector2 = Vector2(x, z) * scale

            var pos : Vector3 = Vector3(xz.x, sin((xz.x + xz.y) * 0.25), xz.y)
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
    
    
    var buffer := PackedFloat32Array()
    var sizeof_float := 4
    
    buffer.resize(16 * sizeof_float)


    var projection = render_scene_data.get_view_projection(0)
    var view = render_scene_data.get_cam_transform().inverse()
    var model = transform

    var model_view = Projection(view * model)
    var MVP = projection * model_view;
    
    
    for i in range(0,16):
        buffer[i] = MVP[i / 4][i % 4]
    

    var buffer_bytes : PackedByteArray = buffer.to_byte_array()
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
        
        layout(location = 0) in vec3 a_Position;
        layout(location = 1) in vec4 a_Color;
        
        layout(set = 0, binding = 0) uniform UniformBufferObject {
            mat4 MVP;
        };
        
        layout(location = 2) out vec4 v_Color;
        
        void main(){
            v_Color = a_Color;
            
            gl_Position = MVP * vec4(a_Position, 1);
        }
        "


const source_fragment = "
        #version 450
        
        layout(location = 2) in vec4 a_Color;
        
        layout(location = 0) out vec4 frag_color; // Bound to buffer index 0
        
        void main(){
            frag_color = a_Color;
        }
        "

const source_wire_fragment = "
        #version 450
        
        layout(location = 2) in vec4 a_Color;
        
        layout(location = 0) out vec4 frag_color; // Bound to buffer index 0
        
        void main(){
            frag_color = vec4(1, 0, 0, 1);
        }
        "