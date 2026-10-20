shader_type canvas_item;

uniform sampler2D textures : hint_screen_texture ,filter_linear_mipmap;
uniform float n : hint_range(0.0, 5.0, 0.1) = 1.5;
void fragment() {
	vec3 result = textureLod(textures,SCREEN_UV,n).rgb;
	COLOR.rgb = result;
	}
