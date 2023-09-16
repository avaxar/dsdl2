/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.texture;
@safe:

import bindbc.sdl;
import dsdl2.sdl;
import dsdl2.blend;
import dsdl2.rect;
import dsdl2.frect;
import dsdl2.pixels;
import dsdl2.renderer;
import dsdl2.surface;

import core.memory : GC;
import std.conv : to;
import std.format : format;

/++
 + D enum that wraps `SDL_TextureAccess` in specifying texture access mode
 +/
enum TextureAccess {
    /++
     + Wraps `SDL_TEXTUREACCESS_*` enumeration constants
     +/
    static_ = SDL_TEXTUREACCESS_STATIC,
    streaming = SDL_TEXTUREACCESS_STREAMING, /// ditto
    target = SDL_TEXTUREACCESS_TARGET /// ditto
}

/++
 + D class that wraps `SDL_Texture` storing textures in GPU memory
 +/
final class Texture {
    private PixelFormat pixelFormatProxy = null;
    private bool isOwner = true;
    private void* userRef = null;

    @system SDL_Texture* sdlTexture; /// Internal `SDL_Texture` pointer

    /++
     + Constructs a `dsdl2.Texture` from a vanilla `SDL_Texture*` from bindbc-sdl
     +
     + Params:
     +   sdlTexture = the `SDL_Texture` pointer to manage
     +   isOwner    = whether the instance owns the given `SDL_Texture*` and should destroy it on its own
     +   userRef    = optional pointer to maintain reference link, avoiding GC cleanup
     +/
    this(SDL_Texture* sdlTexture, bool isOwner = true, void* userRef = null) @system
    in {
        assert(sdlTexture !is null);
    }
    do {
        this.sdlTexture = sdlTexture;
        this.pixelFormat();
        this.isOwner = isOwner;
        this.userRef = userRef;
    }

    /++
     + Creates a blank `dsdl2.Texture` in the VRAM, which wraps `SDL_CreateTexture`
     +
     + Params:
     +   renderer    = `dsdl2.Renderer` the texture belongs to
     +   pixelFormat = `dsdl2.PixelFormat` that the texture pixel data is stored as
     +   access      = `dsdl2.TextureAccess` enumeration which indicates its access rule
     +   size        = the size of the texture (width and height)
     + Throws: `dsdl2.SDLException` if creation failed
     +/
    this(Renderer renderer, PixelFormat pixelFormat, TextureAccess access, uint[2] size) @trusted
    in {
        assert(renderer !is null);
        assert(pixelFormat !is null);
    }
    do {
        this.sdlTexture = SDL_CreateTexture(renderer.sdlRenderer, pixelFormat.sdlPixelFormatEnum, access,
            size[0].to!int, size[1].to!int);
        if (this.sdlTexture is null) {
            throw new SDLException;
        }

        this.pixelFormat();
    }

    /++
     + Creates a `dsdl2.Texture` in the VRAM from a `dsdl2.Surface`, which wraps `SDL_CreateTextureFromSurface`
     +
     + Params:
     +   renderer = `dsdl2.Renderer` the texture belongs to
     +   surface  = `dsdl2.Surface` for its pixel data to be copied over to the texture
     + Throws: `dsdl2.SDLException` if creation failed
     +/
    this(Renderer renderer, Surface surface) @trusted
    in {
        assert(renderer !is null);
        assert(surface !is null);
    }
    do {
        this.sdlTexture = SDL_CreateTextureFromSurface(renderer.sdlRenderer, surface.sdlSurface);
        if (this.sdlTexture is null) {
            throw new SDLException;
        }

        this.pixelFormat();
    }

    ~this() @trusted {
        if (this.isOwner) {
            SDL_DestroyTexture(this.sdlTexture);
        }
    }

    @trusted invariant {
        // Instance might be in an invalid state due to holding a non-owned externally-freed object when
        // destructed in an unpredictable order.
        if (!this.isOwner && GC.inFinalizer) {
            return;
        }

        assert(this.sdlTexture !is null);
    }

    /++
     + Equality operator overload
     +/
    bool opEquals(const Texture rhs) const @trusted {
        return this.sdlTexture is rhs.sdlTexture;
    }

    /++
     + Gets the hash of the `dsdl2.Texture`
     +
     + Returns: unique hash for the instance being the pointer of the internal `SDL_Texture` pointer
     +/
    override hash_t toHash() const @trusted {
        return cast(hash_t) this.sdlTexture;
    }

    /++
     + Formats the `dsdl2.Texture` into its construction representation: `"dsdl2.Texture(<sdlTexture>)"`
     +
     + Returns: the formatted `string`
     +/
    override string toString() const @trusted {
        return "dsdl2.Texture(0x%x)".format(this.sdlTexture);
    }

    const(PixelFormat) pixelFormat() const @property @trusted {
        uint sdlPixelFormatEnum = void;
        if (SDL_QueryTexture(cast(SDL_Texture*) this.sdlTexture, &sdlPixelFormatEnum, null, null, null) != 0) {
            throw new SDLException;
        }

        // If the actual pixel format happens to change, rewire the proxy.
        if (this.pixelFormatProxy.sdlPixelFormatEnum != sdlPixelFormatEnum) {
            (cast(Texture) this).pixelFormatProxy = new PixelFormat(sdlPixelFormatEnum);
        }

        return this.pixelFormatProxy;
    }

