/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.renderer;
@safe:

import bindbc.sdl;
import dsdl2.sdl;
import dsdl2.blend;
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
import std.typecons : Nullable, nullable;

/++
 + D enum that wraps `SDL_RendererFlags` in specifying renderer constructions
 +/
enum RendererFlag {
    /++
     + Wraps `SDL_RENDERER_*` enumeration constants
     +/
    software = SDL_RENDERER_SOFTWARE,
    accelerated = SDL_RENDERER_ACCELERATED, /// ditto
    presentVSync = SDL_RENDERER_PRESENTVSYNC, /// ditto
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

static if (sdlSupport >= SDLSupport.v2_0_18) {
    /++
     + D struct that wraps `SDL_Vertex` (from SDL 2.0.18) containing 2D vertex information
     +
     + `dsdl2.Vertex` stores the `position` of the vertex, `color` modulation (as well as alpha), and mapped texture
     + `texCoord`inate.
     +/
    struct Vertex {
        SDL_Vertex sdlVertex; /// Internal `SDL_Vertex` struct

        this() @disable;

        /++
         + Constructs a `dsdl2.Vertex` from a vanilla `SDL_Vertex` from bindbc-sdl
         +
         + Params:
         +   sdlVertex = the `dsdl2.Vertex` struct
         +/
        this(SDL_Vertex sdlVertex) {
            this.sdlVertex = sdlVertex;
        }

        /++
         + Constructs a `dsdl2.Vertex` by feeding in the position, color, and texture coordinate
         +
         + Params:
         +   position = vertex target position
         +   color    = color and alpha modulation of the vertex
         +   texCoord = vertex texture coordinate
         +/
        this(FPoint position, Color color, FPoint texCoord) {
            this.sdlVertex.position = position.sdlFPoint;
            this.sdlVertex.color = color.sdlColor;
            this.sdlVertex.tex_coord = texCoord.sdlFPoint;
        }

        /++
         + Formats the `dsdl2.Vertex` into its construction representation:
         + `"dsdl2.Vertex(<position>, <color>, <texCoord>)"`
         +
         + Returns: the formatted `string`
         +/
        string toString() const {
            return "dsdl2.Vertex(%f, %f)".format(this.position, this.color, this.texCoord);
        }

        /++
         + Proxy to the X position of the `dsdl2.Vertex`
         +
         + Returns: X position of the `dsdl2.Vertex`
         +/
        ref inout(float) x() return inout @property {
            return this.sdlVertex.position.x;
        }

        /++
         + Proxy to the Y position of the `dsdl2.Vertex`
         +
         + Returns: Y position of the `dsdl2.Vertex`
         +/
        ref inout(float) y() return inout @property {
            return this.sdlVertex.position.y;
        }

        /++
         + Proxy to the position of the `dsdl2.Vertex`
         +
         + Returns: position of the `dsdl2.Vertex`
         +/
        ref inout(FPoint) position() return inout @property {
            return *cast(inout(FPoint*))&this.sdlVertex.position;
        }

        /++
         + Proxy to the color of the `dsdl2.Vertex`
         +
         + Returns: color of the `dsdl2.Vertex`
         +/
        ref inout(Color) color() return inout @property {
            return *cast(inout(Color*))&this.sdlVertex.color;
        }

        /++
         + Proxy to the X texture coordinate of the `dsdl2.Vertex`
         +
         + Returns: X texture coordinate of the `dsdl2.Vertex`
         +/
        ref inout(float) texX() return inout @property {
            return this.sdlVertex.tex_coord.x;
        }

        /++
         + Proxy to the Y texture coordinate of the `dsdl2.Vertex`
         +
         + Returns: Y texture coordinate of the `dsdl2.Vertex`
         +/
        ref inout(float) texY() return inout @property {
            return this.sdlVertex.tex_coord.y;
        }

        /++
         + Proxy to the texture coordinate of the `dsdl2.Vertex`
         +
         + Returns: texture coordinate of the `dsdl2.Vertex`
         +/
        ref inout(FPoint) texCoord() return inout @property {
            return *cast(inout(FPoint*))&this.sdlVertex.tex_coord;
        }
    }
}

/++
 + D class that wraps `SDL_Renderer` managing a backend rendering instance
 +
 + `dsdl2.Renderer` provides access to 2D draw commands, which accesses the internal backend renderer. The output/target
 + of the renderer can be displayed to a `dsdl2.Window` if desired, or be done in software to the RAM as a
 + `dsdl2.Surface`.
 +
 + Examples:
 + ---
 + auto window = new dsdl2.Window("My Window", [dsdl2.WindowPos.centered, dsdl2.WindowPos.centered], [800, 600]);
 + auto renderer = new dsdl2.Renderer(window, flags:
 +     [dsdl2.RendererFlag.accelerated, dsdl2.RendererFlag.presentVSync]);
 + ---
 +/
final class Renderer {
    private Texture targetProxy = null;
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
     +   window       = target `dsdl2.Window` for the renderer to draw onto which must not have a surface associated
     +   renderDriver = the `dsdl2.RenderDriver` to use; `null` to use the default
     +   flags        = optional flags given to the renderer
     + Throws: `dsdl2.SDLException` if creation failed
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
     + Throws: `dsdl2.SDLException` if creation failed
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
        return this.sdlRenderer is rhs.sdlRenderer;
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

    /++
     + Wraps `SDL_GetRendererInfo` which gets the renderer information
     +
     + Returns: `dsdl2.RendererInfo` of the renderer
     + Throws: `dsdl2.SDLException` if failed to get the renderer information
     +/
    RendererInfo info() const @property @trusted {
        SDL_RendererInfo sdlRendererInfo = void;
        if (SDL_GetRendererInfo(cast(SDL_Renderer*) this.sdlRenderer, &sdlRendererInfo) != 0) {
            throw new SDLException;
        }

        return RendererInfo(sdlRendererInfo);
    }

