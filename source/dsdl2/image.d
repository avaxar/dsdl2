/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.image;
@safe:

// dfmt off
import bindbc.sdl;
static if (bindSDLImage):
// dfmt on

import dsdl2.sdl;
import dsdl2.renderer;
import dsdl2.surface;
import dsdl2.texture;

import std.conv : to;
import std.format : format;
import std.string : toStringz;

version (BindSDL_Static) {
}
else {
    void loadSO(string libName = null) @trusted {
        SDLImageSupport current = libName is null ? loadSDLImage() : loadSDLImage(libName.toStringz());
        if (current == sdlImageSupport) {
            return;
        }

        Version wanted = Version(sdlImageSupport);
        if (current == SDLImageSupport.badLibrary) {
            import std.stdio : writeln;

            writeln("WARNING: dsdl2 expects SDL_image ", wanted.format(), ", but got ", getVersion().format(), ".");
        }
        else if (current == SDLImageSupport.noLibrary) {
            throw new SDLException("No SDL2_image library found, especially of version " ~ wanted.format(),
                __FILE__, __LINE__);
        }
    }
}

void init(bool jpg = false, bool png = false, bool tif = false, bool webp = false, bool jxl = false, bool avif = false,
    bool everything = false) @trusted
in {
    static if (sdlImageSupport >= SDLImageSupport.v2_6) {
        assert(jxl == false);
        assert(avif == false);
    }
    else {
        if (jxl || avif) {
            assert(dsdl2.image.getVersion() >= Version(2, 6));
        }
    }
}
do {
    int flags = 0;

    flags |= jpg ? IMG_INIT_JPG : 0;
    flags |= png ? IMG_INIT_PNG : 0;
    flags |= tif ? IMG_INIT_TIF : 0;
    flags |= webp ? IMG_INIT_WEBP : 0;
    flags |= everything ? IMG_INIT_JPG | IMG_INIT_PNG | IMG_INIT_TIF | IMG_INIT_WEBP : 0;

    static if (sdlImageSupport >= SDLImageSupport.v2_6) {
        flags |= jxl ? IMG_INIT_JXL : 0;
        flags |= avif ? IMG_INIT_AVIF : 0;
        flags |= everything ? IMG_INIT_JXL | IMG_INIT_AVIF : 0;
    }

    if (IMG_Init(flags) != 0) {
        throw new SDLException;
    }
}

void quit() @trusted {
    IMG_Quit();
}

Version getVersion() @trusted {
    return Version(*IMG_Linked_Version());
}

Surface load(string file) @trusted {
    if (SDL_Surface* sdlSurface = IMG_Load(file.toStringz())) {
        return new Surface(sdlSurface);
    }
    else {
        throw new SDLException;
    }
}

Surface loadRaw(const void[] data) @trusted {
    SDL_RWops* sdlRWops = SDL_RWFromConstMem(data.ptr, data.length.to!int);
    if (sdlRWops is null) {
        throw new SDLException;
    }

    if (SDL_Surface* sdlSurface = IMG_Load_RW(sdlRWops, 1)) {
        return new Surface(sdlSurface);
    }
    else {
        throw new SDLException;
    }
}

Surface loadTypedRaw(const void[] data, string type) @trusted {
    SDL_RWops* sdlRWops = SDL_RWFromConstMem(data.ptr, data.length.to!int);
    if (sdlRWops is null) {
        throw new SDLException;
    }

    if (SDL_Surface* sdlSurface = IMG_LoadTyped_RW(sdlRWops, 1, type.toStringz())) {
        return new Surface(sdlSurface);
    }
    else {
        throw new SDLException;
    }
}

Texture loadTexture(Renderer renderer, string file) @trusted
in {
    assert(renderer !is null);
}
do {
    if (SDL_Texture* sdlTexture = IMG_LoadTexture(renderer.sdlRenderer, file.toStringz())) {
        return new Texture(sdlTexture);
    }
    else {
        throw new SDLException;
    }
}

Texture loadTextureRaw(Renderer renderer, const void[] data) @trusted
in {
    assert(renderer !is null);
}
do {
    SDL_RWops* sdlRWops = SDL_RWFromConstMem(data.ptr, data.length.to!int);
    if (sdlRWops is null) {
        throw new SDLException;
    }

    if (SDL_Texture* sdlTexture = IMG_LoadTexture_RW(renderer.sdlRenderer, sdlRWops, 1)) {
        return new Texture(sdlTexture);
    }
    else {
        throw new SDLException;
    }
}

