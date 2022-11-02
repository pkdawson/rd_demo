extends SubViewport

var vertSrc = "#version 450
vec2 positions[3] = vec2[](
    vec2(0.0, -0.5),
    vec2(0.5, 0.5),
    vec2(-0.5, 0.5)
);

void main() {
    gl_Position = vec4(positions[gl_VertexIndex], 0.0, 1.0);
}"

var fragSrc = "#version 450
layout(location = 0) out vec4 outColor;

void main() {
    outColor = vec4(0.5, 0.0, 1.0, 1.0);
}"

var framebuffer: RID
var pipeline: RID
var shader: RID
var clearColors := PackedColorArray([Color.TRANSPARENT])
@onready var rd := RenderingServer.get_rendering_device()

func create_framebuffer():
    var vptex := RenderingServer.texture_get_rd_texture(get_texture().get_rid())
    framebuffer = rd.framebuffer_create([vptex])

func _ready():
    var src := RDShaderSource.new()
    src.source_fragment = fragSrc
    src.source_vertex = vertSrc
    var spirv := rd.shader_compile_spirv_from_source(src)
    shader = rd.shader_create_from_spirv(spirv)
    
    create_framebuffer()
    
    var blend := RDPipelineColorBlendState.new()
    blend.attachments.push_back(RDPipelineColorBlendStateAttachment.new())
    pipeline = rd.render_pipeline_create(
        shader,
        rd.screen_get_framebuffer_format(),
        -1,
        RenderingDevice.RENDER_PRIMITIVE_TRIANGLES,
        RDPipelineRasterizationState.new(),
        RDPipelineMultisampleState.new(),
        RDPipelineDepthStencilState.new(),
        blend
    )
    
func _exit_tree():
    rd.free_rid(pipeline)
    rd.free_rid(framebuffer)
    rd.free_rid(shader)

func _process(_delta):
    # handle resizing
    if not rd.framebuffer_is_valid(framebuffer):
        create_framebuffer()

    var draw_list := rd.draw_list_begin(framebuffer,
        RenderingDevice.INITIAL_ACTION_CLEAR, RenderingDevice.FINAL_ACTION_READ,
        RenderingDevice.INITIAL_ACTION_CLEAR, RenderingDevice.FINAL_ACTION_READ,
        clearColors)
    rd.draw_list_bind_render_pipeline(draw_list, pipeline)
    rd.draw_list_draw(draw_list, false, 1, 3)
    rd.draw_list_end()
