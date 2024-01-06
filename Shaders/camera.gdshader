shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform float red_dither : hint_range(0, 2, 0.05) = 1.6;
uniform float green_dither : hint_range(0, 2, 0.05) = 0.15;
uniform float blue_dither : hint_range(0, 2, 0.05) = 0.1;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	float[11] thresholds = float[11](5., 1., .75, .5, .2, .05, .02, .01, .005, .001, 0.);

	ALBEDO = screen_color;

	for(int i = 0; i < 10; i += 1) {
		if (screen_color.r <= thresholds[i]) {
			float dither = 0.;
			if (mod(SCREEN_UV.t, 0.01) < 0.005) {
				dither = thresholds[i];
			} else {
				dither = 0.5 * thresholds[i] + 0.5 * thresholds[i + 1];
			}
			ALBEDO = 0.2 * screen_color + 0.8 * vec3(dither * red_dither, dither * green_dither, dither * blue_dither);
		}
	}
}
