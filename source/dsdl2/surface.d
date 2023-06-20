/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org/, MIT License)
 +/

module dsdl2.surface;
@safe:

import bindbc.sdl;
import dsdl2.sdl;
import dsdl2.pixels;
import dsdl2.rect;

import std.format : format;

/++ 
 + A D class that wraps `SDL_Surface` storing a 2D image in pixels with a `width` and `height`, each pixel stored
 + in the RAM according to a certain `dsdl2.PixelFormat`.
 +/
final class Surface {
    private PixelFormat pixelFormatProxy = null;
    @system SDL_Surface* _sdlSurface = null; /// Internal `SDL_Surface` pointer
    private bool isOwner = true;

    /++ 
     + Constructs a `dsdl2.Surface` from a vanilla `SDL_Surface*` from bindbc-sdl
     + 
     + Params:
     +   sdlSurface = the `SDL_Surface` pointer to manage
     +   owns       = whether the instance owns the given `SDL_Surface*` and should destroy it on its own
     +/
    this(SDL_Surface* sdlSurface, bool owns = true) @system
    in {
        assert(sdlSurface !is null);
    }
    do {
        this._sdlSurface = sdlSurface;
        this.isOwner = owns;
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
    this(int[2] size, const PixelFormat rgbPixelFormat) @trusted
    in {
        assert(size[0] > 0 && size[1] > 0);
        assert(rgbPixelFormat !is null);
        assert(!rgbPixelFormat.isIndexed);
    }
    do {
        uint[4] masks = rgbPixelFormat.toMasks();

        this._sdlSurface = SDL_CreateRGBSurface(0, size[0], size[1], rgbPixelFormat.bitDepth, masks[0],
        masks[1], masks[2], masks[3]);
        if (this._sdlSurface is null) {
            throw new SDLException;
        }

        this.pixelFormatProxy = new PixelFormat(this._sdlSurface.format, false);
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
    this(void[] pixels, int[2] size, int pitch, const PixelFormat rgbPixelFormat) @trusted
    in {
        assert(pixels !is null);
        assert(rgbPixelFormat !is null);
        assert(!rgbPixelFormat.isIndexed);
        assert(size[0] > 0 && size[1] > 0);
        assert(pitch * 8 >= size[0] * rgbPixelFormat.bitDepth);
        assert(pixels.length == pitch * size[1]);
    }
    do {
        this(size, rgbPixelFormat);

        size_t lineBitSize = size[0] * rgbPixelFormat.bitDepth;
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
    this(int[2] size, int bitDepth, Palette boundPalette) @trusted
    in {
        assert(size[0] > 0 && size[1] > 0);
        assert(bitDepth == 1 || bitDepth == 4 || bitDepth == 8);
        assert(boundPalette !is null);
    }
    do {
        this._sdlSurface = SDL_CreateRGBSurface(0, size[0], size[1], bitDepth, 0, 0, 0, 0);
        if (this._sdlSurface is null) {
            throw new SDLException;
        }

        this.pixelFormatProxy = new PixelFormat(this._sdlSurface.format, false);
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
    this(void[] pixels, int[2] size, int pitch, int bitDepth, Palette boundPalette) @trusted
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
}
