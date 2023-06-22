/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.surface;
@safe:

import bindbc.sdl;
import dsdl2.sdl;
import dsdl2.blend;
import dsdl2.pixels;
import dsdl2.rect;

import core.memory : GC;
import std.conv : to;
import std.format : format;

/++ 
 + D class that wraps `SDL_Surface` storing a 2D image in the RAM
 + 
 + `dsdl2.Surface` stores a 2D image out of pixels with a `width` and `height`, where each pixel stored in the
 + RAM according to its defined `dsdl2.PixelFormat`.
 + 
 + Examples:
 + ---
 + auto surface = new dsdl2.Surface([100, 100], dsdl2.PixelFormat.rgba32);
 + surface.fill(dsdl2.Color(24, 24, 24));
 + surface.fillRect(dsdl2.Rect(25, 25, 50, 50), dsdl2.Color(42, 42, 42));
 + 
 + assert(surface.getAt([0, 0]) == dsdl2.Color(24, 24, 24));
 + assert(surface.getAt([50, 50]) == dsdl2.Color(42, 42, 42));
 + ---
 +/
final class Surface {
    private PixelFormat pixelFormatProxy = null;
    @system SDL_Surface* _sdlSurface = null; /// Internal `SDL_Surface` pointer
    private bool isOwner = true;
    private void* refPtr = null;

    /++ 
     + Constructs a `dsdl2.Surface` from a vanilla `SDL_Surface*` from bindbc-sdl
     + 
     + Params:
     +   sdlSurface = the `SDL_Surface` pointer to manage
     +   owns       = whether the instance owns the given `SDL_Surface*` and should destroy it on its own
     +   userRef    = optional pointer to maintain reference link, avoiding GC cleanup
     +/
    this(SDL_Surface* sdlSurface, bool owns = true, void* userRef = null) @system
    in {
        assert(sdlSurface !is null);
    }
    do {
        this._sdlSurface = sdlSurface;
        this.pixelFormatProxy = new PixelFormat(this._sdlSurface.format, false, cast(void*) this);
        this.isOwner = owns;
        this.refPtr = userRef;
    }

    /++ 
     + Constructs a blank RGB(A) `dsdl2.Surface` with a set width, height, and `dsdl2.PixelFormat` which wraps
     + `SDL_CreateRGBSurface`
     + 
     + Params:
     +   size           = size (width and height) of the `dsdl2.Surface` in pixels
     +   rgbPixelFormat = an RGB(A) `dsdl2.PixelFormat`
     + Throws: `dsdl2.SDLException` if allocation failed
     +/
    this(uint[2] size, const PixelFormat rgbPixelFormat) @trusted
    in {
        assert(rgbPixelFormat !is null);
        assert(!rgbPixelFormat.isIndexed);
    }
    do {
        uint[4] masks = rgbPixelFormat.toMasks();

        this._sdlSurface = SDL_CreateRGBSurface(0, size[0].to!int, size[1].to!int, rgbPixelFormat.bitDepth,
        masks[0], masks[1], masks[2], masks[3]);
        if (this._sdlSurface is null) {
            throw new SDLException;
        }

        this.pixelFormatProxy = new PixelFormat(this._sdlSurface.format, false, cast(void*) this);
    }

