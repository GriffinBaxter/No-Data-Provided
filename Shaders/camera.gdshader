shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform float red_dither : hint_range(0, 2, 0.05) = 0.1;
uniform float green_dither : hint_range(0, 2, 0.05) = 0.35;
uniform float blue_dither : hint_range(0, 2, 0.05) = 1.5;
uniform float amount : hint_range(0, 1, 0.05) = 0.8;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	float[3] screen_colors = float[3](screen_color.r, screen_color.g, screen_color.b);
	float[11] thresholds = float[11](5., 1., .75, .5, .2, .05, .02, .01, .005, .001, 0.);

	ALBEDO = screen_color;

	for (int threshold_index = 0; threshold_index < 10; threshold_index++) {
		for (int screen_color_index = 0; screen_color_index < 3; screen_color_index++) {
			if (screen_colors[screen_color_index] <= thresholds[threshold_index]) {
				float dither = 0.;
				if (mod(SCREEN_UV.t, 0.01) < 0.005) {
					dither = thresholds[threshold_index];
				} else {
					dither =
						0.5 * thresholds[threshold_index] + 0.5 * thresholds[threshold_index + 1];
				}
				if (screen_color_index == 0) {
					ALBEDO.r = dither * red_dither;
				} else if (screen_color_index == 1) {
					ALBEDO.g = dither * green_dither;
				} else if (screen_color_index == 2) {
					ALBEDO.b = dither * blue_dither;
				}
			}
		}
	}

	ALPHA = amount;
}