    TextureAccess access() const @property @trusted {
        TextureAccess texAccess = void;
        if (SDL_QueryTexture(cast(SDL_Texture*) this.sdlTexture, null, cast(int*) texAccess, null, null) != 0) {
            throw new SDLException;
        }

        return texAccess;
    }

    uint width() const @property @trusted {
        uint w = void;
        if (SDL_QueryTexture(cast(SDL_Texture*) this.sdlTexture, null, null, cast(int*)&w, null) != 0) {
            throw new SDLException;
        }

        return w;
    }

    uint height() const @property @trusted {
        uint h = void;
        if (SDL_QueryTexture(cast(SDL_Texture*) this.sdlTexture, null, null, null, cast(int*)&h) != 0) {
            throw new SDLException;
        }

        return h;
    }

    uint[2] size() const @property @trusted {
        uint[2] wh = void;
        if (SDL_QueryTexture(cast(SDL_Texture*) this.sdlTexture, null, null, cast(int*)&wh[0],
                cast(int*)&wh[1]) != 0) {
            throw new SDLException;
        }

        return wh;
    }

    /++
     + Gets the color and alpha multipliers of the `dsdl2.Texture` that wraps `SDL_GetTextureColorMod` and
     + `SDL_GetTextureAlphaMod`
     +
     + Returns: color and alpha multipliers of the `dsdl2.Texture`
     +/
    Color mod() const @property @trusted {
        Color multipliers = void;
        SDL_GetTextureColorMod(cast(SDL_Texture*) this.sdlTexture, &multipliers.sdlColor.r,
            &multipliers.sdlColor.g, &multipliers.sdlColor.b);
        SDL_GetTextureAlphaMod(cast(SDL_Texture*) this.sdlTexture, &multipliers.sdlColor.a);
        return multipliers;
    }

    /++
     + Sets the color and alpha multipliers of the `dsdl2.Texture` that wraps `SDL_SetTextureColorMod` and
     + `SDL_SetTextureAlphaMod`
     +
     + Params:
     +   newMod = `dsdl2.Color` with `.r`, `.g`, `.b` as the color multipliers, and `.a` as the alpha
     +            multiplier
     +/
    void mod(Color newMod) @property @trusted {
        SDL_SetTextureColorMod(this.sdlTexture, newMod.r, newMod.g, newMod.b);
        SDL_SetTextureAlphaMod(this.sdlTexture, newMod.a);
    }

    /++
     + Wraps `SDL_GetTextureColorMod` which gets the color multipliers of the `dsdl2.Texture`
     +
     + Returns: color multipliers of the `dsdl2.Texture`
     +/
    ubyte[3] colorMod() const @property @trusted {
        ubyte[3] rgbMod = void;
        SDL_GetTextureColorMod(cast(SDL_Texture*) this.sdlTexture, &rgbMod[0], &rgbMod[1], &rgbMod[2]);
        return rgbMod;
    }

    /++
     + Wraps `SDL_SetTextureColorMod` which sets the color multipliers of the `dsdl2.Texture`
     +
     + Params:
     +   newColorMod = an array of `ubyte`s representing red, green, and blue multipliers (each 0-255)
     +/
    void colorMod(ubyte[3] newColorMod) @property @trusted {
        SDL_SetTextureColorMod(this.sdlTexture, newColorMod[0], newColorMod[1], newColorMod[2]);
    }

    /++
     + Wraps `SDL_GetTextureAlphaMod` which gets the alpha multiplier of the `dsdl2.Texture`
     +
     + Returns: alpha multiplier of the `dsdl2.Texture`
     +/
    ubyte alphaMod() const @property @trusted {
        ubyte aMod = void;
        SDL_GetTextureAlphaMod(cast(SDL_Texture*) this.sdlTexture, &aMod);
        return aMod;
    }

    /++
     + Wraps `SDL_SetTextureAlphaMod` which sets the alpha multiplier of the `dsdl2.Texture`
     +
     + Params:
     +   newAlphaMod = alpha multiplier (0-255)
     +/
    void alphaMod(ubyte newAlphaMod) @property @trusted {
        SDL_SetTextureAlphaMod(this.sdlTexture, newAlphaMod);
    }

    /++
     + Wraps `SDL_GetTextureBlendMode` which gets the `dsdl2.Texture`'s `dsdl2.BlendMode` defining drawing
     +
     + Returns: `dsdl2.BlendMode` of the `dsdl2.Texture`
     + Throws: `dsdl2.SDLException` if `dsdl2.BlendMode` unable to get
     +/
    BlendMode blendMode() const @property @trusted {
        BlendMode mode = void;
        if (SDL_GetTextureBlendMode(cast(SDL_Texture*) this.sdlTexture, &mode.sdlBlendMode) != 0) {
            throw new SDLException;
        }

        return mode;
    }

    /++
     + Wraps `SDL_SetTextureBlendMode` which sets the `dsdl2.Texture`'s `dsdl2.BlendMode` defining drawing
     +
     + Params:
     +   newMode = `dsdl2.BlendMode` to set
     + Throws: `dsdl2.SDLException` if `dsdl2.BlendMode` unable to set
     +/
    void blendMode(BlendMode newMode) @property @trusted {
        if (SDL_SetTextureBlendMode(this.sdlTexture, newMode.sdlBlendMode) != 0) {
            throw new SDLException;
        }
    }
}
