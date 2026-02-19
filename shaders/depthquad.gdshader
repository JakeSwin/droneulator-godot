shader_type spatial;
render_mode unshaded, depth_test_disabled;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform float max_range = 50.0;

void vertex() {
	//POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	//float normalized_depth = clamp(linear_depth / max_range, 0.0, 1.0);
	//ALBEDO = vec3(normalized_depth);
	// Output the raw float value. 
    // Note: This won't "look" right on screen, but the data will be there.
    ALBEDO = vec3(linear_depth);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
