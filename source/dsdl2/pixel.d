/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org/, MIT License)
 +/

module dsdl2.pixel;

import bindbc.sdl;
import dsdl2.sdl;

import std.format : format;

struct Color {
    SDL_Color sdlColor;
    alias sdlColor this;

    @disable this();

    this(ubyte r, ubyte g, ubyte b, ubyte a = 255) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }

    string toString() const {
        return "dsdl2.Color(%d, %d, %d, %d)".format(this.r, this.g, this.b, this.a);
    }
}

final class Palette {
    SDL_Palette* _sdlPalette = null;

    this(SDL_Palette* sdlPalette)
    in {
        assert(this._sdlPalette !is null);
    }
    do {
        this._sdlPalette = sdlPalette;
    }

    this(int ncolors) {
        this._sdlPalette = SDL_AllocPalette(ncolors);
        if (this._sdlPalette is null) {
            throw new SDLException;
        }
    }

    this(const Color[] colors) {
        this._sdlPalette = SDL_AllocPalette(cast(int) colors.length);
        if (this._sdlPalette is null) {
            throw new SDLException;
        }

        foreach (i, const ref Color color; colors) {
            this._sdlPalette.colors[i] = color.sdlColor;
        }
    }

    ~this() {
        SDL_FreePalette(this._sdlPalette);
    }

    invariant {
        assert(this._sdlPalette !is null);
    }

    size_t length() const {
        return this._sdlPalette.ncolors;
    }

    ref inout(Color) opIndex(size_t i) inout
    in {
        assert(0 <= i && i < this.length);
    }
    do {
        return *cast(inout(Color*))&this._sdlPalette.colors[i];
    }

    size_t opDollar(size_t dim)() const if (dim == 0) {
        return this.length;
    }

    override string toString() const {
        string str = "dsdl2.Palette([";

        foreach (size_t i; 0 .. this.length) {
            str ~= this[i].toString();

            if (i + 1 < this.length) {
                str ~= ", ";
            }
        }

        return str ~= "])";
    }
}

final class PixelFormat {
private:
    Palette paletteRef = null;

public:
    static const(PixelFormat) _multiton(SDL_PixelFormatEnum sdlPixelFormatEnum, ubyte minMinorVer = 0,
        ubyte minPatchVer = 0)()
    in {
        assert(getVersion() >= Version(2, minMinorVer, minPatchVer));
    }
    do {
        static PixelFormat pixelFormat = null;
        if (pixelFormat is null) {
            pixelFormat = new PixelFormat(sdlPixelFormatEnum);
        }

        return pixelFormat;
    }

    static PixelFormat _instantiateIndexed(SDL_PixelFormatEnum sdlPixelFormatEnum)(Palette palette)
    in {
        assert(palette !is null);
    }
    do {
        return new PixelFormat(sdlPixelFormatEnum, palette);
    }

    static alias index1lsb = _instantiateIndexed!SDL_PIXELFORMAT_INDEX1LSB;
    static alias index1msb = _instantiateIndexed!SDL_PIXELFORMAT_INDEX1MSB;
    static alias index4lsb = _instantiateIndexed!SDL_PIXELFORMAT_INDEX4LSB;
    static alias index4msb = _instantiateIndexed!SDL_PIXELFORMAT_INDEX4MSB;
    static alias index8 = _multiton!SDL_PIXELFORMAT_INDEX8;
    static alias rgb332 = _multiton!SDL_PIXELFORMAT_RGB332;
    static alias rgb444 = _multiton!SDL_PIXELFORMAT_RGB444;
    static alias rgb555 = _multiton!SDL_PIXELFORMAT_RGB555;
    static alias bgr555 = _multiton!SDL_PIXELFORMAT_BGR555;
    static alias argb4444 = _multiton!SDL_PIXELFORMAT_ARGB4444;
    static alias rgba444 = _multiton!SDL_PIXELFORMAT_RGBA4444;
    static alias abgr4444 = _multiton!SDL_PIXELFORMAT_ABGR4444;
    static alias bgra4444 = _multiton!SDL_PIXELFORMAT_BGRA4444;
    static alias argb1555 = _multiton!SDL_PIXELFORMAT_ARGB1555;
    static alias rgba5551 = _multiton!SDL_PIXELFORMAT_RGBA5551;
    static alias abgr1555 = _multiton!SDL_PIXELFORMAT_ABGR1555;
    static alias bgra5551 = _multiton!SDL_PIXELFORMAT_BGRA5551;
    static alias rgb565 = _multiton!SDL_PIXELFORMAT_RGB565;
    static alias bgr565 = _multiton!SDL_PIXELFORMAT_BGR565;
    static alias rgb24 = _multiton!SDL_PIXELFORMAT_RGB24;
    static alias bgr24 = _multiton!SDL_PIXELFORMAT_BGR24;
    static alias rgb888 = _multiton!SDL_PIXELFORMAT_RGB888;
    static alias rgbx8888 = _multiton!SDL_PIXELFORMAT_RGBX8888;
    static alias bgr888 = _multiton!SDL_PIXELFORMAT_BGR888;
    static alias bgrx8888 = _multiton!SDL_PIXELFORMAT_BGRX8888;
    static alias argb8888 = _multiton!SDL_PIXELFORMAT_ARGB8888;
    static alias rgba8888 = _multiton!SDL_PIXELFORMAT_RGBA8888;
    static alias abgr8888 = _multiton!SDL_PIXELFORMAT_ABGR8888;
    static alias bgra8888 = _multiton!SDL_PIXELFORMAT_BGRA8888;
    static alias argb2101010 = _multiton!SDL_PIXELFORMAT_ARGB2101010;
    static alias yv12 = _multiton!SDL_PIXELFORMAT_YV12;
    static alias iyuv = _multiton!SDL_PIXELFORMAT_IYUV;
    static alias yuy2 = _multiton!SDL_PIXELFORMAT_YUY2;
    static alias uyvy = _multiton!SDL_PIXELFORMAT_UYVY;
    static alias yvyu = _multiton!SDL_PIXELFORMAT_YVYU;