    /++ 
     + Constructs an RGB(A) `dsdl2.Surface` from an array of `pixels`
     + 
     + Params:
     +   pixels         = array of pixel data (copied internally)
     +   size           = size (width and height) of the `dsdl2.Surface` in pixels
     +   pitch          = skips in bytes per line/row of the `dsdl2.Surface`
     +   rgbPixelFormat = an RGB(A) `dsdl2.PixelFormat`
     + Throws: `dsdl2.SDLException` if allocation failed
     +/
    this(void[] pixels, uint[2] size, size_t pitch, const PixelFormat rgbPixelFormat) @trusted
    in {
        assert(pixels !is null);
        assert(rgbPixelFormat !is null);
        assert(!rgbPixelFormat.isIndexed);
        assert(pitch * 8 >= size[0] * rgbPixelFormat.bitDepth);
        assert(pixels.length == pitch * size[1]);
    }
    do {
        this(size, rgbPixelFormat);

        size_t lineBitSize = size[0].to!size_t * rgbPixelFormat.bitDepth;
        size_t lineSize = lineBitSize / 8 + (lineBitSize % 8 != 0);

        foreach (line; 0 .. size[1]) {
            ubyte* srcLine = cast(ubyte*) pixels.ptr + line * pitch;
            ubyte* destLine = cast(ubyte*) this._sdlSurface.pixels + line * this.pitch;
            destLine[0 .. lineSize] = srcLine[0 .. lineSize];
        }
    }

    /++ 
     + Constructs a blank indexed palette-using `dsdl2.Surface` with a set width, height, and index bit depth,
     + which wraps `SDL_CreateRGBSurface` 
     + 
     + Params:
     +   size         = size (width and height) of the `dsdl2.Surface` in pixels
     +   bitDepth     = bit depth of the palette index (1, 4, or 8)
     +   boundPalette = `dsdl2.Palette` to use
     + Throws: `dsdl2.Exception` if allocation failed or palette-setting failed
     +/
    this(uint[2] size, ubyte bitDepth, Palette boundPalette) @trusted
    in {
        assert(bitDepth == 1 || bitDepth == 4 || bitDepth == 8);
        assert(boundPalette !is null);
    }
    do {
        this._sdlSurface = SDL_CreateRGBSurface(0, size[0], size[1], bitDepth, 0, 0, 0, 0);
        if (this._sdlSurface is null) {
            throw new SDLException;
        }

        this.pixelFormatProxy = new PixelFormat(this._sdlSurface.format, false, cast(void*) this);
        this.palette = boundPalette;
    }

    /++ 
     + Constructs a blank indexed palette-using `dsdl2.Surface` from an array of `pixels`
     + 
     + Params:
     +   pixels        = array of pixel data (copied internally)
     +   size          = size (width and height) of the `dsdl2.Surface` in pixels
     +   pitch         = skips in bytes per line/row of the `dsdl2.Surface`
     +   bitDepth      = bit depth of the palette index (1, 4, or 8)
     +   boundPalette  = `dsdl2.Palette` to use
     + Throws: `dsdl2.SDLException` if allocation failed or palette-setting failed
     +/
    this(void[] pixels, uint[2] size, size_t pitch, ubyte bitDepth, Palette boundPalette) @trusted
    in {
        assert(pixels !is null);
        assert(size[0] > 0 && size[1] > 0);
        assert(pitch * 8 >= size[0] * bitDepth);
        assert(pixels.length == pitch * size[1]);
        assert(boundPalette !is null);
    }
    do {
        this(size, bitDepth, boundPalette);

        size_t lineBitSize = size[0] * bitDepth;
        size_t lineSize = lineBitSize / 8 + (lineBitSize % 8 != 0);

        foreach (line; 0 .. size[1]) {
            ubyte* srcLine = cast(ubyte*) pixels.ptr + line * pitch;
            ubyte* destLine = cast(ubyte*) this._sdlSurface.pixels + line * this.pitch;
            destLine[0 .. lineSize] = srcLine[0 .. lineSize];
        }
    }

    ~this() @trusted {
        if (this.isOwner) {
            SDL_FreeSurface(this._sdlSurface);
        }
    }

    @trusted invariant {
        // Instance might be in an invalid state due to holding a non-owned externally-freed object when
        // destructed in an unpredictable order.
        if (!this.isOwner && GC.inFinalizer) {
            return;
        }

        assert(this._sdlSurface !is null);
        assert(this.pixelFormatProxy !is null);
    }