Texture loadTextureTypedRaw(Renderer renderer, const void[] data, string type) @trusted
in {
    assert(renderer !is null);
}
do {
    SDL_RWops* sdlRWops = SDL_RWFromConstMem(data.ptr, data.length.to!int);
    if (sdlRWops is null) {
        throw new SDLException;
    }

    if (SDL_Texture* sdlTexture = IMG_LoadTextureTyped_RW(renderer.sdlRenderer, sdlRWops, 1, type.toStringz())) {
        return new Texture(sdlTexture);
    }
    else {
        throw new SDLException;
    }
}

bool _isType(alias func, ubyte minMinorVer = 0, ubyte minPatchVer = 0)(const void[] data) @trusted
in {
    assert(dsdl2.image.getVersion() >= Version(2, minMinorVer, minPatchVer));
}
do {
    SDL_RWops* sdlRWops = SDL_RWFromConstMem(data.ptr, data.length.to!int);
    if (sdlRWops is null) {
        throw new SDLException;
    }
    scope (exit)
        if (SDL_RWclose(sdlRWops) != 0) {
            throw new SDLException;
        }

    return func(sdlRWops) != 0;
}

alias isICO = _isType!IMG_isICO; /// Wraps `IMG_isICO` which checks whether `data` is an ICO file
alias isCUR = _isType!IMG_isCUR; /// Wraps `IMG_isCUR` which checks whether `data` is a CUR file
alias isBMP = _isType!IMG_isBMP; /// Wraps `IMG_isBMP` which checks whether `data` is a BMP file
alias isGIF = _isType!IMG_isGIF; /// Wraps `IMG_isGIF` which checks whether `data` is a GIF file
alias isJPG = _isType!IMG_isJPG; /// Wraps `IMG_isJPG` which checks whether `data` is a JPG file
alias isLBM = _isType!IMG_isLBM; /// Wraps `IMG_isLBM` which checks whether `data` is a LBM file
alias isPCX = _isType!IMG_isPCX; /// Wraps `IMG_isPCX` which checks whether `data` is a PCX file
alias isPNG = _isType!IMG_isPNG; /// Wraps `IMG_isPNG` which checks whether `data` is a PNG file
alias isPNM = _isType!IMG_isPNM; /// Wraps `IMG_isPNM` which checks whether `data` is a PNM file
alias isTIF = _isType!IMG_isTIF; /// Wraps `IMG_isTIF` which checks whether `data` is a TIF file
alias isXCF = _isType!IMG_isXCF; /// Wraps `IMG_isXCF` which checks whether `data` is an XCF file
alias isXPM = _isType!IMG_isXPM; /// Wraps `IMG_isXPM` which checks whether `data` is an XPM file
alias isXV = _isType!IMG_isXV; /// Wraps `IMG_isXV` which checks whether `data` is an XV file
alias isWEBP = _isType!IMG_isWEBP; /// Wraps `IMG_isWEBP` which checks whether `data` is a WEBP file

static if (sdlImageSupport >= SDLImageSupport.v2_0_2) {
    alias isSVG = _isType!(IMG_isSVG, 0, 2); /// Wraps `IMG_isSVG` which checks whether `data` is a SVG file (from SDL_image 2.0.2)
}

static if (sdlImageSupport >= SDLImageSupport.v2_6) {
    alias isAVIF = _isType!(IMG_isAVIF, 6); /// Wraps `IMG_isAVIF` which checks whether `data` is an AVIF file (from SDL_image 2.6)
    alias isJXL = _isType!(IMG_isJXL, 6); /// Wraps `IMG_isJXL` which checks whether `data` is a JXL file (from SDL_image 2.6)
    alias isQOI = _isType!(IMG_isQOI, 6); /// Wraps `IMG_isQOI` which checks whether `data` is a QOI file (from SDL_image 2.6)
}

Surface _loadTypeRaw(alias func, ubyte minMinorVer = 0, ubyte minPatchVer = 0)(const void[] data) @trusted
in {
    assert(dsdl2.image.getVersion() >= Version(2, minMinorVer, minPatchVer));
}
do {
    SDL_RWops* sdlRWops = SDL_RWFromConstMem(data.ptr, data.length.to!int);
    if (sdlRWops is null) {
        throw new SDLException;
    }
    scope (exit)
        if (SDL_RWclose(sdlRWops) != 0) {
            throw new SDLException;
        }

    if (SDL_Surface* sdlSurface = func(sdlRWops)) {
        return new Surface(sdlSurface);
    }
    else {
        throw new SDLException;
    }
}

