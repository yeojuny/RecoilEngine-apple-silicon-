/* This file is part of the Spring engine (GPL v2 or later), see LICENSE.html */

#pragma once

#include <cstdlib>
#include <string_view>

namespace BaronMetalParticleFlags
{
inline bool EnvFlagEnabled(const char* name)
{
#if defined(__APPLE__)
	const char* value = std::getenv(name);
	return (value != nullptr) && (value[0] == '1') && (value[1] == '\0');
#else
	return false;
#endif
}

inline bool CleanSmokeFx()
{
	return EnvFlagEnabled("BARONMETAL_CLEAN_SMOKE_FX");
}

inline bool CleanUnitMoveFx()
{
	return EnvFlagEnabled("BARONMETAL_CLEAN_UNIT_MOVE_FX");
}

inline bool SkipSimpleParticles()
{
	return CleanSmokeFx() || EnvFlagEnabled("BARONMETAL_SKIP_SIMPLE_PARTICLES");
}

inline bool EnableSimpleParticles()
{
	return EnvFlagEnabled("BARONMETAL_ENABLE_SIMPLE_PARTICLES");
}

inline bool ParticlePremultiplyAlpha()
{
	return EnvFlagEnabled("BARONMETAL_PARTICLE_PREMULTIPLY_ALPHA");
}

inline bool ParticleSrcAlphaBlend()
{
	return EnvFlagEnabled("BARONMETAL_PARTICLE_SRC_ALPHA_BLEND");
}

inline bool ParticleAlphaClip()
{
	return EnvFlagEnabled("BARONMETAL_PARTICLE_ALPHA_CLIP");
}

inline bool ParticleNoMipmaps()
{
	return EnvFlagEnabled("BARONMETAL_PARTICLE_NO_MIPMAPS");
}

inline bool SkipSmokeBillboards()
{
	return CleanSmokeFx() || EnvFlagEnabled("BARONMETAL_SKIP_SMOKE_BILLBOARDS");
}

inline bool EnableSmokeBillboards()
{
	return EnvFlagEnabled("BARONMETAL_ENABLE_SMOKE_BILLBOARDS");
}

inline bool SkipDirtParticles()
{
	return CleanSmokeFx() || EnvFlagEnabled("BARONMETAL_SKIP_DIRT_PARTICLES");
}

inline bool EnableDirtParticles()
{
	return EnvFlagEnabled("BARONMETAL_ENABLE_DIRT_PARTICLES");
}

inline bool SkipHeatClouds()
{
	return CleanSmokeFx() || EnvFlagEnabled("BARONMETAL_SKIP_HEATCLOUDS");
}

inline bool EnableHeatClouds()
{
	return EnvFlagEnabled("BARONMETAL_ENABLE_HEATCLOUDS");
}

inline bool SkipBitmapMuzzleFlames()
{
	return CleanSmokeFx() || CleanUnitMoveFx() || EnvFlagEnabled("BARONMETAL_SKIP_BITMAP_MUZZLE_FLAMES");
}

inline bool SkipMuzzleFlames()
{
	return CleanSmokeFx() || EnvFlagEnabled("BARONMETAL_SKIP_MUZZLE_FLAMES");
}

inline bool SkipBubbles()
{
	return CleanSmokeFx() || EnvFlagEnabled("BARONMETAL_SKIP_BUBBLES");
}

inline bool IsBubbleTexture(std::string_view name)
{
	return (name.find("bubble") != std::string_view::npos) || (name == "subwake") || (name == "subwak");
}
}
