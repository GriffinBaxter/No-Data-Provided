shader_type spatial;

uniform float progress : hint_range(0, 1) = 0;

void fragment() {
	if (UV.x < progress / 3.) {
		EMISSION = vec3(1, 1, 1);
	}
}