    static if (sdlSupport >= SDLSupport.v2_0_4) {
        static alias nv12 = _multiton!(SDL_PIXELFORMAT_NV12, 0, 4);
        static alias nv21 = _multiton!(SDL_PIXELFORMAT_NV21, 0, 4);
    }

    static if (sdlSupport >= SDLSupport.v2_0_5) {
        static alias rgba32 = _multiton!(SDL_PIXELFORMAT_RGBA32, 0, 5);
        static alias argb32 = _multiton!(SDL_PIXELFORMAT_ARGB32, 0, 5);
        static alias bgra32 = _multiton!(SDL_PIXELFORMAT_BGRA32, 0, 5);
        static alias abgr32 = _multiton!(SDL_PIXELFORMAT_ABGR32, 0, 5);
    }

    SDL_PixelFormat* _sdlPixelFormat = null;

    this(SDL_PixelFormatEnum sdlPixelFormatEnum)
    in {
        assert(sdlPixelFormatEnum != SDL_PIXELFORMAT_UNKNOWN);
        assert(!SDL_ISPIXELFORMAT_INDEXED(sdlPixelFormatEnum));
    }
    do {
        this._sdlPixelFormat = SDL_AllocFormat(sdlPixelFormatEnum);
        if (this._sdlPixelFormat is null) {
            throw new SDLException;
        }
    }

    this(SDL_PixelFormatEnum sdlPixelFormatEnum, Palette palette)
    in {
        assert(SDL_ISPIXELFORMAT_INDEXED(sdlPixelFormatEnum));
        assert(palette !is null);
    }
    do {
        this._sdlPixelFormat = SDL_AllocFormat(sdlPixelFormatEnum);
        if (this._sdlPixelFormat is null) {
            throw new SDLException;
        }

        if (SDL_SetPixelFormatPalette(this._sdlPixelFormat, palette._sdlPalette) != 0) {
            throw new SDLException;
        }

        this.paletteRef = palette;
    }

    this(int bitDepth, uint redMask, uint greenMask, uint blueMask, uint alphaMask) {
        uint sdlPixelFormatEnum = SDL_MasksToPixelFormatEnum(bitDepth, redMask, greenMask, blueMask, alphaMask);
        if (sdlPixelFormatEnum == SDL_PIXELFORMAT_UNKNOWN) {
            throw new SDLException("Pixel format conversion is not possible", __FILE__, __LINE__);
        }

        this(sdlPixelFormatEnum);
    }

    this(SDL_PixelFormat* sdlPixelFormat)
    in {
        assert(sdlPixelFormat !is null);
    }
    do {
        this._sdlPixelFormat = sdlPixelFormat;
    }

    ~this() {
        SDL_FreeFormat(this._sdlPixelFormat);
    }

    invariant {
        assert(this._sdlPixelFormat !is null);
        assert(this._sdlPixelFormat.format != SDL_PIXELFORMAT_UNKNOWN);

        if (SDL_ISPIXELFORMAT_INDEXED(this._sdlPixelFormat.format)) {
            assert(this.paletteRef !is null);
            assert(this._sdlPixelFormat.palette !is null);
        }
    }

    override string toString() const {
        if (SDL_ISPIXELFORMAT_INDEXED(this._sdlPixelFormat.format)) {
            return "dsdl2.PixelFormat(%s, %s)".format(
                SDL_GetPixelFormatName(
                    this._sdlPixelFormat.format), this.paletteRef);
        }
        else {
            return "dsdl2.PixelFormat(%s)".format(
                SDL_GetPixelFormatName(this._sdlPixelFormat.format));
        }
    }

    Color get(uint pixel) const {
        Color color = Color(0, 0, 0, 255);
        SDL_GetRGBA(pixel, this._sdlPixelFormat, &color.r, &color.g, &color.b, &color.a);
        return color;
    }

    uint map(Color color) const {
        return SDL_MapRGBA(this._sdlPixelFormat, color.r, color.g, color.b, color.a);
    }

    uint bitDepth() const {
        return this._sdlPixelFormat.BitsPerPixel;
    }

    uint[4] bitMask() const {
        uint[4] rgbaMasks = void;
        int bitDepth = void;

        if (SDL_PixelFormatEnumToMasks(this._sdlPixelFormat.format, &bitDepth, &rgbaMasks[0], &rgbaMasks[1],
            &rgbaMasks[2], &rgbaMasks[3]) == SDL_FALSE) {
            throw new SDLException;
        }

        return rgbaMasks;
    }

    void setPalette(Palette palette)
    in {
        assert(this.isIndexed());
        assert(palette !is null);
    }
    do {
        if (SDL_SetPixelFormatPalette(this._sdlPixelFormat, palette._sdlPalette) != 0) {
            throw new SDLException;
        }

        this.paletteRef = palette;
    }

    inout(Palette) getPalette() inout
    in {
        assert(this.isIndexed());
    }
    do {
        return this.paletteRef;
    }

    bool isIndexed() const {
        return SDL_ISPIXELFORMAT_INDEXED(this._sdlPixelFormat.format);
    }

    bool hasAlpha() const {
        return SDL_ISPIXELFORMAT_ALPHA(this._sdlPixelFormat.format);
    }

    bool isUnique() const {
        return SDL_ISPIXELFORMAT_FOURCC(this._sdlPixelFormat.format) != 0;
    }
}