    /++
     + Formats the `dsdl2.Surface` into its construction representation:
     + `"dsdl2.PixelFormat([...], [<width>, <height>], <pitch>, <pixelFormat>)"`
     +
     + Returns: the formatted `string`
     +/
    override string toString() const @trusted {
        return "dsdl2.Surface([...], [%d, %d], %d, %s)".format(this.width, this.height, this.pitch, this
                .pixelFormat.toString());
    }

    /++ 
     + Gets the `dsdl2.PixelFormat` of the `dsdl2.Surface`
     + 
     + Returns: `const` proxy to the `dsdl2.PixelFormat` of the `dsdl2.Surface`
     +/
    const(PixelFormat) pixelFormat() const @property @trusted {
        return this.pixelFormatProxy;
    }

    /++ 
     + Gets the width of the `dsdl2.Surface` in pixels
     + 
     + Returns: width of the `dsdl2.Surface` in pixels 
     +/
    uint width() const @property @trusted {
        return this._sdlSurface.w;
    }

    /++ 
     + Gets the height of the `dsdl2.Surface` in pixels
     + 
     + Returns: height of the `dsdl2.Surface` in pixels 
     +/
    uint height() const @property @trusted {
        return this._sdlSurface.h;
    }

    /++ 
     + Gets the size of the `dsdl2.Surface` in pixels
     + 
     + Returns: array of width and height of the `dsdl2.Surface` in pixels 
     +/
    uint[2] size() const @property @trusted {
        return [this._sdlSurface.w, this._sdlSurface.h];
    }

    /++ 
     + Gets the pitch of the `dsdl2.Surface` in bytes (multiple of bytes for each line/row)
     + 
     + Returns: pitch of the `dsdl2.Surface` in bytes 
     +/
    size_t pitch() const @property @trusted {
        return this._sdlSurface.pitch;
    }

    inout(Palette) palette() inout @property @trusted
    in {
        assert(this.pixelFormat.isIndexed);
    }
    do {
        return this.pixelFormatProxy.palette;
    }

    void palette(Palette boundPalette) @property @trusted
    in {
        assert(this.pixelFormat.isIndexed);
    }
    do {
        if (SDL_SetSurfacePalette(this._sdlSurface, boundPalette._sdlPalette) != 0) {
            throw new SDLException;
        }

        this.pixelFormatProxy.palette = boundPalette;
    }

    /++ 
     + Gets the pixel value in the `dsdl2.Surface` at the given coordinate
     + 
     + Params:
     +   xy = X and Y values of the coordinate
     + Returns: the pixel value
     +/
    uint getPixelAt(uint[2] xy) const @trusted
    in {
        assert(xy[0] < this.width);
        assert(xy[1] < this.height);
    }
    do {
        const ubyte* row = cast(ubyte*) this._sdlSurface.pixels + xy[1] * this.pitch;

        if (this.pixelFormat.bitDepth >= 8) {
            const ubyte* pixelPtr = row + xy[0] * this.pixelFormat.bytesPerPixel;
            align(4) ubyte[4] pixel;
            pixel[0 .. this.pixelFormat.bytesPerPixel] = pixelPtr[0 .. this
                    .pixelFormat.bytesPerPixel];

            return *cast(uint*) pixel.ptr;
        }
        else {
            ubyte pixelByte = *(row + (xy[0] * this.pixelFormat.bitDepth) / 8);
            ubyte bitOffset = (xy[0] * this.pixelFormat.bitDepth) % 8;

            switch (this.pixelFormat._sdlPixelFormatEnum) {
            case SDL_PIXELFORMAT_INDEX1LSB:
                return (pixelByte & (0b00000001 << bitOffset)) != 0;

            case SDL_PIXELFORMAT_INDEX1MSB:
                return (pixelByte & (0b10000000 >> bitOffset)) != 0;

            case SDL_PIXELFORMAT_INDEX4LSB:
                return pixelByte & (0b00001111 << (bitOffset * 4)) >> (bitOffset * 4);

            case SDL_PIXELFORMAT_INDEX4MSB:
                return pixelByte & (0b11110000 >> (bitOffset * 4)) >> (4 - bitOffset * 4);

            default:
                assert(false);
            }
        }
    }

