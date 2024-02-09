shader_type spatial;

uniform float progress : hint_range(0, 1) = 0.5;

void fragment() {
	if (SCREEN_UV.x < progress) {
		ALBEDO = vec3(1, 1, 1);
	} else {
		ALBEDO = vec3(0, 0, 0);
	}
}
