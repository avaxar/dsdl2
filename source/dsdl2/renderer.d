/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.renderer;
@safe:

import bindbc.sdl;
import dsdl2.sdl;

import core.memory : GC;

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
}