alias loadICORaw = _loadTypeRaw!IMG_LoadICO_RW; /// Wraps `IMG_LoadICO_RW` which loads `data` as an ICO image to surface
alias loadCURRaw = _loadTypeRaw!IMG_LoadCUR_RW; /// Wraps `IMG_LoadCUR_RW` which loads `data` as a CUR image to surface
alias loadBMPRaw = _loadTypeRaw!IMG_LoadBMP_RW; /// Wraps `IMG_LoadBMP_RW` which loads `data` as a BMP image to surface
alias loadGIFRaw = _loadTypeRaw!IMG_LoadGIF_RW; /// Wraps `IMG_LoadGIF_RW` which loads `data` as a GIF image to surface
alias loadJPGRaw = _loadTypeRaw!IMG_LoadJPG_RW; /// Wraps `IMG_LoadJPG_RW` which loads `data` as a JPG image to surface
alias loadLBRaw = _loadTypeRaw!IMG_LoadLBM_RW; /// Wraps `IMG_LoadLBM_RW` which loads `data` as a LBM image to surface
alias loadPCXRaw = _loadTypeRaw!IMG_LoadPCX_RW; /// Wraps `IMG_LoadPCX_RW` which loads `data` as a PCX image to surface
alias loadPNGRaw = _loadTypeRaw!IMG_LoadPNG_RW; /// Wraps `IMG_LoadPNG_RW` which loads `data` as a PNG image to surface
alias loadPNMRaw = _loadTypeRaw!IMG_LoadPNM_RW; /// Wraps `IMG_LoadPNM_RW` which loads `data` as a PNM image to surface
alias loadTIFRaw = _loadTypeRaw!IMG_LoadTIF_RW; /// Wraps `IMG_LoadTIF_RW` which loads `data` as a TIF image to surface
alias loadXCFRaw = _loadTypeRaw!IMG_LoadXCF_RW; /// Wraps `IMG_LoadXCF_RW` which loads `data` as an XCF image to surface
alias loadXPMRaw = _loadTypeRaw!IMG_LoadXPM_RW; /// Wraps `IMG_LoadXPM_RW` which loads `data` as an XPM image to surface
alias loadXVRaw = _loadTypeRaw!IMG_LoadXV_RW; /// Wraps `IMG_LoadXV_RW` which loads `data` as an XV image as surface
alias loadWEBPRaw = _loadTypeRaw!IMG_LoadWEBP_RW; /// Wraps `IMG_LoadWEBP_RW` which loads `data` as a WEBP image to surface

static if (sdlImageSupport >= SDLImageSupport.v2_0_2) {
    alias loadSVGRaw = _loadTypeRaw!(IMG_LoadSVG_RW, 0, 2); /// Wraps `IMG_LoadSVG_RW` which loads `data` as a SVG image (from SDL_image 2.0.2)
}

static if (sdlImageSupport >= SDLImageSupport.v2_6) {
    alias loadAVIFRaw = _loadTypeRaw!(IMG_LoadAVIF_RW, 6); /// Wraps `IMG_LoadAVIF_RW` which loads `data` as an AVIF image (from SDL_image 2.6)
    alias loadJXLRaw = _loadTypeRaw!(IMG_LoadJXL_RW, 6); /// Wraps `IMG_LoadJXL_RW` which loads `data` as a JXL image (from SDL_image 2.6)
    alias loadQOIRaw = _loadTypeRaw!(IMG_LoadQOI_RW, 6); /// Wraps `IMG_LoadQOI_RW` which loads `data` as a QOI image (from SDL_image 2.6)
}

void savePNG(Surface surface, string file) @trusted
in {
    assert(surface !is null);
}
do {
    if (IMG_SavePNG(surface.sdlSurface, file.toStringz()) != 0) {
        throw new SDLException;
    }
}

void[] savePNGRaw(Surface surface) @trusted
in {
    assert(surface !is null);
}
do {
    assert(false, "Not implemented");
}

static if (sdlImageSupport >= SDLImageSupport.v2_0_2) {
    void saveJPG(Surface surface, string file, ubyte quality) @trusted
    in {
        assert(dsdl2.image.getVersion() >= Version(2, 0, 2));
        assert(surface !is null);
    }
    do {
        if (IMG_SaveJPG(surface.sdlSurface, file.toStringz(), quality) != 0) {
            throw new SDLException;
        }
    }

    void[] saveJPGRaw(Surface surface) @trusted
    in {
        assert(dsdl2.image.getVersion() >= Version(2, 0, 2));
        assert(surface !is null);
    }
    do {
        assert(false, "Not implemented");
    }
}
