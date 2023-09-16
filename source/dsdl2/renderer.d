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

/++
 + D class that wraps `SDL_Renderer` managing a backend rendering instance
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
     +   window       = target `dsdl2.Window` for the renderer to draw onto
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

    void clear() @trusted {
        if (SDL_RenderClear(this.sdlRenderer) != 0) {
            throw new SDLException;
        }
    }

    void drawPoint(Point point) @trusted {
        if (SDL_RenderDrawPoint(this.sdlRenderer, point.x, point.y) != 0) {
            throw new SDLException;
        }
    }

    void drawPoints(const Point[] points) @trusted {
        if (SDL_RenderDrawPoints(this.sdlRenderer, cast(SDL_Point*) points.ptr, points.length.to!int) != 0) {
            throw new SDLException;
        }
    }

    void drawLine(Point[2] line) @trusted {
        if (SDL_RenderDrawLine(this.sdlRenderer, line[0].x, line[0].y, line[1].x, line[1].y) != 0) {
            throw new SDLException;
        }
    }

    void drawLines(const Point[] points) @trusted {
        if (SDL_RenderDrawLines(this.sdlRenderer, cast(SDL_Point*) points.ptr, points.length.to!int) != 0) {
            throw new SDLException;
        }
    }

    void drawRect(Rect rect) @trusted {
        if (SDL_RenderDrawRect(this.sdlRenderer, &rect.sdlRect) != 0) {
            throw new SDLException;
        }
    }

    void drawRects(const Rect[] rects) @trusted {
        if (SDL_RenderDrawRects(this.sdlRenderer, cast(SDL_Rect*) rects.ptr, rects.length.to!int) != 0) {
            throw new SDLException;
        }
    }

    void fillRect(Rect rect) @trusted {
        if (SDL_RenderFillRect(this.sdlRenderer, &rect.sdlRect) != 0) {
            throw new SDLException;
        }
    }

    void fillRects(const Rect[] rects) @trusted {
        if (SDL_RenderFillRects(this.sdlRenderer, cast(SDL_Rect*) rects.ptr, rects.length.to!int) != 0) {
            throw new SDLException;
        }
    }

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

    void present() @trusted {
        SDL_RenderPresent(this.sdlRenderer);
    }

    static if (sdlSupport >= SDLSupport.v2_0_4) {
        bool hasClipRect() const @property @trusted {
            return SDL_RenderIsClipEnabled(cast(SDL_Renderer*) this.sdlRenderer) == SDL_TRUE;
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_5) {
        bool integerScale() const @property @trusted {
            return SDL_RenderGetIntegerScale(cast(SDL_Renderer*) this.sdlRenderer) == SDL_TRUE;
        }

        void integerScale(bool newScale) @property @trusted {
            if (SDL_RenderSetIntegerScale(this.sdlRenderer, newScale) != 0) {
                throw new SDLException;
            }
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_8) {
        void* getMetalLayer() @trusted {
            return SDL_RenderGetMetalLayer(this.sdlRenderer);
        }

        void* getMetalCommandEncoder() @trusted {
            return SDL_RenderGetMetalCommandEncoder(this.sdlRenderer);
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_10) {
        void drawPoint(FPoint point) @trusted {
            if (SDL_RenderDrawPointF(this.sdlRenderer, point.x, point.y) != 0) {
                throw new SDLException;
            }
        }

        void drawPoints(const FPoint[] points) @trusted {
            if (SDL_RenderDrawPointsF(this.sdlRenderer, cast(SDL_FPoint*) points.ptr, points.length.to!int) != 0) {
                throw new SDLException;
            }
        }

        void drawLine(FPoint[2] line) @trusted {
            if (SDL_RenderDrawLineF(this.sdlRenderer, line[0].x, line[0].y, line[1].x, line[1].y) != 0) {
                throw new SDLException;
            }
        }

        void drawLines(const FPoint[] points) @trusted {
            if (SDL_RenderDrawLinesF(this.sdlRenderer, cast(SDL_FPoint*) points.ptr, points.length.to!int) != 0) {
                throw new SDLException;
            }
        }

        void drawRect(FRect rect) @trusted {
            if (SDL_RenderDrawRectF(this.sdlRenderer, &rect.sdlFRect) != 0) {
                throw new SDLException;
            }
        }

        void drawRects(const FRect[] rects) @trusted {
            if (SDL_RenderDrawRectsF(this.sdlRenderer, cast(SDL_FRect*) rects.ptr, rects.length.to!int) != 0) {
                throw new SDLException;
            }
        }

        void fillRect(FRect rect) @trusted {
            if (SDL_RenderFillRectF(this.sdlRenderer, &rect.sdlFRect) != 0) {
                throw new SDLException;
            }
        }

        void fillRects(const FRect[] rects) @trusted {
            if (SDL_RenderFillRectsF(this.sdlRenderer, cast(SDL_FRect*) rects.ptr, rects.length.to!int) != 0) {
                throw new SDLException;
            }
        }

        void flush() @trusted {
            if (SDL_RenderFlush(this.sdlRenderer) != 0) {
                throw new SDLException;
            }
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_18) {
        float[2] windowToLogical(int[2] xy) const @trusted {
            float[2] fxy = void;
            SDL_RenderWindowToLogical(cast(SDL_Renderer*) this.sdlRenderer, xy[0], xy[1], &fxy[0], &fxy[1]);
            return fxy;
        }

        int[2] logicalToWindow(float[2] fxy) const @trusted {
            int[2] xy = void;
            SDL_RenderLogicalToWindow(cast(SDL_Renderer*) this.sdlRenderer, fxy[0], fxy[1], &xy[0], &xy[1]);
            return xy;
        }

        void setVSync(bool vSync) @trusted {
            if (SDL_RenderSetVSync(this.sdlRenderer, vSync) != 0) {
                throw new SDLException;
            }
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_22) {
        inout(Window) window() inout @property @trusted {
            SDL_Window* sdlWindow = SDL_RenderGetWindow(cast(SDL_Renderer*) this.sdlRenderer);
            if (sdlWindow is null) {
                throw new SDLException;
            }

            return cast(inout Window) new Window(sdlWindow, false, cast(void*) this);
        }
    }
}
