/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.texture;
@safe:

import bindbc.sdl;
import dsdl2.sdl;
import dsdl2.rect;
import dsdl2.frect;
import dsdl2.renderer;
import dsdl2.surface;

import core.memory : GC;
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
        this.isOwner = isOwner;
        this.userRef = userRef;
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
        return this.sdlTexture == rhs.sdlTexture;
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
}
