#version 430 core

layout (location = 0) in vec3 vertexPos;

layout(std140, binding = 0) uniform UniformMatrixBuffer {
	mat4 screenView;
	mat4 screenProj;
	mat4 screenViewProj;

	mat4 cameraView;
	mat4 cameraProj;
	mat4 cameraViewProj;
	mat4 cameraBillboardView;

	mat4 cameraViewInv;
	mat4 cameraProjInv;
	mat4 cameraViewProjInv;

	mat4 shadowView;
	mat4 shadowProj;
	mat4 shadowViewProj;

	mat4 reflectionView;
	mat4 reflectionProj;
	mat4 reflectionViewProj;

	mat4 orthoProj01;

	mat4 mmDrawView;
	mat4 mmDrawProj;
	mat4 mmDrawViewProj;

	mat4 mmDrawIMMView;
	mat4 mmDrawIMMProj;
	mat4 mmDrawIMMViewProj;

	mat4 mmDrawDimView;
	mat4 mmDrawDimProj;
	mat4 mmDrawDimViewProj;
};

layout(std140, binding = 1) uniform UniformParamsBuffer {
	vec3 rndVec3;
	uint renderCaps;

	vec4 timeInfo;
	vec4 viewGeometry;
	vec4 mapSize;
	vec4 mapHeight;

	vec4 fogColor;
	vec4 fogParams; // {start, end, 0.0, scale}

	vec4 sunDir;

	vec4 sunAmbientModel;
	vec4 sunAmbientMap;
	vec4 sunDiffuseModel;
	vec4 sunDiffuseMap;
	vec4 sunSpecularModel;
	vec4 sunSpecularMap;

	vec4 shadowDensity;

	vec4 windInfo;
	vec2 mouseScreenPos;
	uint mouseStatus;
	uint mouseUnused;
	vec4 mouseWorldPos;

	vec4 teamColor[255];
};

uniform vec2 texSquare;
uniform vec2 specularTexGen;
uniform sampler2D heightMapTex;

out vec4 vertexWorldPos;
out vec2 diffuseTexCoords;
out float fogFactor;
out vec3 halfDir;
flat out vec2 texSquareCoords;

const float SMF_TEXSQR_SIZE = 1024.0;

vec2 mapWorldSize = vec2(1.0) / specularTexGen;

float HeightAtWorldPos(vec2 worldXZ) {
	const vec2 HM_TEXEL = vec2(8.0, 8.0);

	worldXZ += -HM_TEXEL * (worldXZ * specularTexGen) + 0.5 * HM_TEXEL;

	vec2 heightUV = clamp(worldXZ, HM_TEXEL, mapWorldSize - HM_TEXEL);
	heightUV *= specularTexGen;

	return textureLod(heightMapTex, heightUV, 0.0).x;
}

void main() {
	vertexWorldPos = vec4(vertexPos, 1.0);
	vertexWorldPos.xz += texSquare * SMF_TEXSQR_SIZE;
	#ifdef SMF_MACOS_FLAT_GEOM
	vertexWorldPos.y = 0.0;
	#else
	vertexWorldPos.y = HeightAtWorldPos(vertexWorldPos.xz);
	#endif

	diffuseTexCoords = (vertexWorldPos.xz / SMF_TEXSQR_SIZE) - texSquare;
	texSquareCoords = texSquare;

	vec3 cameraPos = vec3(cameraViewInv * vec4(0.0, 0.0, 0.0, 1.0));
	vec3 viewDir = normalize(cameraPos - vertexWorldPos.xyz);
	halfDir = normalize(sunDir.xyz + viewDir);

	gl_Position = cameraViewProj * vertexWorldPos;

#ifndef DEFERRED_MODE
	float fogCoord = length((cameraView * vertexWorldPos).xyz);
	fogFactor = clamp((fogParams.y - fogCoord) * fogParams.w, 0.0, 1.0);
#else
	fogFactor = 1.0;
#endif
}
