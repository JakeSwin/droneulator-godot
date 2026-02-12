extends MeshInstance3D

@export var segmentation_color: Color = Color(1, 0, 0)
@export var alpha_threshold: float = 0.5 # Adjust for "crunchiness" of the edges

func _ready():
	create_segmentation_proxy()

func create_segmentation_proxy():
	var proxy_mesh = MeshInstance3D.new()
	proxy_mesh.mesh = self.mesh
	proxy_mesh.layers = 2 # Segmentation Layer
	add_child(proxy_mesh)

	# 1. Try to grab the texture from the original object
	var original_mat = get_active_material(0)
	var original_texture = null
	
	# Check if the original material actually has a texture
	if original_mat and original_mat is StandardMaterial3D:
		original_texture = original_mat.albedo_texture

	# 2. Setup the Material logic
	if original_texture:
		# COMPLEX CASE: We need a shader to strip color but keep alpha
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = _get_segmentation_shader()
		shader_mat.set_shader_parameter("id_color", segmentation_color)
		shader_mat.set_shader_parameter("mask_texture", original_texture)
		shader_mat.set_shader_parameter("threshold", alpha_threshold)
		proxy_mesh.material_override = shader_mat
	else:
		# SIMPLE CASE: Just a solid block (like a wall or drone body)
		var flat_mat = StandardMaterial3D.new()
		flat_mat.albedo_color = segmentation_color
		flat_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		proxy_mesh.material_override = flat_mat

# This helper function creates the shader code dynamically
func _get_segmentation_shader() -> Shader:
	var code = """
    shader_type spatial;
    render_mode unshaded, cull_disabled; // cull_disabled lets you see both sides of leaves

    uniform vec4 id_color : source_color;
    uniform sampler2D mask_texture : source_color, filter_nearest_mipmap;
    uniform float threshold;

    void fragment() {
        vec4 tex = texture(mask_texture, UV);
        ALBEDO = id_color.rgb;     // Force the flat ID color
        ALPHA = tex.a;             // Use the texture's transparency
        ALPHA_SCISSOR_THRESHOLD = threshold; // Cut out the transparent parts
    }
	"""
	var shader = Shader.new()
	shader.code = code
	return shader
