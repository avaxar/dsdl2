/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.renderer;
@safe:

import bindbc.sdl;
import dsdl2.sdl;
import dsdl2.rect;
import dsdl2.frect;
import dsdl2.pixels;
import dsdl2.surface;
import dsdl2.texture;
import dsdl2.window;

import core.memory : GC;
import std.conv : to;
import std.format : format;
import std.string : toStringz;

/++
 + D enum that wraps `SDL_RendererFlags` in specifying renderer constructions
 +/
enum RendererFlag {
    /++
     + Wraps `SDL_RENDERER_*` enumeration constants
     +/
    software = SDL_RENDERER_SOFTWARE,
    accelerated = SDL_RENDERER_ACCELERATED, /// ditto
    presentVsync = SDL_RENDERER_PRESENTVSYNC, /// ditto
    targetTexture = SDL_RENDERER_TARGETTEXTURE, /// ditto
}

/++
 + D struct that wraps `SDL_RendererInfo` containing renderer information
 +/
struct RendererInfo {
    string name; /// Name of the renderer
    uint sdlFlags; /// Internal SDL bitmask of supported renderer flags
    PixelFormat[] textureFormats; /// Available texture pixel formats
    uint[2] maxTextureSize; /// Maximum texture size

    this() @disable;

    /++
     + Constructs a `dsdl2.RendererInfo` from a vanilla `SDL_RendererInfo` from bindbc-sdl
     +
     + Params:
     +   sdlRendererInfo = the `SDL_RendererInfo` struct
     +/
    this(SDL_RendererInfo sdlRendererInfo) @trusted {
        this.name = sdlRendererInfo.name.to!string.idup;
        this.sdlFlags = sdlRendererInfo.flags;
        this.textureFormats.length = sdlRendererInfo.num_texture_formats;
        foreach (i; 0 .. sdlRendererInfo.num_texture_formats) {
            this.textureFormats[i] = new PixelFormat(sdlRendererInfo.texture_formats[i]);
        }
        this.maxTextureSize = [
            sdlRendererInfo.max_texture_width.to!uint,
            sdlRendererInfo.max_texture_height.to!uint
        ];
    }

    /++
     + Constructs a `dsdl2.RendererInfo` by feeding it its attributes
     +
     + Params:
     +   name           = name of the renderer
     +   flags          = array of `dsdl2.RendererFlag`s, specifying available renderer flags
     +   textureFormats = available texture pixel format(s)
     +   maxTextureSize = maximum size a texture can be
     +/
    this(string name, const RendererFlag[] flags, PixelFormat[] textureFormats, uint[2] maxTextureSize) @trusted {
        this.name = name;
        foreach (flag; flags) {
            this.sdlFlags |= flag;
        }
        this.textureFormats = textureFormats;
        this.maxTextureSize = maxTextureSize;
    }

    /++
     + Formats the `dsdl2.RendererInfo` into its construction representation:
     + `"dsdl2.RendererInfo(<name>, <flags>, <textureFormats>, <maxTextureSize>)"`
     +
     + Returns: the formatted `string`
     +/
    string toString() const {
        return "dsdl2.RendererInfo(%s, %s, %s, %s)".format([this.name].to!string[1 .. $ - 1], this.flags,
            this.textureFormats, this.maxTextureSize);
    }

    /++
     + Gets the internal `SDL_RendererInfo` representation
     +
     + Returns: `SDL_RendererInfo` with all of the attributes
     +/
    inout(SDL_RendererInfo) sdlRendererInfo() inout @property {
        uint[16] textureFormatEnums = void;
        foreach (i, inout textureFormat; this.textureFormats) {
            textureFormatEnums[i] = textureFormat.sdlPixelFormatEnum;
        }

        return inout SDL_RendererInfo(this.name.toStringz(), this.sdlFlags, this.textureFormats.length.to!uint,
            textureFormatEnums, this.maxTextureWidth, this.maxTextureHeight);
    }

    /++
     + Gets the available renderer flags
     +
     + Returns: array of the available `dsdl2.RendererFlag`s
     +/
    const(RendererFlag[]) flags() const @property {
        RendererFlag[] flags;
        foreach (flagStr; __traits(allMembers, RendererFlag)) {
            RendererFlag flag = mixin("RendererFlag." ~ flagStr);
            if ((this.sdlFlags & flag) == flag) {
                flags ~= flag;
            }
        }

        return flags;
    }

    /++
     + Sets the available renderer flags
     +
     + Params:
     +   newFlags = new array of the available `dsdl2.RendererFlag`s
     +/
    void flags(const RendererFlag[] newFlags) @property {
        this.sdlFlags = 0;
        foreach (flag; newFlags) {
            this.sdlFlags |= flag;
        }
    }

    /++
     + Proxy to the maximum texture width of the `dsdl2.RendererInfo`
     +
     + Returns: maximum texture width of the `dsdl2.RendererInfo`
     +/
    ref inout(uint) maxTextureWidth() return inout @property {
        return this.maxTextureSize[0];
    }

    /++
     + Proxy to the maximum texture height of the `dsdl2.RendererInfo`
     +
     + Returns: maximum texture height of the `dsdl2.RendererInfo`
     +/
    ref inout(uint) maxTextureHeight() return inout @property {
        return this.maxTextureSize[1];
    }
}

/++
 + D class that acts as a proxy for a render driver from a render driver index
 +/
