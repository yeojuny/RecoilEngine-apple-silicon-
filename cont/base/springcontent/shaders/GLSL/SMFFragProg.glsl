#version 430 core

#ifdef NOSPRING
	#define SMF_INTENSITY_MULT (210.0 / 255.0)
	#define SMF_TEXSQUARE_SIZE 1024.0
	#define GBUFFER_NORMTEX_IDX 0
	#define GBUFFER_DIFFTEX_IDX 1
	#define GBUFFER_SPECTEX_IDX 2
	#define GBUFFER_EMITTEX_IDX 3
	#define GBUFFER_MISCTEX_IDX 4
#endif

#if (GL_FRAGMENT_PRECISION_HIGH == 1)
precision highp float;
#else
precision mediump float;
#endif

/***********************************************************************/
// Consts

const float SMF_SHALLOW_WATER_DEPTH     = 10.0;
const float SMF_SHALLOW_WATER_DEPTH_INV = 1.0 / SMF_SHALLOW_WATER_DEPTH;
const float SMF_DETAILTEX_RES           = 0.02;

/***********************************************************************/
// UBO: params (binding=1)

layout(std140, binding = 1) uniform UniformParamsBuffer {
	vec3 rndVec3;
	uint renderCaps;
	vec4 timeInfo;
	vec4 viewGeometry;
	vec4 mapSize;
	vec4 mapHeight;
	vec4 fogColor;
	vec4 fogParams;
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

/***********************************************************************/
// Uniforms + Varyings + Output

in vec3 halfDir;
in float fogFactor;
in vec4 vertexWorldPos;
in vec2 diffuseTexCoords;
flat in vec2 texSquareCoords;

uniform sampler2D diffuseTex;
uniform sampler2D normalsTex;
uniform sampler2D detailTex;
#ifndef SMF_ADV_SHADING
	uniform sampler2D shadingTex;
#endif

uniform vec2 specularTexGen;

#ifdef SMF_ADV_SHADING
	uniform vec2 normalTexGen;
	uniform vec3 groundAmbientColor;
	uniform vec3 groundDiffuseColor;
	uniform vec3 groundSpecularColor;
	uniform float groundSpecularExponent;
	uniform float groundShadowDensity;

	uniform vec2 mapHeights;

	uniform vec4 lightDir;
	uniform vec3 cameraPos;
#endif

uniform sampler2D infoTex;
uniform float infoTexIntensityMul;
uniform vec2 infoTexGen;

#ifdef SMF_SPECULAR_LIGHTING
	uniform sampler2D specularTex;
#endif

#ifdef HAVE_SHADOWS
	uniform sampler2DShadow shadowTex;
	uniform sampler2D shadowColorTex;
	uniform mat4 shadowMat;
#endif

#ifdef SMF_WATER_ABSORPTION
	uniform vec3 waterMinColor;
	uniform vec3 waterBaseColor;
	uniform vec3 waterAbsorbColor;
#endif

#if defined(SMF_DETAIL_TEXTURE_SPLATTING) && !defined(SMF_DETAIL_NORMAL_TEXTURE_SPLATTING)
	uniform sampler2D splatDetailTex;
	uniform sampler2D splatDistrTex;
	uniform vec4 splatTexMults;
	uniform vec4 splatTexScales;
#endif

#ifdef SMF_DETAIL_NORMAL_TEXTURE_SPLATTING
	uniform sampler2D splatDetailNormalTex1;
	uniform sampler2D splatDetailNormalTex2;
	uniform sampler2D splatDetailNormalTex3;
	uniform sampler2D splatDetailNormalTex4;
	uniform sampler2D splatDistrTex;
	uniform vec4 splatTexMults;
	uniform vec4 splatTexScales;
#endif

#ifdef SMF_SKY_REFLECTIONS
	uniform samplerCube skyReflectTex;
	uniform sampler2D skyReflectModTex;
#endif

#ifdef SMF_BLEND_NORMALS
	uniform sampler2D blendNormalsTex;
#endif

#ifdef SMF_LIGHT_EMISSION
	uniform sampler2D lightEmissionTex;
#endif

#ifdef SMF_PARALLAX_MAPPING
	uniform sampler2D parallaxHeightTex;
#endif

#ifdef DEFERRED_MODE
	out vec4 fragData[GBUFFER_MISCTEX_IDX + 1];
#else
	out vec4 fragColor;
#endif

/***********************************************************************/
// Helper functions

#ifdef SMF_PARALLAX_MAPPING
vec2 GetParallaxUVOffset(vec2 uv, vec3 dir) {
	vec4 texel = texture(parallaxHeightTex, uv);
	const float RMUL = 255.0 * 256.0;
	const float GMUL = 256.0;
	const float HDIV = 65536.0;
	float heightValue  = dot(texel.rg, vec2(RMUL, GMUL)) / HDIV;
	float heightScale  = texel.b;
	float heightBias   = texel.a - 0.5;
	float heightOffset = heightValue * heightScale + heightBias;
	return ((dir.xy / dir.z) * heightOffset);
}
#endif

#ifdef SMF_ADV_SHADING
	vec3 GetFragmentNormal(vec2 uv) {
		vec3 normal;
		normal.xz = texture(normalsTex, uv).ra;
		normal.y  = sqrt(1.0 - dot(normal.xz, normal.xz));
		return normal;
	}
#endif

#ifndef SMF_DETAIL_NORMAL_TEXTURE_SPLATTING
vec4 GetDetailTextureColor(vec2 uv) {
	#ifndef SMF_DETAIL_TEXTURE_SPLATTING
		vec2 detailTexCoord = vertexWorldPos.xz * vec2(SMF_DETAILTEX_RES);
		vec4 detailCol = (texture(detailTex, detailTexCoord) * 2.0) - 1.0;
	#else
		vec4 splatTexCoord0 = vertexWorldPos.xzxz * splatTexScales.rrgg;
		vec4 splatTexCoord1 = vertexWorldPos.xzxz * splatTexScales.bbaa;
		vec4 splatDetails;
			splatDetails.r = texture(splatDetailTex, splatTexCoord0.st).r;
			splatDetails.g = texture(splatDetailTex, splatTexCoord0.pq).g;
			splatDetails.b = texture(splatDetailTex, splatTexCoord1.st).b;
			splatDetails.a = texture(splatDetailTex, splatTexCoord1.pq).a;
			splatDetails   = (splatDetails * 2.0) - 1.0;
		vec4 splatCofac = texture(splatDistrTex, uv) * splatTexMults;
		vec4 detailCol = vec4(dot(splatDetails, splatCofac));
	#endif
	return detailCol;
}
#else
vec4 GetSplatDetailTextureNormal(vec2 uv, out vec2 splatDetailStrength) {
	vec4 splatTexCoord0 = vertexWorldPos.xzxz * splatTexScales.rrgg;
	vec4 splatTexCoord1 = vertexWorldPos.xzxz * splatTexScales.bbaa;
	vec4 splatCofac = texture(splatDistrTex, uv) * splatTexMults;
	splatDetailStrength.x = min(1.0, dot(splatCofac, vec4(1.0)));
	vec4 splatDetailNormal;
		splatDetailNormal  = ((texture(splatDetailNormalTex1, splatTexCoord0.st) * 2.0 - 1.0) * splatCofac.r);
		splatDetailNormal += ((texture(splatDetailNormalTex2, splatTexCoord0.pq) * 2.0 - 1.0) * splatCofac.g);
		splatDetailNormal += ((texture(splatDetailNormalTex3, splatTexCoord1.st) * 2.0 - 1.0) * splatCofac.b);
		splatDetailNormal += ((texture(splatDetailNormalTex4, splatTexCoord1.pq) * 2.0 - 1.0) * splatCofac.a);
	splatDetailNormal.y = max(splatDetailNormal.y, 0.01);
	#ifdef SMF_DETAIL_NORMAL_DIFFUSE_ALPHA
		splatDetailStrength.y = clamp(splatDetailNormal.a, -1.0, 1.0);
	#endif
	return splatDetailNormal;
}
#endif

#ifdef SMF_ADV_SHADING
	vec4 GetShadeInt(float groundLightInt, vec3 groundShadowCoeff, float groundDiffuseAlpha) {
		vec4 groundShadeInt = vec4(0.0, 0.0, 0.0, 1.0);
		groundShadeInt.rgb = groundAmbientColor + groundDiffuseColor * (groundLightInt * groundShadowCoeff);
		groundShadeInt.rgb *= vec3(SMF_INTENSITY_MULT);
	#ifdef SMF_VOID_WATER
		groundShadeInt.a = float(vertexWorldPos.y >= 0.0);
	#endif
	#ifdef SMF_VOID_GROUND
		groundShadeInt.a = groundDiffuseAlpha;
	#endif
	#ifdef SMF_WATER_ABSORPTION
		vec4 waterShadeInt = vec4(waterBaseColor.rgb, groundShadeInt.a);
		if (mapHeights.x <= 0.0) {
			float waterShadeAlpha  = abs(vertexWorldPos.y) * SMF_SHALLOW_WATER_DEPTH_INV;
			float waterShadeDecay  = 0.2 + (waterShadeAlpha * 0.1);
			float vertexStepHeight = min(1023.0, -vertexWorldPos.y);
			float waterLightInt    = min(groundLightInt * 2.0 + 0.4, 1.0);
			waterShadeAlpha = min(1.0, waterShadeAlpha + float(vertexWorldPos.y <= -SMF_SHALLOW_WATER_DEPTH));
			waterShadeInt.rgb -= (waterAbsorbColor.rgb * vertexStepHeight);
			waterShadeInt.rgb  = max(waterMinColor.rgb, waterShadeInt.rgb);
			waterShadeInt.rgb *= vec3(SMF_INTENSITY_MULT * waterLightInt);
			waterShadeInt.rgb *= (1.0 - waterShadeDecay * (vec3(1.0) - groundShadowCoeff));
			waterShadeInt.rgb = mix(groundShadeInt.rgb, waterShadeInt.rgb, waterShadeAlpha);
		}
		return mix(groundShadeInt, waterShadeInt, float(vertexWorldPos.y < 0.0));
	#else
		return groundShadeInt;
	#endif
	}
#endif

/***********************************************************************/
// main()

void main() {
	vec2 diffTexCoords = diffuseTexCoords;
	vec2 specTexCoords = vertexWorldPos.xz * specularTexGen;
	vec2 infoTexCoords = vertexWorldPos.xz * infoTexGen;
	#ifdef SMF_ADV_SHADING
		vec2 normTexCoords = vertexWorldPos.xz * normalTexGen;
		vec3 cameraDir = vertexWorldPos.xyz - cameraPos;
		vec3 normal = GetFragmentNormal(normTexCoords);
	#endif

	#if defined(SMF_BLEND_NORMALS) || defined(SMF_PARALLAX_MAPPING) || defined(SMF_DETAIL_NORMAL_TEXTURE_SPLATTING)
		vec3 tTangent = normalize(cross(normal, vec3(-1.0, 0.0, 0.0)));
		vec3 sTangent = cross(normal, tTangent);
		mat3 stnMatrix = mat3(sTangent, tTangent, normal);
	#endif

	#ifdef SMF_PARALLAX_MAPPING
	{
		vec2 uvOffset = GetParallaxUVOffset(specTexCoords, transpose(stnMatrix) * cameraDir);
		diffTexCoords += (uvOffset / (SMF_TEXSQUARE_SIZE * specularTexGen));
		normTexCoords += (uvOffset * (normalTexGen / specularTexGen));
		specTexCoords += (uvOffset);
		normal = GetFragmentNormal(normTexCoords);
	}
	#endif

	#ifdef SMF_BLEND_NORMALS
	{
		vec4 dtSample = texture(blendNormalsTex, normTexCoords);
		vec3 dtNormal = (dtSample.xyz * 2.0) - 1.0;
		normal = normalize(mix(normal, stnMatrix * dtNormal, dtSample.a));
	}
	#endif

	vec4 detailCol;
	#if !defined(SMF_DETAIL_NORMAL_TEXTURE_SPLATTING) || !defined(SMF_ADV_SHADING)
	{
		detailCol = GetDetailTextureColor(specTexCoords);
	}
	#else
	{
		vec2 splatDetailStrength = vec2(0.0, 0.0);
		vec4 splatDetailNormal = GetSplatDetailTextureNormal(specTexCoords, splatDetailStrength);
		detailCol = vec4(splatDetailStrength.y);
		normal = normalize(mix(normal, normalize(stnMatrix * splatDetailNormal.xyz), splatDetailStrength.x));
	}
	#endif

#if !defined(DEFERRED_MODE) && defined(SMF_ADV_SHADING)
	float cosAngleDiffuse = clamp(dot(lightDir.xyz, normal), 0.0, 1.0);
	float cosAngleSpecular = clamp(dot(normalize(halfDir), normal), 0.001, 1.0);
#endif

	vec4 diffuseCol = texture(diffuseTex, diffTexCoords);
	vec4 terrainCol = diffuseCol + detailCol;

	#ifdef SMF_MACOS_SAFE_DETAIL
		// Apple Silicon under Zink/KosmicKrisp currently shows unstable mid-distance
		// terrain composition. Prefer a stable diffuse-only fallback over black bands.
		terrainCol = diffuseCol;
	#endif

	#ifdef SMF_MACOS_DEBUG_TEXSQUARE
	{
		ivec2 texSquareCoordsI = ivec2(round(texSquareCoords));
		vec3 patchDebug = vec3(
			float((texSquareCoordsI.x & 1) != 0),
			float((texSquareCoordsI.y & 1) != 0),
			float(((texSquareCoordsI.x + texSquareCoordsI.y) & 1) != 0)
		);
		terrainCol.rgb = 0.20 + patchDebug * 0.55;
	}
	#endif

	vec4 specularCol = vec4(0.0, 0.0, 0.0, 1.0);
	vec4 emissionCol = vec4(0.0, 0.0, 0.0, 0.0);

	#if !defined(DEFERRED_MODE) && defined(SMF_SKY_REFLECTIONS)
	{
		vec3 reflectDir = reflect(cameraDir, normal);
		vec3 reflectCol = texture(skyReflectTex, reflectDir).rgb;
		vec3 reflectMod = texture(skyReflectModTex, specTexCoords).rgb;
		diffuseCol.rgb = mix(diffuseCol.rgb, reflectCol, reflectMod);
	}
	#endif

	#if !defined(DEFERRED_MODE) && defined(HAVE_INFOTEX)
	{
		#ifndef SMF_MACOS_SAFE_DETAIL
		diffuseCol.rgb += (texture(infoTex, infoTexCoords).rgb * infoTexIntensityMul);
		diffuseCol.rgb -= (vec3(0.5, 0.5, 0.5) * float(infoTexIntensityMul == 1.0));
		#endif
	}
	#endif

	vec3 shadowCoeff = vec3(1.0);

	#if !defined(DEFERRED_MODE) && defined(HAVE_SHADOWS)
	{
		vec4 vertexShadowPos = shadowMat * vertexWorldPos;
			vertexShadowPos.xy += vec2(0.5);
		vec3 shadowColor = texture(shadowColorTex, vertexShadowPos.xy).rgb;
		shadowCoeff = mix(vec3(1.0), textureProj(shadowTex, vertexShadowPos).r * shadowColor, groundShadowDensity);
	}
	#endif

	#ifndef DEFERRED_MODE
		#ifdef SMF_ADV_SHADING
		{
			vec4 shadeInt = GetShadeInt(cosAngleDiffuse, shadowCoeff, diffuseCol.a);
			fragColor.rgb = terrainCol.rgb * shadeInt.rgb;
			fragColor.a = shadeInt.a;
		}
		#else
		{
			#ifdef SMF_MACOS_SAFE_DETAIL
			fragColor.rgb = max(terrainCol.rgb, vec3(0.05));
			fragColor.a = diffuseCol.a;
			#else
			fragColor.rgb = terrainCol.rgb * texture(shadingTex, specTexCoords).rgb;
			fragColor.a = diffuseCol.a;
			#endif
		}
		#endif
	#endif

	#ifdef SMF_LIGHT_EMISSION
	{
		emissionCol = texture(lightEmissionTex, specTexCoords);
		#ifndef DEFERRED_MODE
		fragColor.rgb = fragColor.rgb * (1.0 - emissionCol.a) + emissionCol.rgb;
		#endif
	}
	#endif

	#ifdef SMF_ADV_SHADING
		#ifdef SMF_SPECULAR_LIGHTING
			specularCol = texture(specularTex, specTexCoords);
		#else
			specularCol = vec4(groundSpecularColor, 1.0);
		#endif

		#ifndef DEFERRED_MODE
			#ifdef SMF_SPECULAR_LIGHTING
				float specularExp  = specularCol.a * 16.0;
			#else
				float specularExp  = groundSpecularExponent;
			#endif
			float specularPow  = pow(cosAngleSpecular, specularExp);
			vec3  specularInt  = specularCol.rgb * specularPow;
				  specularInt *= shadowCoeff;
			fragColor.rgb += specularInt;
		#endif
	#endif

#ifdef DEFERRED_MODE
	fragData[GBUFFER_NORMTEX_IDX] = vec4((normal + vec3(1.0, 1.0, 1.0)) * 0.5, 1.0);
	fragData[GBUFFER_DIFFTEX_IDX] = terrainCol;
	fragData[GBUFFER_SPECTEX_IDX] = specularCol;
	fragData[GBUFFER_EMITTEX_IDX] = emissionCol;
	fragData[GBUFFER_MISCTEX_IDX] = vec4(0.0, 0.0, 0.0, 0.0);
#else
	#ifdef SMF_MACOS_NO_FOG
	fragColor.a = 1.0;
	#else
	fragColor.rgb = mix(fogColor.rgb, fragColor.rgb, fogFactor);
	fragColor.a = 1.0;  // Force alpha=1 for Metal compositor
	#endif
#endif
}
