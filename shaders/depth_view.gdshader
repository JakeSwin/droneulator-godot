shader_type canvas_item;

uniform bool is_depth_mode = false;
uniform float debug_max_range = 10.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    if (is_depth_mode) {
        // Assume raw meters are in the Red channel from your Depth viewport
        float dist = tex_color.r;
        // Normalize for the human eye (0.0 to 1.0)
        float visualization = clamp(dist / debug_max_range, 0.0, 1.0);
        COLOR = vec4(vec3(visualization), 1.0);
    } else {
        // Pass-through for RGB and Segmentation
        COLOR = tex_color;
    }
}