    /++ 
     + Sets the pixel value in the `dsdl2.Surface` at the given coordinate
     + 
     + Params:
     +   xy    = X and Y values of the coordinate
     +   value = pixel value to set at the given coordinate
     +/
    void setPixelAt(uint[2] xy, uint value) @trusted
    in {
        assert(xy[0] < this.width);
        assert(xy[1] < this.height);
        if (this.pixelFormat.bitDepth != 32) { // Overflow protection
            assert(value < 1 << this.pixelFormat.bitDepth);
        }
    }
    do {
        ubyte* row = cast(ubyte*) this._sdlSurface.pixels + xy[1] * this.pitch;

        if (this.pixelFormat.bitDepth >= 8) {
            ubyte* pixelPtr = row + xy[0] * this.pixelFormat.bytesPerPixel;
            pixelPtr[0 .. this.pixelFormat.bytesPerPixel] = (*cast(ubyte[4]*)&value)[0 .. this
                    .pixelFormat.bytesPerPixel];
        }
        else {
            ubyte* pixelPtr = row + (xy[0] * this.pixelFormat.bitDepth) / 8;
            ubyte bitOffset = (xy[0] * this.pixelFormat.bitDepth) % 8;

            switch (this.pixelFormat._sdlPixelFormatEnum) {
            case SDL_PIXELFORMAT_INDEX1LSB:
                *pixelPtr &= !(0b00000001 << bitOffset);
                *pixelPtr |= value << bitOffset;
                break;

            case SDL_PIXELFORMAT_INDEX1MSB:
                *pixelPtr &= !(0b10000000 >> bitOffset);
                *pixelPtr |= value << (7 - bitOffset);
                break;

            case SDL_PIXELFORMAT_INDEX4LSB:
                *pixelPtr &= !(0b00001111 << (bitOffset * 4));
                *pixelPtr |= value << (bitOffset * 4);
                break;

            case SDL_PIXELFORMAT_INDEX4MSB:
                *pixelPtr &= !(0b11110000 >> (bitOffset * 4));
                *pixelPtr |= value << (4 - bitOffset * 4);
                break;

            default:
                assert(false);
            }
        }
    }

    /++ 
     + Gets the pixel color in the `dsdl2.Surface` at the given coordinate
     + 
     + Params:
     +   xy = X and Y values of the coordinate
     + Returns: the pixel color
     +/
    Color getAt(uint[2] xy) const
    in {
        assert(xy[0] < this.width);
        assert(xy[1] < this.height);
    }
    do {
        if (this.pixelFormat.hasAlpha) {
            return this.pixelFormat.getRGBA(this.getPixelAt(xy));
        }
        else {
            return this.pixelFormat.getRGB(this.getPixelAt(xy));
        }
    }

    /++ 
     + Sets the pixel color in the `dsdl2.Surface` at the given coordinate
     + 
     + Params:
     +   xy    = X and Y values of the coordinate
     +   color = pixel color to set at the given coordinate
     +/
    void setAt(uint[2] xy, Color color)
    in {
        assert(xy[0] < this.width);
        assert(xy[1] < this.height);
    }
    do {
        if (this.pixelFormat.hasAlpha) {
            this.setPixelAt(xy, this.pixelFormat.mapRGBA(color));
        }
        else {
            this.setPixelAt(xy, this.pixelFormat.mapRGB(color));
        }
    }

    /++ 
     + Gets the color and alpha multipliers of the `dsdl2.Surface` which wraps `SDL_GetSurfaceColorMod` and
     + `SDL_GetSurfaceAlphaMod`
     + 
     + Returns: color and alpha multipliers of the `dsdl2.Surface`
     +/
    Color mod() const @property @trusted {
        Color multipliers = void;
        SDL_GetSurfaceColorMod(cast(SDL_Surface*) this._sdlSurface, &multipliers._sdlColor.r,
            &multipliers._sdlColor.g, &multipliers._sdlColor.b);
        SDL_GetSurfaceAlphaMod(cast(SDL_Surface*) this._sdlSurface, &multipliers._sdlColor.a);
        return multipliers;
    }