final class RenderDriver {
    const uint sdlRenderDriverIndex; /// Render driver index from SDL
    const RendererInfo rendererInfo = void; /// `dsdl2.RendererInfo` instance fetched from the driver
    alias rendererInfo this;

    this() @disable;

    private this(uint sdlRenderDriverIndex) @trusted {
        this.sdlRenderDriverIndex = sdlRenderDriverIndex;

        SDL_RendererInfo sdlRendererInfo;
        if (SDL_GetRenderDriverInfo(sdlRenderDriverIndex.to!int, &sdlRendererInfo) != 0) {
            throw new SDLException;
        }

        this.rendererInfo = RendererInfo(sdlRendererInfo);
    }

    /++
     + Formats the `dsdl2.RenderDriver` into its construction representation:
     + `"dsdl2.RenderDriver(<sdlRenderDriverIndex>)"`
     +
     + Returns: the formatted `string`
     +/
    override string toString() const {
        return "dsdl2.RenderDriver(%d)".format(this.sdlRenderDriverIndex);
    }
}

/++
 + Gets `dsdl2.RenderDriver` proxy instances of the available render drivers in the system
 +
 + Returns: array of proxies to the available `dsdl2.RenderDriver`s
 + Throws: `dsdl2.SDLException` if failed to get the available render drivers
 +/
const(RenderDriver[]) getRenderDrivers() @trusted {
    int numDrivers = SDL_GetNumRenderDrivers();
    if (numDrivers < 0) {
        throw new SDLException;
    }

    static RenderDriver[] drivers;
    if (drivers !is null) {
        drivers.length = numDrivers;
        if (numDrivers > drivers.length) {
            foreach (i; drivers.length .. numDrivers) {
                drivers[i] = new RenderDriver(i.to!uint);
            }
        }
    }
    else {
        drivers = new RenderDriver[](numDrivers);
        foreach (i; 0 .. numDrivers) {
            drivers[i] = new RenderDriver(i);
        }
    }

    return drivers;
}

/++
 + D class that wraps `SDL_Renderer` managing a backend rendering instance
 +/
final class Renderer {
    private bool isOwner = true;
    private void* userRef = null;

    @system SDL_Renderer* sdlRenderer = null; /// Internal `SDL_Renderer` pointer

    /++
     + Constructs a `dsdl2.Renderer` from a vanilla `SDL_Renderer*` from bindbc-sdl
     +
     + Params:
     +   sdlRenderer = the `SDL_Renderer` pointer to manage
     +   isOwner     = whether the instance owns the given `SDL_Renderer*` and should destroy it on its own
     +   userRef     = optional pointer to maintain reference link, avoiding GC cleanup
     +/
    this(SDL_Renderer* sdlRenderer, bool isOwner = true, void* userRef = null) @system
    in {
        assert(sdlRenderer !is null);
    }
    do {
        this.sdlRenderer = sdlRenderer;
        this.isOwner = isOwner;
        this.userRef = userRef;
    }

    /++
     + Creates a hardware `dsdl2.Renderer` that renders to a `dsdl2.Window`, which wraps `SDL_CreateRenderer`
     +
     + Params:
     +   window       = target `dsdl2.Window` for the renderer to draw onto
     +   renderDriver = the `dsdl2.RenderDriver` to use; `null` to use the default
     +   flags        = optional flags given to the renderer
     +/
    this(Window window, const RenderDriver renderDriver = null, const RendererFlag[] flags = null) @trusted
    in {
        assert(window !is null);
    }
    do {
        uint intFlags;
        foreach (flag; flags) {
            intFlags |= flag;
        }

        this.sdlRenderer = SDL_CreateRenderer(window.sdlWindow,
            renderDriver is null ? -1 : renderDriver.sdlRenderDriverIndex.to!uint, intFlags);
        if (this.sdlRenderer is null) {
            throw new SDLException;
        }
    }

    /++
     + Creates a software `dsdl2.Renderer` that renders to a target surface, which wraps `SDL_CreateSoftwareRenderer`
     +
     + Params:
     +   surface = `dsdl2.Surface` to be the target of rendering
     +/
    this(Surface surface) @trusted
    in {
        assert(surface !is null);
    }
    do {
        this.sdlRenderer = SDL_CreateSoftwareRenderer(surface.sdlSurface);
        if (this.sdlRenderer is null) {
            throw new SDLException;
        }

        this.userRef = cast(void*) surface;
    }

    ~this() @trusted {
        if (this.isOwner) {
            SDL_DestroyRenderer(this.sdlRenderer);
        }
    }

    @trusted invariant {
        // Instance might be in an invalid state due to holding a non-owned externally-freed object when
        // destructed in an unpredictable order.
        if (!this.isOwner && GC.inFinalizer) {
            return;
        }

        assert(this.sdlRenderer !is null);
    }

    /++
     + Equality operator overload
     +/
    bool opEquals(const Renderer rhs) const @trusted {
        return this.sdlRenderer == rhs.sdlRenderer;
    }

    /++
     + Gets the hash of the `dsdl2.Renderer`
     +
     + Returns: unique hash for the instance being the pointer of the internal `SDL_Renderer` pointer
     +/
    override hash_t toHash() const @trusted {
        return cast(hash_t) this.sdlRenderer;
    }

    /++
     + Formats the `dsdl2.Renderer` into its construction representation: `"dsdl2.Renderer(<sdlRenderer>)"`
     +
     + Returns: the formatted `string`
     +/
    override string toString() const @trusted {
        return "dsdl2.Renderer(0x%x)".format(this.sdlRenderer);
    }
}
