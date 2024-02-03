shader_type spatial;

uniform sampler2D offset_image;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

const float UV_CUTOFF = 0.1;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec4 output = texture(SCREEN_TEXTURE, SCREEN_UV);

	float shift = 0.015 * texture(offset_image, SCREEN_UV).r;
	output.r = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x + shift, SCREEN_UV.y)).r;
	output.g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
	output.b = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x - shift, SCREEN_UV.y)).b;



	if (SCREEN_UV.x > UV_CUTOFF && SCREEN_UV.x < 1. - UV_CUTOFF) {
		ALBEDO = output.rgb;
	} else if (SCREEN_UV.x <= UV_CUTOFF) {
		ALBEDO = (SCREEN_UV.x / UV_CUTOFF) * output.rgb + ((UV_CUTOFF - SCREEN_UV.x) / UV_CUTOFF) * texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	} else if (SCREEN_UV.x >= 1. - UV_CUTOFF) {
		ALBEDO = ((1. - SCREEN_UV.x) / UV_CUTOFF) * output.rgb + ((SCREEN_UV.x - (1. - UV_CUTOFF)) / UV_CUTOFF) * texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	}
	ALPHA = output.a;
}