    /++ 
     + Sets the color and alpha multipliers of the `dsdl2.Surface` which wraps `SDL_SetSurfaceColorMod` and
     + `SDL_SetSurfaceAlphaMod`
     + 
     + Params:
     +   multipliers = `dsdl2.Color` with `.r`, `.g`, `.b` as the color multipliers, and `.a` as the alpha
     +                 multiplier
     +/
    void mod(Color multipliers) @property @trusted {
        SDL_SetSurfaceColorMod(this._sdlSurface, multipliers.r, multipliers.g, multipliers.b);
        SDL_SetSurfaceAlphaMod(this._sdlSurface, multipliers.a);
    }

    /++ 
     + Wraps `SDL_GetSurfaceColorMod` which gets the color multipliers of the `dsdl2.Surface`
     + 
     + Returns: color multipliers of the `dsdl2.Surface`
     +/
    ubyte[3] colorMod() const @property @trusted {
        ubyte[3] multipliers = void;
        SDL_GetSurfaceColorMod(cast(SDL_Surface*) this._sdlSurface, &multipliers[0], &multipliers[1],
        &multipliers[2]);
        return multipliers;
    }

    /++ 
     + Wraps `SDL_SetSurfaceColorMod` which sets the color multipliers of the `dsdl2.Surface`
     + 
     + Params:
     +   multipliers = an array of `ubyte`s representing red, green, and blue multipliers (each 0-255)
     +/
    void colorMod(ubyte[3] multipliers) @property @trusted {
        SDL_SetSurfaceColorMod(this._sdlSurface, multipliers[0], multipliers[1], multipliers[2]);
    }

    /++ 
     + Wraps `SDL_GetSurfaceAlphaMod` which gets the alpha multiplier of the `dsdl2.Surface`
     + 
     + Returns: alpha multiplier of the `dsdl2.Surface`
     +/
    ubyte alphaMod() const @property @trusted {
        ubyte multiplier = void;
        SDL_GetSurfaceAlphaMod(cast(SDL_Surface*) this._sdlSurface, &multiplier);
        return multiplier;
    }

    /++ 
     + Wraps `SDL_SetSurfaceAlphaMod` which sets the alpha multiplier of the `dsdl2.Surface`
     + 
     + Params:
     +   multiplier = alpha multiplier (0-255)
     +/
    void alphaMod(ubyte multiplier) @property @trusted {
        SDL_SetSurfaceAlphaMod(this._sdlSurface, multiplier);
    }

    /++ 
     + Wraps `SDL_GetClipRect` which gets the clipping `dsdl2.Rect` of the `dsdl2.Surface`
     + 
     + Returns: clipping `dsdl2.Rect` of the `dsdl2.Surface`
     +/
    Rect clipRect() const @property @trusted {
        Rect rect = void;
        SDL_GetClipRect(cast(SDL_Surface*) this._sdlSurface, &rect._sdlRect);
        return rect;
    }

    /++ 
     + Wraps `SDL_SetClipRect` which sets the clipping `dsdl2.Rect` of the `dsdl2.Surface`
     + 
     + Params:
     +   rect = `dsdl2.Rect` to set as the clipping rectangle
     +/
    void clipRect(Rect rect) @property @trusted {
        SDL_SetClipRect(this._sdlSurface, &rect._sdlRect);
    }

    /++ 
     + Acts as `SDL_SetClipRect(surface, NULL)` which removes the clipping `dsdl2.Rect` of the 
     + `dsdl2.Surface`
     +/
    void clipRect(typeof(null) _) @property @trusted {
        SDL_SetClipRect(this._sdlSurface, null);
    }

