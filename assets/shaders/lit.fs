#version 330
in vec2 fragTexCoord;
in vec3 fragNormal;
in vec4 fragColor;
uniform vec3 lightDir;
uniform vec4 tint;
out vec4 finalColor;
void main() {
	vec3 n = normalize(fragNormal);
	float diff = max(dot(n, normalize(-lightDir)), 0.0);
	vec3 lit = fragColor.rgb * tint.rgb * (0.35 + 0.65 * diff);
	finalColor = vec4(lit, fragColor.a * tint.a);
}
