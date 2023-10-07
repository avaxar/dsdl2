/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.ttf;
@safe:

// dfmt off
import bindbc.sdl;
static if (bindSDLTTF):
// dfmt on

import dsdl2.sdl;
import dsdl2.surface;

import core.memory : GC;
import std.conv : to;
import std.format : format;
import std.string : toStringz;
import std.typecons : Tuple;

version (BindSDL_Static) {
}
else {
    /++
     + Loads the SDL2_ttf shared dynamic library, which wraps bindbc-sdl's `loadSDLTTF` function
     +
     + Unless if bindbc-sdl is on static mode (by adding a `BindSDL_Static` version), this function will exist and must
     + be called before any calls are made to the library. Otherwise, a segfault will happen upon any function calls.
     +
     + Params:
     +   libName = name or path to look the SDL2_ttf SO/DLL for, otherwise `null` for default searching path
     + Throws: `dsdl2.SDLException` if failed to find the library
     +/
    void loadSO(string libName = null) @trusted {
        SDLTTFSupport current = libName is null ? loadSDLTTF() : loadSDLTTF(libName.toStringz());
        if (current == sdlTTFSupport) {
            return;
        }

        Version wanted = Version(sdlTTFSupport);
        if (current == SDLTTFSupport.badLibrary) {
            import std.stdio : writeln;

            writeln("WARNING: dsdl2 expects SDL_ttf ", wanted.format(), ", but got ", getVersion().format(), ".");
        }
        else if (current == SDLTTFSupport.noLibrary) {
            throw new SDLException("No SDL2_ttf library found, especially of version " ~ wanted.format(),
                __FILE__, __LINE__);
        }
    }
}

/++
 + Wraps `TTF_Init` which initializes SDL2_ttf
 +
 + Throws: `dsdl2.SDLException` if failed to initialize
 + Example:
 + ---
 + dsdl2.ttf.init();
 + ---
 +/
void init() @trusted {
    if (TTF_Init() != 0) {
        throw new SDLException;
    }
}

version (unittest) {
    static this() {
        version (BindSDL_Static) {
        }
        else {
            dsdl2.ttf.loadSO();
        }

        dsdl2.ttf.init();
    }
}

/++
 + Wraps `TTF_Quit` which deinitializes SDL2_ttf
 +/
void quit() @trusted {
    TTF_Quit();
}

/++
 + Wraps `TTF_WasInit` which checks whether SDL2_ttf has been initialized
 +
 + Returns: `true` if the library has been initialized, otherwise `false`
 +/
bool wasInit() @trusted {
    return TTF_WasInit() > 0;
}

/++
 + Wraps `TTF_Linked_version` which gets the version of the linked SDL2_ttf library
 +
 + Returns: `dsdl2.Version` of the linked SDL2_ttf library
 +/
Version getVersion() @trusted {
    return Version(*TTF_Linked_Version());
}

static if (sdlTTFSupport >= SDLTTFSupport.v2_0_18) {
    /++
     + Wraps `TTF_GetFreeTypeVersion` (from SDL_ttf 2.0.18) which gets the version of the FreeType library used by the
     + linked SDL2_ttf
     +
     + Returns: `dsdl2.Version` of the used FreeType library
     +/
    Version getFreeTypeVersion() @trusted
    in {
        assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
    }
    do {
        int[3] ver = void;
        TTF_GetFreeTypeVersion(&ver[0], &ver[1], &ver[2]);
        return Version(ver[0].to!ubyte, ver[1].to!ubyte, ver[2].to!ubyte);
    }

    /++
     + Wraps `TTF_GetHarfBuzzVersion` (from SDL_ttf 2.0.18) which gets the version of the HarfBuzz library used by the
     + linked SDL2_ttf
     +
     + Returns: `dsdl2.Version` of the used HarfBuzz library
     +/
    Version getHarfBuzzVersion() @trusted
    in {
        assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
    }
    do {
        int[3] ver = void;
        TTF_GetHarfBuzzVersion(&ver[0], &ver[1], &ver[2]);
        return Version(ver[0].to!ubyte, ver[1].to!ubyte, ver[2].to!ubyte);
    }
}

/++
 + D struct that wraps a glyph's metrics information
 +/
struct GlyphMetrics {
    int[2] min;
    int[2] max;
    int advance;

    this() @disable;

    this(int[2] min, int[2] max, int advance) {
        this.min = min;
        this.max = max;
        this.advance = advance;
    }