    /++ 
     + Wraps `SDL_GetColorKey` which gets the color key used by the `dsdl2.Surface` for transparency
     + 
     + Returns: transparency color key in `dsdl2.Color`
     + Throws: `dsdl2.SDLException` if color key unable to be fetched
     +/
    Color colorKey() const @property @trusted {
        uint key = void;
        if (SDL_GetColorKey(cast(SDL_Surface*) this._sdlSurface, &key) != 0) {
            throw new SDLException;
        }

        if (this.pixelFormat.hasAlpha) {
            return this.pixelFormat.getRGBA(key);
        }
        else {
            return this.pixelFormat.getRGB(key);
        }
    }

    /++ 
     + Wraps `SDL_SetColorKey` which sets the color key used for the `dsdl2.Surface` making pixels of the same
     + color transparent
     + 
     + Params:
     +   pixelKey = pixel value of the color key that get transparency
     + Throws: `dsdl2.SDLException` if color key unable to set
     +/
    void colorKey(uint pixelKey) @property @trusted {
        if (SDL_SetColorKey(this._sdlSurface, SDL_TRUE, pixelKey) != 0) {
            throw new SDLException;
        }
    }

    /++ 
     + Wraps `SDL_SetColorKey` which sets the color key used for the `dsdl2.Surface` making pixels of the same
     + color transparent
     + 
     + Params:
     +   key = `dsdl2.Color` specifying pixels that get transparency
     + Throws: `dsdl2.SDLException` if color key unable to set
     +/
    void colorKey(Color key) @property @trusted {
        if (this.pixelFormat.hasAlpha) {
            this.colorKey = this.pixelFormat.mapRGBA(key);
        }
        else {
            this.colorKey = this.pixelFormat.mapRGB(key);
        }
    }

