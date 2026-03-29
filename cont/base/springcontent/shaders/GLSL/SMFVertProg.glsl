#version 430 core

layout (location = 0) in vec3 vertexPos;

uniform ivec2 texSquare;
uniform vec2 specularTexGen;
uniform sampler2D heightMapTex;

out vec4 vertexWorldPos;
out vec2 diffuseTexCoords;
out float fogFactor;
out vec3 halfDir;

void main() {
	vertexWorldPos = vec4(vertexPos, 1.0);
	diffuseTexCoords = vec2(0.0);
	halfDir = vec3(0.0);
	fogFactor = 1.0;

	// Force to fill entire NDC space
	// Clamp all vertex positions to [-1, 1]
	gl_Position = vec4(
		clamp(vertexPos.x * 0.0005, -1.0, 1.0),
		clamp(vertexPos.z * 0.0005, -1.0, 1.0),
		0.0,
		1.0
	);
}