    /++
     + Wraps `SDL_GetRendererOutputSize` which gets the renderer output's width
     +
     + Returns: drawable width of the renderer's output/target
     + Throws: `dsdl2.SDLException` if failed to get the renderer output width
     +/
    uint width() const @property @trusted {
        uint w = void;
        if (SDL_GetRendererOutputSize(cast(SDL_Renderer*) this.sdlRenderer, cast(int*) w, null) != 1) {
            throw new SDLException;
        }

        return w;
    }

    /++
     + Wraps `SDL_GetRendererOutputSize` which gets the renderer output's height
     +
     + Returns: drawable height of the renderer's output/target
     + Throws: `dsdl2.SDLException` if failed to get the renderer output height
     +/
    uint height() const @property @trusted {
        uint h = void;
        if (SDL_GetRendererOutputSize(cast(SDL_Renderer*) this.sdlRenderer, null, cast(int*) h) != 1) {
            throw new SDLException;
        }

        return h;
    }

    /++
     + Wraps `SDL_GetRendererOutputSize` which gets the renderer output's size
     +
     + Returns: drawable size of the renderer's output/target
     + Throws: `dsdl2.SDLException` if failed to get the renderer output size
     +/
    uint[2] size() const @property @trusted {
        uint[2] xy = void;
        if (SDL_GetRendererOutputSize(cast(SDL_Renderer*) this.sdlRenderer, cast(int*) xy[0],
                cast(int*) xy[1]) != 1) {
            throw new SDLException;
        }

        return xy;
    }

    /++
     + Wraps `SDL_RenderTargetSupported` which checks if the renderer supports texture targets
     +
     + Returns: `true` if the renderer supports, otherwise `false`
     +/
    bool supportsTarget() const @property @trusted {
        return SDL_RenderTargetSupported(cast(SDL_Renderer*) this.sdlRenderer) == SDL_TRUE;
    }

    /++
     + Wraps `SDL_GetRenderTarget` which gets the renderer's target
     +
     + Returns: `null` if the renderer uses the default target (usually the window), otherwise a `dsdl2.Texture`
     +          proxy to the the set texture target
     +/
    inout(Texture) target() inout @property @trusted {
        SDL_Texture* targetPtr = SDL_GetRenderTarget(cast(SDL_Renderer*) this.sdlRenderer);
        if (targetPtr is null) {
            (cast(Renderer) this).targetProxy = null;
        }
        else {
            // If the target texture pointer happens to change, rewire the proxy.
            if (this.targetProxy is null || this.targetProxy.sdlTexture !is targetPtr) {
                (cast(Renderer) this).targetProxy = new Texture(targetPtr);
            }
        }

        return this.targetProxy;
    }

    /++
     + Wraps `SDL_SetRenderTarget` which sets the renderer's target
     +
     + Params:
     +   newTarget = `null` to set the target to be the default target (usually the window), or a valid
     +               target `dsdl2.Texture` as the texture target
     + Throws: `dsdl2.SDLException` if failed to set the renderer's target
     +/
    void target(Texture newTarget) @property @trusted {
        if (newTarget is null) {
            if (SDL_SetRenderTarget(cast(SDL_Renderer*) this.sdlRenderer, null) != 0) {
                throw new SDLException;
            }
        }
        else {
            if (SDL_SetRenderTarget(cast(SDL_Renderer*) this.sdlRenderer, newTarget.sdlTexture) != 0) {
                throw new SDLException;
            }
        }
    }

    /++
     + Wraps `SDL_RenderGetClipRect` which gets the clipping `dsdl2.Rect` of the renderer
     +
     + Returns: clipping `dsdl2.Rect` of the renderer
     +/
    Rect clipRect() const @property @trusted {
        Rect rect = void;
        SDL_RenderGetClipRect(cast(SDL_Renderer*) this.sdlRenderer, &rect.sdlRect);
        return rect;
    }

    /++
     + Wraps `SDL_RenderSetClipRect` which sets the clipping `dsdl2.Rect` of the renderer
     +
     + Params:
     +   newRect = `dsdl2.Rect` to set as the clipping rectangle
     +/
    void clipRect(Rect newRect) @property @trusted {
        SDL_RenderSetClipRect(this.sdlRenderer, &newRect.sdlRect);
    }

    /++
     + Acts as `SDL_RenderSetClipRect(renderer, NULL)` which removes the clipping `dsdl2.Rect` of the
     + renderer
     +/
    void clipRect(typeof(null) _) @property @trusted {
        SDL_RenderSetClipRect(this.sdlRenderer, null);
    }

    /++
     + Wraps `SDL_RenderSetClipRect` which sets or removes the clipping `dsdl2.Rect` of the renderer
     +
     + Params:
     +   newRect = `dsdl2.Rect` to set as the clipping rectangle; `null` to remove the clipping rectangle
     +/
    void clipRect(Nullable!Rect newRect) @property @trusted {
        if (newRect.isNull) {
            this.clipRect = null;
        }
        else {
            this.clipRect = newRect.get;
        }
    }

    /++
     + Wraps `SDL_RenderGetLogicalSize` which gets the renderer output's logical width
     +
     + Returns: logical width of the renderer's output/target
     +/
    uint logicalWidth() const @property @trusted {
        uint w = void;
        SDL_RenderGetLogicalSize(cast(SDL_Renderer*) this.sdlRenderer, cast(int*) w, null);
        return w;
    }