    /++
     + Formats the `dsdl2.ttf.GlyphMetrics` into its construction representation:
     + `"dsdl2.ttf.GlyphMetrics(<min>, <max>, <advance>)"`
     +
     + Returns: the formatted `string`
     +/
    string toString() const {
        return "dsdl2.ttf.GlyphMetrics(%s, %s, %d)".format(this.min, this.max, this.advance);
    }

    /++
     + Proxy to the minimum X value of the `dsdl2.ttf.GlyphMetrics`
     +
     + Returns: minimum X value of the `dsdl2.ttf.GlyphMetrics`
     +/
    ref inout(int) minX() return inout @property {
        return this.min[0];
    }

    /++
     + Proxy to the minimum Y value of the `dsdl2.ttf.GlyphMetrics`
     +
     + Returns: minimum Y value of the `dsdl2.ttf.GlyphMetrics`
     +/
    ref inout(int) minY() return inout @property {
        return this.min[1];
    }

    /++
     + Proxy to the maximum X value of the `dsdl2.ttf.GlyphMetrics`
     +
     + Returns: maximum X value of the `dsdl2.ttf.GlyphMetrics`
     +/
    ref inout(int) maxX() return inout @property {
        return this.max[0];
    }

    /++
     + Proxy to the maximum Y value of the `dsdl2.ttf.GlyphMetrics`
     +
     + Returns: maximum Y value of the `dsdl2.ttf.GlyphMetrics`
     +/
    ref inout(int) maxY() return inout @property {
        return this.max[1];
    }
}

/++
 + D enum that wraps `TTF_HINTING_*` enumerations
 +/
enum Hinting {
    /++
     + Wraps `TTF_HINTING_*` enumeration constants
     +/
    normal = TTF_HINTING_NORMAL,
    light = TTF_HINTING_LIGHT, /// ditto
    mono = TTF_HINTING_MONO, /// ditto
    none = TTF_HINTING_NONE, /// ditto

    lightSubpixel = 4 /// Wraps `TTF_HINTING_LIGHT_SUBPIXEL` (from SDL_ttf 2.0.18)
}

static if (sdlTTFSupport >= SDLTTFSupport.v2_20) {
    /++
     + D enum that wraps `TTF_WRAPPED_ALIGN_*` enumerations (from SDL_ttf 2.20)
     +/
    enum WrappedAlign {
        /++
         + Wraps `TTF_WRAPPED_ALIGN_*` enumeration constants
         +/
        left = TTF_WRAPPED_ALIGN_LEFT,
        center = TTF_WRAPPED_ALIGN_CENTER, /// ditto
        right = TTF_WRAPPED_ALIGN_RIGHT /// ditto
    }

    /++
     + D enum that wraps `TTF_Direction` (from SDL_ttf 2.20)
     +/
    enum Direction {
        /++
         + Wraps `TTF_DIRECTION_*` enumeration constants
         +/
        leftToRight = TTF_DIRECTION_LTR,
        rightToLeft = TTF_DIRECTION_RTL, /// ditto
        topToBottom = TTF_DIRECTION_TTB, /// ditto
        bottomToTop = TTF_DIRECTION_BTT /// ditto
    }
}

/++
 + D class that wraps `TTF_Font` enclosing a font object to render text from
 +/
final class Font {
    private bool isOwner = true;
    private void* userRef = null;

    @system TTF_Font* ttfFont = null; /// Internal `TTF_Font` pointer

    /++
     + Constructs a `dsdl2.ttf.Font` from a vanilla `TTF_Font*` from bindbc-sdl
     +
     + Params:
     +   ttfFont = the `TTF_Font` pointer to manage
     +   isOwner = whether the instance owns the given `TTF_Font*` and should destroy it on its own
     +   userRef = optional pointer to maintain reference link, avoiding GC cleanup
     +/
    this(TTF_Font* ttfFont, bool isOwner = true, void* userRef = null) @system
    in {
        assert(ttfFont !is null);
    }
    do {
        this.ttfFont = ttfFont;
        this.isOwner = isOwner;
        this.userRef = userRef;
    }

    this(string file, uint size) @trusted {
        this.ttfFont = TTF_OpenFont(file.toStringz(), size.to!int);
        if (this.ttfFont is null) {
            throw new SDLException;
        }
    }

    this(string file, uint size, size_t index) @trusted {
        this.ttfFont = TTF_OpenFontIndex(file.toStringz(), size.to!int, index.to!c_long);
        if (this.ttfFont is null) {
            throw new SDLException;
        }
    }

    this(const void[] data, uint size) @trusted {
        SDL_RWops* sdlRWops = SDL_RWFromConstMem(data.ptr, data.length.to!int);
        if (sdlRWops is null) {
            throw new SDLException;
        }

        this.ttfFont = TTF_OpenFontRW(sdlRWops, 1, size.to!int);
        if (this.ttfFont is null) {
            throw new SDLException;
        }
    }

