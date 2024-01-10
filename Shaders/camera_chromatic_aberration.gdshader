shader_type spatial;

uniform sampler2D offset_image;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec4 output = texture(SCREEN_TEXTURE, SCREEN_UV);

	float shift = 0.015 * texture(offset_image, SCREEN_UV).r;
	output.r = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x + shift, SCREEN_UV.y)).r;
	output.g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
	output.b = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x - shift, SCREEN_UV.y)).b;

	if (SCREEN_UV.x > 0.02 && SCREEN_UV.x < 0.98) {
		ALBEDO = output.rgb;
	} else if (SCREEN_UV.x <= 0.02) {
		ALBEDO = (SCREEN_UV.x / 0.02) * output.rgb + ((0.02 - SCREEN_UV.x) / 0.02) * texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	} else if (SCREEN_UV.x >= 0.98) {
		ALBEDO = ((1. - SCREEN_UV.x) / 0.02) * output.rgb + ((SCREEN_UV.x - 0.98) / 0.02) * texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	}
	ALPHA = output.a;
}