    /++ 
     + Acts as `SDL_SetColorKey(surface, NULL)` which disables color-keying
     +/
    void colorKey(typeof(null) _) @property @trusted {
        if (SDL_SetColorKey(this._sdlSurface, SDL_FALSE, 0) != 0) {
            throw new SDLException;
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_9) {
        /++ 
         + Wraps `SDL_HasColorKey` which checks whether the `dsdl2.Surface` has a color key for transparency
         + 
         + Returns: `true` if it does, otherwise `false`
         +/
        bool hasColorKey() const @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 9));
        }
        do {
            return SDL_HasColorKey(cast(SDL_Surface*) this._sdlSurface) == SDL_TRUE;
        }
    }

    /++ 
     + Wraps `SDL_GetSurfaceBlendMode` which gets the `dsdl2.Surface`'s `dsdl2.BlendMode` defining blitting
     + 
     + Returns: `dsdl2.BlendMode` of the `dsdl2.Surface`
     + Throws: `dsdl2.SDLException` if `dsdl2.BlendMode` unable to get
     +/
    BlendMode blendMode() const @property @trusted {
        BlendMode mode = void;
        if (SDL_GetSurfaceBlendMode(cast(SDL_Surface*) this._sdlSurface, &mode._sdlBlendMode) != 0) {
            throw new SDLException;
        }

        return mode;
    }

    /++ 
     + Wraps `SDL_SetSurfaceBlendMode` which sets the `dsdl2.Surface`'s `dsdl2.BlendMode` defining blitting
     + 
     + Params:
     +   mode = `dsdl2.BlendMode` to set
     + Throws: `dsdl2.SDLException` if `dsdl2.BlendMode` unable to set
     +/
    void blendMode(BlendMode mode) @property @trusted {
        if (SDL_SetSurfaceBlendMode(this._sdlSurface, mode._sdlBlendMode) != 0) {
            throw new SDLException;
        }
    }

    /++ 
     + Wraps `SDL_ConvertPixels` which converts the `dsdl2.Surface` from its RGB(A) `dsdl2.PixelFormat` to another
     + `dsdl2.Surface` with a different RGB(A) `dsdl2.PixelFormat` 
     + 
     + Params:
     +   rgbPixelFormat = the RGB(A) `dsdl2.PixelFormat` to target the conversion
     + Returns: result `dsdl2.Surface` with the `targetPixelFormat`
     + Throws: `dsdl2.SDLException` if pixels failed to convert
     +/
    Surface convert(const PixelFormat rgbPixelFormat) const @trusted
    in {
        assert(!this.pixelFormat.isIndexed);
        assert(rgbPixelFormat !is null);
    }
    do {
        auto target = new Surface([this.width, this.height], rgbPixelFormat);
        if (SDL_ConvertPixels(this.width, this.height, this.pixelFormat._sdlPixelFormatEnum,
                this._sdlSurface.pixels, this.pitch.to!int, target.pixelFormat._sdlPixelFormatEnum,
                target._sdlSurface.pixels, target.pitch.to!int) != 0) {
            throw new SDLException;
        }

        return target;
    }

    /++ 
     + Acts as `SDL_FillRect(surface, NULL)` which fills the entire `dsdl2.Surface` with a pixel value
     + 
     + Params:
     +   pixel = pixel value of the color to fill the entire `dsdl2.Surface`
     +/
    void fill(uint pixel) @trusted {
        if (SDL_FillRect(this._sdlSurface, null, pixel) != 0) {
            throw new SDLException;
        }
    }

    /++ 
     + Acts as `SDL_FillRect(surface, NULL)` which fills the entire `dsdl2.Surface` with a `dsdl2.Color` value
     + 
     + Params:
     +   color = `dsdl2.Color` of the color to fill the entire `dsdl2.Surface`
     +/
    void fill(Color color) @trusted {
        if (this.pixelFormat.hasAlpha) {
            this.fill(this.pixelFormat.mapRGBA(color));
        }
        else {
            this.fill(this.pixelFormat.mapRGB(color));
        }
    }

    /++ 
     + Wraps `SDL_FillRect` which draws a filled rectangle in the `dsdl2.Surface` with specifying a pixel color value
     + 
     + Params:
     +   rect  = `dsdl2.Rect` specifying the position and size
     +   pixel = pixel value of the color to fill the rectangle
     + Throws: `dsdl2.SDLException` if rectangle failed to draw
     +/
    void fillRect(Rect rect, uint pixel) @trusted {
        if (SDL_FillRect(this._sdlSurface, &rect._sdlRect, pixel) != 0) {
            throw new SDLException;
        }
    }

    /++ 
     + Wraps `SDL_FillRect` which draws a filled rectangle in the `dsdl2.Surface` with specifying a `dsdl2.Color` value
     + 
     + Params:
     +   rect  = `dsdl2.Rect` specifying the position and size
     +   color = `dsdl2.Color` of the color to fill the rectangle
     + Throws: `dsdl2.SDLException` if rectangle failed to draw
     +/
    void fillRect(Rect rect, Color color) @trusted {
        if (this.pixelFormat.hasAlpha) {
            this.fillRect(rect, this.pixelFormat.mapRGBA(color));
        }
        else {
            this.fillRect(rect, this.pixelFormat.mapRGB(color));
        }
    }

    /++ 
     + Wraps `SDL_FillRects` which draws multiple filled rectangles in the `dsdl2.Surface` with specifying a pixel
     + color value
     + 
     + Params:
     +   rects = an array of `dsdl2.Rect`s specifying the drawn rectangles' positions and sizes
     +   pixel = pixel value of the color to fill the rectangles
     + Throws: `dsdl2.SDLException` if the rectangles failed to draw
     +/
    void fillRects(const Rect[] rects, uint pixel) @trusted {
        if (SDL_FillRects(this._sdlSurface, cast(SDL_Rect*) rects.ptr, rects.length.to!int, pixel) != 0) {
            throw new SDLException;
        }
    }

    /++ 
     + Wraps `SDL_FillRects` which draws multiple filled rectangles in the `dsdl2.Surface` with specifying a
     + `dsdl2.Color` value
     + 
     + Params:
     +   rects = an array of `dsdl2.Rect`s specifying the drawn rectangles' positions and sizes
     +   color = `dsdl2.Color` of the color to fill the rectangles
     + Throws: `dsdl2.SDLException` if the rectangles failed to draw
     +/
    void fillRects(const Rect[] rects, Color color) @trusted {
        if (this.pixelFormat.hasAlpha) {
            this.fillRects(rects, this.pixelFormat.mapRGBA(color));
        }
        else {
            this.fillRects(rects, this.pixelFormat.mapRGB(color));
        }
    }

    /++ 
     + Wraps `SDL_BlitSurface` which blits/draws a `dsdl2.Surface` on top of the `dsdl2.Surface` at a specific
     + point as the top-left point of the drawn `dsdl2.Surface` without any scaling done
     + 
     + Params:
     +   destPoint = top-left `dsdl2.Point` of where `source` is drawn
     +   source    = `dsdl2.Surface` to blit/draw
     +/
    void blit(Point destPoint, const Surface source) @trusted {
        SDL_Rect dstrect = SDL_Rect(destPoint.x, destPoint.y, 0, 0);
        if (SDL_BlitSurface(cast(SDL_Surface*) source._sdlSurface, null, this._sdlSurface, &dstrect) != 0) {
            throw new SDLException;
        }
    }

    /++ 
     + Wraps `SDL_BlitSurface` which blits/draws a `dsdl2.Surface` on top of the `dsdl2.Surface` at a specific
     + point as the top-left point of the drawn `dsdl2.Surface` without any scaling done
     + 
     + Params:
     +   destPoint  = top-left `dsdl2.Point` of where `source` is drawn
     +   source     = `dsdl2.Surface` to blit/draw
     +   sourceRect = the clipping rect of `source` specifying which part is drawn
     +/
    void blit(Point destPoint, const Surface source, Rect sourceRect) @trusted {
        SDL_Rect dstrect = SDL_Rect(destPoint.x, destPoint.y, 0, 0);
        if (SDL_BlitSurface(cast(SDL_Surface*) source._sdlSurface, &sourceRect._sdlRect, this._sdlSurface,
                &dstrect) != 0) {
            throw new SDLException;
        }
    }

    /++ 
     + Wraps `SDL_BlitScaled` which blits/draws a `dsdl2.Surface` on top of the `dsdl2.Surface` at a specific
     + point as the top-left point of the drawn `dsdl2.Surface` with scaling
     + 
     + Params:
     +   destRect = `dsdl2.Rect` of where `source` should be drawn (squeezes/stretches to the dimensions as well)
     +   source   = `dsdl2.Surface` to blit/draw
     +/
    void blitScaled(Rect destRect, const Surface source) @trusted {
        if (SDL_BlitScaled(cast(SDL_Surface*) source._sdlSurface, null, this._sdlSurface,
                &destRect._sdlRect) != 0) {
            throw new SDLException;
        }
    }

    /++ 
     + Wraps `SDL_BlitScaled` which blits/draws a `dsdl2.Surface` on top of the `dsdl2.Surface` at a specific
     + point as the top-left point of the drawn `dsdl2.Surface` with scaling
     + 
     + Params:
     +   destRect   = `dsdl2.Rect` of where `source` should be drawn (squeezes/stretches to the dimensions as well)
     +   source     = `dsdl2.Surface` to blit/draw
     +   sourceRect = the clipping rect of `source` specifying which part is drawn
     +/
    void blitScaled(Rect destRect, const Surface source, Rect sourceRect) @trusted {
        if (SDL_BlitSurface(cast(SDL_Surface*) source._sdlSurface, &sourceRect._sdlRect, this._sdlSurface,
                &destRect._sdlRect) != 0) {
            throw new SDLException;
        }
    }
}