    this(const void[] data, uint size, size_t index) @trusted {
        SDL_RWops* sdlRWops = SDL_RWFromConstMem(data.ptr, data.length.to!int);
        if (sdlRWops is null) {
            throw new SDLException;
        }

        this.ttfFont = TTF_OpenFontIndexRW(sdlRWops, 1, size.to!int, index.to!c_long);
        if (this.ttfFont is null) {
            throw new SDLException;
        }
    }

    static if (sdlTTFSupport >= SDLTTFSupport.v2_0_18) {
        this(string file, uint size, uint hdpi, uint vdpi) @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
        }
        do {
            this.ttfFont = TTF_OpenFontDPI(file.toStringz(), size.to!int, hdpi, vdpi);
            if (this.ttfFont is null) {
                throw new SDLException;
            }
        }

        this(string file, uint size, size_t index, uint hdpi, uint vdpi) @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
        }
        do {
            this.ttfFont = TTF_OpenFontIndexDPI(file.toStringz(), size.to!int, index.to!c_long, hdpi, vdpi);
            if (this.ttfFont is null) {
                throw new SDLException;
            }
        }

        this(const void[] data, uint size, uint hdpi, uint vdpi) @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
        }
        do {
            SDL_RWops* sdlRWops = SDL_RWFromConstMem(data.ptr, data.length.to!int);
            if (sdlRWops is null) {
                throw new SDLException;
            }

            this.ttfFont = TTF_OpenFontDPIRW(sdlRWops, 1, size.to!int, hdpi, vdpi);
            if (this.ttfFont is null) {
                throw new SDLException;
            }
        }

        this(const void[] data, uint size, size_t index, uint hdpi, uint vdpi) @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
        }
        do {
            SDL_RWops* sdlRWops = SDL_RWFromConstMem(data.ptr, data.length.to!int);
            if (sdlRWops is null) {
                throw new SDLException;
            }

            this.ttfFont = TTF_OpenFontIndexDPIRW(sdlRWops, 1, size.to!int, index.to!c_long, hdpi, vdpi);
            if (this.ttfFont is null) {
                throw new SDLException;
            }
        }
    }

    ~this() @trusted {
        if (this.isOwner) {
            TTF_CloseFont(this.ttfFont);
        }
    }

    @trusted invariant {
        // Instance might be in an invalid state due to holding a non-owned externally-freed object when
        // destructed in an unpredictable order.
        if (!this.isOwner && GC.inFinalizer) {
            return;
        }

        assert(this.ttfFont !is null);
    }

    /++
     + Equality operator overload
     +/
    bool opEquals(const Font rhs) const @trusted {
        return this.ttfFont is rhs.ttfFont;
    }

    /++
     + Gets the hash of the `dsdl2.ttf.Font`
     +
     + Returns: unique hash for the instance being the pointer of the internal `TTF_Font` pointer
     +/
    override hash_t toHash() const @trusted {
        return cast(hash_t) this.ttfFont;
    }

    /++
     + Formats the `dsdl2.ttf.Font` into its construction representation: `"dsdl2.ttf.Font(<ttfFont>)"`
     +
     + Returns: the formatted `string`
     +/
    override string toString() const @trusted {
        return "dsdl2.ttf.Font(0x%x)".format(this.ttfFont);
    }

    bool bold() const @property @trusted {
        return (TTF_GetFontStyle(this.ttfFont) & TTF_STYLE_BOLD) == TTF_STYLE_BOLD;
    }

    void bold(bool newBold) @property @trusted {
        if (newBold) {
            TTF_SetFontStyle(this.ttfFont, TTF_GetFontStyle(this.ttfFont) | TTF_STYLE_BOLD);
        }
        else {
            TTF_SetFontStyle(this.ttfFont, TTF_GetFontStyle(this.ttfFont) & ~TTF_STYLE_BOLD);
        }
    }

    bool italic() const @property @trusted {
        return (TTF_GetFontStyle(this.ttfFont) & TTF_STYLE_ITALIC) == TTF_STYLE_ITALIC;
    }

    void italic(bool newItalic) @property @trusted {
        if (newItalic) {
            TTF_SetFontStyle(this.ttfFont, TTF_GetFontStyle(this.ttfFont) | TTF_STYLE_ITALIC);
        }
        else {
            TTF_SetFontStyle(this.ttfFont, TTF_GetFontStyle(this.ttfFont) & ~TTF_STYLE_ITALIC);
        }
    }

    bool underline() const @property @trusted {
        return (TTF_GetFontStyle(this.ttfFont) & TTF_STYLE_UNDERLINE) == TTF_STYLE_UNDERLINE;
    }

    void underline(bool newUnderline) @property @trusted {
        if (newUnderline) {
            TTF_SetFontStyle(this.ttfFont, TTF_GetFontStyle(this.ttfFont) | TTF_STYLE_UNDERLINE);
        }
        else {
            TTF_SetFontStyle(this.ttfFont, TTF_GetFontStyle(this.ttfFont) & ~TTF_STYLE_UNDERLINE);
        }
    }

    bool strikethrough() const @property @trusted {
        return (TTF_GetFontStyle(this.ttfFont) & TTF_STYLE_STRIKETHROUGH) == TTF_STYLE_STRIKETHROUGH;
    }

    void strikethrough(bool newStrikethrough) @property @trusted {
        if (newStrikethrough) {
            TTF_SetFontStyle(this.ttfFont, TTF_GetFontStyle(this.ttfFont) | TTF_STYLE_STRIKETHROUGH);
        }
        else {
            TTF_SetFontStyle(this.ttfFont, TTF_GetFontStyle(this.ttfFont) & ~TTF_STYLE_STRIKETHROUGH);
        }
    }

    uint outline() const @property @trusted {
        return TTF_GetFontOutline(this.ttfFont).to!uint;
    }

    void outline(uint newOutline) @property @trusted {
        TTF_SetFontOutline(this.ttfFont, newOutline.to!int);
    }

    Hinting hinting() const @property @trusted {
        return cast(Hinting) TTF_GetFontHinting(this.ttfFont);
    }

    void hinting(Hinting newHinting) @property @trusted {
        TTF_SetFontHinting(this.ttfFont, newHinting);
    }

    static if (sdlTTFSupport >= SDLTTFSupport.v2_0_18) {
        bool sdf() const @property @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
        }
        do {
            return TTF_GetFontSDF(this.ttfFont) == SDL_TRUE;
        }

        void sdf(bool newSDF) @property @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
        }
        do {
            if (TTF_SetFontSDF(this.ttfFont, newSDF ? SDL_TRUE : SDL_FALSE) != 0) {
                throw new SDLException;
            }
        }

        void size(uint newSize) @property @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
        }
        do {
            if (TTF_SetFontSize(this.ttfFont, newSize.to!int) != 0) {
                throw new SDLException;
            }
        }

        void sizeDPI(Tuple!(uint, uint, uint) newSizeDPI) @property @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
        }
        do {
            if (TTF_SetFontSizeDPI(this.ttfFont, newSizeDPI[0].to!int, newSizeDPI[1], newSizeDPI[2]) != 0) {
                throw new SDLException;
            }
        }
    }

    static if (sdlTTFSupport >= SDLTTFSupport.v2_20) {
        WrappedAlign wrappedAlign() const @property @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 20));
        }
        do {
            return cast(WrappedAlign) TTF_GetFontWrappedAlign(this.ttfFont);
        }

        void wrappedAlign(WrappedAlign newWrappedAlign) @property @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 20));
        }
        do {
            TTF_SetFontWrappedAlign(this.ttfFont, newWrappedAlign);
        }

        void direction(Direction newDirection) @property @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 20));
        }
        do {
            if (TTF_SetFontDirection(this.ttfFont, newDirection) != 0) {
                throw new SDLException;
            }
        }

        void scriptName(string newScriptName) @property @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 20));
        }
        do {
            if (TTF_SetFontScriptName(this.ttfFont, newScriptName.toStringz()) != 0) {
                throw new SDLException;
            }
        }
    }

    int height() const @property @trusted {
        return TTF_FontHeight(this.ttfFont);
    }

    int ascent() const @property @trusted {
        return TTF_FontAscent(this.ttfFont);
    }

    int descent() const @property @trusted {
        return TTF_FontDescent(this.ttfFont);
    }

    int lineSkip() const @property @trusted {
        return TTF_FontLineSkip(this.ttfFont);
    }

    bool kerning() const @property @trusted {
        return TTF_GetFontKerning(this.ttfFont) != 0;
    }

    void kerning(bool newKerning) @property @trusted {
        TTF_SetFontKerning(this.ttfFont, newKerning ? 1 : 0);
    }

    size_t faces() const @property @trusted {
        return TTF_FontFaces(this.ttfFont);
    }

    bool fixedWidth() const @property @trusted {
        return TTF_FontFaceIsFixedWidth(this.ttfFont) != 0;
    }

    string familyName() const @property @trusted {
        return TTF_FontFaceFamilyName(this.ttfFont).to!string;
    }

    string styleName() const @property @trusted {
        return TTF_FontFaceStyleName(this.ttfFont).to!string;
    }

    bool providesGlyph(wchar glyph) const @trusted {
        return TTF_GlyphIsProvided(this.ttfFont, cast(ushort) glyph) != 0;
    }

    static if (sdlTTFSupport >= SDLTTFSupport.v2_0_18) {
        bool providesGlyph(dchar glyph) const @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
        }
        do {
            return TTF_GlyphIsProvided32(cast(TTF_Font*) this.ttfFont, cast(uint) glyph) != 0;
        }
    }

    GlyphMetrics glyphMetrics(wchar glyph) const @trusted {
        GlyphMetrics metrics = void;
        if (TTF_GlyphMetrics(cast(TTF_Font*) this.ttfFont, cast(ushort) glyph, &metrics.min[0], &metrics.max[0],
                &metrics.min[1], &metrics.max[1], &metrics.advance) != 0) {
            throw new SDLException;
        }

        return metrics;
    }

    static if (sdlTTFSupport >= SDLTTFSupport.v2_0_18) {
        GlyphMetrics glyphMetrics(dchar glyph) const @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
        }
        do {
            GlyphMetrics metrics = void;
            if (TTF_GlyphMetrics32(cast(TTF_Font*) this.ttfFont, cast(uint) glyph, &metrics.min[0], &metrics.max[0],
                    &metrics.min[1], &metrics.max[1], &metrics.advance) != 0) {
                throw new SDLException;
            }

            return metrics;
        }
    }

    static if (sdlTTFSupport >= SDLTTFSupport.v2_0_14) {
        int glyphKerning(wchar prevGlyph, wchar glyph) const @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 14));
        }
        do {
            return TTF_GetFontKerningSizeGlyphs(cast(TTF_Font*) this.ttfFont, cast(ushort) prevGlyph,
                cast(ushort) glyph);
        }
    }

    static if (sdlTTFSupport >= SDLTTFSupport.v2_0_18) {
        int glyphKerning(dchar prevGlyph, dchar glyph) const @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
        }
        do {
            return TTF_GetFontKerningSizeGlyphs32(cast(TTF_Font*) this.ttfFont, cast(uint) prevGlyph,
                cast(uint) glyph);
        }
    }

    uint[2] textSize(string text) const @trusted {
        uint[2] wh = void;
        if (TTF_SizeUTF8(cast(TTF_Font*) this.ttfFont, text.toStringz(), cast(int*)&wh[0], cast(int*)&wh[1]) != 0) {
            throw new SDLException;
        }

        return wh;
    }

    uint[2] textSize(wstring text) const @trusted {
        // `std.string.toStringz` doesn't have any `wstring` overloads.
        wchar[] ctext;
        ctext.length = text.length + 1;
        ctext[0 .. text.length] = text;
        ctext[text.length] = '\0';

        uint[2] wh = void;
        if (TTF_SizeUNICODE(cast(TTF_Font*) this.ttfFont, cast(ushort*) ctext.ptr, cast(int*)&wh[0],
                cast(int*)&wh[1]) != 0) {
            throw new SDLException;
        }

        return wh;
    }

    static if (sdlTTFSupport >= SDLTTFSupport.v2_0_18) {
        private alias TextMeasurement = Tuple!(uint, "extent", uint, "count");

        TextMeasurement measureText(string text, uint measureWidth) const @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
        }
        do {
            TextMeasurement measurement = void;
            if (TTF_MeasureUTF8(cast(TTF_Font*) this.ttfFont, text.toStringz(), measureWidth.to!int,
                    cast(int*)&measurement.extent, cast(int*)&measurement.count) != 0) {
                throw new SDLException;
            }

            return measurement;
        }

        TextMeasurement measureText(wstring text, uint measureWidth) const @trusted
        in {
            assert(dsdl2.ttf.getVersion() >= Version(2, 0, 18));
        }
        do {
            // `std.string.toStringz` doesn't have any `wstring` overloads.
            wchar[] ctext;
            ctext.length = text.length + 1;
            ctext[0 .. text.length] = text;
            ctext[text.length] = '\0';

            TextMeasurement measurement = void;
            if (TTF_MeasureUNICODE(cast(TTF_Font*) this.ttfFont, cast(ushort*) ctext.ptr, measureWidth.to!int,
                    cast(int*)&measurement[0], cast(int*)&measurement[1]) != 0) {
                throw new SDLException;
            }

            return measurement;
        }
    }
}