    /++
     + Wraps `SDL_RenderSetLogicalSize` which sets the renderer output's logical width
     +
     + Params:
     +   newWidth = new logical width of the renderer's output
     + Throws: `dsdl2.SDLException` if failed to set the renderer's logical width
     +/
    void logicalWidth(uint newWidth) @property @trusted {
        if (SDL_RenderSetLogicalSize(this.sdlRenderer, newWidth, this.logicalHeight) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderGetLogicalSize` which gets the renderer output's logical height
     +
     + Returns: logical height of the renderer's output/target
     +/
    uint logicalHeight() const @property @trusted {
        uint h = void;
        SDL_RenderGetLogicalSize(cast(SDL_Renderer*) this.sdlRenderer, null, cast(int*) h);
        return h;
    }

    /++
     + Wraps `SDL_RenderSetLogicalSize` which sets the renderer output's logical height
     +
     + Params:
     +   newHeight = new logical height of the renderer's output
     + Throws: `dsdl2.SDLException` if failed to set the renderer's logical height
     +/
    void logicalHeight(uint newHeight) @property @trusted {
        if (SDL_RenderSetLogicalSize(this.sdlRenderer, this.logicalWidth, newHeight) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderGetLogicalSize` which gets the renderer logical size
     +
     + Returns: logical size of the renderer's output/target
     +/
    uint[2] logicalSize() const @property @trusted {
        uint[2] wh = void;
        SDL_RenderGetLogicalSize(cast(SDL_Renderer*) this.sdlRenderer, cast(int*) wh[0], cast(int*) wh[1]);
        return wh;
    }

    /++
     + Wraps `SDL_RenderSetLogicalSize` which sets the renderer output's logical size
     +
     + Params:
     +   newSize = new logical size (width and height) of the renderer's output
     + Throws: `dsdl2.SDLException` if failed to set the renderer's logical size
     +/
    void logicalSize(uint[2] newSize) @property @trusted {
        if (SDL_RenderSetLogicalSize(this.sdlRenderer, newSize[0].to!int, newSize[1].to!int) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderGetViewport` which gets the `dsdl2.Rect` viewport of the renderer
     +
     + Returns: viewport `dsdl2.Rect` of the renderer
     +/
    Rect viewport() const @property @trusted {
        Rect rect = void;
        SDL_RenderGetClipRect(cast(SDL_Renderer*) this.sdlRenderer, &rect.sdlRect);
        return rect;
    }

    /++
     + Wraps `SDL_RenderSetViewport` which sets the `dsdl2.Rect` viewport of the `dsdl2.Renderer`
     +
     + Params:
     +   newViewport = `dsdl2.Rect` to set as the rectangle viewport
     + Throws: `dsdl2.SDLException` if failed to set the renderer's viewport
     +/
    void viewport(Rect newViewport) @property @trusted {
        if (SDL_RenderSetViewport(this.sdlRenderer, &newViewport.sdlRect) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Acts as `SDL_RenderSetViewport(renderer, NULL)` which removes the `dsdl2.Rect` viewport of the
     + `dsdl2.Renderer`
     + Throws: `dsdl2.SDLException` if failed to set the renderer's viewport
     +/
    void viewport(typeof(null) _) @property @trusted {
        if (SDL_RenderSetViewport(this.sdlRenderer, null) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderSetViewport` which sets or removes the viewport `dsdl2.Rect` of the `dsdl2.Renderer`
     +
     + Params:
     +   newViewport = `dsdl2.Rect` to set as the rectangle viewport; `null` to remove the rectangle viewport
     + Throws: `dsdl2.SDLException` if failed to set the renderer's viewport
     +/
    void viewport(Nullable!Rect newViewport) @property @trusted {
        if (newViewport.isNull) {
            this.clipRect = null;
        }
        else {
            this.clipRect = newViewport.get;
        }
    }

    /++
     + Wraps `SDL_RenderGetScale` which gets the X drawing scale of the renderer target
     +
     + Returns: `float` scale in the X axis
     +/
    float scaleX() const @property @trusted {
        float x = void;
        SDL_RenderGetScale(cast(SDL_Renderer*) this.sdlRenderer, &x, null);
        return x;
    }

    /++
     + Wraps `SDL_RenderSetScale` which sets the X drawing scale of the renderer target
     +
     + Params:
     +   newX = new `float` scale of the X axis
     + Throws: `dsdl2.SDLException` if failed to set the scale
     +/
    void scaleX(float newX) @property @trusted {
        if (SDL_RenderSetScale(this.sdlRenderer, newX, this.scaleY) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderGetScale` which gets the Y drawing scale of the renderer target
     +
     + Returns: `float` scale in the Y axis
     +/
    float scaleY() const @property @trusted {
        float y = void;
        SDL_RenderGetScale(cast(SDL_Renderer*) this.sdlRenderer, null, &y);
        return y;
    }

    /++
     + Wraps `SDL_RenderSetScale` which sets the Y drawing scale of the renderer target
     +
     + Params:
     +   newY = new `float` scale of the Y axis
     + Throws: `dsdl2.SDLException` if failed to set the scale
     +/
    void scaleY(float newY) @property @trusted {
        if (SDL_RenderSetScale(this.sdlRenderer, this.scaleX, newY) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderGetScale` which gets the drawing scale of the renderer target
     +
     + Returns: array of 2 `float`s for the X and Y scales
     +/
    float[2] scale() const @property @trusted {
        float[2] xy = void;
        SDL_RenderGetScale(cast(SDL_Renderer*) this.sdlRenderer, &xy[0], &xy[1]);
        return xy;
    }

    /++
     + Wraps `SDL_RenderSetScale` which sets the drawing scale of the renderer target
     +
     + Params:
     +   newScale = array of 2 `float`s for the new X and Y scales
     + Throws: `dsdl2.SDLException` if failed to set the scale
     +/
    void scale(float[2] newScale) @property @trusted {
        if (SDL_RenderSetScale(this.sdlRenderer, newScale[0], newScale[1]) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_GetRenderDrawColor` which gets the draw color for the following draw calls
     +
     + Returns: `dsdl2.Color` of the renderer's current draw color
     +/
    Color drawColor() const @property @trusted {
        Color color = void;
        if (SDL_GetRenderDrawColor(cast(SDL_Renderer*) this.sdlRenderer, &color.r(), &color.g(), &color.b(),
                &color.a()) != 0) {
            throw new SDLException;
        }

        return color;
    }

    /++
     + Wraps `SDL_SetRenderDrawColor` which sets the draw color for the following draw calls
     +
     + Params:
     +   newColor = new `dsdl2.Color` as the renderer's current draw color
     + Throws: `dsdl2.SDLException` if failed to set the draw color
     +/
    void drawColor(Color newColor) @property @trusted {
        if (SDL_SetRenderDrawColor(this.sdlRenderer, newColor.r, newColor.g, newColor.b, newColor.a) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_GetRenderDrawBlendMode` which gets the color blending mode of the renderer
     +
     + Returns: color `dsdl2.BlendMode` of the renderer
     + Throws: `dsdl2.SDLException` if failed to get the color blending mode
     +/
    BlendMode blendMode() const @property @trusted {
        BlendMode mode = void;
        if (SDL_GetRenderDrawBlendMode(cast(SDL_Renderer*) this.sdlRenderer, &mode.sdlBlendMode) != 0) {
            throw new SDLException;
        }

        return mode;
    }

    /++
     + Wraps `SDL_SetRenderDrawBlendMode` which sets the color blending mode of the renderer
     +
     + Params:
     +   newMode = new `dsdl2.BlendMode` as the renderer's current color blending mode
     + Throws: `dsdl2.SDLException` if failed to set the color blending mode
     +/
    void blendMode(BlendMode newMode) @property @trusted {
        if (SDL_SetRenderDrawBlendMode(this.sdlRenderer, newMode.sdlBlendMode) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderClear` which clears the target with the renderer's draw color
     +
     + Throws: `dsdl2.SDLException` if failed to clear
     +/
    void clear() @trusted {
        if (SDL_RenderClear(this.sdlRenderer) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderDrawPoint` which draws a single point at a given position with the renderer's draw color
     +
     + Params:
     +   point = `dsdl2.Point` position the point is drawn at
     + Throws: `dsdl2.SDLException` if point failed to draw
     +/
    void drawPoint(Point point) @trusted {
        if (SDL_RenderDrawPoint(this.sdlRenderer, point.x, point.y) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderDrawPoints` which draws multiple points at given positions with the renderer's draw color
     +
     + Params:
     +   points = array of `dsdl2.Point` positions the points are drawn at
     + Throws: `dsdl2.SDLException` if points failed to draw
     +/
    void drawPoints(const Point[] points) @trusted {
        if (SDL_RenderDrawPoints(this.sdlRenderer, cast(SDL_Point*) points.ptr, points.length.to!int) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderDrawLine` which draws a line between two points with the renderer's draw color
     +
     + Params:
     +   line = array of two `dsdl2.Point`s indicating the line's start and end
     + Throws: `dsdl2.SDLException` if line failed to draw
     +/
    void drawLine(Point[2] line) @trusted {
        if (SDL_RenderDrawLine(this.sdlRenderer, line[0].x, line[0].y, line[1].x, line[1].y) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderDrawLines` which draws multiple lines following given points with the renderer's draw color
     +
     + Params:
     +   points = array of `dsdl2.Point` edges the lines are drawn from and to
     + Throws: `dsdl2.SDLException` if lines failed to draw
     +/
    void drawLines(const Point[] points) @trusted {
        if (SDL_RenderDrawLines(this.sdlRenderer, cast(SDL_Point*) points.ptr, points.length.to!int) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderDrawRect` which draws a rectangle's edges with the renderer's draw color
     +
     + Params:
     +   rect = `dsdl2.Rect` of the rectangle
     + Throws: `dsdl2.SDLException` if rectangle failed to draw
     +/
    void drawRect(Rect rect) @trusted {
        if (SDL_RenderDrawRect(this.sdlRenderer, &rect.sdlRect) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderDrawRects` which draws multiple rectangles' edges with the renderer's draw color
     +
     + Params:
     +   rects = array of `dsdl2.Rect` of the rectangles
     + Throws: `dsdl2.SDLException` if rectangles failed to draw
     +/
    void drawRects(const Rect[] rects) @trusted {
        if (SDL_RenderDrawRects(this.sdlRenderer, cast(SDL_Rect*) rects.ptr, rects.length.to!int) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderFillRect` which fills a rectangle with the renderer's draw color
     +
     + Params:
     +   rect = `dsdl2.Rect` of the rectangle
     + Throws: `dsdl2.SDLException` if rectangle failed to fill
     +/
    void fillRect(Rect rect) @trusted {
        if (SDL_RenderFillRect(this.sdlRenderer, &rect.sdlRect) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderFillRects` which fills multiple rectangles with the renderer's draw color
     +
     + Params:
     +   rects = array of `dsdl2.Rect` of the rectangles
     + Throws: `dsdl2.SDLException` if rectangles failed to fill
     +/
    void fillRects(const Rect[] rects) @trusted {
        if (SDL_RenderFillRects(this.sdlRenderer, cast(SDL_Rect*) rects.ptr, rects.length.to!int) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Acts as `SDL_RenderCopy(renderer, texture, NULL, destRect)` which copies the entire texture to `destRect` at
     + the renderer's target
     +
     + Params:
     +   texture  = `dsdl2.Texture` to be copied/drawn
     +   destRect = destination `dsdl2.Rect` in the target for the texture to be drawn to
     + Throws: `dsdl2.SDLException` if texture failed to draw
     +/
    void copy(const Texture texture, Rect destRect) @trusted
    in {
        assert(texture !is null);
    }
    do {
        if (SDL_RenderCopy(this.sdlRenderer, cast(SDL_Texture*) texture.sdlTexture, null, &destRect.sdlRect) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderCopy` which copies a part of the texture at `srcRect` to `destRect` at the renderer's target
     +
     + Params:
     +   texture  = `dsdl2.Texture` to be copied/drawn
     +   destRect = destination `dsdl2.Rect` in the target for the texture to be drawn to
     +   srcRect  = source `dsdl2.Rect` which clips the given texture
     + Throws: `dsdl2.SDLException` if texture failed to draw
     +/
    void copy(const Texture texture, Rect destRect, Rect srcRect) @trusted
    in {
        assert(texture !is null);
    }
    do {
        if (SDL_RenderCopy(this.sdlRenderer, cast(SDL_Texture*) texture.sdlTexture, &srcRect.sdlRect,
                &destRect.sdlRect) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Acts as `SDL_RenderCopyEx(renderer, texture, NULL, destRect, angle, NULL, flip)` which copies the
     + entire texture to `destRect` at the renderer's target with certain `angle` and flipping
     +
     + Params:
     +   texture             = `dsdl2.Texture` to be copied/drawn
     +   destRect            = destination `dsdl2.Rect` in the target for the texture to be drawn to
     +   angle               = angle in degrees to rotate the texture counterclockwise
     +   flippedHorizontally = `true` to flip the texture horizontally, otherwise `false`
     +   flippedVertically   = `true` to flip the texture vertically, otherwise `false`
     + Throws: `dsdl2.SDLException` if texture failed to draw
     +/
    void copyEx(const Texture texture, Rect destRect, double angle, bool flippedHorizontally = false,
        bool flippedVertically = false) @trusted
    in {
        assert(texture !is null);
    }
    do {
        if (SDL_RenderCopyEx(this.sdlRenderer, cast(SDL_Texture*) texture.sdlTexture, null, &destRect.sdlRect, angle,
                null, (flippedHorizontally ? SDL_FLIP_HORIZONTAL : 0) |
                (flippedVertically ? SDL_FLIP_VERTICAL : 0)) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Acts as `SDL_RenderCopyEx(renderer, texture, srcRect, destRect, angle, NULL, flip)` which copies the
     + entire texture to `destRect` at the renderer's target with certain `angle` and flipping
     +
     + Params:
     +   texture             = `dsdl2.Texture` to be copied/drawn
     +   destRect            = destination `dsdl2.Rect` in the target for the texture to be drawn to
     +   angle               = angle in degrees to rotate the texture counterclockwise
     +   srcRect             = source `dsdl2.Rect` which clips the given texture
     +   flippedHorizontally = `true` to flip the texture horizontally, otherwise `false`
     +   flippedVertically   = `true` to flip the texture vertically, otherwise `false`
     + Throws: `dsdl2.SDLException` if texture failed to draw
     +/
    void copyEx(const Texture texture, Rect destRect, double angle, Rect srcRect, bool flippedHorizontally = false,
        bool flippedVertically = false) @trusted
    in {
        assert(texture !is null);
    }
    do {
        if (SDL_RenderCopyEx(this.sdlRenderer, cast(SDL_Texture*) texture.sdlTexture, &srcRect.sdlRect,
                &destRect.sdlRect, angle, null, (flippedHorizontally ? SDL_FLIP_HORIZONTAL : 0) |
                (flippedVertically ? SDL_FLIP_VERTICAL : 0)) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Acts as `SDL_RenderCopyEx(renderer, texture, NULL, destRect, angle, center, flip)` which copies the
     + entire texture to `destRect` at the renderer's target with certain `angle` and flipping
     +
     + Params:
     +   texture             = `dsdl2.Texture` to be copied/drawn
     +   destRect            = destination `dsdl2.Rect` in the target for the texture to be drawn to
     +   angle               = angle in degrees to rotate the texture counterclockwise
     +   center              = pivot `dsdl2.Point` of the texture for rotation
     +   flippedHorizontally = `true` to flip the texture horizontally, otherwise `false`
     +   flippedVertically   = `true` to flip the texture vertically, otherwise `false`
     + Throws: `dsdl2.SDLException` if texture failed to draw
     +/
    void copyEx(const Texture texture, Rect destRect, double angle, Point center, bool flippedHorizontally = false,
        bool flippedVertically = false) @trusted
    in {
        assert(texture !is null);
    }
    do {
        if (SDL_RenderCopyEx(this.sdlRenderer, cast(SDL_Texture*) texture.sdlTexture, null, &destRect.sdlRect, angle,
                &center.sdlPoint, (flippedHorizontally ? SDL_FLIP_HORIZONTAL : 0) |
                (flippedVertically ? SDL_FLIP_VERTICAL : 0)) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderCopyEx` which copies the entire texture to `destRect` at the renderer's target with certain
     + `angle` and flipping
     +
     + Params:
     +   texture             = `dsdl2.Texture` to be copied/drawn
     +   destRect            = destination `dsdl2.Rect` in the target for the texture to be drawn to
     +   angle               = angle in degrees to rotate the texture counterclockwise
     +   srcRect             = source `dsdl2.Rect` which clips the given texture
     +   center              = pivot `dsdl2.Point` of the texture for rotation
     +   flippedHorizontally = `true` to flip the texture horizontally, otherwise `false`
     +   flippedVertically   = `true` to flip the texture vertically, otherwise `false`
     + Throws: `dsdl2.SDLException` if texture failed to draw
     +/
    void copyEx(const Texture texture, Rect destRect, double angle, Rect srcRect, Point center,
        bool flippedHorizontally = false, bool flippedVertically = false) @trusted
    in {
        assert(texture !is null);
    }
    do {
        if (SDL_RenderCopyEx(this.sdlRenderer, cast(SDL_Texture*) texture.sdlTexture, &srcRect.sdlRect,
                &destRect.sdlRect, angle, &center.sdlPoint, (flippedHorizontally ? SDL_FLIP_HORIZONTAL
                : 0) | (flippedVertically ? SDL_FLIP_VERTICAL : 0)) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_RenderReadPixels` which makes a `dsdl2.Surface` from the renderer's entire target
     +
     + Params:
     +   format = requested `dsdl2.PixelFormat` of the returned `dsdl2.Surface`
     + Returns: `dsdl2.Surface` copy of the renderer's entire target
     + Throws: `dsdl2.SDLException` if pixels failed to be read
     +/
    Surface readPixels(const PixelFormat format = PixelFormat.rgba8888) const @trusted
    in {
        assert(!format.isIndexed);
    }
    do {
        Surface surface = new Surface(this.size, format);
        if (SDL_RenderReadPixels(cast(SDL_Renderer*) this.sdlRenderer, null, format.sdlPixelFormatEnum,
                surface.buffer.ptr, surface.pitch.to!int) != 0) {
            throw new SDLException;
        }

        return surface;
    }

    /++
     + Wraps `SDL_RenderReadPixels` which makes a `dsdl2.Surface` from a specified `dsdl2.Rect` boundary at the
     + renderer's target
     +
     + Params:
     +   rect   = `dsdl2.Rect` boundary to be read and copied
     +   format = requested `dsdl2.PixelFormat` of the returned `dsdl2.Surface`
     + Returns: `dsdl2.Surface` copy of the specified rectangle boundary in the renderer's target
     + Throws: `dsdl2.SDLException` if pixels failed to be read
     +/
    Surface readPixels(Rect rect, const PixelFormat format = PixelFormat.rgba8888) const @trusted
    in {
        assert(!format.isIndexed);
    }
    do {
        Surface surface = new Surface([rect.x, rect.x], format);
        if (SDL_RenderReadPixels(cast(SDL_Renderer*) this.sdlRenderer, &rect.sdlRect, format.sdlPixelFormatEnum,
                surface.buffer.ptr, surface.pitch.to!int) != 0) {
            throw new SDLException;
        }

        return surface;
    }

    /++
     + Wraps `SDL_RenderPresent` which presents any appending changes to the renderer's target
     +/
    void present() @trusted {
        SDL_RenderPresent(this.sdlRenderer);
    }

    static if (sdlSupport >= SDLSupport.v2_0_4) {
        /++
         + Wraps `SDL_RenderIsClipEnabled` (from SDL 2.0.4) which checks whether a clipping rectangle is set in the
         + renderer
         +
         + Returns: `true` if a clipping rectangle is set, otherwise `false`
         +/
        bool hasClipRect() const @property @trusted {
            return SDL_RenderIsClipEnabled(cast(SDL_Renderer*) this.sdlRenderer) == SDL_TRUE;
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_5) {
        /++
         + Wraps `SDL_RenderGetIntegerScale` (from SDL 2.0.5) which gets whether integer scales are forced
         +
         + Returns: `true` if integer scaling is enabled, otherwise `false`
         +/
        bool integerScaling() const @property @trusted {
            return SDL_RenderGetIntegerScale(cast(SDL_Renderer*) this.sdlRenderer) == SDL_TRUE;
        }

        /++
         + Wraps `SDL_RenderSetIntegerScale` (from SDL 2.0.5) which sets whether integer scales should be forced
         +
         + Params:
         +   newScale = `true` to enable integer scaling, otherwise `false`
         + Throws: `dsdl2.SDLException` if failed to set integer scaling
         +/
        void integerScaling(bool newScale) @property @trusted {
            if (SDL_RenderSetIntegerScale(this.sdlRenderer, newScale) != 0) {
                throw new SDLException;
            }
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_8) {
        /++
         + Wraps `SDL_RenderGetMetalLayer` (from SDL 2.0.8) which gets the `CAMetalLayer` pointer associated with the
         + given Metal renderer
         +
         + Returns: pointer to the `CAMetalLayer`, otherwise `null` if not using a Metal renderer
         +/
        void* getMetalLayer() @system {
            return SDL_RenderGetMetalLayer(this.sdlRenderer);
        }

        /++
         + Wraps `SDL_RenderGetMetalCommandEncoder` (from SDL 2.0.8) which gets the Metal command encoder for the
         + current frame
         +
         + Returns: ID of the `MTLRenderCommandEncoder`, otherwise `null` if not using a Metal renderer
         +/
        void* getMetalCommandEncoder() @system {
            return SDL_RenderGetMetalCommandEncoder(this.sdlRenderer);
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_10) {
        /++
         + Wraps `SDL_RenderDrawPointF` (from SDL 2.0.10) which draws a single point at a given position with the
         + renderer's draw color
         +
         + Params:
         +   point = `dsdl2.FPoint` position the point is drawn at
         + Throws: `dsdl2.SDLException` if point failed to draw
         +/
        void drawPoint(FPoint point) @trusted {
            if (SDL_RenderDrawPointF(this.sdlRenderer, point.x, point.y) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_RenderDrawPointsF` (from SDL 2.0.10) which draws multiple points at given positions with the
         + renderer's draw color
         +
         + Params:
         +   points = array of `dsdl2.FPoint` positions the points are drawn at
         + Throws: `dsdl2.SDLException` if points failed to draw
         +/
        void drawPoints(const FPoint[] points) @trusted {
            if (SDL_RenderDrawPointsF(this.sdlRenderer, cast(SDL_FPoint*) points.ptr, points.length.to!int) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_RenderDrawLineF` (from SDL 2.0.10) which draws a line between two points with the renderer's draw
         + color
         +
         + Params:
         +   line = array of two `dsdl2.FPoint`s indicating the line's start and end
         + Throws: `dsdl2.SDLException` if line failed to draw
         +/
        void drawLine(FPoint[2] line) @trusted {
            if (SDL_RenderDrawLineF(this.sdlRenderer, line[0].x, line[0].y, line[1].x, line[1].y) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_RenderDrawLinesF` (from SDL 2.0.10) which draws multiple lines following given points with the
         + renderer's draw color
         +
         + Params:
         +   points = array of `dsdl2.FPoint` edges the lines are drawn from and to
         + Throws: `dsdl2.SDLException` if lines failed to draw
         +/
        void drawLines(const FPoint[] points) @trusted {
            if (SDL_RenderDrawLinesF(this.sdlRenderer, cast(SDL_FPoint*) points.ptr, points.length.to!int) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_RenderDrawRectF` (from SDL 2.0.10) which draws a rectangle's edges with the renderer's draw color
         +
         + Params:
         +   rect = `dsdl2.FRect` of the rectangle
         + Throws: `dsdl2.SDLException` if rectangle failed to draw
         +/
        void drawRect(FRect rect) @trusted {
            if (SDL_RenderDrawRectF(this.sdlRenderer, &rect.sdlFRect) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_RenderDrawRectsF` (from SDL 2.0.10) which draws multiple rectangles' edges with the renderer's
         + draw color
         +
         + Params:
         +   rects = array of `dsdl2.FRect` of the rectangles
         + Throws: `dsdl2.SDLException` if rectangles failed to draw
         +/
        void drawRects(const FRect[] rects) @trusted {
            if (SDL_RenderDrawRectsF(this.sdlRenderer, cast(SDL_FRect*) rects.ptr, rects.length.to!int) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_RenderFillRectF` (from SDL 2.0.10) which fills a rectangle with the renderer's draw color
         +
         + Params:
         +   rect = `dsdl2.FRect` of the rectangle
         + Throws: `dsdl2.SDLException` if rectangle failed to fill
         +/
        void fillRect(FRect rect) @trusted {
            if (SDL_RenderFillRectF(this.sdlRenderer, &rect.sdlFRect) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_RenderFillRectsF` (from SDL 2.0.10) which fills multiple rectangles with the renderer's draw color
         +
         + Params:
         +   rects = array of `dsdl2.FRect` of the rectangles
         + Throws: `dsdl2.SDLException` if rectangles failed to fill
         +/
        void fillRects(const FRect[] rects) @trusted {
            if (SDL_RenderFillRectsF(this.sdlRenderer, cast(SDL_FRect*) rects.ptr, rects.length.to!int) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Acts as `SDL_RenderCopyF(renderer, texture, NULL, destRect)` (from SDL 2.0.10) which copies the entire
         + texture to `destRect` at the renderer's target
         +
         + Params:
         +   texture  = `dsdl2.Texture` to be copied/drawn
         +   destRect = destination `dsdl2.FRect` in the target for the texture to be drawn to
         + Throws: `dsdl2.SDLException` if texture failed to draw
         +/
        void copy(const Texture texture, FRect destRect) @trusted
        in {
            assert(texture !is null);
        }
        do {
            if (SDL_RenderCopyF(this.sdlRenderer, cast(SDL_Texture*) texture.sdlTexture, null,
                    &destRect.sdlFRect) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_RenderCopyF` (from SDL 2.0.10) which copies a part of the texture at `srcRect` to `destRect` at
         + the renderer's target
         +
         + Params:
         +   texture  = `dsdl2.Texture` to be copied/drawn
         +   destRect = destination `dsdl2.FRect` in the target for the texture to be drawn to
         +   srcRect  = source `dsdl2.Rect` which clips the given texture
         + Throws: `dsdl2.SDLException` if texture failed to draw
         +/
        void copy(const Texture texture, FRect destRect, Rect srcRect) @trusted
        in {
            assert(texture !is null);
        }
        do {
            if (SDL_RenderCopyF(this.sdlRenderer, cast(SDL_Texture*) texture.sdlTexture, &srcRect.sdlRect,
                    &destRect.sdlFRect) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Acts as `SDL_RenderCopyExF(renderer, texture, NULL, destRect, angle, NULL, flip)` (from SDL 2.0.10) which
         + copies the entire texture to `destRect` at the renderer's target with certain `angle` and flipping
         +
         + Params:
         +   texture             = `dsdl2.Texture` to be copied/drawn
         +   destRect            = destination `dsdl2.FRect` in the target for the texture to be drawn to
         +   angle               = angle in degrees to rotate the texture counterclockwise
         +   flippedHorizontally = `true` to flip the texture horizontally, otherwise `false`
         +   flippedVertically   = `true` to flip the texture vertically, otherwise `false`
         + Throws: `dsdl2.SDLException` if texture failed to draw
         +/
        void copyEx(const Texture texture, FRect destRect, double angle, bool flippedHorizontally = false,
            bool flippedVertically = false) @trusted
        in {
            assert(texture !is null);
        }
        do {
            if (SDL_RenderCopyExF(this.sdlRenderer, cast(SDL_Texture*) texture.sdlTexture, null, &destRect.sdlFRect,
                    angle, null, (flippedHorizontally ? SDL_FLIP_HORIZONTAL : 0) |
                    (flippedVertically ? SDL_FLIP_VERTICAL : 0)) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Acts as `SDL_RenderCopyExF(renderer, texture, srcRect, destRect, angle, NULL, flip)` (from SDL 2.0.10) which
         + copies the entire texture to `destRect` at the renderer's target with certain `angle` and flipping
         +
         + Params:
         +   texture             = `dsdl2.Texture` to be copied/drawn
         +   destRect            = destination `dsdl2.FRect` in the target for the texture to be drawn to
         +   angle               = angle in degrees to rotate the texture counterclockwise
         +   srcRect             = source `dsdl2.Rect` which clips the given texture
         +   flippedHorizontally = `true` to flip the texture horizontally, otherwise `false`
         +   flippedVertically   = `true` to flip the texture vertically, otherwise `false`
         + Throws: `dsdl2.SDLException` if texture failed to draw
         +/
        void copyEx(const Texture texture, FRect destRect, double angle, Rect srcRect, bool flippedHorizontally = false,
            bool flippedVertically = false) @trusted
        in {
            assert(texture !is null);
        }
        do {
            if (SDL_RenderCopyExF(this.sdlRenderer, cast(SDL_Texture*) texture.sdlTexture, &srcRect.sdlRect,
                    &destRect.sdlFRect, angle, null, (flippedHorizontally ? SDL_FLIP_HORIZONTAL : 0) |
                    (flippedVertically ? SDL_FLIP_VERTICAL : 0)) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Acts as `SDL_RenderCopyExF(renderer, texture, NULL, destRect, angle, center, flip)` (from SDL 2.0.10) which
         + copies the entire texture to `destRect` at the renderer's target with certain `angle` and flipping
         +
         + Params:
         +   texture             = `dsdl2.Texture` to be copied/drawn
         +   destRect            = destination `dsdl2.FRect` in the target for the texture to be drawn to
         +   angle               = angle in degrees to rotate the texture counterclockwise
         +   center              = pivot `dsdl2.FPoint` of the texture for rotation
         +   flippedHorizontally = `true` to flip the texture horizontally, otherwise `false`
         +   flippedVertically   = `true` to flip the texture vertically, otherwise `false`
         + Throws: `dsdl2.SDLException` if texture failed to draw
         +/
        void copyEx(const Texture texture, FRect destRect, double angle, FPoint center,
            bool flippedHorizontally = false, bool flippedVertically = false) @trusted
        in {
            assert(texture !is null);
        }
        do {
            if (SDL_RenderCopyExF(this.sdlRenderer, cast(SDL_Texture*) texture.sdlTexture, null, &destRect.sdlFRect,
                    angle, &center.sdlFPoint, (flippedHorizontally ? SDL_FLIP_HORIZONTAL : 0) |
                    (flippedVertically ? SDL_FLIP_VERTICAL : 0)) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_RenderCopyExF` (from SDL 2.0.10) which copies the entire texture to `destRect` at the renderer's
         + target with certain `angle` and flipping
         +
         + Params:
         +   texture             = `dsdl2.Texture` to be copied/drawn
         +   destRect            = destination `dsdl2.FRect` in the target for the texture to be drawn to
         +   angle               = angle in degrees to rotate the texture counterclockwise
         +   srcRect             = source `dsdl2.Rect` which clips the given texture
         +   center              = pivot `dsdl2.FPoint` of the texture for rotation
         +   flippedHorizontally = `true` to flip the texture horizontally, otherwise `false`
         +   flippedVertically   = `true` to flip the texture vertically, otherwise `false`
         + Throws: `dsdl2.SDLException` if texture failed to draw
         +/
        void copyEx(const Texture texture, FRect destRect, double angle, Rect srcRect, FPoint center,
            bool flippedHorizontally = false, bool flippedVertically = false) @trusted
        in {
            assert(texture !is null);
        }
        do {
            if (SDL_RenderCopyExF(this.sdlRenderer, cast(SDL_Texture*) texture.sdlTexture, &srcRect.sdlRect,
                    &destRect.sdlFRect, angle, &center.sdlFPoint, (flippedHorizontally ? SDL_FLIP_HORIZONTAL
                    : 0) | (flippedVertically ? SDL_FLIP_VERTICAL : 0)) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_RenderFlush` (from SDL 2.0.10) which executes and flushes all pending rendering operations
         +
         + Throws: `dsdl2.SDLException` if cannot flush
         +/
        void flush() @trusted {
            if (SDL_RenderFlush(this.sdlRenderer) != 0) {
                throw new SDLException;
            }
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_18) {
        /++
         + Wraps `SDL_RenderWindowToLogical` (from SDL 2.0.18) which maps window coordinates to logical coordinates
         +
         + Params:
         +   xy = `int[2]` window coordinate of X and Y
         + Returns: mapped `float[2]` logical coordinate of X and Y
         +/
        float[2] windowToLogical(int[2] xy) const @trusted {
            float[2] fxy = void;
            SDL_RenderWindowToLogical(cast(SDL_Renderer*) this.sdlRenderer, xy[0], xy[1], &fxy[0], &fxy[1]);
            return fxy;
        }

        /++
         + Wraps `SDL_RenderLogicalToWindow` (from SDL 2.0.18) which maps logical coordinates to window coordinates
         +
         + Params:
         +   fxy = `float[2]` logical coordinate of X and Y
         + Returns: mapped `int[2]` window coordinate of X and Y
         +/
        int[2] logicalToWindow(float[2] fxy) const @trusted {
            int[2] xy = void;
            SDL_RenderLogicalToWindow(cast(SDL_Renderer*) this.sdlRenderer, fxy[0], fxy[1], &xy[0], &xy[1]);
            return xy;
        }

        /++
         + Wraps `SDL_RenderGeometry` (from SDL 2.0.18) which renders triangles to the renderer's target
         +
         + Params:
         +   vertices = array of `dsdl2.Vertex`es of the triangles
         +   texture  = `dsdl2.Texture` for the drawn triangles; `null` for none
         +   indices  = array of `uint` indices for the vertices to be drawn (must be in multiples of three); `null`
         +              for order defined by `vertices` directly
         + Throws: `dsdl2.SDLException` if failed to render
         +/
        void renderGeometry(const Vertex[] vertices, Texture texture = null, const uint[] indices = null) @trusted {
            SDL_Texture* sdlTexture = texture is null ? null : texture.sdlTexture;
            if (SDL_RenderGeometry(this.sdlRenderer, sdlTexture, cast(SDL_Vertex*) vertices.ptr,
                    vertices.length.to!int, cast(int*) indices.ptr, indices.length.to!int) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_RenderSetVSync` which sets whether vertical synchronization should be enabled
         +
         + Params:
         +   vSync = `true` to enable v-sync, otherwise `false`
         + Throws: `dsdl2.SDLException` if failed to set v-sync
         +/
        void setVSync(bool vSync) @trusted {
            if (SDL_RenderSetVSync(this.sdlRenderer, vSync) != 0) {
                throw new SDLException;
            }
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_22) {
        /++
         + Wraps `SDL_RenderGetWindow` (from SDL 2.0.22) which gets a `dsdl2.Window` proxy to the window associated
         + with the renderer
         +
         + Returns: `dsdl2.Window` proxy to the window
         + Throws: `dsdl2.SDLException` if failed to get window
         +/
        inout(Window) window() inout @property @trusted {
            SDL_Window* sdlWindow = SDL_RenderGetWindow(cast(SDL_Renderer*) this.sdlRenderer);
            if (sdlWindow is null) {
                throw new SDLException;
            }

            return cast(inout Window) new Window(sdlWindow, false, cast(void*) this);
        }
    }
}
