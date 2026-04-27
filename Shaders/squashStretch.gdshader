shader_type spatial;

uniform vec2 direction = vec2(1.0);
uniform float squash: hint_range(0.0, 2.0) = 1.0;
uniform float offset: hint_range(-0.5, 0.5) = 0.0;

void vertex() {
	float v = abs(VERTEX.y + offset) * squash + direction.x;
	VERTEX *= vec3(v, direction.y, v);
}