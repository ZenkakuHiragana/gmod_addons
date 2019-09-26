AddCSLuaFile()
local TEXTUREFLAGS = include "textureflags.lua"
local MINIMUM   = 0 -- 2048x2048,       32MB
local SMALL     = 1 -- 4096x4096,       128MB
local DSMALL    = 2 -- 2x4096x4096,     256MB
local MEDIUM    = 3 -- 8192x8192,       512MB
local DMEDIUM   = 4 -- 2x8192x8192,     1GB 
local LARGE     = 5 -- 16384x16384,     2GB
local DLARGE    = 6 -- 2x16384x16384,   4GB
local ULTRA     = 7 -- 32768x32768,     8GB
local DULTRA    = 8 -- 2x32768x32768,   16GB
return {
	RESOLUTION = {
		MINIMUM = MINIMUM,
		SMALL   = SMALL,
		DSMALL  = DSMALL,
		MEDIUM  = MEDIUM,
		DMEDIUM = DMEDIUM,
		LARGE   = LARGE,
		DLARGE  = DLARGE,
		ULTRA   = ULTRA,
		DULTRA  = ULTRA,
	},
	Size = {
		[MINIMUM] = 2048,
		[SMALL  ] = 4096,
		[DSMALL ] = 5792,
		[MEDIUM ] = 8192,
		[DMEDIUM] = 11585,
		[LARGE  ] = 16384,
		[DLARGE ] = 23170,
		[ULTRA  ] = 32768,
		[DULTRA ] = 40132,
	},
	Name = {
		BaseTexture			= "splatoonsweps_basetexture",
		InkSplash			= "splatoonsweps_inksplash",
		InkSplashMaterial	= "splatoonsweps_inksplashmaterial",
		Lightmap			= "splatoonsweps_lightmap",
		Normalmap			= "splatoonsweps_normalmap",
		RenderTarget		= "splatoonsweps_rendertarget",
		RTScope				= "splatoonsweps_rtscope",
		WaterMaterial		= "splatoonsweps_watermaterial",
	},
	Flags = {
		BaseTexture = bit.bor(
			TEXTUREFLAGS.NOMIP,
			TEXTUREFLAGS.NOLOD,
			TEXTUREFLAGS.ALL_MIPS,
			TEXTUREFLAGS.PROCEDURAL,
			TEXTUREFLAGS.RENDERTARGET,
			TEXTUREFLAGS.NODEPTHBUFFER
		),
		Normalmap = bit.bor(
			TEXTUREFLAGS.NORMAL,
			TEXTUREFLAGS.NOMIP,
			TEXTUREFLAGS.NOLOD,
			TEXTUREFLAGS.ALL_MIPS,
			TEXTUREFLAGS.PROCEDURAL,
			TEXTUREFLAGS.RENDERTARGET,
			TEXTUREFLAGS.NODEPTHBUFFER,
			TEXTUREFLAGS.SSBUMP
		),
		Lightmap = bit.bor(
			TEXTUREFLAGS.NOMIP,
			TEXTUREFLAGS.NOLOD,
			TEXTUREFLAGS.ALL_MIPS,
			TEXTUREFLAGS.PROCEDURAL,
			TEXTUREFLAGS.RENDERTARGET,
			TEXTUREFLAGS.NODEPTHBUFFER
		),
		InkSplash = bit.bor(
			TEXTUREFLAGS.EIGHTBITALPHA,
			TEXTUREFLAGS.NOMIP,
			TEXTUREFLAGS.NOLOD,
			TEXTUREFLAGS.ALL_MIPS,
			TEXTUREFLAGS.PROCEDURAL,
			TEXTUREFLAGS.RENDERTARGET,
			TEXTUREFLAGS.NODEPTHBUFFER
		),
	},
}
